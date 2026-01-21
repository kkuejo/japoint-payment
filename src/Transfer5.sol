// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JAPointMint.sol";
import "./ITokenReceiver.sol";
import "./JPYCWrapper.sol";

/**
 * @title Transfer5
 * @dev Contract that receives JPYC and:
 *      - Sends 0.5% to JAPointMint and mints JAPoint to the sender
 *      - Sends remaining 99.5% to ShopAddress
 *
 * Flow (Automatic - just send JPYC):
 * 1. User sends JPYC directly to this contract via MetaMask
 * 2. Contract automatically processes the payment
 * 3. Contract sends 0.5% to JAPointMint and mints JAPoint to sender
 * 4. Contract sends 99.5% to ShopAddress
 *
 * Alternative Flow (Manual):
 * 1. User approves JPYC to this contract
 * 2. User calls deposit(amount) or processPayment()
 */
contract Transfer5 is Ownable, ITokenReceiver {
    IERC20 public jpycToken;
    JAPointMint public japointMint;
    address public shopAddress;
    JPYCWrapper public jpycWrapper;

    event PaymentProcessed(
        address indexed sender,
        uint256 totalAmount,
        uint256 japointMintAmount,
        uint256 shopAmount
    );
    event ShopAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event TokenReceived(address indexed from, uint256 amount, address indexed caller);

    /**
     * @dev Constructor
     * @param _jpycToken Address of JPYC token contract
     * @param _japointMint Address of JAPointMint contract
     * @param _shopAddress Address to receive 99.5% of JPYC
     * @param _jpycWrapper Address of JPYCWrapper contract (optional, can be address(0))
     */
    constructor(
        address _jpycToken,
        address _japointMint,
        address _shopAddress,
        address _jpycWrapper
    ) Ownable(msg.sender) {
        require(_jpycToken != address(0), "Invalid JPYC address");
        require(_japointMint != address(0), "Invalid JAPointMint address");
        require(_shopAddress != address(0), "Invalid shop address");

        jpycToken = IERC20(_jpycToken);
        japointMint = JAPointMint(_japointMint);
        shopAddress = _shopAddress;
        if (_jpycWrapper != address(0)) {
            jpycWrapper = JPYCWrapper(_jpycWrapper);
        }
    }

    /**
     * @dev Deposit JPYC and automatically process payment (RECOMMENDED METHOD)
     * This function allows users to specify an amount and process it in one transaction.
     *
     * Usage:
     * 1. User approves JPYC to this contract (can be done once for multiple deposits)
     * 2. User calls deposit(amount) - everything happens automatically
     *
     * Requirements:
     * - Caller must have approved JPYC tokens to this contract
     * - Amount must be greater than 0
     *
     * Process:
     * 1. Transfer specified JPYC amount from caller to this contract
     * 2. Calculate 0.5% for JAPointMint and 99.5% for shop
     * 3. Approve 0.5% to JAPointMint
     * 4. Call JAPointMint.transferJAPoint() with sender's address as recipient
     * 5. Transfer 99.5% to shop address
     *
     * @param amount Amount of JPYC to deposit and process
     */
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer JPYC from caller to this contract
        require(
            jpycToken.transferFrom(msg.sender, address(this), amount),
            "JPYC transfer failed"
        );

        // Process the payment internally
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Process payment by distributing JPYC (uses all approved amount)
     *
     * Requirements:
     * - Caller must have approved JPYC tokens to this contract
     * - Approved amount must be greater than 0
     *
     * Process:
     * 1. Transfer approved JPYC from caller to this contract
     * 2. Calculate 0.5% for JAPointMint and 99.5% for shop
     * 3. Approve 0.5% to JAPointMint
     * 4. Call JAPointMint.transferJAPoint() with sender's address as recipient
     * 5. Transfer 99.5% to shop address
     */
    function processPayment() public {
        // Get the approved amount from the caller
        uint256 amount = jpycToken.allowance(msg.sender, address(this));
        require(amount > 0, "No JPYC tokens approved");

        // Transfer JPYC from caller to this contract
        require(
            jpycToken.transferFrom(msg.sender, address(this), amount),
            "JPYC transfer failed"
        );

        // Process the payment internally
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Internal function to process payment distribution
     * @param amount Amount of JPYC to distribute
     * @param sender Address of the sender (who will receive JAPoint)
     */
    function _processPayment(uint256 amount, address sender) internal {
        // Calculate 0.5% for JAPointMint and 99.5% for shop
        uint256 japointMintAmount = amount / 200; // 0.5%
        uint256 shopAmount = amount - japointMintAmount; // 99.5%

        // Approve JAPointMint to spend 0.5%
        require(
            jpycToken.approve(address(japointMint), japointMintAmount),
            "Approval to JAPointMint failed"
        );

        // Call JAPointMint.transferJAPoint() with sender's address as recipient
        japointMint.transferJAPoint(sender);

        // Transfer remaining 99.5% to shop address
        require(
            jpycToken.transfer(shopAddress, shopAmount),
            "Transfer to shop failed"
        );

        emit PaymentProcessed(sender, amount, japointMintAmount, shopAmount);
    }

    /**
     * @dev Called automatically when JPYC tokens are sent to this contract
     * Implements ITokenReceiver interface for automatic payment processing
     * @param from Address of the sender
     * @param amount Amount of JPYC received
     * @return success True if processing succeeded
     */
    function onTokenReceived(address from, uint256 amount) external override returns (bool) {
        // Emit event for debugging
        emit TokenReceived(from, amount, msg.sender);

        // Only accept JPYC tokens from JPYCWrapper
        // JPYC tokens don't have automatic notification, so JPYCWrapper must be used
        require(
            address(jpycWrapper) != address(0) && msg.sender == address(jpycWrapper),
            "Only JPYC tokens from JPYCWrapper accepted. Use JPYCWrapper to transfer JPYC."
        );
        require(amount > 0, "Amount must be greater than 0");
        require(from != address(0), "Invalid sender");

        // Process the payment automatically
        _processPayment(amount, from);

        return true;
    }

    /**
     * @dev Update shop address (only owner)
     * @param _newShopAddress New shop address
     */
    function updateShopAddress(address _newShopAddress) external onlyOwner {
        require(_newShopAddress != address(0), "Invalid shop address");

        address oldAddress = shopAddress;
        shopAddress = _newShopAddress;

        emit ShopAddressUpdated(oldAddress, _newShopAddress);
    }

    /**
     * @dev Process JPYC that was sent directly to this contract
     * This function processes JPYC balance and assigns it to the caller.
     *
     * Usage:
     * If you sent JPYC directly to Transfer5 (not via JPYCWrapper), call this function
     * to process the payment and receive JAPoint rewards.
     *
     * Note: This function processes the entire JPYC balance of this contract
     * and assigns the JAPoint reward to the caller. Make sure you are the one
     * who sent the JPYC, or you may receive rewards intended for someone else.
     *
     * @param amount Amount of JPYC to process (must match the balance or less)
     */
    function processDirectTransfer(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Check that this contract has at least the requested amount
        uint256 contractBalance = jpycToken.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient JPYC balance in contract");

        // Process the payment - caller receives JAPoint reward
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Process all JPYC that was sent directly to this contract
     * This function processes all JPYC balance and assigns JAPoint reward to the caller.
     *
     * Usage:
     * If you sent JPYC directly to Transfer5, call this function to process
     * all JPYC balance and receive JAPoint rewards.
     *
     * Note: This function processes the entire JPYC balance. Make sure you are
     * the one who sent the JPYC, or you may receive rewards intended for someone else.
     */
    function processAllDirectTransfer() external {
        uint256 amount = jpycToken.balanceOf(address(this));
        require(amount > 0, "No JPYC balance to process");

        // Process the payment - caller receives JAPoint reward
        _processPayment(amount, msg.sender);
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
