/**
 * TODO: desc how it works
 * 
 */

import { ethers, utils } from "ethers";
import NftRewardArtifact from "../out/NftReward.sol/NftReward.json";

// PK of address eligible for claiming NFT, set to any PK you want to mint NFT to
const BENEFICIARY_PRIVATE_KEY = '';
// PK of minter address who signs off-chain mint requests that target users can later use to mint NFTs
// DM me for test minter PK for this contract https://gnosisscan.io/address/0x408fcb8275974b5ac35cf8904c15fc4adb1d916a
const MINTER_PRIVATE_KEY = '';

// EIP-721 domain name, can be taken from contract source
// https://github.com/ubiquity/nft-rewards/blob/12f72c3a84d2d73a624bbb0f596613de4d277d4e/src/NftReward.sol#L66 
const SIGNING_DOMAIN_NAME = 'NftReward-Domain';
// EIP-721 domain version, can be taken from contract source
// https://github.com/ubiquity/nft-rewards/blob/12f72c3a84d2d73a624bbb0f596613de4d277d4e/src/NftReward.sol#L66 
const SIGNING_DOMAIN_VERSION = '1';
// contract address that verifies mint request (i.e. NftReward address)
// https://gnosisscan.io/address/0x408fcb8275974b5ac35cf8904c15fc4adb1d916a
const VERIFYING_CONTRACT_ADDRESS = '0x408fcB8275974b5AC35cF8904C15fc4aDb1D916A';
// chain id, gnosis for this example
const CHAIN_ID = 100;
// RPC URL, gnosis used for this example
const RPC_URL = 'https://gnosis.publicnode.com';

const provider = new ethers.providers.JsonRpcProvider(RPC_URL)
const beneficiaryWallet = new ethers.Wallet(BENEFICIARY_PRIVATE_KEY, provider);
const minterWallet = new ethers.Wallet(MINTER_PRIVATE_KEY, provider);

const domain = {
    name: SIGNING_DOMAIN_NAME,
    version: SIGNING_DOMAIN_VERSION,
    verifyingContract: VERIFYING_CONTRACT_ADDRESS,
    chainId: CHAIN_ID,
};

const types = {
    MintRequest: [
        { name: "beneficiary", type: "address" },
        { name: "deadline", type: "uint256" },
        { name: "keys", type: "bytes32[]" },
        { name: "nonce", type: "uint256" },
        { name: "values", type: "string[]" },
    ],
};

const mintRequest = {
    beneficiary: beneficiaryWallet.address,
    deadline: 9999999999,
    keys: [
        utils.keccak256(utils.toUtf8Bytes("GITHUB_ORGANIZATION_NAME")),
        utils.keccak256(utils.toUtf8Bytes("GITHUB_REPOSITORY_NAME")),
        utils.keccak256(utils.toUtf8Bytes("GITHUB_ISSUE_ID")),
        utils.keccak256(utils.toUtf8Bytes("GITHUB_CONTRIBUTION_TYPE")),
    ],
    nonce: 19246288,
    values: [
        "ubiquity",
        "nft-rewards",
        "1",
        "issue_solver",
    ]
};

async function run() {
    try {
        // minter signs mint request redeemable by beneficiary
        const signature = await minterWallet._signTypedData(domain, types, mintRequest);
        
        // init NftReward contract instance
        const nftRewardContract = new ethers.Contract(VERIFYING_CONTRACT_ADDRESS, NftRewardArtifact.abi, beneficiaryWallet);

        // beneficiary redeems NFT
        const receipt = await nftRewardContract.safeMint(mintRequest, signature, {
            gasLimit: 400_000,
        });
    
        console.log(receipt);
    } catch (err) {
        console.error('Oops', err);
    }
}

run();
