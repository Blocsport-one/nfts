// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BlocsportNFTERC721 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

	address[] public minters;
    string private _baseTokenURI = "https://api.nftdeals.io/v1/collection/item/metadata/";
    string private _contractURI = "https://nft-storage-system.s3.eu-west-1.amazonaws.com/nfts-1/contract_uri";

    constructor() ERC721("BlocsportNFT", "BLSNFT") {}

    function mint(uint256 qty, address to) external payable {
        require(qty > 0, "minimum 1 token");
        require(isMinter(msg.sender), "only minters can call this");

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(to, totalSupply() + 1);
        }
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
    
    function burn(uint256 tokenId) public virtual {
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

    // earnings withdrawal
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

	function getBackERC1155(IERC1155 erc1155Token, uint256 id) public onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	function getBackERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}
}