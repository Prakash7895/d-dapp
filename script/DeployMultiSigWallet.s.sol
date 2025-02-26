// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DeployMatchMaking} from "./DeployMatchMaking.s.sol";
import {MatchMaking} from "./../src/MatchMaking.sol";

contract DeployMultiSigWallet is Script {
    function run() external returns (MatchMaking) {
        DeployMatchMaking deployerMathMaking = new DeployMatchMaking();

        MatchMaking matchMaking = deployerMathMaking.run();

        return matchMaking;
    }
}
