// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title MockJPYC
 * @dev Mock JPYC token for testing purposes
 */
contract MockJPYC is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(uint256 initialSupply) ERC20("JPY Coin", "JPYC") Ownable(msg.sender) ERC20Permit("JPY Coin") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
