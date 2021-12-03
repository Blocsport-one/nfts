// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BalliesNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private _baseTokenURI = "https://api.ballies.gg/v1/nft/metadata/";
    string private _contractURI =
        "ipfs://QmW9pbU8DHYUz2Ap1wRQivnu1gE9S2zgwX8xu1hC8DDgNo/contracts/contract_uri";

    uint256 public maxSupply = 9999;
    uint256 public salePrice = 10000000000000000; // default 0.01  - update prices for BNB

    uint256 public privateSaleStartTime = block.timestamp; // update to correct
    uint256 public publicSaleStartTime = block.timestamp; // update to correct

    address[] public minters;

    constructor() ERC721("BalliesNFT", "BALL") {
        addMinter(msg.sender);
    }

    function privateSale(uint256 qty, address to) external payable {
        require(
            block.timestamp >= privateSaleStartTime,
            "private sale not live"
        );
        require(isMinter(msg.sender), "only minters can call this");
        require(qty > 0 && qty <= 3, "minimum of 1 and maximum of 3 token");
        require(salePrice * qty == msg.value, "exact BNB amount needed");
        require(
            totalSupply() + qty <= maxSupply,
            "out of stock (total supply)"
        );

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function publicSale(uint256 qty, address to) external payable {
        require(block.timestamp >= publicSaleStartTime, "public sale not live");
        require(qty > 0 && qty <= 3, "minimum of 1 and maximum of 3 token");
        require(salePrice * qty == msg.value, "exact BNB amount needed");
        require(
            totalSupply() + qty <= maxSupply,
            "out of stock (total supply)"
        );

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    /// owner related functions
    function addMinter(address newMinter) public onlyOwner {
        if (!isMinter(newMinter)) {
            minters.push(newMinter);
        }
    }

    function removeMinter(address minter) public onlyOwner {
        removeByValue(minter);
    }

    function listMinters() public view returns (address[] memory) {
        return minters;
    }

    function isMinter(address newMinter) public view returns (bool) {
        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == newMinter) {
                return true;
            }
        }
        return false;
    }

    function find(address value) internal view returns (uint256) {
        uint256 i = 0;
        while (minters[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(address value) internal {
        uint256 i = find(value);
        removeByIndex(i);
    }

    function removeByIndex(uint256 i) internal {
        delete minters[i];
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function changeSalePrice(uint256 newPrice) external onlyOwner {
        salePrice = newPrice;
    }

    function setPrivateSaleStartTime(uint256 _saleStartTime)
        external
        onlyOwner
    {
        privateSaleStartTime = _saleStartTime;
    }

    function setPublicSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        publicSaleStartTime = _saleStartTime;
    }

    /// interface functions
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setContractURI(string memory newuri) public onlyOwner {
        _contractURI = newuri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// earnings withdrawal
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function getBackERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function getBackERC1155(IERC1155 erc1155Token, uint256 id)
        public
        onlyOwner
    {
        erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    function getBackERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }
}
