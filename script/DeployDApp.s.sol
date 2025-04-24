// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MatchMaking} from "../src/MatchMaking.sol";
import {SoulboundNft} from "../src/SoulboundNft.sol";
import {PriceConvertor} from "../src/PriceConvertor.sol";

contract DeployDApp is Script {
    function run() external {
        address oracleAddress = getOracleAddress();
        vm.startBroadcast();
        MatchMaking matchMaking = new MatchMaking(
            1e18 / 1000,
            1,
            oracleAddress
        );
        SoulboundNft soulboundNft = new SoulboundNft(1e18 / 1000);
        console.log("matchMaking", address(matchMaking));
        console.log("soulboundNft", address(soulboundNft));
        vm.stopBroadcast();
    }

    function getOracleAddress() internal view returns (address) {
        if (block.chainid == 1) {
            return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // mainnet oracle
        } else if (block.chainid == 11155111) {
            return 0x694AA1769357215DE4FAC081bf1f309aDC325306; // sepolia oracle
        }
        return address(0);
    }
}
