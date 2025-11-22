// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "./ITokenReceiver.sol";

/**
 * @title JPYDWrapper
 * @dev Wrapper contract that adds automatic notification functionality to JPYD/JPYC tokens
 * 
 * This wrapper allows JPYD (or JPYC) to be used with automatic payment processing
 * without modifying the original token contract. Users can transfer tokens through
 * this wrapper to enable automatic notifications to contracts implementing ITokenReceiver.
 * 
 * Usage:
 * 1. User approves JPYD/JPYC to this wrapper contract
 * 2. User calls transfer() on this wrapper (not directly on JPYD/JPYC)
 * 3. Wrapper transfers tokens and automatically notifies recipient if it's a contract
 */
contract JPYDWrapper {
    IERC20 public immutable token;

    event ContractDetected(address indexed to);
    event NotificationAttempt(address indexed to, bool success);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Constructor
     * @param _token Address of the JPYD or JPYC token contract
     */
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    /**
     * @dev Transfer tokens and notify recipient if it's a contract implementing ITokenReceiver
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success True if transfer succeeded
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfer tokens using EIP-2612 permit for single-QR payment flows.
     *      Caller first signs the permit data off-chain, then submits the signature
     *      and transfer parameters in one transaction.
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param deadline Permit signature deadline
     * @param v ECDSA signature v value
     * @param r ECDSA signature r value
     * @param s ECDSA signature s value
     */
    function transferWithPermit(
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        IERC20Permit(address(token)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Internal function to check if an address is a contract
     * @param account Address to check
     * @return True if the address is a contract
     */
    function _isContract(address account) internal view returns (bool) {
        // Check if the address has code
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Internal function to notify recipient contract about token receipt
     * Uses low-level call to forward all available gas
     * @param from Original sender of the tokens
     * @param to Recipient address (contract)
     * @param amount Amount of tokens transferred
     */
    function _notifyTokenReceived(address from, address to, uint256 amount) internal {
        // Use low-level call to forward all available gas
        bytes memory data = abi.encodeWithSelector(
            ITokenReceiver.onTokenReceived.selector,
            from,
            amount
        );

        // Call with all available gas by not specifying a gas limit
        (bool success,) = to.call(data);

        emit NotificationAttempt(to, success);
    }

    function _transferFrom(address from, address to, uint256 amount) internal {
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than 0");

        bool success = token.transferFrom(from, to, amount);
        require(success, "Token transfer failed");

        emit Transfer(from, to, amount);

        if (_isContract(to)) {
            emit ContractDetected(to);
            _notifyTokenReceived(from, to, amount);
        }
    }

    /**
     * @dev Get the token balance of an address
     * @param account Address to check balance for
     * @return Balance of the account
     */
    function balanceOf(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /**
     * @dev Get the allowance of an owner for a spender
     * @param owner Address of the token owner
     * @param spender Address of the token spender
     * @return Allowance amount
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return token.allowance(owner, spender);
    }
}
