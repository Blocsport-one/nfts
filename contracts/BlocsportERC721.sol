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

	uint256 public maxSupplyT1 = 5000;
	uint256 public maxSupplyT2 = 5000;
	uint256 public maxSupplyT3 = 5000;
	uint256 public maxSupplyT4 = 5000;

	uint256 public totalMintedT1 = 0;
	uint256 public totalMintedT2 = 0;
	uint256 public totalMintedT3 = 0;
	uint256 public totalMintedT4 = 0;

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

		if (nftTier == 1) {
			require(pricePerTokenTier1 * qty == msg.value, "exact amount needed");
			require(totalMintedT1 + qty <= maxSupplyT1, "out of stock T1");
			totalMintedT1 = totalMintedT1 + qty;
		} else if (nftTier == 2) {
			require(pricePerTokenTier2 * qty == msg.value, "exact amount needed");
			require(totalMintedT2 + qty <= maxSupplyT2, "out of stock T2");
			totalMintedT2 = totalMintedT2 + qty;
		} else if (nftTier == 3) {
			require(pricePerTokenTier3 * qty == msg.value, "exact amount needed");
			require(totalMintedT3 + qty <= maxSupplyT3, "out of stock T3");
			totalMintedT3 = totalMintedT3 + qty;
		} else if (nftTier == 4) {
			require(pricePerTokenTier4 * qty == msg.value, "exact amount needed");
			require(totalMintedT4 + qty <= maxSupplyT4, "out of stock T4");
			totalMintedT4 = totalMintedT4 + qty;
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
		if (nftTier == 1) {
			require(totalMintedT1 + 1 <= maxSupplyT1, "out of stock T1");
			totalMintedT1 = totalMintedT1 + 1;
		} else if (nftTier == 2) {
			require(totalMintedT2 + 1 <= maxSupplyT2, "out of stock T2");
			totalMintedT2 = totalMintedT2 + 1;
		} else if (nftTier == 3) {
			require(totalMintedT3 + 1 <= maxSupplyT3, "out of stock T3");
			totalMintedT3 = totalMintedT3 + 1;
		} else if (nftTier == 4) {
			require(totalMintedT4 + 1 <= maxSupplyT4, "out of stock T4");
			totalMintedT4 = totalMintedT4 + 1;
		} else {
			revert("unknown tier");
		}
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

	//modify the tires supply
	function changeTireMaxSupply(uint256 tier, uint256 newMaxSupply) external onlyOwner {
		if (tier == 1) {
			require(newMaxSupply < maxSupplyT1, "you can only lower it");
			maxSupplyT1 = newMaxSupply;
		}
		if (tier == 2) {
			require(newMaxSupply < maxSupplyT2, "you can only lower it");
			maxSupplyT2 = newMaxSupply;
		}
		if (tier == 3) {
			require(newMaxSupply < maxSupplyT3, "you can only lower it");
			maxSupplyT3 = newMaxSupply;
		}
		if (tier == 4) {
			require(newMaxSupply < maxSupplyT4, "you can only lower it");
			maxSupplyT4 = newMaxSupply;
		}
	}

	//easy for some devs
	function getTire(uint256 nftID) external view returns (uint256) {
		return tire[nftID];
	}
}
