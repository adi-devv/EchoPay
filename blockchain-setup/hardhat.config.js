// hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle"); // Required if you plan to write tests with Waffle

// Import dotenv to load environment variables from .env file
require("dotenv").config();

module.exports = {
  solidity: "0.8.0", // Ensure this matches the pragma in your Payment.sol (e.g., pragma solidity ^0.8.0;)
  networks: {
    // This is the default Hardhat Network, good for local testing and development
    hardhat: {
      // You can configure it further if needed, but default is usually fine
    },
    // Add your BlockDAG Testnet configuration here
    blockdagTestnet: {
      url: process.env.BLOCKDAG_TESTNET_RPC_URL || "", // Loads RPC URL from .env file
      accounts: [process.env.PRIVATE_KEY || ""], // Loads private key from .env file for deployment
      chainId: parseInt(process.env.BLOCKDAG_TESTNET_CHAIN_ID || "0"), // Loads Chain ID from .env file
      // Optional: You might need to adjust gasPrice or gasLimit if BlockDAG has specific recommendations
      // gasPrice: 1000000000, // Example: 1 Gwei
      // gasLimit: 2100000, // Example: Standard gas limit for transfers
    }
  }
};