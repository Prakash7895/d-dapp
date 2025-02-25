// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {PriceConvertorLibrary} from "./PriceConvertorLibrary.sol";

contract PriceConvertor {
    using PriceConvertorLibrary for uint256;

    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // accepts wei and converts to usd
    function getPriceInCents(uint _amount) public view returns (uint) {
        return uint256(_amount).toUSD(priceFeed);
    }

    // accepts cents and converts to usd
    function getWeiFromCents(uint _amount) public view returns (uint) {
        return uint256(_amount).toWEI(priceFeed);
    }
}
