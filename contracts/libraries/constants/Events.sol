// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";

library Events {
    event TreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the treasury fee is set.
     *
     * @param feeType The treasury fee type: 1 = buy, 2 = sell
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event TreasuryFeeSet(
        uint8 indexed feeType,
        uint16 indexed prevTreasuryFee,
        uint16 indexed newTreasuryFee,
        uint256 timestamp
    );

    event BlacklistedAccount(address account, bool status, uint256 timestamp);

    // ============== FIXED PRICE ==============
    event ListNftForSale(
        Types.ListERC721Params listNftParams,
        uint256 indexed requestId,
        address creator,
        uint256 timestamp
    );

    event ListNftForSale(
        Types.ListERC1155Params listNftParams,
        uint256 indexed requestId,
        address creator,
        uint256 timestamp
    );

    event ListNftCancelled(uint256 indexed requestId, uint256 timestamp);

    event BuyNft(uint256 indexed requestId, address buyer, uint256 timestamp);

    // =============== AUCTION ===============

    event AuctionNftCreated(
        Types.AuctionERC721Params auctionNftParams,
        uint256 indexed requestId,
        address creator,
        uint256 timestamp
    );

    event AuctionNftCreated(
        Types.AuctionERC1155Params auctionNftParams,
        uint256 indexed requestId,
        address creator,
        uint256 timestamp
    );

    event AuctionNftCancelled(uint256 indexed requestId, uint256 timestamp);
    event BidNft(
        uint256 indexed requestId,
        address bidder,
        uint256 amount,
        uint256 timestamp
    );

    event AmountClaimed(
        uint256 indexed requestId,
        address bidder,
        uint256 amount,
        uint256 timestamp
    );

    event NftClaimed(
        uint256 indexed requestId,
        address bidder,
        address nft,
        uint256 tokenId,
        uint256 timestamp
    );

    event AuctionNftFinished(uint256 indexed requestId, uint256 timestamp);
}
