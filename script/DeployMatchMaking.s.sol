// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MatchMaking} from "../src/MatchMaking.sol";
import {MockAggregator} from "./mock/MockAggregator.sol";

contract DeployMatchMaking is Script {
    function run() external returns (MatchMaking) {
        address oracleAddress = getOracleAddress();
        vm.startBroadcast();
        MatchMaking matchMaking = new MatchMaking(500, 7, oracleAddress);
        vm.stopBroadcast();

        return matchMaking;
    }

    function getOracleAddress() internal returns (address) {
        if (block.chainid == 1) {
            return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // mainnet oracle
        } else if (block.chainid == 11155111) {
            return 0x694AA1769357215DE4FAC081bf1f309aDC325306; // sepolia oracle
        }
        MockAggregator mockOracle = new MockAggregator(2495.68 * 1e8);
        return address(mockOracle);
    }
}
