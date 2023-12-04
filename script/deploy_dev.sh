#!/bin/bash

# load env variables
source .env

# Deploy001_NftReward (deploys NftReward)
forge script script/Deploy001_NftReward.s.sol:Deploy001_NftReward --rpc-url $RPC_URL --broadcast -vvvv
