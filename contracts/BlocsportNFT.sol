// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

// contract BlocsportNFT is ERC1155, Ownable {
// 	using SafeMath for uint256;
// 	using Strings for string;
// 	uint256 public adoptedCats;

// 	//priceSetter can set the price & maxSupply for an NFT
// 	address public priceSetter;

// 	string public _baseURI = "https://api.nftdeals.io/v1/collection/item/metadata/";
// 	string public _contractURI =
// 		"https://nft-storage-system.s3.eu-west-1.amazonaws.com/nfts-1/contract_uri";
// 	mapping(uint256 => string) public _tokenURIs;

// 	mapping(uint256 => uint256) public totalSupply;
// 	mapping(uint256 => uint256) public price;
// 	mapping(uint256 => uint256) public maxSupply;

// 	constructor() ERC1155(_baseURI) {
// 		priceSetter = msg.sender;
// 	}

// 	/**@dev sets the price & maxSupply for an NFT. price is in wei */
// 	function setPriceAndMaxSupply(
// 		uint256 _index,
// 		uint256 _price,
// 		uint256 _maxSupply
// 	) public {
// 		require(msg.sender == priceSetter, "not price setter");
// 		require(_maxSupply >= maxSupply[_index], "not less than existing maxSupply");
// 		price[_index] = _price;
// 		maxSupply[_index] = _maxSupply;
// 	}

// 	/**@dev the core of the system. you can buy only one  */
// 	function buyNFT(uint256 _id) public payable {
// 		//get the item price
// 		require(price[_id] != 0, "price not set");
// 		require(msg.value == price[_id], "you should send the exact amount of ETH to buy this");
// 		require(totalSupply[_id] < maxSupply[_id], "max quantity reached");

// 		totalSupply[_id] = totalSupply[_id] + 1;
// 		_mint(msg.sender, _id, 1, "0x0000");
// 	}

// 	//the minting
// 	function mint(
// 		address to,
// 		uint256 id,
// 		uint256 qty,
// 		bytes memory data
// 	) public onlyOwner {
// 		require(totalSupply[id] < maxSupply[id], "max quantity reached");
// 		totalSupply[id] = totalSupply[id] + qty;
// 		_mint(to, id, qty, data);
// 	}

// 	//burns one token
// 	function burn(
// 		address account,
// 		uint256 id,
// 		uint256 value
// 	) public virtual {
// 		require(
// 			account == _msgSender() || isApprovedForAll(account, _msgSender()),
// 			"ERC1155: caller is not owner nor approved"
// 		);
// 		_burn(account, id, value);
// 		totalSupply[id] = totalSupply[id] - 1;
// 	}

// 	function setBaseURI(string memory newuri) public onlyOwner {
// 		_baseURI = newuri;
// 	}

// 	function setContractURI(string memory newuri) public onlyOwner {
// 		_contractURI = newuri;
// 	}

// 	// sets the priceSetter address.
// 	function setPriceSetter(address _newPriceSetter) public onlyOwner {
// 		priceSetter = _newPriceSetter;
// 	}

// 	function uri(uint256 tokenId) public view override returns (string memory) {
// 		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
// 	}

// 	function tokenURI(uint256 tokenId) public view returns (string memory) {
// 		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
// 	}

// 	function contractURI() public view returns (string memory) {
// 		return _contractURI;
// 	}

// 	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
// 		if (_i == 0) {
// 			return "0";
// 		}
// 		uint256 j = _i;
// 		uint256 len;
// 		while (j != 0) {
// 			len++;
// 			j /= 10;
// 		}
// 		bytes memory bstr = new bytes(len);
// 		uint256 k = len;
// 		while (_i != 0) {
// 			k = k - 1;
// 			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
// 			bytes1 b1 = bytes1(temp);
// 			bstr[k] = b1;
// 			_i /= 10;
// 		}
// 		return string(bstr);
// 	}

// 	/**
// 	 * @dev Indicates weither any token exist with a given id, or not.
// 	 */
// 	function exists(uint256 id) public view virtual returns (bool) {
// 		return totalSupply[id] > 0;
// 	}

// 	// withdraw the earnings
// 	function withdraw() public onlyOwner {
// 		uint256 balance = address(this).balance;
// 		payable(msg.sender).transfer(balance);
// 	}

// 	// reclaim accidentally sent tokens
// 	function reclaimToken(IERC20 token) public onlyOwner {
// 		require(address(token) != address(0));
// 		uint256 balance = token.balanceOf(address(this));
// 		token.transfer(msg.sender, balance);
// 	}
// }
