// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JAPointMint.sol";
import "./ITokenReceiver.sol";
import "./JPYDWrapper.sol";

/**
 * @title Transfer10
 * @dev Contract that receives JPYD and:
 *      - Sends 1% to JAPointMint and mints JAPoint to the sender
 *      - Sends remaining 99% to ShopAddress
 *
 * Flow (Automatic - just send JPYD):
 * 1. User sends JPYD directly to this contract via MetaMask
 * 2. Contract automatically processes the payment
 * 3. Contract sends 1% to JAPointMint and mints JAPoint to sender
 * 4. Contract sends 99% to ShopAddress
 *
 * Alternative Flow (Manual):
 * 1. User approves JPYD to this contract
 * 2. User calls deposit(amount) or processPayment()
 */
contract Transfer10 is Ownable, ITokenReceiver {
    IERC20 public jpydToken;
    JAPointMint public japointMint;
    address public shopAddress;
    JPYDWrapper public jpydWrapper;

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
     * @param _jpydToken Address of JPYD token contract
     * @param _japointMint Address of JAPointMint contract
     * @param _shopAddress Address to receive 99% of JPYD
     * @param _jpydWrapper Address of JPYDWrapper contract (optional, can be address(0))
     */
    constructor(
        address _jpydToken,
        address _japointMint,
        address _shopAddress,
        address _jpydWrapper
    ) Ownable(msg.sender) {
        require(_jpydToken != address(0), "Invalid JPYD address");
        require(_japointMint != address(0), "Invalid JAPointMint address");
        require(_shopAddress != address(0), "Invalid shop address");

        jpydToken = IERC20(_jpydToken);
        japointMint = JAPointMint(_japointMint);
        shopAddress = _shopAddress;
        if (_jpydWrapper != address(0)) {
            jpydWrapper = JPYDWrapper(_jpydWrapper);
        }
    }

    /**
     * @dev Deposit JPYD and automatically process payment (RECOMMENDED METHOD)
     * This function allows users to specify an amount and process it in one transaction.
     *
     * Usage:
     * 1. User approves JPYD to this contract (can be done once for multiple deposits)
     * 2. User calls deposit(amount) - everything happens automatically
     *
     * Requirements:
     * - Caller must have approved JPYD tokens to this contract
     * - Amount must be greater than 0
     *
     * Process:
     * 1. Transfer specified JPYD amount from caller to this contract
     * 2. Calculate 1% for JAPointMint and 99% for shop
     * 3. Approve 1% to JAPointMint
     * 4. Call JAPointMint.mint() with sender's address as recipient
     * 5. Transfer 99% to shop address
     *
     * @param amount Amount of JPYD to deposit and process
     */
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer JPYD from caller to this contract
        require(
            jpydToken.transferFrom(msg.sender, address(this), amount),
            "JPYD transfer failed"
        );

        // Process the payment internally
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Process payment by distributing JPYD (uses all approved amount)
     *
     * Requirements:
     * - Caller must have approved JPYD tokens to this contract
     * - Approved amount must be greater than 0
     *
     * Process:
     * 1. Transfer approved JPYD from caller to this contract
     * 2. Calculate 1% for JAPointMint and 99% for shop
     * 3. Approve 1% to JAPointMint
     * 4. Call JAPointMint.mint() with sender's address as recipient
     * 5. Transfer 99% to shop address
     */
    function processPayment() public {
        // Get the approved amount from the caller
        uint256 amount = jpydToken.allowance(msg.sender, address(this));
        require(amount > 0, "No JPYD tokens approved");

        // Transfer JPYD from caller to this contract
        require(
            jpydToken.transferFrom(msg.sender, address(this), amount),
            "JPYD transfer failed"
        );

        // Process the payment internally
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Internal function to process payment distribution
     * @param amount Amount of JPYD to distribute
     * @param sender Address of the sender (who will receive JAPoint)
     */
    function _processPayment(uint256 amount, address sender) internal {
        // Calculate 1% for JAPointMint and 99% for shop
        uint256 japointMintAmount = amount / 100; // 1%
        uint256 shopAmount = amount - japointMintAmount; // 99%

        // Approve JAPointMint to spend 1%
        require(
            jpydToken.approve(address(japointMint), japointMintAmount),
            "Approval to JAPointMint failed"
        );

        // Call JAPointMint.transferJAPoint() with sender's address as recipient
        japointMint.transferJAPoint(sender);

        // Transfer remaining 99% to shop address
        require(
            jpydToken.transfer(shopAddress, shopAmount),
            "Transfer to shop failed"
        );

        emit PaymentProcessed(sender, amount, japointMintAmount, shopAmount);
    }

    /**
     * @dev Called automatically when JPYD tokens are sent to this contract
     * Implements ITokenReceiver interface for automatic payment processing
     * @param from Address of the sender
     * @param amount Amount of JPYD received
     * @return success True if processing succeeded
     */
    function onTokenReceived(address from, uint256 amount) external override returns (bool) {
        // Emit event for debugging
        emit TokenReceived(from, amount, msg.sender);

        // Only accept JPYD tokens from JPYDWrapper
        // JPYD/JPYC tokens don't have automatic notification, so JPYDWrapper must be used
        require(
            address(jpydWrapper) != address(0) && msg.sender == address(jpydWrapper),
            "Only JPYD tokens from JPYDWrapper accepted. Use JPYDWrapper to transfer JPYD."
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
     * @dev Process JPYD that was sent directly to this contract
     * This function processes JPYD balance and assigns it to the caller.
     * 
     * Usage:
     * If you sent JPYD directly to Transfer10 (not via JPYDWrapper), call this function
     * to process the payment and receive JAPoint rewards.
     * 
     * Note: This function processes the entire JPYD balance of this contract
     * and assigns the JAPoint reward to the caller. Make sure you are the one
     * who sent the JPYD, or you may receive rewards intended for someone else.
     * 
     * @param amount Amount of JPYD to process (must match the balance or less)
     */
    function processDirectTransfer(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Check that this contract has at least the requested amount
        uint256 contractBalance = jpydToken.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient JPYD balance in contract");
        
        // Process the payment - caller receives JAPoint reward
        _processPayment(amount, msg.sender);
    }

    /**
     * @dev Process all JPYD that was sent directly to this contract
     * This function processes all JPYD balance and assigns JAPoint reward to the caller.
     * 
     * Usage:
     * If you sent JPYD directly to Transfer10, call this function to process
     * all JPYD balance and receive JAPoint rewards.
     * 
     * Note: This function processes the entire JPYD balance. Make sure you are
     * the one who sent the JPYD, or you may receive rewards intended for someone else.
     */
    function processAllDirectTransfer() external {
        uint256 amount = jpydToken.balanceOf(address(this));
        require(amount > 0, "No JPYD balance to process");
        
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
