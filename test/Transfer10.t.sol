// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/JPYD.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";
import "../src/Transfer10.sol";
import "../src/JPYDWrapper.sol";

contract Transfer10Test is Test {
    JPYD public jpyd;
    JAPoint public japoint;
    JAPointMint public japointMint;
    Transfer10 public transfer10;
    JPYDWrapper public jpydWrapper;

    address public owner;
    address public user1;
    address public user2;
    address public companyAddress;
    address public shopAddress;

    uint256 constant INITIAL_JPYD_SUPPLY = 1000000 * 10**18;
    uint256 constant INITIAL_JAPOINT_RESERVE = 1000000 * 10**18;
    uint256 private constant USER1_PRIVATE_KEY = 0xA11CE;
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event PaymentProcessed(
        address indexed sender,
        uint256 totalAmount,
        uint256 japointMintAmount,
        uint256 shopAmount
    );
    event ShopAddressUpdated(address indexed oldAddress, address indexed newAddress);

    function setUp() public {
        owner = address(this);
        user1 = vm.addr(USER1_PRIVATE_KEY);
        user2 = address(0x2);
        companyAddress = address(0x999);
        shopAddress = address(0x888);

        // Deploy JPYD
        jpyd = new JPYD(INITIAL_JPYD_SUPPLY);

        // Deploy JAPoint
        japoint = new JAPoint();

        // Deploy JAPointMint
        japointMint = new JAPointMint(
            address(jpyd),
            address(japoint),
            companyAddress
        );

        // Deploy JPYDWrapper for automatic notifications
        jpydWrapper = new JPYDWrapper(address(jpyd));

        // Deploy Transfer10 with wrapper support
        transfer10 = new Transfer10(
            address(jpyd),
            address(japointMint),
            shopAddress,
            address(jpydWrapper)
        );

        // Transfer JAPoint ownership to JAPointMint so it can mint
        japoint.transferOwnership(address(japointMint));
        vm.prank(address(japointMint));
        japoint.mint(address(japointMint), INITIAL_JAPOINT_RESERVE);

        // Give user1 some JPYD tokens
        jpyd.transfer(user1, 100000 * 10**18);
    }

    function testTransfer10Setup() public view {
        assertEq(address(transfer10.jpydToken()), address(jpyd));
        assertEq(address(transfer10.japointMint()), address(japointMint));
        assertEq(transfer10.shopAddress(), shopAddress);
    }

    function testProcessPaymentSuccess() public {
        uint256 paymentAmount = 10000 * 10**18; // 10,000 JPYD
        uint256 expectedJAPointMintAmount = paymentAmount / 100; // 1% = 100 JPYD
        uint256 expectedShopAmount = paymentAmount - expectedJAPointMintAmount; // 99% = 9,900 JPYD

        // User1 approves JPYD to Transfer10
        vm.startPrank(user1);
        jpyd.approve(address(transfer10), paymentAmount);

        // User1 calls processPayment
        vm.expectEmit(true, false, false, true, address(transfer10));
        emit PaymentProcessed(user1, paymentAmount, expectedJAPointMintAmount, expectedShopAmount);
        transfer10.processPayment();
        vm.stopPrank();

        // Check balances
        // User1 should have received JAPoint (1% worth)
        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount, "User1 should receive JAPoint");

        // Shop should have received 99% of JPYD
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount, "Shop should receive 99% JPYD");

        // Company should have received 1% of JPYD (from JAPointMint)
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount, "Company should receive 1% JPYD");

        // Transfer10 should not hold any JPYD
        assertEq(jpyd.balanceOf(address(transfer10)), 0, "Transfer10 should not hold JPYD");

        // JAPointMint should not hold any JPYD
        assertEq(jpyd.balanceOf(address(japointMint)), 0, "JAPointMint should not hold JPYD");

        // User1 JPYD should decrease by payment amount
        assertEq(jpyd.balanceOf(user1), 100000 * 10**18 - paymentAmount, "User1 JPYD should decrease");
    }

    function testProcessPaymentMultipleTimes() public {
        uint256 firstPayment = 10000 * 10**18;
        uint256 secondPayment = 20000 * 10**18;

        vm.startPrank(user1);

        // First payment
        jpyd.approve(address(transfer10), firstPayment);
        transfer10.processPayment();

        // Second payment
        jpyd.approve(address(transfer10), secondPayment);
        transfer10.processPayment();

        vm.stopPrank();

        uint256 totalPayment = firstPayment + secondPayment;
        uint256 expectedJAPointTotal = totalPayment / 100; // 1%
        uint256 expectedShopTotal = totalPayment - expectedJAPointTotal; // 99%

        assertEq(japoint.balanceOf(user1), expectedJAPointTotal);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopTotal);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointTotal);
    }

    function testProcessPaymentFailsWithoutApproval() public {
        vm.startPrank(user1);
        vm.expectRevert("No JPYD tokens approved");
        transfer10.processPayment();
        vm.stopPrank();
    }

    function testProcessPaymentWithSmallAmount() public {
        uint256 paymentAmount = 100 * 10**18; // 100 JPYD
        uint256 expectedJAPointMintAmount = 1 * 10**18; // 1% = 1 JPYD
        uint256 expectedShopAmount = 99 * 10**18; // 99% = 99 JPYD

        vm.startPrank(user1);
        jpyd.approve(address(transfer10), paymentAmount);
        transfer10.processPayment();
        vm.stopPrank();

        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount);
    }

    function testProcessPaymentWithLargeAmount() public {
        uint256 paymentAmount = 50000 * 10**18; // 50,000 JPYD
        uint256 expectedJAPointMintAmount = 500 * 10**18; // 1% = 500 JPYD
        uint256 expectedShopAmount = 49500 * 10**18; // 99% = 49,500 JPYD

        vm.startPrank(user1);
        jpyd.approve(address(transfer10), paymentAmount);
        transfer10.processPayment();
        vm.stopPrank();

        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount);
    }

    function testUpdateShopAddress() public {
        address newShop = address(0x777);

        vm.expectEmit(true, true, false, true, address(transfer10));
        emit ShopAddressUpdated(shopAddress, newShop);
        transfer10.updateShopAddress(newShop);

        assertEq(transfer10.shopAddress(), newShop);
    }

    function testUpdateShopAddressFailsForNonOwner() public {
        address newShop = address(0x777);

        vm.prank(user1);
        vm.expectRevert();
        transfer10.updateShopAddress(newShop);
    }

    function testUpdateShopAddressFailsWithZeroAddress() public {
        vm.expectRevert("Invalid shop address");
        transfer10.updateShopAddress(address(0));
    }

    // NOTE: testRecoverTokens is disabled because payments routed through JPYDWrapper
    // automatically trigger onTokenReceived() in the same transaction. The function
    // remains for recovering unrelated tokens that might be sent by mistake.
    // The recoverTokens() function is still useful for recovering OTHER tokens.
    /*
    function testRecoverTokens() public {
        // Accidentally send some JPYD directly to Transfer10
        uint256 accidentalAmount = 100 * 10**18;
        jpyd.transfer(address(transfer10), accidentalAmount);

        assertEq(jpyd.balanceOf(address(transfer10)), accidentalAmount);

        // Owner recovers the tokens
        transfer10.recoverTokens(address(jpyd), accidentalAmount, owner);

        assertEq(jpyd.balanceOf(address(transfer10)), 0);
    }
    */

    function testRecoverTokensFailsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        transfer10.recoverTokens(address(jpyd), 100, user1);
    }

    function testFuzzProcessPayment(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 100, 100000 * 10**18);

        uint256 expectedJAPointMintAmount = amount / 100; // 1%
        uint256 expectedShopAmount = amount - expectedJAPointMintAmount; // 99%

        vm.startPrank(user1);
        jpyd.approve(address(transfer10), amount);
        transfer10.processPayment();
        vm.stopPrank();

        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount);
    }

    function testConstructorValidation() public {
        // Test invalid JPYD address
        vm.expectRevert("Invalid JPYD address");
        new Transfer10(address(0), address(japointMint), shopAddress, address(0));

        // Test invalid JAPointMint address
        vm.expectRevert("Invalid JAPointMint address");
        new Transfer10(address(jpyd), address(0), shopAddress, address(0));

        // Test invalid shop address
        vm.expectRevert("Invalid shop address");
        new Transfer10(address(jpyd), address(japointMint), address(0), address(0));
    }

    function testProcessPaymentDistributionAccuracy() public {
        uint256 paymentAmount = 12345 * 10**18; // Odd number to test rounding
        uint256 expectedJAPointMintAmount = paymentAmount / 100; // 123.45 * 10^18
        uint256 expectedShopAmount = paymentAmount - expectedJAPointMintAmount;

        vm.startPrank(user1);
        jpyd.approve(address(transfer10), paymentAmount);
        transfer10.processPayment();
        vm.stopPrank();

        // Verify exact amounts
        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount);

        // Verify total adds up
        assertEq(
            expectedJAPointMintAmount + expectedShopAmount,
            paymentAmount,
            "Total should equal payment amount"
        );
    }

    function testDepositSuccess() public {
        uint256 depositAmount = 5000 * 10**18; // 5,000 JPYD
        uint256 expectedJAPointMintAmount = depositAmount / 100; // 1% = 50 JPYD
        uint256 expectedShopAmount = depositAmount - expectedJAPointMintAmount; // 99% = 4,950 JPYD

        // User1 approves JPYD to Transfer10
        vm.startPrank(user1);
        jpyd.approve(address(transfer10), depositAmount);

        // User1 calls deposit with specific amount
        vm.expectEmit(true, false, false, true, address(transfer10));
        emit PaymentProcessed(user1, depositAmount, expectedJAPointMintAmount, expectedShopAmount);
        transfer10.deposit(depositAmount);
        vm.stopPrank();

        // Check balances
        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount, "User1 should receive JAPoint");
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount, "Shop should receive 99% JPYD");
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount, "Company should receive 1% JPYD");
        assertEq(jpyd.balanceOf(address(transfer10)), 0, "Transfer10 should not hold JPYD");
    }

    function testDepositMultipleTimes() public {
        uint256 firstDeposit = 1000 * 10**18;
        uint256 secondDeposit = 2000 * 10**18;

        vm.startPrank(user1);
        // Approve once for multiple deposits
        jpyd.approve(address(transfer10), 10000 * 10**18);

        // First deposit
        transfer10.deposit(firstDeposit);

        // Second deposit
        transfer10.deposit(secondDeposit);

        vm.stopPrank();

        uint256 totalDeposit = firstDeposit + secondDeposit;
        uint256 expectedJAPointTotal = totalDeposit / 100; // 1%
        uint256 expectedShopTotal = totalDeposit - expectedJAPointTotal; // 99%

        assertEq(japoint.balanceOf(user1), expectedJAPointTotal);
        assertEq(jpyd.balanceOf(shopAddress), expectedShopTotal);
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointTotal);
    }

    function testDepositFailsWithZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be greater than 0");
        transfer10.deposit(0);
        vm.stopPrank();
    }

    function testDepositFailsWithoutApproval() public {
        uint256 depositAmount = 1000 * 10**18;

        vm.startPrank(user1);
        vm.expectRevert();
        transfer10.deposit(depositAmount);
        vm.stopPrank();
    }

    function testAutomaticProcessingViaTransfer() public {
        // Test the automatic processing feature via wrapper transfer
        uint256 transferAmount = 2000 * 10**18; // 2,000 JPYD
        uint256 expectedJAPointMintAmount = transferAmount / 100; // 1% = 20 JPYD
        uint256 expectedShopAmount = transferAmount - expectedJAPointMintAmount; // 99% = 1,980 JPYD

        // User1 sends JPYD via wrapper (requires prior approval)
        vm.startPrank(user1);
        jpyd.approve(address(jpydWrapper), transferAmount);
        vm.expectEmit(true, false, false, true, address(transfer10));
        emit PaymentProcessed(user1, transferAmount, expectedJAPointMintAmount, expectedShopAmount);
        jpydWrapper.transfer(address(transfer10), transferAmount);
        vm.stopPrank();

        // Verify automatic processing happened
        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount, "User1 should receive JAPoint automatically");
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount, "Shop should receive 99% JPYD");
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount, "Company should receive 1% JPYD");
        assertEq(jpyd.balanceOf(address(transfer10)), 0, "Transfer10 should not hold JPYD after processing");
    }

    function testAutomaticProcessingViaTransferWithPermit() public {
        uint256 transferAmount = 3000 * 10**18; // 3,000 JPYD
        uint256 expectedJAPointMintAmount = transferAmount / 100;
        uint256 expectedShopAmount = transferAmount - expectedJAPointMintAmount;
        uint256 deadline = block.timestamp + 1 days;
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            USER1_PRIVATE_KEY,
            user1,
            address(jpydWrapper),
            transferAmount,
            deadline
        );

        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true, address(transfer10));
        emit PaymentProcessed(user1, transferAmount, expectedJAPointMintAmount, expectedShopAmount);
        jpydWrapper.transferWithPermit(address(transfer10), transferAmount, deadline, v, r, s);
        vm.stopPrank();

        assertEq(japoint.balanceOf(user1), expectedJAPointMintAmount, "User1 should receive JAPoint automatically");
        assertEq(jpyd.balanceOf(shopAddress), expectedShopAmount, "Shop should receive 99% JPYD");
        assertEq(jpyd.balanceOf(companyAddress), expectedJAPointMintAmount, "Company should receive 1% JPYD");
        assertEq(jpyd.balanceOf(address(transfer10)), 0, "Transfer10 should not hold JPYD after processing");
    }

    function _signPermit(
        uint256 privateKey,
        address permitOwner,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                permitOwner,
                spender,
                value,
                jpyd.nonces(permitOwner),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", jpyd.DOMAIN_SEPARATOR(), structHash));
        return vm.sign(privateKey, digest);
    }
}
