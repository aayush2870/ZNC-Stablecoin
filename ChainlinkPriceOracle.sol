// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the Chainlink price oracle interface
interface IChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
}

contract ChainlinkPriceOracle is IChainlinkPriceOracle {
    // Hardcoded address of the Chainlink price feed contract
    address public constant ORACLE_ADDRESS = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // Replace with the actual address

    // Retrieve the latest price from the Chainlink oracle
    function latestAnswer() external view override returns (int256) {
        // Call the Chainlink oracle to get the latest price
        return IChainlinkPriceOracle(ORACLE_ADDRESS).latestAnswer();
    }
}
