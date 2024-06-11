// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Types} from "contracts/libraries/constants/Types.sol";

library StorageLib {
    // Storage slots constants
    uint256 constant TOTAL_LIST_NFTS_SLOT = 0;
    uint256 constant TOTAL_AUCTION_NFTS_SLOT = 1;
    uint256 constant OWNER_SLOT = 2;
    uint256 constant TREASURY_DATA_SLOT = 3;
    uint256 constant LIST_NFTS_MAPPING_SLOT = 4;
    uint256 constant AUCTION_NFTS_MAPPING_SLOT = 5;
    uint256 constant BID_PLACES_MAPPING_SLOT = 6;

    function getTotalListNfts() internal view returns (uint256 _totalListNfts) {
        assembly {
            _totalListNfts := sload(TOTAL_LIST_NFTS_SLOT)
        }
    }

    function setTotalListNfts(uint256 _totalListNfts) internal {
        assembly {
            sstore(TOTAL_LIST_NFTS_SLOT, _totalListNfts)
        }
    }

    function getTotalAuctionNfts()
        internal
        view
        returns (uint256 _totalAuctionNfts)
    {
        assembly {
            _totalAuctionNfts := sload(TOTAL_AUCTION_NFTS_SLOT)
        }
    }

    function setTotalAuctionNfts(uint256 _totalAuctionNfts) internal {
        assembly {
            sstore(TOTAL_AUCTION_NFTS_SLOT, _totalAuctionNfts)
        }
    }

    function getListNFT(
        uint256 id
    ) internal pure returns (Types.ListNFT storage _listNFT) {
        assembly {
            mstore(0, id)
            mstore(32, LIST_NFTS_MAPPING_SLOT)
            _listNFT.slot := keccak256(0, 64)
        }
    }

    function getAuctionNFT(
        uint256 id
    ) internal pure returns (Types.AuctionNFT storage _auctionNFT) {
        assembly {
            mstore(0, id)
            mstore(32, AUCTION_NFTS_MAPPING_SLOT)
            _auctionNFT.slot := keccak256(0, 64)
        }
    }

    function getTreasuryData()
        internal
        pure
        returns (Types.TreasuryData storage _treasuryData)
    {
        assembly {
            _treasuryData.slot := TREASURY_DATA_SLOT
        }
    }

    function getBidPlace(
        uint256 auctionId,
        address bidder
    ) internal pure returns (Types.BidPlace storage _bidPlace) {
        assembly {
            mstore(0, auctionId)
            mstore(32, BID_PLACES_MAPPING_SLOT)
            let auctionBidPlaceSlot := keccak256(0, 64)
            mstore(0, bidder)
            mstore(32, auctionBidPlaceSlot)
            _bidPlace.slot := keccak256(0, 64)
        }
    }

    function getProtocolOwner() internal view returns (address _owner) {
        assembly {
            _owner := sload(OWNER_SLOT)
        }
    }

    function setProtocolOwner(address _owner) internal {
        assembly {
            sstore(OWNER_SLOT, _owner)
        }
    }
}
