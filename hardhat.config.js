require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    opencampus: {
      url: "https://lb.drpc.org/ogrpc?network=open-campus-codex-sepolia&dkey=AvdUpBeMqkYSjPsYOd4pkGLjqR4BynsR77KAIlZWwHzR",
      chainId: 656476,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      opencampus: "no-api-key-needed"
    },
    customChains: [
      {
        network: "opencampus",
        chainId: 656476,
        urls: {
          apiURL: "https://explorer.sepolia.openmesh.network/api",
          browserURL: "https://explorer.sepolia.openmesh.network"
        }
      }
    ]
  },
  sourcify: {
    enabled: true
  }
};