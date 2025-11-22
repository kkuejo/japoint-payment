// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/JPYD.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";
import "../src/JPYDWrapper.sol";
import "../src/Transfer10.sol";
import "../src/Transfer5.sol";

/**
 * @title TestAutomation
 * @dev Script to deploy and test the full automation flow on local Anvil
 *
 * Usage:
 * 1. Start Anvil in one terminal: anvil
 * 2. Run this script in another terminal:
 *    forge script script/TestAutomation.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract TestAutomation is Script {
    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant COMPANY_ADDRESS = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant SHOP_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant USER = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    uint256 constant DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant USER_KEY = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    JPYD public jpyd;
    JAPoint public japoint;
    JAPointMint public japointMint;
    JPYDWrapper public jpydWrapper;
    Transfer10 public transfer10;
    Transfer5 public transfer5;

    function run() external {
        console.log("=== Starting Automated Payment System Test ===\n");

        // Deploy all contracts
        vm.startBroadcast(DEPLOYER_KEY);
        _deployContracts();
        _setupContracts();
        vm.stopBroadcast();

        console.log("\n=== Testing Transfer10 (1% fee) ===");
        _testTransfer10();

        console.log("\n=== Testing Transfer5 (0.5% fee) ===");
        _testTransfer5();

        console.log("\n=== All Tests Completed Successfully! ===");
    }

    function _deployContracts() internal {
        console.log("Deploying contracts...\n");

        // Deploy JPYD with 10M initial supply
        jpyd = new JPYD(10_000_000 * 10**18);
        console.log("JPYD deployed at:", address(jpyd));

        // Deploy JAPoint
        japoint = new JAPoint();
        console.log("JAPoint deployed at:", address(japoint));

        // Deploy JAPointMint
        japointMint = new JAPointMint(
            address(jpyd),
            address(japoint),
            COMPANY_ADDRESS
        );
        console.log("JAPointMint deployed at:", address(japointMint));

        // Deploy JPYDWrapper
        jpydWrapper = new JPYDWrapper(address(jpyd));
        console.log("JPYDWrapper deployed at:", address(jpydWrapper));

        // Deploy Transfer10
        transfer10 = new Transfer10(
            address(jpyd),
            address(japointMint),
            SHOP_ADDRESS,
            address(jpydWrapper)
        );
        console.log("Transfer10 deployed at:", address(transfer10));

        // Deploy Transfer5
        transfer5 = new Transfer5(
            address(jpyd),
            address(japointMint),
            SHOP_ADDRESS,
            address(jpydWrapper)
        );
        console.log("Transfer5 deployed at:", address(transfer5));
    }

    function _setupContracts() internal {
        console.log("\nSetting up contracts...\n");

        // Mint 1 trillion JAPT to JAPointMint as reserve
        japoint.mint(address(japointMint), 1_000_000_000_000 * 10**18);
        console.log("Minted 1T JAPT to JAPointMint as reserve");

        // Transfer 100,000 JPYD to user for testing
        jpyd.transfer(USER, 100_000 * 10**18);
        console.log("Transferred 100,000 JPYD to user:", USER);

        console.log("\nInitial Balances:");
        console.log("User JPYD balance:", jpyd.balanceOf(USER) / 10**18, "JPYD");
        console.log("User JAPT balance:", japoint.balanceOf(USER) / 10**18, "JAPT");
        console.log("Shop JPYD balance:", jpyd.balanceOf(SHOP_ADDRESS) / 10**18, "JPYD");
        console.log("Company JPYD balance:", jpyd.balanceOf(COMPANY_ADDRESS) / 10**18, "JPYD");
    }

    function _testTransfer10() internal {
        uint256 paymentAmount = 10_000 * 10**18; // 10,000 JPYD

        console.log("\nUser sending", paymentAmount / 10**18, "JPYD via JPYDWrapper to Transfer10...");

        // Get balances before
        uint256 userJpydBefore = jpyd.balanceOf(USER);
        uint256 userJaptBefore = japoint.balanceOf(USER);
        uint256 shopJpydBefore = jpyd.balanceOf(SHOP_ADDRESS);
        uint256 companyJpydBefore = jpyd.balanceOf(COMPANY_ADDRESS);

        // User approves and transfers
        vm.startBroadcast(USER_KEY);
        jpyd.approve(address(jpydWrapper), paymentAmount);
        jpydWrapper.transfer(address(transfer10), paymentAmount);
        vm.stopBroadcast();

        // Get balances after
        uint256 userJpydAfter = jpyd.balanceOf(USER);
        uint256 userJaptAfter = japoint.balanceOf(USER);
        uint256 shopJpydAfter = jpyd.balanceOf(SHOP_ADDRESS);
        uint256 companyJpydAfter = jpyd.balanceOf(COMPANY_ADDRESS);

        // Calculate changes
        uint256 expectedJaptReward = paymentAmount / 100; // 1%
        uint256 expectedShopAmount = paymentAmount * 99 / 100; // 99%
        uint256 expectedCompanyAmount = paymentAmount / 100; // 1%

        console.log("\nResults:");
        console.log("User JPYD spent:", (userJpydBefore - userJpydAfter) / 10**18);
        console.log("User JAPT received:", (userJaptAfter - userJaptBefore) / 10**18);
        console.log("Shop JPYD received:", (shopJpydAfter - shopJpydBefore) / 10**18);
        console.log("Shop expected:", expectedShopAmount / 10**18);
        console.log("Company JPYD received:", (companyJpydAfter - companyJpydBefore) / 10**18);
        console.log("Company expected:", expectedCompanyAmount / 10**18);

        // Verify
        require(userJpydBefore - userJpydAfter == paymentAmount, "User JPYD spent incorrect");
        require(userJaptAfter - userJaptBefore == expectedJaptReward, "User JAPT reward incorrect");
        require(shopJpydAfter - shopJpydBefore == expectedShopAmount, "Shop JPYD incorrect");
        require(companyJpydAfter - companyJpydBefore == expectedCompanyAmount, "Company JPYD incorrect");

        console.log("\nTransfer10 automation test PASSED!");
    }

    function _testTransfer5() internal {
        uint256 paymentAmount = 20_000 * 10**18; // 20,000 JPYD

        console.log("\nUser sending", paymentAmount / 10**18, "JPYD via JPYDWrapper to Transfer5...");

        // Get balances before
        uint256 userJpydBefore = jpyd.balanceOf(USER);
        uint256 userJaptBefore = japoint.balanceOf(USER);
        uint256 shopJpydBefore = jpyd.balanceOf(SHOP_ADDRESS);
        uint256 companyJpydBefore = jpyd.balanceOf(COMPANY_ADDRESS);

        // User approves and transfers
        vm.startBroadcast(USER_KEY);
        jpyd.approve(address(jpydWrapper), paymentAmount);
        jpydWrapper.transfer(address(transfer5), paymentAmount);
        vm.stopBroadcast();

        // Get balances after
        uint256 userJpydAfter = jpyd.balanceOf(USER);
        uint256 userJaptAfter = japoint.balanceOf(USER);
        uint256 shopJpydAfter = jpyd.balanceOf(SHOP_ADDRESS);
        uint256 companyJpydAfter = jpyd.balanceOf(COMPANY_ADDRESS);

        // Calculate changes
        uint256 expectedJaptReward = paymentAmount / 200; // 0.5%
        uint256 expectedShopAmount = paymentAmount * 199 / 200; // 99.5%
        uint256 expectedCompanyAmount = paymentAmount / 200; // 0.5%

        console.log("\nResults:");
        console.log("User JPYD spent:", (userJpydBefore - userJpydAfter) / 10**18);
        console.log("User JAPT received:", (userJaptAfter - userJaptBefore) / 10**18);
        console.log("Shop JPYD received:", (shopJpydAfter - shopJpydBefore) / 10**18);
        console.log("Shop expected:", expectedShopAmount / 10**18);
        console.log("Company JPYD received:", (companyJpydAfter - companyJpydBefore) / 10**18);
        console.log("Company expected:", expectedCompanyAmount / 10**18);

        // Verify
        require(userJpydBefore - userJpydAfter == paymentAmount, "User JPYD spent incorrect");
        require(userJaptAfter - userJaptBefore == expectedJaptReward, "User JAPT reward incorrect");
        require(shopJpydAfter - shopJpydBefore == expectedShopAmount, "Shop JPYD incorrect");
        require(companyJpydAfter - companyJpydBefore == expectedCompanyAmount, "Company JPYD incorrect");

        console.log("\nTransfer5 automation test PASSED!");
    }
}
