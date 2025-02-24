// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MatchMaking} from "../src/MatchMaking.sol";

contract DeployMatchMaking is Script {
    address USER1 = address(0xaF3A89D6B8ECBD83510aF833d82D8A7e706379Bb);
    address USER2 = address(0x4e281a642ba67Cf4851366EA463dcd76b1bFa491);

    function run() external {
        MatchMaking matchMaking = MatchMaking(
            0x8C85db386CA5F169dFE5E2431429AD4596b2d2D5
        );

        // vm.startBroadcast(USER1);
        // matchMaking.like(USER2);

        vm.startBroadcast(USER2);
        matchMaking.like(USER1);
        vm.stopBroadcast();
    }
}
