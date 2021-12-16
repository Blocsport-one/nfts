// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBS1NFT {
	function getTire(uint256 nftID) external view returns (uint256);

	function transferFrom(
		address from,
		address to,
		uint256 id
	) external;
}

//ShardManager converts an NFT into an ERC20 token
contract ShardManager is
	Context,
	ERC20Permit,
	ERC20Burnable,
	Ownable,
	IERC721Receiver,
	ReentrancyGuard
{
	IBS1NFT public bs1NFT; //address of bss1NFT

	constructor(address _bss1NFT) ERC20Permit("Blocsport.one") ERC20("Blocsport.one", "LPUD") {
		bs1NFT = IBS1NFT(_bss1NFT);
	}

	//only the initial owner of the NFT can redeem it
	mapping(uint256 => address) public initialOwner;

	bool public onlyOwnerClaimEnabled = true;

	event NFTConvertedToShards(uint256 nftID, uint256 shardsAmount);
	event ShardsConvertedToNFT(uint256 nftID, uint256 shardsAmount);

	//how many shards this NFT will generate
	//tier 1 tokens for 1 NFT  - 1000 ERC20
	//tier 2 tokens for 1 NFT- 3000 ERC20
	//tier 3 tokens for 1 NFT - 6 000 ERC20
	//tier 4 tokens for 1 NFT - 10000 ERC20
	function shardsPerToken(uint256 _id) public view returns (uint256) {
		if (bs1NFT.getTire(_id) == 1) {
			return 1000 ether;
		}
		if (bs1NFT.getTire(_id) == 2) {
			return 3000 ether;
		}
		if (bs1NFT.getTire(_id) == 3) {
			return 6000 ether;
		}
		if (bs1NFT.getTire(_id) == 4) {
			return 10000 ether;
		}
		return 0;
	}

	//deposits an NFT to get shards equivalence. must have setApprovalForAll
	function getShards(uint256 _id) external nonReentrant {
		require(bs1NFT.getTire(_id) > 0, "this NFT has no tire set");

		uint256 shards = shardsPerToken(_id);
		require(shards != 0, "invalid number of shards");

		initialOwner[_id] = msg.sender; //set the initial owner

		bs1NFT.transferFrom(msg.sender, address(this), _id);

		_mint(msg.sender, shards);
		emit NFTConvertedToShards(_id, shards);
	}

	//returns the NFT after you deposit back the shards
	function getNFT(uint256 _id) external nonReentrant {
		uint256 shards = shardsPerToken(_id);
		require(shards != 0, "invalid number of shards");
		if (onlyOwnerClaimEnabled) {
			require(initialOwner[_id] == msg.sender, "only initial owner can redeem the NFT");
		}

		//burns shards!
		burn(shards);

		//transfer the NFTs
		bs1NFT.transferFrom(address(this), msg.sender, _id);

		emit ShardsConvertedToNFT(_id, shards);
	}

	// can change if NFTs are claimable by everyone using shards or just the owner
	function setOnlyOwnerClaimEnabled(bool _isEnabled) public onlyOwner {
		onlyOwnerClaimEnabled = _isEnabled;
	}

	// change the address of bss1NFT.
	function changeNFTAddress(address _newAddress) public onlyOwner {
		bs1NFT = IBS1NFT(_newAddress);
	}

	// reclaim accidentally sent eth
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// reclaim accidentally sent tokens
	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function onERC721Received(
		address,
		address from,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		require(from == address(0x0), "Cannot send tokens to Barn directly");
		return IERC721Receiver.onERC721Received.selector;
	}
}
