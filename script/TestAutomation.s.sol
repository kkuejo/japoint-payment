// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";
import "../src/JPYCWrapper.sol";
import "../src/Transfer10.sol";
import "../src/Transfer5.sol";

/**
 * @title TestAutomation
 * @dev Script to deploy and test the full automation flow on Sepolia
 *
 * This script uses the existing JPYC token on Sepolia testnet.
 *
 * Usage:
 * 1. Set environment variables: PRIVATE_KEY, COMPANY_ADDRESS, SHOP_ADDRESS
 * 2. Run this script:
 *    forge script script/TestAutomation.s.sol --rpc-url sepolia --broadcast
 */
contract TestAutomation is Script {
    // Sepolia JPYC Token Address
    address constant SEPOLIA_JPYC = 0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29;

    IERC20 public jpyc;
    JAPoint public japoint;
    JAPointMint public japointMint;
    JPYCWrapper public jpycWrapper;
    Transfer10 public transfer10;
    Transfer5 public transfer5;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address companyAddress = vm.envAddress("COMPANY_ADDRESS");
        address shopAddress = vm.envAddress("SHOP_ADDRESS");

        console.log("=== Starting Automated Payment System Test (Sepolia) ===\n");

        // Deploy all contracts
        vm.startBroadcast(deployerPrivateKey);
        _deployContracts(companyAddress, shopAddress);
        _setupContracts();
        vm.stopBroadcast();

        console.log("\n=== All Contracts Deployed Successfully! ===");
        console.log("\nTo test, you need to:");
        console.log("1. Get JPYC from the Sepolia JPYC faucet or owner");
        console.log("2. Approve JPYCWrapper to spend your JPYC");
        console.log("3. Call jpycWrapper.transfer(transfer10Address, amount)");
    }

    function _deployContracts(address companyAddress, address shopAddress) internal {
        console.log("Deploying contracts...\n");

        // Use existing JPYC on Sepolia
        jpyc = IERC20(SEPOLIA_JPYC);
        console.log("Using JPYC (Sepolia):", address(jpyc));

        // Deploy JAPoint
        japoint = new JAPoint();
        console.log("JAPoint deployed at:", address(japoint));

        // Deploy JAPointMint
        japointMint = new JAPointMint(
            address(jpyc),
            address(japoint),
            companyAddress
        );
        console.log("JAPointMint deployed at:", address(japointMint));

        // Deploy JPYCWrapper
        jpycWrapper = new JPYCWrapper(address(jpyc));
        console.log("JPYCWrapper deployed at:", address(jpycWrapper));

        // Deploy Transfer10
        transfer10 = new Transfer10(
            address(jpyc),
            address(japointMint),
            shopAddress,
            companyAddress,
            address(jpycWrapper)
        );
        console.log("Transfer10 deployed at:", address(transfer10));

        // Deploy Transfer5
        transfer5 = new Transfer5(
            address(jpyc),
            address(japointMint),
            shopAddress,
            companyAddress,
            address(jpycWrapper)
        );
        console.log("Transfer5 deployed at:", address(transfer5));
    }

    function _setupContracts() internal {
        console.log("\nSetting up contracts...\n");

        // Mint 1 trillion JAPT to JAPointMint as reserve
        japoint.mint(address(japointMint), 1_000_000_000_000 * 10**18);
        console.log("Minted 1T JAPT to JAPointMint as reserve");

        console.log("\nDeployment Summary:");
        console.log("JPYC (Sepolia):", address(jpyc));
        console.log("JAPoint:", address(japoint));
        console.log("JAPointMint:", address(japointMint));
        console.log("JPYCWrapper:", address(jpycWrapper));
        console.log("Transfer10:", address(transfer10));
        console.log("Transfer5:", address(transfer5));
    }
}
