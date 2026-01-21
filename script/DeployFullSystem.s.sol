// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/JAPoint.sol";
import "../src/JAPointMint.sol";
import "../src/JPYCWrapper.sol";
import "../src/Transfer10.sol";
import "../src/Transfer5.sol";

contract DeployFullSystem is Script {
    // Sepolia JPYC Test Token Address
    address constant SEPOLIA_JPYC = 0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29;

    function run() external {
        // Get environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address companyAddress = vm.envAddress("COMPANY_ADDRESS");
        address shopAddress = vm.envAddress("SHOP_ADDRESS");
        uint256 japointReserve = vm.envOr("JAPOINT_RESERVE", uint256(1_000_000_000_000 * 10**18)); // 1 trillion JAPT

        vm.startBroadcast(deployerPrivateKey);

        // 1. Use existing JPYC token on Sepolia
        address jpyc = SEPOLIA_JPYC;
        console.log("Using JPYC (Sepolia):", jpyc);

        // 2. Deploy JAPoint token
        JAPoint japoint = new JAPoint();
        console.log("JAPoint deployed to:", address(japoint));

        // 3. Deploy JAPointMint contract
        JAPointMint japointMint = new JAPointMint(
            jpyc,
            address(japoint),
            companyAddress
        );
        console.log("JAPointMint deployed to:", address(japointMint));

        // 4. Deploy JPYCWrapper contract (for automatic notification functionality)
        JPYCWrapper jpycWrapper = new JPYCWrapper(jpyc);
        console.log("JPYCWrapper deployed to:", address(jpycWrapper));

        // 5. Deploy Transfer10 contract
        Transfer10 transfer10 = new Transfer10(
            jpyc,
            address(japointMint),
            shopAddress,
            address(jpycWrapper)
        );
        console.log("Transfer10 deployed to:", address(transfer10));

        // 6. Deploy Transfer5 contract
        Transfer5 transfer5 = new Transfer5(
            jpyc,
            address(japointMint),
            shopAddress,
            address(jpycWrapper)
        );
        console.log("Transfer5 deployed to:", address(transfer5));

        // 7. Mint JAPoint reserve to JAPointMint contract
        japoint.mint(address(japointMint), japointReserve);
        console.log("Minted", japointReserve / 10**18, "JAPT to JAPointMint as reserve");

        console.log("---");
        console.log("Deployment Summary:");
        console.log("JPYC (Sepolia):", jpyc);
        console.log("JAPoint:", address(japoint));
        console.log("JAPointMint:", address(japointMint));
        console.log("JPYCWrapper:", address(jpycWrapper));
        console.log("Transfer10:", address(transfer10));
        console.log("Transfer5:", address(transfer5));
        console.log("Company Address:", companyAddress);
        console.log("Shop Address:", shopAddress);
        console.log("JAPoint Reserve:", japointReserve / 10**18, "JAPT");
        console.log("");
        console.log("Note: Use JPYCWrapper to transfer JPYC for automatic notification functionality.");
        console.log("Users should approve JPYC to JPYCWrapper and call JPYCWrapper.transfer()");

        vm.stopBroadcast();
    }
}
