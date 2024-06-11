// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {StorageLib} from "contracts/libraries/StorageLib.sol";

library ValidationLib {
    function validateCallerIsProtocolOwner() internal view {
        if (msg.sender != StorageLib.getProtocolOwner()) {
            revert Errors.NotProtocolOwner();
        }
    }

    function validateBlacklistUser() internal view {
        if (StorageLib.getBlacklistUser(msg.sender)) {
            revert Errors.BlacklistedAccount();
        }
    }

    // ============== FIXED PRICE ==============

    function validateListErc721Request(
        address nft,
        uint256 price
    ) internal pure {
        if (nft == address(0)) {
            revert Errors.InvalidParameter();
        }

        if (price == 0) {
            revert Errors.InvalidParameter();
        }
    }

    function validateListErc1155Request(
        address nft,
        uint256 price,
        uint256 amount
    ) internal pure {
        if (nft == address(0)) {
            revert Errors.InvalidParameter();
        }

        if (price == 0) {
            revert Errors.InvalidParameter();
        }

        if (amount == 0) {
            revert Errors.InvalidParameter();
        }
    }

    function validateCancelListNft(
        address caller,
        address seller,
        bool sold
    ) internal pure {
        if (caller != seller) {
            revert Errors.InvalidParameter();
        }

        if (sold) {
            revert Errors.InvalidParameter();
        }
    }

    function validateBuyListNft(
        address caller,
        address seller,
        bool sold
    ) internal pure {
        if (caller == seller) {
            revert Errors.InvalidParameter();
        }

        if (sold) {
            revert Errors.InvalidParameter();
        }
    }

    function validateInitAuctionERC721(
        address nft,
        uint256 initialPrice,
        uint256 minBid,
        uint256 endTime
    ) internal view {
        if (nft == address(0)) {
            revert Errors.InvalidParameter();
        }

        if (initialPrice == 0) {
            revert Errors.InvalidParameter();
        }

        if (minBid == 0) {
            revert Errors.InvalidParameter();
        }

        if (endTime < block.timestamp) {
            revert Errors.InvalidParameter();
        }
    }

    // =============== AUCTION ===============

    function validateInitAuctionERC1155(
        address nft,
        uint256 amount,
        uint256 initialPrice,
        uint256 minBid,
        uint256 endTime
    ) internal view {
        if (nft == address(0)) {
            revert Errors.InvalidParameter();
        }

        if (amount == 0) {
            revert Errors.InvalidParameter();
        }

        if (initialPrice == 0) {
            revert Errors.InvalidParameter();
        }

        if (minBid == 0) {
            revert Errors.InvalidParameter();
        }

        if (endTime < block.timestamp) {
            revert Errors.InvalidParameter();
        }
    }

    function validateCancelAuctionNft(
        address caller,
        address creator,
        address lastBidder,
        uint256 endTime
    ) internal view {
        if (caller != creator) {
            revert Errors.InvalidParameter();
        }

        if (lastBidder != address(0)) {
            revert Errors.InvalidParameter();
        }

        if (endTime < block.timestamp) {
            revert Errors.InvalidParameter();
        }
    }

    function validateBidNft(
        address caller,
        address creator,
        uint256 amount,
        uint256 minimumAmountToBid,
        uint256 endTime
    ) internal view {
        if (caller == creator) {
            revert Errors.InvalidParameter();
        }

        if (amount < minimumAmountToBid) {
            revert Errors.InvalidParameter();
        }

        if (endTime < block.timestamp) {
            revert Errors.InvalidParameter();
        }
    }

    function validateClaimToken(
        address caller,
        address lastBidder,
        uint256 endTime,
        uint256 amount,
        bool claimed
    ) internal view {
        if (caller == lastBidder) {
            revert Errors.InvalidParameter();
        }

        if (endTime >= block.timestamp) {
            revert Errors.InvalidParameter();
        }

        if (amount == 0) {
            revert Errors.InvalidParameter();
        }

        if (claimed) {
            revert Errors.InvalidParameter();
        }
    }

    function validateFinishAuction(
        address caller,
        address lastBidder,
        address creator,
        uint256 endTime,
        bool claimed
    ) internal view {
        if (caller != creator || caller != lastBidder) {
            revert Errors.InvalidParameter();
        }

        if (lastBidder == address(0)) {
            revert Errors.InvalidParameter();
        }

        if (endTime >= block.timestamp) {
            revert Errors.InvalidParameter();
        }

        if (claimed) {
            revert Errors.InvalidParameter();
        }
    }
}
