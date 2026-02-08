// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/IdentityRegistry.sol";
import "../src/ReputationRegistry.sol";
import "../src/ValidationRegistry.sol";

/**
 * @title Deploy
 * @dev Deployment script for ERC-8004 Trustless Agents contracts on Unichain Sepolia
 * @notice Deploys IdentityRegistry, ReputationRegistry, and ValidationRegistry
 *
 * Usage:
 *   1. Set environment variables:
 *      export PRIVATE_KEY=your_private_key
 *      export UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.unichain.org
 *
 *   2. Deploy:
 *      forge script script/Deploy.s.sol:Deploy --rpc-url $UNICHAIN_SEPOLIA_RPC_URL --broadcast --verify
 *
 *   Or with private key directly:
 *      forge script script/Deploy.s.sol:Deploy --rpc-url https://sepolia.unichain.org --private-key $PRIVATE_KEY --broadcast
 */
contract Deploy is Script {
    // Deployed contract addresses
    IdentityRegistry public identityRegistry;
    ReputationRegistry public reputationRegistry;
    ValidationRegistry public validationRegistry;

    function run() external {
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy IdentityRegistry (no dependencies)
        identityRegistry = new IdentityRegistry();
        console.log("IdentityRegistry deployed at:", address(identityRegistry));

        // 2. Deploy ReputationRegistry (depends on IdentityRegistry)
        reputationRegistry = new ReputationRegistry(address(identityRegistry));
        console.log(
            "ReputationRegistry deployed at:",
            address(reputationRegistry)
        );

        // 3. Deploy ValidationRegistry (depends on IdentityRegistry)
        validationRegistry = new ValidationRegistry(address(identityRegistry));
        console.log(
            "ValidationRegistry deployed at:",
            address(validationRegistry)
        );

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n========== DEPLOYMENT SUMMARY ==========");
        console.log("Network: Unichain Sepolia (Chain ID: 1301)");
        console.log("IdentityRegistry:   ", address(identityRegistry));
        console.log("ReputationRegistry: ", address(reputationRegistry));
        console.log("ValidationRegistry: ", address(validationRegistry));
        console.log("=========================================\n");
    }
}
