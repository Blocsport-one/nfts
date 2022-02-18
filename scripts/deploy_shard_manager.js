const hre = require("hardhat");
require("@nomiclabs/hardhat-web3");
const fs = require("fs-extra");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
  fs.removeSync("cache");
  fs.removeSync("artifacts");
  await hre.run("compile");

  // We get the contract to deploy
  const ShardManagerContract = await hre.ethers.getContractFactory(
    "ShardManager"
  );
  console.log("Deploying ShardManager Contract...");

  let network = process.env.NETWORK ? process.env.NETWORK : "rinkeby";

  console.log(">-> Network is set to " + network);

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  const account = await web3.utils.toChecksumAddress(deployerAddress);
  const balance = await web3.eth.getBalance(account);

  console.log(
    "Deployer Account " +
      deployerAddress +
      " has balance: " +
      web3.utils.fromWei(balance, "ether"),
    "ETH"
  );

  //const BlocsportGenesisNFTAddress = "0x7a07a318978564cbCe217449f695154Cd0d46754" // TODO: uncomment for rinkeby
  const BlocsportGenesisNFTAddress  = "0xD1815780c0cD6E700B7c3B8eC6B5D33194D33029" // TODO uncomment for moonriver

  const deployed = await ShardManagerContract.deploy(BlocsportGenesisNFTAddress);

  let dep = await deployed.deployed();

  console.log("Contract deployed to:", dep.address);

  await sleep(50000);
  await hre.run("verify:verify", {
    address: dep.address,
    constructorArguments: [BlocsportGenesisNFTAddress],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
