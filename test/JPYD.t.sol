// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/JPYD.sol";

contract JPYDTest is Test {
    JPYD public jpyd;
    address public owner;
    address public user1;
    address public user2;

    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 million JPYD

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        jpyd = new JPYD(INITIAL_SUPPLY);
    }

    function testInitialSupply() public view {
        assertEq(jpyd.totalSupply(), INITIAL_SUPPLY);
        assertEq(jpyd.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testDecimals() public view {
        assertEq(jpyd.decimals(), 18);
    }

    function testName() public view {
        assertEq(jpyd.name(), "JPY Digital");
    }

    function testSymbol() public view {
        assertEq(jpyd.symbol(), "JPYD");
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10**18;

        jpyd.transfer(user1, amount);

        assertEq(jpyd.balanceOf(user1), amount);
        assertEq(jpyd.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function testTransferFrom() public {
        uint256 amount = 1000 * 10**18;

        jpyd.approve(user1, amount);

        vm.prank(user1);
        jpyd.transferFrom(owner, user2, amount);

        assertEq(jpyd.balanceOf(user2), amount);
        assertEq(jpyd.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    function testMintOnlyOwner() public {
        uint256 mintAmount = 1000 * 10**18;

        jpyd.mint(user1, mintAmount);

        assertEq(jpyd.balanceOf(user1), mintAmount);
        assertEq(jpyd.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function testMintFailsForNonOwner() public {
        uint256 mintAmount = 1000 * 10**18;

        vm.prank(user1);
        vm.expectRevert();
        jpyd.mint(user1, mintAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;

        jpyd.burn(burnAmount);

        assertEq(jpyd.totalSupply(), INITIAL_SUPPLY - burnAmount);
        assertEq(jpyd.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
    }

    function testBurnFrom() public {
        uint256 amount = 1000 * 10**18;

        jpyd.transfer(user1, amount);

        vm.prank(user1);
        jpyd.approve(owner, amount);

        jpyd.burnFrom(user1, amount);

        assertEq(jpyd.balanceOf(user1), 0);
        assertEq(jpyd.totalSupply(), INITIAL_SUPPLY - amount);
    }

    function testOwnership() public view {
        assertEq(jpyd.owner(), owner);
    }

    function testTransferOwnership() public {
        jpyd.transferOwnership(user1);

        assertEq(jpyd.owner(), user1);
    }

    function testFuzzTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != owner);
        vm.assume(amount <= INITIAL_SUPPLY);

        jpyd.transfer(to, amount);

        assertEq(jpyd.balanceOf(to), amount);
    }

    function testFuzzMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != owner);
        vm.assume(amount <= type(uint256).max - INITIAL_SUPPLY);

        jpyd.mint(to, amount);

        assertEq(jpyd.balanceOf(to), amount);
        assertEq(jpyd.totalSupply(), INITIAL_SUPPLY + amount);
    }
}
