// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Events} from "contracts/libraries/constants/Events.sol";
import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {StorageLib} from "contracts/libraries/StorageLib.sol";
import {ValidationLib} from "contracts/libraries/ValidationLib.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library AuctionNftLib {
    using SafeERC20 for IERC20;

    function processInitERC721Auction(
        address _creator,
        Types.AuctionERC721Params calldata _initAuctionParams
    ) internal {
        ValidationLib.validateInitAuctionERC721(
            _initAuctionParams.nft,
            _initAuctionParams.initialPrice,
            _initAuctionParams.minBid,
            _initAuctionParams.endTime
        );

        uint256 currentAuctionId = _initAuctionNft(
            _creator,
            _initAuctionParams.nft,
            _initAuctionParams.tokenId,
            1,
            _initAuctionParams.payToken,
            _initAuctionParams.initialPrice,
            _initAuctionParams.minBid,
            _initAuctionParams.endTime
        );

        _forwardERC721FromCreator(
            _creator,
            _initAuctionParams.nft,
            _initAuctionParams.tokenId
        );

        emit Events.AuctionNftCreated(
            _initAuctionParams,
            currentAuctionId,
            _creator,
            block.timestamp
        );
    }

    function processInitERC1155Auction(
        address _creator,
        Types.AuctionERC1155Params calldata _initAuctionParams
    ) internal {
        ValidationLib.validateInitAuctionERC1155(
            _initAuctionParams.nft,
            _initAuctionParams.amount,
            _initAuctionParams.initialPrice,
            _initAuctionParams.minBid,
            _initAuctionParams.endTime
        );

        uint256 currentAuctionId = _initAuctionNft(
            _creator,
            _initAuctionParams.nft,
            _initAuctionParams.tokenId,
            _initAuctionParams.amount,
            _initAuctionParams.payToken,
            _initAuctionParams.initialPrice,
            _initAuctionParams.minBid,
            _initAuctionParams.endTime
        );

        _forwardERC1155FromCreator(
            _creator,
            _initAuctionParams.nft,
            _initAuctionParams.tokenId,
            _initAuctionParams.amount
        );

        emit Events.AuctionNftCreated(
            _initAuctionParams,
            currentAuctionId,
            _creator,
            block.timestamp
        );
    }

    function processCancelAuction(
        address _creator,
        uint256 _auctionId
    ) internal {
        Types.AuctionNFT storage request = StorageLib.getAuctionNFT(_auctionId);
        ValidationLib.validateCancelAuctionNft(
            _creator,
            request.creator,
            request.lastBidder,
            request.endTime
        );

        request.claimed = true;

        if (request.nftType == Types.NftType.ERC721) {
            _forwardERC721ToBidder(_creator, request.nft, request.tokenId);
        } else {
            _forwardERC1155ToBidder(
                _creator,
                request.nft,
                request.tokenId,
                request.amount
            );
        }

        emit Events.AuctionNftCancelled(_auctionId, block.timestamp);
    }

    function processBidNft(
        address _bidder,
        uint256 _auctionId,
        uint256 _amount
    ) internal {
        Types.AuctionNFT storage request = StorageLib.getAuctionNFT(_auctionId);
        Types.BidPlace storage bidPlace = StorageLib.getBidPlace(
            _auctionId,
            request.lastBidder
        );
        uint256 minimumToBid = request.lastBidder == address(0)
            ? request.initialPrice
            : bidPlace.amount + request.minBid;
        ValidationLib.validateBidNft(
            _bidder,
            request.creator,
            _amount,
            minimumToBid,
            request.endTime
        );
        Types.BidPlace storage newBidPlace = StorageLib.getBidPlace(
            _auctionId,
            _bidder
        );

        uint256 amountNeedToTransfer = _amount - newBidPlace.amount;
        newBidPlace.amount = _amount;
        request.lastBidder = _bidder;

        if (request.payToken == address(0)) {
            _forwardETHFromBidder(amountNeedToTransfer);
        } else {
            _forwardERC20FromBidder(
                _bidder,
                request.payToken,
                amountNeedToTransfer
            );
        }

        emit Events.BidNft(_auctionId, _bidder, _amount, block.timestamp);
    }

    function processClaimToken(address _bidder, uint256 _auctionId) internal {
        Types.AuctionNFT storage request = StorageLib.getAuctionNFT(_auctionId);

        Types.BidPlace storage bidPlace = StorageLib.getBidPlace(
            _auctionId,
            _bidder == request.creator ? request.lastBidder : _bidder // Nếu người claim là creator của auction thì sẽ claim token của last bidder
        );

        ValidationLib.validateClaimToken(
            _bidder,
            request.lastBidder,
            request.endTime,
            bidPlace.amount,
            bidPlace.claimed
        );

        bidPlace.claimed = true;

        if (request.payToken == address(0)) {
            _forwardETHtoUser(_bidder, bidPlace.amount);
        } else {
            _forwardERC20ToUser(_bidder, request.payToken, bidPlace.amount);
        }

        emit Events.AmountClaimed(
            _auctionId,
            _bidder,
            bidPlace.amount,
            block.timestamp
        );
    }

    function processClaimNft(address _bidder, uint256 _auctionId) internal {
        Types.AuctionNFT storage request = StorageLib.getAuctionNFT(_auctionId);
        ValidationLib.validateClaimNft(
            _bidder,
            request.lastBidder,
            request.creator,
            request.endTime,
            request.claimed
        );

        request.claimed = true;

        if (request.nftType == Types.NftType.ERC721) {
            _forwardERC721ToBidder(_bidder, request.nft, request.tokenId);
        } else {
            _forwardERC1155ToBidder(
                _bidder,
                request.nft,
                request.tokenId,
                request.amount
            );
        }

        emit Events.NftClaimed(
            _auctionId,
            _bidder,
            request.nft,
            request.tokenId,
            block.timestamp
        );
    }

    function _initAuctionNft(
        address _creator,
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _payToken,
        uint256 _initialPrice,
        uint256 _minBid,
        uint256 _endTime
    ) private returns (uint256 currentAuctionId) {
        currentAuctionId = StorageLib.getTotalAuctionNfts();
        Types.AuctionNFT storage auctionNft = StorageLib.getAuctionNFT(
            currentAuctionId
        );

        auctionNft.id = currentAuctionId;
        auctionNft.nft = _nft;
        auctionNft.tokenId = _tokenId;
        auctionNft.amount = _amount;
        auctionNft.creator = _creator;
        auctionNft.payToken = _payToken;
        auctionNft.initialPrice = _initialPrice;
        auctionNft.minBid = _minBid;
        auctionNft.endTime = _endTime;

        StorageLib.setTotalAuctionNfts(currentAuctionId + 1);
    }

    function _forwardETHFromBidder(uint256 _amount) private {
        if (msg.value != _amount) {
            revert Errors.InsufficientBalance();
        }
    }

    function _forwardERC20FromBidder(
        address _bidder,
        address _token,
        uint256 _amount
    ) private {
        if (msg.value > 0) {
            revert Errors.InvalidParameter();
        }
        IERC20(_token).safeTransferFrom(_bidder, address(this), _amount);
    }

    function _forwardETHtoUser(address _bidder, uint256 _amount) private {
        payable(_bidder).transfer(_amount);
    }

    function _forwardERC20ToUser(
        address _bidder,
        address _token,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransfer(_bidder, _amount);
    }

    function _forwardERC721FromCreator(
        address _seller,
        address _nft,
        uint256 _tokenId
    ) private {
        IERC721(_nft).safeTransferFrom(_seller, address(this), _tokenId);
    }

    function _forwardERC1155FromCreator(
        address _seller,
        address _nft,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        IERC1155(_nft).safeTransferFrom(
            _seller,
            address(this),
            _tokenId,
            _amount,
            ""
        );
    }

    function _forwardERC721ToBidder(
        address _bidder,
        address _nft,
        uint256 _tokenId
    ) private {
        IERC721(_nft).safeTransferFrom(address(this), _bidder, _tokenId);
    }

    function _forwardERC1155ToBidder(
        address _bidder,
        address _nft,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        IERC1155(_nft).safeTransferFrom(
            address(this),
            _bidder,
            _tokenId,
            _amount,
            ""
        );
    }
}
