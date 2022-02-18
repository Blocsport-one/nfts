const hre = require("hardhat")
require("@nomiclabs/hardhat-web3")
const fs = require("fs-extra")

function sleep(ms) {
	return new Promise((resolve) => {
		setTimeout(resolve, ms)
	})
}

async function main() {
	fs.removeSync("cache")
	fs.removeSync("artifacts")
	await hre.run("compile")

	// We get the contract to deploy
	const NFTContract = await hre.ethers.getContractFactory("BlocsportNFTERC155WithToken")
	console.log("Deploying NFT Contract...")

	let network = process.env.NETWORK ? process.env.NETWORK : "rinkeby"

	console.log(">-> Network is set to " + network)

	// ethers is avaialble in the global scope
	const [deployer] = await ethers.getSigners()
	const deployerAddress = await deployer.getAddress()
	const account = await web3.utils.toChecksumAddress(deployerAddress)
	const balance = await web3.eth.getBalance(account)

	console.log(
		"Deployer Account " + deployerAddress + " has balance: " + web3.utils.fromWei(balance, "ether"),
		"ETH"
	)

    // const BLSTokenAddress = "0x9adfda14886aac3454979f2ea82adc604b81fb7b" // TODO: this is for rinkeby
    const BLSTokenAddress = "0x708739980021A0b0B2E555383fE1283697e140e9" // TODO: for bsc mainnet

	const deployed = await NFTContract.deploy(BLSTokenAddress)

	let dep = await deployed.deployed()

	console.log("Contract deployed to:", dep.address)

	await sleep(50000)
	await hre.run("verify:verify", {
		address: dep.address,
		constructorArguments: [BLSTokenAddress],
	})
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
