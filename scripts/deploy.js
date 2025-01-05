const hre = require("hardhat");

async function main() {
  console.log("Deploying EduConnect contract...");

  // Deploy the contract
  const EduConnect = await hre.ethers.getContractFactory("EduConnect");
  const eduConnect = await EduConnect.deploy();

  await eduConnect.waitForDeployment();
  const address = await eduConnect.getAddress();

  console.log(`EduConnect deployed to: ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });