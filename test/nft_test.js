const { expect, assert } = require("chai")
const { web3, ethers } = require("hardhat")
const { BN, time, balance, expectEvent, expectRevert } = require("@openzeppelin/test-helpers")
const ether = require("@openzeppelin/test-helpers/src/ether")

let nft
let owner, acc1, acc2

describe("NFT", function () {
	beforeEach(async function () {
		let NFTContract = await ethers.getContractFactory("BlocsportNFT")
		nft = await NFTContract.deploy()
		await nft.deployed()

		signers = await ethers.getSigners()
		owner = signers[0]
		acc1 = signers[1]
		acc2 = signers[2]
	})

	it("simple test...", async function () {
		expect(await nft.getItemPrice(1)).to.equal(web3.utils.toWei("14.7", "ether"))
	})

	it("buying one works", async function () {
		expect(await nft.getItemPrice(1)).to.equal(web3.utils.toWei("14.7", "ether"))
	})

	it("simple minting test", async function () {
		expect(await nft.balanceOf(acc1.address, 1)).to.equal(0)
		await nft.mint(acc1.address, 1, 1, 0x00)
		expect(await nft.balanceOf(acc1.address, 1)).to.equal(1)
	})

	it("multiple minting test", async function () {
		expect(await nft.balanceOf(acc1.address, 1)).to.equal(0)
		await nft.mint(acc1.address, 1, 10, 0x00)
		expect(await nft.balanceOf(acc1.address, 1)).to.equal(10)
	})

	it("setting a price per range works", async function () {
		expect(await nft.getItemPrice(1)).to.equal(web3.utils.toWei("14.7", "ether"))
		await nft.setPriceRange(0, web3.utils.toWei("15", "ether"))
		expect(await nft.getItemPrice(1)).to.equal(web3.utils.toWei("15", "ether"))
	})

	it("buying an NFT with money works", async function () {
		//buys an NFT in range 7... 0.05 eth
		await nft.connect(acc1).buyNFT(1000001, { value: web3.utils.toWei("0.05", "ether") })
		//acc1 should have a token
		expect(await nft.balanceOf(acc1.address, 1000001)).to.equal(1)
	})

	it("can't buy over the limit", async function () {
		//try to buy 11 nfts range 0
		await nft.setPriceRange(0, web3.utils.toWei("0.01", "ether"))

		for (i = 0; i <= 9; i++) {
			await nft.connect(acc1).buyNFT(1, { value: web3.utils.toWei("0.01", "ether") })
		}
		//acc1 should have 10 tokens
		expect(await nft.balanceOf(acc1.address, 1)).to.equal(10)

		//tries to buy one more
		await expectRevert.unspecified(
			nft.connect(acc1).buyNFT(1, { value: web3.utils.toWei("0.01", "ether") })
		)
	})

	it("buying an NFT with less money. fails", async function () {
		//buys an NFT in range 7... 0.05 eth
		const itemPrice = await nft.getItemPrice(1000001)
		await expectRevert.unspecified(
			nft.connect(acc1).buyNFT(1000001, { value: web3.utils.toWei("0.049", "ether") })
		)
		//acc1 should not have the token
		expect(await nft.balanceOf(acc1.address, 1000001)).to.equal(0)
	})

	it("change price range and buy works with the new price", async function () {
		expect(await nft.getItemPrice(1000001)).to.equal(web3.utils.toWei("0.05", "ether"))
		await nft.setPriceRange(7, web3.utils.toWei("0.2", "ether"))
		expect(await nft.getItemPrice(1000001)).to.equal(web3.utils.toWei("0.2", "ether"))

		await nft.connect(acc1).buyNFT(1000001, { value: web3.utils.toWei("0.2", "ether") })

		//acc1 should have a token
		expect(await nft.balanceOf(acc1.address, 1000001)).to.equal(1)
	})

	it("withdraw monney works", async function () {
		const tracker = await balance.tracker(owner.address)
		let ownerInitialBalance = Number(await tracker.get("wei"))

		await nft.connect(acc1).buyNFT(1000001, { value: web3.utils.toWei("0.05", "ether") })
		await nft.connect(acc2).buyNFT(1000002, { value: web3.utils.toWei("0.05", "ether") })

		await nft.withdraw()
		let ownerFinalBalance = Number(await tracker.get("wei"))
		expect(ownerFinalBalance - ownerInitialBalance).to.be.greaterThan(
			Number(web3.utils.toWei("0.099", "ether")) //some gas costs are lost
		)
	})
})
