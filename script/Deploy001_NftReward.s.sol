// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NftReward} from "../src/NftReward.sol";

contract Deploy001_NftReward is Script {
    NftReward nftReward;

    function run() public {
        // read env variables
        address minterAddress = vm.envAddress("MINTER_ADDRESS");
        string memory nftTokenName = vm.envString("NFT_TOKEN_NAME");
        string memory nftTokenSymbol = vm.envString("NFT_TOKEN_SYMBOL");
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        // bytes32 salt = vm.envBytes32("SALT");
        address ownerAddress = vm.addr(ownerPrivateKey);

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);
        //Enter the your salt here
        bytes32 salt = "694204353";
        // deploy NftReward
        nftReward = new NftReward{salt: salt}(
            nftTokenName, // token name
            nftTokenSymbol, // token symbol
            ownerAddress, // owner address
            minterAddress // minter address (who signs off-chain mint requests)
        );

        // stop sending owner transactions
        vm.stopBroadcast();
    }
}
