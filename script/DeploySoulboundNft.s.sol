// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {SoulboundNft} from "../src/SoulboundNft.sol";

contract DeploySoulboundNft is Script {
    function run() external returns (SoulboundNft) {
        vm.startBroadcast();
        SoulboundNft soulboundNft = new SoulboundNft(1e18 / 1000);
        vm.stopBroadcast();

        return soulboundNft;
    }
}
