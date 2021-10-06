require("@nomiclabs/hardhat-waffle")
require("dotenv").config()
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-web3")
require("@nomiclabs/hardhat-etherscan")

module.exports = {
	solidity: {
		version: "0.8.7",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	networks: {
		hardhat: {
			chainId: 127001,
			accounts: {
				mnemonic: "test test test test test test test test test test test junk",
			},
			blockGasLimit: 199022552,
			gas: 1500000,
			gasPrice: 100,
			allowUnlimitedContractSize: false,
			throwOnTransactionFailures: false,
			throwOnCallFailures: true,
		},
		ganache: {
			url: "http://127.0.0.1:7545",
			blockGasLimit: 10000000,
		},
		mainnet: {
			url: process.env.MAINNET_RPC,
			gas: 1500000,
			gasPrice: 87000000000, //87 gwei
			timeout: 15000,
			accounts: [process.env.PRIVATE_KEY],
		},
		rinkeby: {
			url: process.env.RINKEBY_RPC,
			network_id: 4,
			gas: 1500000,
			gasPrice: 87000000000, //87 gwei
			timeout: 15000,
			accounts: [process.env.PRIVATE_KEY],
		},
		bsc_test: {
			url: process.env.BSC_RPC_TEST,
			network_id: 97,
			accounts: [process.env.PRIVATE_KEY],
		},
		bsc: {
			url: process.env.BSC_RPC,
			network_id: 56,
			accounts: [process.env.PRIVATE_KEY],
		},
		matic: {
			url: process.env.MATIC_RPC,
			network_id: 137,
			gas: 10000000,
			gasPrice: 10000000000, //10 gwei
			allowUnlimitedContractSize: true,
			accounts: [process.env.PRIVATE_KEY],
		},
		matic_test: {
			url: process.env.MATIC_RPC_TEST,
			network_id: 80001,
			gas: 10000000,
			gasPrice: 3000000000, //3 gwei
			allowUnlimitedContractSize: true,
			accounts: [process.env.PRIVATE_KEY],
		},
		iotex: {
			url: process.env.IOTEX_RPC,
			network_id: 4689,
			gas: 10000000,
			gasPrice: 1000000000000, //10000 gwei
			allowUnlimitedContractSize: true,
			accounts: [process.env.PRIVATE_KEY],
		},
		iotex_test: {
			url: process.env.IOTEX_RPC_TEST,
			network_id: 4690,
			gas: 10000000,
			gasPrice: 10000000000, //100 gwei
			allowUnlimitedContractSize: true,
			accounts: [process.env.PRIVATE_KEY],
		},
	},

	gasReporter: {
		enabled: !!process.env.REPORT_GAS === true,
		currency: "USD",
		gasPrice: 15,
		showTimeSpent: true,
		coinmarketcap: "99f32a19-565a-444a-8238-e89dc9a0d7c3",
	},
	mocha: {
		timeout: 20000,
	},
	etherscan: {
		apiKey: process.env.POLYSCAN_KEY,
	},
}
