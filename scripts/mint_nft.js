const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');
const Web3 = require('web3');
const NFTFactoryABI = require('../build/contracts/NFTFactory.json');
const ERC3664Generic = require('../build/contracts/ERC3664Generic.json');
const ATTACH_ROLE = Web3.utils.soliditySha3('ATTACH_ROLE');

const mnemonic = fs.readFileSync(".secret").toString().trim();
const bscLiveNetwork = "https://bsc-dataseed1.binance.org/";
const bscTestNetwork = "https://data-seed-prebsc-1-s1.binance.org:8545/";
const caller = "0xA5225cBEE5052100Ec2D2D94aA6d258558073757";

const genericAttrAddress = "0x3826eE4F3bdF0C727c328d792039141c7535c26D";
const nftFactoryAddress = "0xF99e00ebF5FCE2f5045bf5B9f6cd5714A91B9d07";

async function main() {
    const provider = new HDWalletProvider(mnemonic, bscTestNetwork);
    const web3 = new Web3(provider);

    const nftFactoryInstance = new web3.eth.Contract(
        NFTFactoryABI.abi,
        nftFactoryAddress,
        {gasLimit: "5500000"}
    );
    const genericAttrInstance = new web3.eth.Contract(
        ERC3664Generic.abi,
        genericAttrAddress,
        {gasLimit: "5500000"}
    );

    // await nftFactoryInstance.methods.registerAttribute(2, genericAttrAddress).send({from: caller});
    console.log("attributes: ", await nftFactoryInstance.methods.attributes(2).call());

    // await genericAttrInstance.methods.grantRole(ATTACH_ROLE, nftFactoryAddress).send({from: caller});

    // attributes
    const bg = 1;
    const body = 2;
    const dress = 3;
    const neck = 4;
    const eyes = 5;
    const tooth = 6;
    const mouth = 7;
    const decorates = 8;
    const hat = 9;
    const rare = 10;

    await genericAttrInstance.methods.mintBatch(
        [bg, body, dress, neck, eyes, tooth, mouth, decorates, hat, rare],
        ["bg", "body", "dress", "neck", "eyes", "tooth", "mouth", "decorates", "hat", "rare"],
        ["bg", "body", "dress", "neck", "eyes", "tooth", "mouth", "decorates", "hat", "rare"],
        ["", "", "", "", "", "", "", "", "", ""]
    ).send({from: caller});
    
    const result1 = await nftFactoryInstance.methods
        .createNFT("0x0A559eD20fD86DC38A7aF82E7EdE91aE9b43b5f5",
            "007005000000007001003000010",
            [bg, body, dress, neck, eyes, tooth, mouth, decorates, hat, rare],
            [7, 5, 0, 0, 7, 1, 3, 0, 10, 10]
        ).send({from: caller});
    console.log("result: " + result1);

    // const result2 = await nftFactoryInstance.methods
    //     .batchCreateNFT(["0x0A559eD20fD86DC38A7aF82E7EdE91aE9b43b5f5", "0x6e1F35c11eACcc4D81B67c50827c3674593C8D23"],
    //         ["0011100001111000001111", "110001000100010001"]).send();
    // console.log("result: " + result);
}

main();