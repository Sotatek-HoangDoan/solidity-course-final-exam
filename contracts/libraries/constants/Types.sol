// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

library Types {
    enum NftType {
        ERC721,
        ERC1155
    }

    struct ListNFT {
        uint256 id;
        address nft;
        uint256 tokenId;
        uint256 amount;
        address seller;
        address payToken; // address(0) means ETH
        uint256 price;
        bool sold;
        NftType nftType;
    }

    struct AuctionNFT {
        uint256 id;
        address nft;
        uint256 tokenId;
        uint256 amount;
        address creator;
        address payToken; // address(0) means ETH
        uint256 initialPrice;
        uint256 minBid;
        uint256 endTime;
        address lastBidder;
        bool claimed;
        NftType nftType;
    }

    struct BidPlace {
        uint256 amount;
        bool claimed;
    }

    struct TreasuryData {
        address treasury;
        uint16 treasuryBuyFeeBPS;
        uint16 treasurySellFeeBPS;
    }

    struct ListERC721Params {
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
    }

    struct ListERC1155Params {
        address nft;
        uint256 tokenId;
        uint256 amount;
        address payToken;
        uint256 price;
    }

    struct AuctionERC721Params {
        uint256 id;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 initialPrice;
        uint256 minBid;
        uint256 endTime;
    }

    struct AuctionERC1155Params {
        uint256 id;
        address nft;
        uint256 tokenId;
        uint256 amount;
        address payToken;
        uint256 initialPrice;
        uint256 minBid;
        uint256 endTime;
    }
}
