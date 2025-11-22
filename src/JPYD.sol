// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title JPYD
 * @dev JPY-pegged stablecoin with 18 decimals (same as JPYC)
 * 
 * Features:
 * - ERC20 compliant (standard transfer, transferFrom, approve, allowance, balanceOf functions)
 * - Token holders can burn their own tokens (via burn() and burnFrom() from ERC20Burnable)
 * - Owner can mint new tokens (via mint() function)
 * - EIP-2612 permit functionality (gasless approvals via permit() function)
 * 
 * Note: This contract is designed to be compatible with existing JPYC token.
 * For automatic notification functionality when transferring to contracts,
 * use JPYDWrapper contract. This allows JPYD to work with both JPYC and custom
 * automatic payment processing without modifying the token contract itself.
 */
contract JPYD is ERC20, ERC20Burnable, Ownable, ERC20Permit {

    /**
     * @dev Constructor that gives msg.sender initial supply of tokens
     * @param initialSupply Initial supply of tokens (in wei, 18 decimals)
     */
    constructor(uint256 initialSupply)
        ERC20("JPY Digital", "JPYD")
        Ownable(msg.sender)
        ERC20Permit("JPY Digital")
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mint new tokens (only owner)
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Returns the number of decimals (18, same as JPYC)
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
