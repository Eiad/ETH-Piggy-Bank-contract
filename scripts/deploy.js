const hre = require("hardhat");

async function main() {
  console.log("Deploying PiggyBank contract...");

  const PiggyBank = await hre.ethers.getContractFactory("PiggyBank");
  const piggyBank = await PiggyBank.deploy();

  await piggyBank.waitForDeployment();

  const address = await piggyBank.getAddress();
  console.log("PiggyBank deployed to:", address);

  // Wait for a few block confirmations to ensure Etherscan picks up the deployment
  console.log("Waiting for block confirmations...");
  await piggyBank.deploymentTransaction().wait(6);

  // Verify the contract on Etherscan
  console.log("Verifying contract on Etherscan...");
  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [],
  });

  console.log("Contract verified on Etherscan!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 