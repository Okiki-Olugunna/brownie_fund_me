// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // preventing overflow from occurring
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // fund function to allow people to send money to me
    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "More ETH is required"
        );
        //keep track of people(addresses) who sent money(value)
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // function to get the price of the ETH
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // converting to wei
        return uint256(answer * 10000000000);
    }

    // converting the amount of ETH to USD
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // withdraw function with onlyOwner modifier to make sure that only (I) the contract owner can withdraw funds
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        // creating a for loop to reset the addressToAmountFunded mapping after withdrawing
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // getting the address of the funder from the funders array
            address funder = funders[funderIndex];
            // making the funded amount to 0
            addressToAmountFunded[funder] = 0;
        }

        //resetting the funders array
        funders = new address[](0);
    }
}
