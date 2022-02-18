// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20, Ownable {
	constructor() ERC20("BLS", "BLS") {
		_mint(msg.sender, 1000000000 * (10**uint256(18)));
	}
}