// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title JAPoint
 * @dev ERC20 token that can be minted by the JAPointMint contract
 */
contract JAPoint is ERC20, ERC20Burnable, Ownable {

    /**
     * @dev Constructor
     */
    constructor()
        ERC20("JA Point", "JAPT")
        Ownable(msg.sender)
    {}

    /**
     * @dev Mint new tokens (only owner)
     * @param to Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Returns the number of decimals (18)
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
