// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";

abstract contract SotaMarketplaceStorage {
    uint256 public totalListNfts; // SLOT 0
    uint256 public totalAuctionNfts; // SLOT 1

    Types.TreasuryData public treasuryData; // SLOT 2

    mapping(uint256 => Types.ListNFT) public listNfts; // SLOT 3
    mapping(uint256 => Types.AuctionNFT) public auctionNfts; // SLOT 4

    // autionId => bidder address => bid place
    mapping(uint256 => mapping(address => Types.BidPlace)) public bidPlaces; // SLOT 5

    mapping(address => bool) public blacklist; // SLOT 6
}
