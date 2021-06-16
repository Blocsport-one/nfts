// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlocsportNFT is ERC1155, Ownable {
	using SafeMath for uint256;
	using Strings for string;
	uint256 public adoptedCats;
	mapping(uint256 => uint256) private _totalSupply;

	string public _baseURI = "https://api.nftdeals.io/v1/collection/item/metadata/";
	string public _contractURI =
		"https://raw.githubusercontent.com/Blocsport-one/nfts/master/contract-uri.json";
	mapping(uint256 => string) public _tokenURIs;

	uint256[] priceRanges = new uint256[](8);
	uint256[] limitRanges = new uint256[](8);

	constructor() ERC1155(_baseURI) {
		//initial prices
		priceRanges[0] = 14.7 ether;
		priceRanges[1] = 7.36 ether;
		priceRanges[2] = 2.94 ether;
		priceRanges[3] = 1.47 ether;
		priceRanges[4] = 0.74 ether;
		priceRanges[5] = 0.3 ether;
		priceRanges[6] = 0.1 ether;
		priceRanges[7] = 0.05 ether;

		//max supply of a token in range
		limitRanges[0] = 10;
		limitRanges[1] = 10;
		limitRanges[2] = 300;
		limitRanges[3] = 1000;
		limitRanges[4] = 1000;
		limitRanges[5] = 1000;
		limitRanges[6] = 3000;
		limitRanges[7] = 5000;
	}

	/**@dev sets the price for a range  */
	function setPriceRange(uint256 _index, uint256 _newPrice) public onlyOwner {
		priceRanges[_index] = _newPrice;
	}

	/**@dev gets the price for a range  */
	function getPriceForRange(uint256 _index) internal view returns (uint256) {
		return priceRanges[_index];
	}

	/**@dev gets the max supply for a range  */
	function getLimitForRange(uint256 _index) internal view returns (uint256) {
		return limitRanges[_index];
	}

	/**@dev returns the price for an NFT */
	function getItemPrice(uint256 _id) public view returns (uint256) {
		uint256 priceRange = 0;
		if (_id <= 500) {
			priceRange = getPriceForRange(0);
		}
		if (_id > 500 && _id <= 5000) {
			priceRange = getPriceForRange(1);
		}
		if (_id > 5000 && _id <= 10000) {
			priceRange = getPriceForRange(2);
		}
		if (_id > 10000 && _id <= 50000) {
			priceRange = getPriceForRange(3);
		}
		if (_id > 50000 && _id <= 100000) {
			priceRange = getPriceForRange(4);
		}
		if (_id > 100000 && _id <= 500000) {
			priceRange = getPriceForRange(5);
		}
		if (_id > 500000 && _id <= 1000000) {
			priceRange = getPriceForRange(6);
		}
		if (_id > 1000000) {
			priceRange = getPriceForRange(7);
		}
		return priceRange;
	}

	/**@dev returns the price for an NFT */
	function getItemMaxSupply(uint256 _id) public view returns (uint256) {
		uint256 maxSupplyOfID = 0;
		if (_id <= 500) {
			maxSupplyOfID = getLimitForRange(0);
		}
		if (_id > 500 && _id <= 5000) {
			maxSupplyOfID = getLimitForRange(1);
		}
		if (_id > 5000 && _id <= 10000) {
			maxSupplyOfID = getLimitForRange(2);
		}
		if (_id > 10000 && _id <= 50000) {
			maxSupplyOfID = getLimitForRange(3);
		}
		if (_id > 50000 && _id <= 100000) {
			maxSupplyOfID = getLimitForRange(4);
		}
		if (_id > 100000 && _id <= 500000) {
			maxSupplyOfID = getLimitForRange(5);
		}
		if (_id > 500000 && _id <= 1000000) {
			maxSupplyOfID = getLimitForRange(6);
		}
		if (_id > 1000000) {
			maxSupplyOfID = getPriceForRange(7);
		}
		return maxSupplyOfID;
	}

	/**@dev the core of the system. you can buy only one  */
	function buyNFT(uint256 _id) public payable {
		//get the item price
		require(msg.value == getItemPrice(_id), "you should send the exact amount of ETH to buy this");
		require(_totalSupply[_id] < getItemMaxSupply(_id), "max quantity reached");

		_totalSupply[_id] = _totalSupply[_id] + 1;
		_mint(msg.sender, _id, 1, "0x0000");
	}

	//the minting
	function mint(
		address to,
		uint256 id,
		uint256 qty,
		bytes memory data
	) public onlyOwner {
		require(_totalSupply[id] < getItemMaxSupply(id), "max quantity reached");
		_totalSupply[id] = _totalSupply[id] + qty;
		_mint(to, id, qty, data);
	}

	//burns one token
	function burn(
		address account,
		uint256 id,
		uint256 value
	) public virtual {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_burn(account, id, value);
		_totalSupply[id] = _totalSupply[id] - 1;
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	/**
	 * @dev Total amount of tokens in with a given id.
	 */
	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	/**
	 * @dev Indicates weither any token exist with a given id, or not.
	 */
	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	// withdraw the earnings
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	// reclaim accidentally sent tokens
	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}
