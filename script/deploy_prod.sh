#!/bin/bash

# load env variables
source .env

# Deploy001_NftReward (deploys NftReward and verifies on etherscan/gnosisscan)
forge script script/Deploy001_NftReward.s.sol:Deploy001_NftReward --rpc-url $RPC_URL --broadcast --verify -vvvv
