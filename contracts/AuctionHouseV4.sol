// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AuctionHouse is Ownable, Pausable, ReentrancyGuard {
    uint256 public auctionPeriod = 1 days;
    uint256 public auctionBoost = 5 minutes;
    uint256 public tick = 0.01 ether;
    uint256 marketFee = 300; //3%
    mapping(uint256 => SellListing) public sellListings;
    mapping(uint256 => AuctionListing) public auctions;
    mapping(uint256 => bool) public auctionActive;
    uint256 public auctionCount = 0;
    uint256 public sellsCount = 0;
    uint256 minSaleTime = 2 minutes;
    uint256 maxSaleTime = 2592000; // 30 days

    //address -> funds available to withdraw
    mapping(address => uint256) public fundsByAddress;

    event AuctionListed(
        uint256 auction_id,
        address auctioneer,
        address auctionToken,
        uint256 startPrice,
        uint256 tick,
        uint256 endTime
    );
    event BidPlaced(uint256 auction_id, address indexed bidder, uint256 price);
    event AuctionWon(uint256 auction_id, uint256 highestBid, address winner);
    event OnSale(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        uint256 endTime,
        address seller
    );
    event ListingSold(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        address buyer
    );
    event RemovedFromSale(
        address indexed nftContract,
        uint256 saleID,
        uint256 itemID,
        uint256 price,
        address seller
    );

    struct AuctionListing {
        address auctioneer;
        uint256 auctionId;
        uint256 nftID;
        address nftContract;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 currentBid;
        uint256 tick;
        uint256 bidCount;
        address highBidder;
    }
    struct SellListing {
        address seller;
        uint256 nftID;
        address nftContract;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool sold;
    }

    //nothing fancy
    constructor() {
        sellsCount = 0;
        auctionCount = 0;
    }

    /// @notice Create an auction listing and take custody of item
    /// @dev Note - this doesn't start the auction or the timer.
    /// @param nftContract Address of the token/NFT being listed
    /// @param nftID Item identifier for NFT listing types
    /// @param startPrice Starting price of auction. For auctions > 0.01 starting price, tick is set to 0.01, else it matches precision of the start price (triangular auction)
    function createAuction(
        address nftContract,
        uint256 nftID,
        uint256 startPrice
    ) external whenNotPaused {
        require(startPrice >= 0.01 ether, "startprice should be >= 0.01 ether");
        require(nftContract != address(0), "tokenContract != address(0)");
        //NFT deposit //MUST BE APPROVED BEFORE!
        if (isERC721(nftContract)) {
            IERC721 auctionToken = IERC721(nftContract);
            auctionToken.safeTransferFrom(msg.sender, address(this), nftID);
        } else if (isERC1155(nftContract)) {
            IERC1155 auctionToken = IERC1155(nftContract);
            auctionToken.safeTransferFrom(
                msg.sender,
                address(this),
                nftID,
                1,
                ""
            );
        } else {
            revert("only ERC721 and ERC1155 types of tokens are supported");
        }
        AuctionListing memory al = AuctionListing(
            msg.sender,
            auctionCount,
            nftID,
            nftContract,
            0,
            0,
            startPrice,
            startPrice,
            0,
            0,
            address(0)
        );
        al.tick = tick;
        al.startTime = block.timestamp;
        al.endTime = block.timestamp + auctionPeriod;
        auctions[auctionCount] = al;
        auctionActive[auctionCount] = true;
        emit AuctionListed(
            al.auctionId,
            msg.sender,
            nftContract,
            al.startPrice,
            tick,
            al.endTime
        );
        auctionCount = auctionCount + 1;
    }

    /// @notice Place a bid on an auction
    /// @param auctionId uint. Which listing to place bid on.
    function bid(uint256 auctionId) external payable nonReentrant {
        require(auctionId < auctionCount, "auctionId < auctionCount");
        require(
            auctionActive[auctionId] == true,
            "auctionActive[auctionId] == true"
        );
        AuctionListing storage al = auctions[auctionId];
        require(block.timestamp < al.endTime, "auction expired");
        uint256 currentBid = al.currentBid;
        if (al.bidCount > 0) {
            require(
                msg.value >= currentBid + al.tick,
                "msg.value >= currentBid + al.tick"
            );
            //refund the previous bidder
            if (al.highBidder != address(0)) {
                fundsByAddress[al.highBidder] += al.currentBid; // record the refund that this user can claim
            }
        } else {
            require(msg.value >= al.startPrice, "msg.value >= al.startPrice");
        }
        al.currentBid = msg.value;
        al.highBidder = msg.sender;
        al.bidCount = al.bidCount + 1;
        if (((al.endTime - block.timestamp) + auctionBoost) < auctionPeriod)
            al.endTime = al.endTime + auctionBoost;
        auctions[auctionId] = al;
        emit BidPlaced(al.auctionId, msg.sender, msg.value);
    }

    /// @notice Claim. Release the goods and send funds to auctioneer. If no bids, item is returned to auctioneer!
    /// @param auctionId uint. Which listing to claim.
    function claim(uint256 auctionId) external nonReentrant {
        require(auctionId < auctionCount, "auctionId < auctionCount");
        require(
            auctionActive[auctionId] == true,
            "auctionActive[auctionId] == true"
        );
        AuctionListing storage al = auctions[auctionId];
        require(block.timestamp >= al.endTime, "ongoing auction");
        auctionActive[auctionId] = false;
        //auctions[auctionId].tokenContract = address(0);
        if (al.bidCount == 0) {
            //Release the item back to the auctioneer
            if (isERC721(al.nftContract)) {
                IERC721 auctionToken = IERC721(al.nftContract);
                auctionToken.safeTransferFrom(
                    address(this),
                    al.auctioneer,
                    auctions[auctionId].nftID
                );
            } else if (isERC1155(al.nftContract)) {
                IERC1155 auctionToken = IERC1155(al.nftContract);
                auctionToken.safeTransferFrom(
                    address(this),
                    al.auctioneer,
                    auctions[auctionId].nftID,
                    1,
                    ""
                );
            }
        } else {
            //Release the item to highestBidder
            if (isERC721(al.nftContract)) {
                IERC721 auctionToken = IERC721(al.nftContract);
                auctionToken.safeTransferFrom(
                    address(this),
                    al.highBidder,
                    auctions[auctionId].nftID
                );
            } else if (isERC1155(al.nftContract)) {
                IERC1155 auctionToken = IERC1155(al.nftContract);
                auctionToken.safeTransferFrom(
                    address(this),
                    al.highBidder,
                    auctions[auctionId].nftID,
                    1,
                    ""
                );
            }
            //Release the funds to auctioneer
            fundsByAddress[al.auctioneer] += al.currentBid;
            emit AuctionWon(auctionId, al.currentBid - al.tick, al.highBidder);
        }
    }

    /// @notice Returns time left in seconds or 0 if auction is over or not active.
    /// @param auctionId uint. Which auction to query.
    function getTimeLeft(uint256 auctionId) external view returns (uint256) {
        require(auctionId < auctionCount);
        uint256 time = block.timestamp;
        AuctionListing memory al = auctions[auctionId];
        return (time > al.endTime) ? 0 : al.endTime - time;
    }

    //puts an NFT for a simple sale
    //saleDurationInSeconds - if you go over it, the sale is canceled and the nft must be removeFromSale
    function putForSale(
        address nftContract,
        uint256 nftID,
        uint256 price,
        uint256 saleDurationInSeconds
    ) external whenNotPaused nonReentrant {
        require(price >= 0.01 ether, "price must be >= 0.01 ether");
        require(nftContract != address(0), "tokenContract != address(0)");
        require(
            saleDurationInSeconds >= minSaleTime,
            "sale time < minSaleTime"
        );
        require(
            saleDurationInSeconds <= maxSaleTime,
            "sale time > maxSaleTime"
        );
        //transfer the tokens
        if (isERC721(nftContract)) {
            IERC721 auctionToken = IERC721(nftContract);
            auctionToken.safeTransferFrom(msg.sender, address(this), nftID);
        } else if (isERC1155(nftContract)) {
            IERC1155 auctionToken = IERC1155(nftContract);
            auctionToken.safeTransferFrom(
                msg.sender,
                address(this),
                nftID,
                1,
                ""
            );
        } else {
            revert(
                "only ERC721 and ERC1155 types of tokens are supported for sale"
            );
        }
        //update the storage
        SellListing memory sl = SellListing(
            msg.sender,
            nftID,
            nftContract,
            block.timestamp,
            block.timestamp + saleDurationInSeconds,
            price,
            false //sold
        );

        sellListings[sellsCount] = sl;

        emit OnSale(
            nftContract,
            sellsCount, // saleID
            nftID,
            price,
            block.timestamp + saleDurationInSeconds,
            msg.sender
        );

        sellsCount = sellsCount + 1;
    }

    //removeFromSale returs the item to the owner
    function removeFromSale(uint256 saleID) external {
        SellListing storage sl = sellListings[saleID];
        require(sl.sold == false, "can't claim a sold item");
        require(msg.sender == sl.seller, "only the seller can remove it");
        //Release the item back to the auctioneer
        if (isERC721(sl.nftContract)) {
            IERC721 auctionToken = IERC721(sl.nftContract);
            auctionToken.safeTransferFrom(address(this), msg.sender, sl.nftID);
        } else if (isERC1155(sl.nftContract)) {
            IERC1155 auctionToken = IERC1155(sl.nftContract);
            auctionToken.safeTransferFrom(
                address(this),
                msg.sender,
                sl.nftID,
                1,
                ""
            );
        }

        emit RemovedFromSale(
            sl.nftContract,
            saleID,
            sl.nftID,
            sl.price,
            msg.sender
        );
    }

    // buys an NFT from a sale
    function buyItem(uint256 saleID) external payable nonReentrant {
        SellListing storage sl = sellListings[saleID];
        require(block.timestamp <= sl.endTime, "sale period expired");
        require(sl.sold == false, "can't buy a sold item");
        require(msg.value == sl.price, "msg.value == listig price");
        //fees
        uint256 _marketFee = _calcPercentage(msg.value, marketFee);
        payable(sl.seller).transfer(msg.value - _marketFee);
        //no need to transfer the market fee, the amount is in the contract
        sl.sold = true;
        //transfer the tokens
        if (isERC721(sl.nftContract)) {
            IERC721 auctionToken = IERC721(sl.nftContract);
            auctionToken.safeTransferFrom(address(this), msg.sender, sl.nftID);
        } else if (isERC1155(sl.nftContract)) {
            IERC1155 auctionToken = IERC1155(sl.nftContract);
            auctionToken.safeTransferFrom(
                address(this),
                msg.sender,
                sl.nftID,
                1,
                ""
            );
        } else {
            revert(
                "only ERC721 and ERC1155 types of tokens are supported for sale"
            );
        }

        emit ListingSold(
            sl.nftContract,
            saleID,
            sl.nftID,
            sl.price,
            msg.sender
        );
    }

    //get the $ that you're supposed to
    function withdrawByAddress() external {
        uint256 refund = fundsByAddress[msg.sender];
        fundsByAddress[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: refund}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    // withdraw the ETH from this contract (ONLY OWNER)
    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed.");
    }

    //get stuck tokens back
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

    // changes the market fee. 50 = 0.5%
    function changeMarketFee(uint256 _marketFee) external onlyOwner {
        marketFee = _marketFee;
    }

    function isERC721(address contractAddr) internal view returns (bool) {
        if (ERC165(contractAddr).supportsInterface(0x80ac58cd)) {
            return true;
        }
        return false;
    }

    function isERC1155(address contractAddr) internal view returns (bool) {
        if (ERC165(contractAddr).supportsInterface(0xd9b67a26)) {
            return true;
        }
        return false;
    }

    //300 = 3%, 1 = 0.01%
    function _calcPercentage(uint256 amount, uint256 basisPoints)
        internal
        pure
        returns (uint256)
    {
        require(basisPoints >= 0);
        return (amount * basisPoints) / 10000;
    }

    // makes life easier
    function getCurrentBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //others
    /**
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) external onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }
}
