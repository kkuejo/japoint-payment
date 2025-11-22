// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/JPYD.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";
import "../src/JPYDWrapper.sol";
import "../src/Transfer10.sol";
import "../src/Transfer5.sol";

contract DeployFullSystem is Script {
    function run() external {
        // Get environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address companyAddress = vm.envAddress("COMPANY_ADDRESS");
        address shopAddress = vm.envAddress("SHOP_ADDRESS");
        uint256 initialJpydSupply = vm.envOr("INITIAL_JPYD_SUPPLY", uint256(10_000_000 * 10**18));
        uint256 japointReserve = vm.envOr("JAPOINT_RESERVE", uint256(1_000_000_000_000 * 10**18)); // 1 trillion JAPT

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy JPYD token
        JPYD jpyd = new JPYD(initialJpydSupply);
        console.log("JPYD deployed to:", address(jpyd));

        // 2. Deploy JAPoint token
        JAPoint japoint = new JAPoint();
        console.log("JAPoint deployed to:", address(japoint));

        // 3. Deploy JAPointMint contract
        JAPointMint japointMint = new JAPointMint(
            address(jpyd),
            address(japoint),
            companyAddress
        );
        console.log("JAPointMint deployed to:", address(japointMint));

        // 4. Deploy JPYDWrapper contract (for automatic notification functionality)
        JPYDWrapper jpydWrapper = new JPYDWrapper(address(jpyd));
        console.log("JPYDWrapper deployed to:", address(jpydWrapper));

        // 5. Deploy Transfer10 contract
        Transfer10 transfer10 = new Transfer10(
            address(jpyd),
            address(japointMint),
            shopAddress,
            address(jpydWrapper)
        );
        console.log("Transfer10 deployed to:", address(transfer10));

        // 6. Deploy Transfer5 contract
        Transfer5 transfer5 = new Transfer5(
            address(jpyd),
            address(japointMint),
            shopAddress,
            address(jpydWrapper)
        );
        console.log("Transfer5 deployed to:", address(transfer5));

        // 7. Mint JAPoint reserve to JAPointMint contract
        japoint.mint(address(japointMint), japointReserve);
        console.log("Minted", japointReserve / 10**18, "JAPT to JAPointMint as reserve");

        console.log("---");
        console.log("Deployment Summary:");
        console.log("JPYD:", address(jpyd));
        console.log("JAPoint:", address(japoint));
        console.log("JAPointMint:", address(japointMint));
        console.log("JPYDWrapper:", address(jpydWrapper));
        console.log("Transfer10:", address(transfer10));
        console.log("Transfer5:", address(transfer5));
        console.log("Company Address:", companyAddress);
        console.log("Shop Address:", shopAddress);
        console.log("Initial JPYD Supply:", initialJpydSupply / 10**18, "JPYD");
        console.log("JAPoint Reserve:", japointReserve / 10**18, "JAPT");
        console.log("");
        console.log("Note: Use JPYDWrapper to transfer JPYD for automatic notification functionality.");
        console.log("Users should approve JPYD to JPYDWrapper and call JPYDWrapper.transfer()");

        vm.stopBroadcast();
    }
}
