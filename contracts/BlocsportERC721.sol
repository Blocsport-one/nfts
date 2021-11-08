// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BlocsportERC721 is ERC721Enumerable, Ownable {
	using Strings for uint256;
	using ECDSA for bytes32;

	string private _baseTokenURI = "https://xxxxxxxxxxxx";
	string private _contractURI = "https://yyyyyyyyyyyyy";

	uint256 public maxSupply = 30000;

	uint256 public pricePerTokenTier1 = 70000000000000000; //0.07 ETH
	uint256 public pricePerTokenTier2 = 80000000000000000; //0.08 ETH
	uint256 public pricePerTokenTier3 = 90000000000000000; //0.09 ETH
	uint256 public pricePerTokenTier4 = 100000000000000000; //0.1 ETH

	mapping(uint256 => uint256) public tire;

	bool public saleLive = true; //TODO: make it false for live!
	address private devWallet;

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev can modify");
		_;
	}

	constructor() ERC721("Blocksport", "BS1") {
		devWallet = msg.sender;
	}

	function publicBuy(uint256 nftTier, uint256 qty) external payable {
		require(saleLive, "sale not live");
		require(qty <= 20, "no more than 20");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		if (nftTier == 1) {
			require(pricePerTokenTier1 * qty == msg.value, "exact amount needed");
		} else if (nftTier == 2) {
			require(pricePerTokenTier2 * qty == msg.value, "exact amount needed");
		} else if (nftTier == 3) {
			require(pricePerTokenTier3 * qty == msg.value, "exact amount needed");
		} else if (nftTier == 4) {
			require(pricePerTokenTier4 * qty == msg.value, "exact amount needed");
		} else {
			revert("unknown tier");
		}

		for (uint256 i = 0; i < qty; i++) {
			tire[totalSupply() + 1] = nftTier;
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	// admin can mint for giveaways, airdrops etc
	function adminMint(uint256 nftTier, address to) external onlyOwner {
		require(totalSupply() + 1 <= maxSupply, "out of stock");
		tire[totalSupply() + 1] = nftTier;
		_safeMint(to, totalSupply() + 1);
	}

	// overwrite the tier
	function setTier(uint256 nftID, uint256 nftTier) external onlyOwner {
		tire[nftID] = nftTier;
	}

	//----------------------------------
	//---------- other things ----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
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

	function burn(uint256 tokenId) external virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
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

	// withdrawals
	function withdrawEarnings() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyDev {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyDev {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) external onlyDev {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	//toggle sale on/off
	function toggleSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	//change the price per NFT according to their tier
	function changeTierPrice(uint256 tier, uint256 newPrice) external onlyOwner {
		if (tier == 1) {
			pricePerTokenTier1 = newPrice;
		}
		if (tier == 2) {
			pricePerTokenTier2 = newPrice;
		}
		if (tier == 3) {
			pricePerTokenTier3 = newPrice;
		}
		if (tier == 4) {
			pricePerTokenTier4 = newPrice;
		}
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	//easy for some devs
	function getTire(uint256 nftID) external view returns (uint256) {
		return tire[nftID];
	}
}
