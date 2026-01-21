// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "./ITokenReceiver.sol";

/**
 * @title JPYCWrapper
 * @dev Wrapper contract that adds automatic notification functionality to JPYC tokens
 *
 * This wrapper allows JPYC to be used with automatic payment processing
 * without modifying the original token contract. Users can transfer tokens through
 * this wrapper to enable automatic notifications to contracts implementing ITokenReceiver.
 *
 * Usage:
 * 1. User approves JPYC to this wrapper contract
 * 2. User calls transfer() on this wrapper (not directly on JPYC)
 * 3. Wrapper transfers tokens and automatically notifies recipient if it's a contract
 */
contract JPYCWrapper {
    IERC20 public immutable token;

    event ContractDetected(address indexed to);
    event NotificationAttempt(address indexed to, bool success);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Constructor
     * @param _token Address of the JPYC token contract
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
     * Reverts if the recipient contract call fails
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
        (bool success, bytes memory returnData) = to.call(data);

        // Revert if the call failed to prevent tokens from being stuck
        require(success, string(abi.encodePacked(
            "Recipient contract call failed: ",
            _getRevertMsg(returnData)
        )));

        emit NotificationAttempt(to, success);
    }

    /**
     * @dev Extract revert message from returnData
     * @param returnData The return data from a failed call
     * @return The revert message as a string
     */
    function _getRevertMsg(bytes memory returnData) internal pure returns (string memory) {
        // If the returnData length is less than 68, then the transaction failed silently
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash (first 4 bytes)
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
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
