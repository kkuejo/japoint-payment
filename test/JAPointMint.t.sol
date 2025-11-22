// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/JPYD.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";

contract JAPointMintTest is Test {
    JPYD public jpyd;
    JAPoint public japoint;
    JAPointMint public japointMint;

    address public owner;
    address public user1;
    address public user2;
    address public companyAddress;

    uint256 constant INITIAL_JPYD_SUPPLY = 1000000 * 10**18;
    uint256 constant INITIAL_JAPOINT_RESERVE = 1000000 * 10**18;

    event Minted(address indexed user, address indexed recipient, uint256 amount);
    event CompanyAddressUpdated(address indexed oldAddress, address indexed newAddress);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        companyAddress = address(0x999);

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

        // Transfer JAPoint ownership to JAPointMint so it can mint
        japoint.transferOwnership(address(japointMint));
        vm.prank(address(japointMint));
        japoint.mint(address(japointMint), INITIAL_JAPOINT_RESERVE);

        // Give user1 some JPYD tokens
        jpyd.transfer(user1, 100000 * 10**18);
    }

    function testJAPointBasics() public view {
        assertEq(japoint.name(), "JA Point");
        assertEq(japoint.symbol(), "JAPT");
        assertEq(japoint.decimals(), 18);
        assertEq(japoint.totalSupply(), INITIAL_JAPOINT_RESERVE);
        assertEq(japoint.balanceOf(address(japointMint)), INITIAL_JAPOINT_RESERVE);
    }

    function testJAPointMintSetup() public view {
        assertEq(address(japointMint.jpydToken()), address(jpyd));
        assertEq(address(japointMint.japointToken()), address(japoint));
        assertEq(japointMint.companyAddress(), companyAddress);
    }

    function testJAPointMintSuccess() public {
        uint256 mintAmount = 1000 * 10**18;

        // User1 approves JPYD to JAPointMint
        vm.startPrank(user1);
        jpyd.approve(address(japointMint), mintAmount);

        // User1 calls mint to mint JAPoint for user2
        vm.expectEmit(true, true, false, true, address(japointMint));
        emit Minted(user1, user2, mintAmount);
        japointMint.transferJAPoint(user2);
        vm.stopPrank();

        // Check balances
        assertEq(japoint.balanceOf(user2), mintAmount, "User2 should receive JAPoint");
        assertEq(jpyd.balanceOf(companyAddress), mintAmount, "Company should receive JPYD");
        assertEq(jpyd.balanceOf(user1), 100000 * 10**18 - mintAmount, "User1 JPYD should decrease");
        assertEq(jpyd.balanceOf(address(japointMint)), 0, "JAPointMint should not hold JPYD");
    }

    function testJAPointMintToSelf() public {
        uint256 mintAmount = 1000 * 10**18;

        // User1 mints to themselves
        vm.startPrank(user1);
        jpyd.approve(address(japointMint), mintAmount);
        japointMint.transferJAPoint(user1);
        vm.stopPrank();

        assertEq(japoint.balanceOf(user1), mintAmount);
        assertEq(jpyd.balanceOf(companyAddress), mintAmount);
    }

    function testJAPointMintFailsWithoutApproval() public {
        vm.startPrank(user1);
        vm.expectRevert("No JPYD tokens approved");
        japointMint.transferJAPoint(user2);
        vm.stopPrank();
    }

    function testJAPointMintFailsWithZeroRecipient() public {
        uint256 mintAmount = 1000 * 10**18;

        vm.startPrank(user1);
        jpyd.approve(address(japointMint), mintAmount);

        vm.expectRevert("Invalid recipient address");
        japointMint.transferJAPoint(address(0));
        vm.stopPrank();
    }

    function testJAPointMintMultipleTimes() public {
        uint256 firstAmount = 1000 * 10**18;
        uint256 secondAmount = 2000 * 10**18;

        vm.startPrank(user1);

        // First mint
        jpyd.approve(address(japointMint), firstAmount);
        japointMint.transferJAPoint(user2);

        // Second mint
        jpyd.approve(address(japointMint), secondAmount);
        japointMint.transferJAPoint(user2);

        vm.stopPrank();

        assertEq(japoint.balanceOf(user2), firstAmount + secondAmount);
        assertEq(jpyd.balanceOf(companyAddress), firstAmount + secondAmount);
    }

    function testUpdateCompanyAddress() public {
        address newCompany = address(0x888);

        vm.expectEmit(true, true, false, true, address(japointMint));
        emit CompanyAddressUpdated(companyAddress, newCompany);
        japointMint.updateCompanyAddress(newCompany);

        assertEq(japointMint.companyAddress(), newCompany);
    }

    function testUpdateCompanyAddressFailsForNonOwner() public {
        address newCompany = address(0x888);

        vm.prank(user1);
        vm.expectRevert();
        japointMint.updateCompanyAddress(newCompany);
    }

    function testUpdateCompanyAddressFailsWithZeroAddress() public {
        vm.expectRevert("Invalid company address");
        japointMint.updateCompanyAddress(address(0));
    }

    function testRecoverTokens() public {
        // Accidentally send some JPYD directly to JAPointMint
        uint256 accidentalAmount = 100 * 10**18;
        jpyd.transfer(address(japointMint), accidentalAmount);

        assertEq(jpyd.balanceOf(address(japointMint)), accidentalAmount);

        // Owner recovers the tokens
        japointMint.recoverTokens(address(jpyd), accidentalAmount, owner);

        assertEq(jpyd.balanceOf(address(japointMint)), 0);
        assertEq(jpyd.balanceOf(owner), INITIAL_JPYD_SUPPLY - 100000 * 10**18);
    }

    function testRecoverTokensFailsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        japointMint.recoverTokens(address(jpyd), 100, user1);
    }

    function testFuzzJAPointMint(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 1, 100000 * 10**18);

        vm.startPrank(user1);
        jpyd.approve(address(japointMint), amount);
        japointMint.transferJAPoint(user2);
        vm.stopPrank();

        assertEq(japoint.balanceOf(user2), amount);
        assertEq(jpyd.balanceOf(companyAddress), amount);
    }

    function testConstructorValidation() public {
        // Test invalid JPYD address
        vm.expectRevert("Invalid JPYD address");
        new JAPointMint(address(0), address(japoint), companyAddress);

        // Test invalid JAPoint address
        vm.expectRevert("Invalid JAPoint address");
        new JAPointMint(address(jpyd), address(0), companyAddress);

        // Test invalid company address
        vm.expectRevert("Invalid company address");
        new JAPointMint(address(jpyd), address(japoint), address(0));
    }
}
