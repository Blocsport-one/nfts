require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: {
    version: "0.8.9",
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
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    rinkeby: {
      url: process.env.RINKEBY_RPC,
      network_id: 4,
      gas: 1500000,
      gasPrice: 87000000000, //87 gwei
      timeout: 15000,
      accounts: [process.env.PRIVATE_KEY_RINKEBY],
    },
    bsc_test: {
      url: process.env.BSC_RPC_TEST,
      network_id: 97,
      accounts: [process.env.PRIVATE_KEY_BSC_TESTNET],
    },
    bsc: {
      url: process.env.BSC_RPC,
      network_id: 56,
      accounts: [process.env.PRIVATE_KEY_BSC],
    },
    matic: {
      url: process.env.MATIC_RPC,
      network_id: 137,
      gas: 10000000,
      gasPrice: 10000000000, //10 gwei
      allowUnlimitedContractSize: true,
      accounts: [process.env.PRIVATE_KEY_MATIC],
    },
    matic_test: {
      url: process.env.MATIC_RPC_TEST,
      network_id: 80001,
      gas: 10000000,
      gasPrice: 3000000000, //3 gwei
      allowUnlimitedContractSize: true,
      accounts: [process.env.PRIVATE_KEY_MATIC_TESTNET],
    },
    bsc_test: {
      url: process.env.BSC_RPC_TEST,
      network_id: 97,
      accounts: [process.env.PRIVATE_KEY_BSC_TESTNET],
    },
    bsc: {
      url: process.env.BSC_RPC,
      network_id: 56,
      accounts: [process.env.PRIVATE_KEY_BSC],
    },
    moonbase_alpha: {
      url: process.env.MOONBASE_ALPHA_RPC_TEST,
      chainId: 1287, // 0x507 in hex,
      accounts: [process.env.PRIVATE_MOONBASE_ALPHA],
    },
    moonriver: {
      url: process.env.MOONRIVER_RPC,
      chainId: 1285, // 0x505 in hex,
      accounts: [process.env.PRIVATE_MOONRIVER],
    },
    // iotex: {
    // 	url: process.env.IOTEX_RPC,
    // 	network_id: 4689,
    // 	gas: 10000000,
    // 	gasPrice: 1000000000000, //10000 gwei
    // 	allowUnlimitedContractSize: true,
    // 	accounts: [process.env.PRIVATE_KEY_IOTEX],
    // },
    // iotex_test: {
    // 	url: process.env.IOTEX_RPC_TEST,
    // 	network_id: 4690,
    // 	gas: 10000000,
    // 	gasPrice: 10000000000, //100 gwei
    // 	allowUnlimitedContractSize: true,
    // 	accounts: [process.env.PRIVATE_KEY_IOTEX_TESTNET],
    // },
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS === true,
    currency: "USD",
    gasPrice: 15,
    showTimeSpent: true,
    coinmarketcap: process.env.COINMARKETCAP_API,
  },
  mocha: {
    timeout: 20000,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY, // or use process.env.MOONSCAN_KEY for moonbeam/moonriver network or process.env.POLYSCAN_KEY or process.env.ETHERSCAN_KEY
  },
};
