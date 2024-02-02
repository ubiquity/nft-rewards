# NFT rewards

**Set of contracts that allow minter to sign off-chain mint requests for target users who can later mint NFTs using the minter's signature.**

## Deployed contract

https://gnosisscan.io/address/0xAa1bfC0e51969415d64d6dE74f27CDa0587e645b

## How it works

1. Minter signs an off-chain mint request for a target user
2. Target user takes the minter's signature and [mints](https://github.com/ubiquity/nft-rewards/blob/f7e1e2c093d33ba23f316da2267983fc6d8bf572/src/NftReward.sol#L123) a new NFT on-chain

## How to deploy

1. Create a new `.env` file and set environment variables, example:

```
# API key from a code contract verifying service.
# May be empty for a local anvil deployment.
# - mainnet: https://etherscan.io
# - gnosis: https://gnosisscan.io
ETHERSCAN_API_KEY=""

# Minter address (who signs off-chain NFT mint requests).
# By default set to 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
# which is the 2nd address derived from mnemonic "test test test test test test test test test test test junk".
MINTER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# NFT reward token name
NFT_TOKEN_NAME="NftReward"

# NFT reward token symbol
NFT_TOKEN_SYMBOL="RWD"

# Deployer private key + NftReward owner.
# By default set to the private key from address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# which is the 1st address derived from mnemonic "test test test test test test test test test test test junk".
OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# RPC URL (used in contract migrations)
# - anvil: http://127.0.0.1:8545
# - gnosis: https://gnosis.publicnode.com
RPC_URL="http://127.0.0.1:8545"

#this is an example salt that is used to deploy the contract on the same address in different
#make sure to change the salt if u need to redeploy the same contract in the same chain
SALT="69420"

```

2. (Optional) Run a local anvil instance via the `anvil` command (if you want to deploy locally)
3. Run one of the deployment scripts:

```
yarn deploy:dev # deploys contracts WITHOUT source code verifying
yarn deploy:prod # deploys contracts WITH source code verifying (`ETHERSCAN_API_KEY` env variable must be set)
```

## How to use

Example js: https://github.com/ubiquity/nft-rewards/blob/7d9495bcdedae9304fdaa66a9d62cdf31fad50d0/js/sign-and-redeem-mint-request.ts

## How to run tests

```
yarn test
```
