// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NftReward} from "../src/NftReward.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy001_NftReward is Script {
    function run() public returns(address) {
        // deploy NftReward contract
        address proxy = deployNftReward();
        return proxy;
    }

    function deployNftReward() public returns(address) {
        // read env variables
        address minterAddress = vm.envAddress("MINTER_ADDRESS");
        string memory nftTokenName = vm.envString("NFT_TOKEN_NAME");
        string memory nftTokenSymbol = vm.envString("NFT_TOKEN_SYMBOL");
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        bytes32 salt = bytes32(bytes(vm.envString("SALT")));
        address ownerAddress = vm.addr(ownerPrivateKey);

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // deploy NftReward contract
        NftReward nftReward = new NftReward{salt: salt}();
        ERC1967Proxy proxy = new ERC1967Proxy(address(nftReward), 
            abi.encodeWithSignature("initialize(string,string,address,address)", 
                nftTokenName, nftTokenSymbol, ownerAddress, minterAddress)
        );

        // stop sending owner transactions
        vm.stopBroadcast();

        return address(proxy);
    }
}
