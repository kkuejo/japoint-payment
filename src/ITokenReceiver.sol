// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITokenReceiver
 * @dev Interface for contracts that want to be notified when they receive tokens
 */
interface ITokenReceiver {
    /**
     * @dev Called when tokens are transferred to this contract
     * @param from Address of the sender
     * @param amount Amount of tokens received
     * @return success True if the contract accepts the tokens
     */
    function onTokenReceived(address from, uint256 amount) external returns (bool);
}
