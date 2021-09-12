require('babel-register')
require('babel-polyfill')

const chai = require('chai')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised).should()

var HDWalletProvider = require('@truffle/hdwallet-provider');

const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

const INFURA_API_KEY = process.env.INFURA_API_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

module.exports = {
    networks: {
        development: {
            host: 'localhost',
            port: 8545,
            network_id: '*',
            skipDryRun: true,
            gas: 7000000
        },
        rinkeby: {
            provider: () =>
                new HDWalletProvider(
                    mnemonic,
                    `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`
                ),
            network_id: 4,
            gas: 8000000,
            skipDryRun: true
        },
        matic: {
            provider: () =>
                new HDWalletProvider(
                    mnemonic,
                    `https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}`
                ),
            network_id: '137',
            gasPrice: '90000000000'
        },
        mumbai: {
            provider: () =>
                new HDWalletProvider(
                    mnemonic,
                    `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`
                ),
            network_id: 80001,
            gas: 8000000,
            skipDryRun: true
        },
        bsclive: {
            provider: () => new HDWalletProvider(mnemonic,
                'https://bsc-dataseed1.binance.org/'
            ),
            network_id: '56',
            gas: 5500000
        },
        bsctest: {
            provider: () => new HDWalletProvider(mnemonic,
                'https://data-seed-prebsc-1-s1.binance.org:8545/'
            ),
            network_id: '97',
            gas: 5500000
        },
        // Another network with more advanced options...
        // advanced: {
        // port: 8777,             // Custom port
        // network_id: 1342,       // Custom network
        // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
        // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
        // from: <address>,        // Account to send txs from (default: accounts[0])
        // websocket: true        // Enable EventEmitter interface for web3 (default: false)
        // },
    },

    // Set default mocha options here, use special reporters etc.
    mocha: {
        reporter: "eth-gas-reporter",
        reporterOptions: {
            currency: "USD",
            gasPrice: 2,
        },
    },

    // Configure your compilers
    compilers: {
        solc: {
            version: "^0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
            settings: {          // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 20
                },
                evmVersion: "istanbul"
                // evmVersion: "london"
            }
        }
    },
    plugins: ['truffle-plugin-verify'],
    verify: {
        preamble: 'Matic network contracts'
    },
    api_keys: {
        etherscan: ETHERSCAN_API_KEY
    }
};
