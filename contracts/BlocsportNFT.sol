// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BlocsportNFT is ERC1155Burnable, Ownable, Pausable {
	using Strings for string;

	address[] public minters;
	string public _baseURI = "https://api.nftdeals.io/v1/collection/item/metadata/";
	string public _contractURI =
		"https://nft-storage-system.s3.eu-west-1.amazonaws.com/nfts-1/contract_uri";

	constructor() ERC1155(_baseURI) {}

	//mint 1 NFT with quantity 'quantity' to the receiver
	function mint(
		address receiver,
		uint256 nftID,
		uint256 quantity,
		bytes memory data //use "0x0000"
	) external whenNotPaused {
		require(isMinter(msg.sender), "only minters can call this");
		_mint(receiver, nftID, quantity, data);
	}

	//airdrops an NFT
	function airdrop(
		address[] memory receivers,
		uint256[] memory quantities,
		uint256[] memory NFTIDs,
		bytes[] memory datas //pass "0x0000"
	) external whenNotPaused {
		require(receivers.length == quantities.length, "arrays should be equal");
		require(receivers.length == NFTIDs.length, "arrays should be equal 2");
		require(isMinter(msg.sender), "only minters can call this");
		require(receivers.length <= 50, "max 50 addresses per call");
		for (uint256 i = 0; i < receivers.length; i++) {
			_mint(receivers[i], NFTIDs[i], quantities[i], datas[i]);
		}
	}

	//airdrop an ERC20 Token
	//requires allowance: await erc20.increaseAllowance(address, "999999999999999999999999999999")
	function airdropToken(
		address[] memory receivers,
		uint256[] memory amounts,
		address tokenAddress,
		uint256 decimalFactor
	) external whenNotPaused {
		require(isMinter(msg.sender), "only minters can call this");
		require(receivers.length <= 50, "max 50 addresses per call");
		require(receivers.length == amounts.length, "arrays should be equal");
		IERC20 erc20token = IERC20(tokenAddress);
		for (uint256 index = 0; index < receivers.length; index++) {
			erc20token.transferFrom(msg.sender, receivers[index], amounts[index] * (10**decimalFactor));
		}
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	//adds a new minter to the minter's list
	function addMinter(address newMinter) public onlyOwner {
		if (!isMinter(newMinter)) {
			minters.push(newMinter);
		}
	}

	//removes a minter from the minter's list
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

	function uri(uint256 tokenId) public view override returns (string memory) {
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

	//see what's the current timestamp
	function currentTimestamp() public view returns (uint256) {
		return block.timestamp;
	}

	// withdraw the earnings to pay for the artists & devs :)
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	// reclaim accidentally sent tokens
	function reclaimERC20Token(IERC20 token) external onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}
