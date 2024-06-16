// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";

interface ISotaMarketplaceHub {
    // ============= FIXED PRICE ===============
    function listERC721Nft(Types.ListERC721Params calldata params) external;

    function listERC1155Nft(Types.ListERC1155Params calldata params) external;

    function buyNft(uint256 _listNftId) external payable;

    function cancelListNft(uint256 _listNftId) external;

    // ============= AUCTION NFT ===============
    function initERC721Auction(
        Types.AuctionERC721Params calldata params
    ) external;

    function initERC1155Auction(
        Types.AuctionERC1155Params calldata params
    ) external;

    function cancelAuction(uint256 _auctionId) external;

    function bidNft(uint256 _auctionId, uint256 _amount) external payable;

    function claimToken(uint256 _auctionId) external;

    function claimNft(uint256 _auctionId) external;

    // ============== GOVERNANCE ===============
    function setTreasuryBuyFee(uint16 newTreasuryFee) external;

    function setTreasurySellFee(uint16 newTreasuryFee) external;

    function setTreasury(address treasury) external;
}
