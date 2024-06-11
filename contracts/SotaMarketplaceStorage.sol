// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";

abstract contract SotaMarketplaceStorage {
    uint256 totalListNfts; // SLOT 0
    uint256 totalAuctionNfts; // SLOT 1

    address public owner; // SLOT 2
    Types.TreasuryData public treasuryData; // SLOT 3

    mapping(uint256 => Types.ListNFT) public listNfts; // SLOT 4
    mapping(uint256 => Types.AuctionNFT) public auctionNfts; // SLOT 5

    // aution index => bidder => bid place
    mapping(uint256 => mapping(address => Types.BidPlace)) public bidPlaces; // SLOT 6

    mapping(address => bool) public blacklist; // SLOT 7
}
