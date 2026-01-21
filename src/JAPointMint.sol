// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JAPoint.sol";

/**
 * @title JAPointMint
 * @dev Contract that distributes JAPoint when receiving JPYC tokens
 *
 * Flow:
 * 1. User approves JPYC to this contract
 * 2. User calls mint(recipient)
 * 3. Contract transfers JPYC from user to itself
 * 4. Contract transfers same amount of JAPoint to recipient (from its reserve)
 * 5. Contract transfers JPYC to company address
 *
 * Note: This contract must hold sufficient JAPoint tokens to distribute.
 * The initial supply is minted to this contract during deployment.
 */
contract JAPointMint is Ownable {
    IERC20 public jpycToken;
    IERC20 public japointToken;
    address public companyAddress;

    event Minted(address indexed user, address indexed recipient, uint256 amount);
    event CompanyAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Constructor
     * @param _jpycToken Address of JPYC token contract
     * @param _japointToken Address of JAPoint token contract
     * @param _companyAddress Address to receive JPYC tokens
     */
    constructor(
        address _jpycToken,
        address _japointToken,
        address _companyAddress
    ) Ownable(msg.sender) {
        require(_jpycToken != address(0), "Invalid JPYC address");
        require(_japointToken != address(0), "Invalid JAPoint address");
        require(_companyAddress != address(0), "Invalid company address");

        jpycToken = IERC20(_jpycToken);
        japointToken = IERC20(_japointToken);
        companyAddress = _companyAddress;
    }

    /**
     * @dev Distribute JAPoint by depositing JPYC
     * @param recipient Address to receive JAPoint
     *
     * Requirements:
     * - Caller must have approved JPYC tokens to this contract
     * - Approved amount must be greater than 0
     * - This contract must have sufficient JAPoint balance
     *
     * Process:
     * 1. Transfer approved JPYC from caller to this contract
     * 2. Transfer same amount of JAPoint to recipient (from reserve)
     * 3. Transfer JPYC to company address
     */
    function transferJAPoint(address recipient) public {
        require(recipient != address(0), "Invalid recipient address");

        // Get the approved amount from the caller
        uint256 amount = jpycToken.allowance(msg.sender, address(this));
        require(amount > 0, "No JPYC tokens approved");

        // Check if this contract has enough JAPoint
        require(
            japointToken.balanceOf(address(this)) >= amount,
            "Insufficient JAPoint reserve"
        );

        // Transfer JPYC from caller to this contract
        require(
            jpycToken.transferFrom(msg.sender, address(this), amount),
            "JPYC transfer failed"
        );

        // Transfer JAPoint to recipient from reserve
        require(
            japointToken.transfer(recipient, amount),
            "JAPoint transfer failed"
        );

        // Transfer JPYC to company address
        require(
            jpycToken.transfer(companyAddress, amount),
            "Transfer to company failed"
        );

        emit Minted(msg.sender, recipient, amount);
    }

    /**
     * @dev Update company address (only owner)
     * @param _newCompanyAddress New company address
     */
    function updateCompanyAddress(address _newCompanyAddress) external onlyOwner {
        require(_newCompanyAddress != address(0), "Invalid company address");

        address oldAddress = companyAddress;
        companyAddress = _newCompanyAddress;

        emit CompanyAddressUpdated(oldAddress, _newCompanyAddress);
    }

    /**
     * @dev Emergency function to recover tokens sent by mistake (only owner)
     * @param token Address of token to recover
     * @param amount Amount to recover
     * @param to Address to send recovered tokens
     */
    function recoverTokens(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(IERC20(token).transfer(to, amount), "Recovery failed");
    }
}
