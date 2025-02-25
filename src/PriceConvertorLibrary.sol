// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

library PriceConvertorLibrary {
    // converts eth to cents
    function toUSD(
        uint _amountInWei,
        AggregatorV3Interface priceFeed
    ) public view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price returned by oracle");

        uint adjustedPrice = (uint(price) * 100) / 1e8;

        uint cents = (_amountInWei * adjustedPrice) / 1e18;

        return cents;
    }

    function toWEI(
        uint _amountInCents, // 500
        AggregatorV3Interface priceFeed
    ) public view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price returned by oracle");

        uint adjustedPriceInCents = (uint(price) * 100) / 1e8;

        uint weis = ((_amountInCents * 1e18) / adjustedPriceInCents);

        return weis;
    }
}
