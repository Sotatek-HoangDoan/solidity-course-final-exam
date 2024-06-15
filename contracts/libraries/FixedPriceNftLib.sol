// SPDX-License-Identifier: Apache
pragma solidity 0.8.24;

import {Events} from "contracts/libraries/constants/Events.sol";
import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {StorageLib} from "contracts/libraries/StorageLib.sol";
import {ValidationLib} from "contracts/libraries/ValidationLib.sol";
import {GovernanceLib} from "contracts/libraries/GovernanceLib.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library FixedPriceNftLib {
    using SafeERC20 for IERC20;

    function processListERC721(
        address _creator,
        Types.ListERC721Params calldata _listNftParams
    ) internal {
        ValidationLib.validateListErc721Request(
            _listNftParams.nft,
            _listNftParams.price
        );

        uint256 currentListNftId = _initListNft(
            _creator,
            _listNftParams.nft,
            _listNftParams.tokenId,
            1,
            _listNftParams.payToken,
            _listNftParams.price,
            Types.NftType.ERC721
        );

        _forwardERC721FromSeller(
            _creator,
            _listNftParams.nft,
            _listNftParams.tokenId
        );

        emit Events.ListNftForSale(
            _listNftParams,
            currentListNftId,
            _creator,
            block.timestamp
        );
    }

    function processListERC1155(
        address _creator,
        Types.ListERC1155Params calldata _listNftParams
    ) internal {
        ValidationLib.validateListErc1155Request(
            _listNftParams.nft,
            _listNftParams.price,
            _listNftParams.amount
        );

        uint256 currentListNftId = _initListNft(
            _creator,
            _listNftParams.nft,
            _listNftParams.tokenId,
            _listNftParams.amount,
            _listNftParams.payToken,
            _listNftParams.price,
            Types.NftType.ERC1155
        );

        _forwardERC1155FromSeller(
            _creator,
            _listNftParams.nft,
            _listNftParams.tokenId,
            _listNftParams.amount
        );

        emit Events.ListNftForSale(
            _listNftParams,
            currentListNftId,
            _creator,
            block.timestamp
        );
    }

    // Thieu logic fee
    function processBuyNft(address _buyer, uint256 _listNftId) internal {
        Types.ListNFT storage request = StorageLib.getListNFT(_listNftId);
        ValidationLib.validateBuyListNft(_buyer, request.seller, request.sold);
        (uint256 buyFee, uint256 sellFee, address treasury) = GovernanceLib
            .getFeeInfo(request.price);
        request.sold = true;

        if (request.payToken == address(0)) {
            if (msg.value != request.price + buyFee) {
                revert Errors.InsufficientBalance();
            }
            _forwardETHFromBuyer(request.seller, request.price - sellFee);
            _forwardETHFromBuyer(treasury, sellFee + buyFee);
        } else {
            _forwardERC20FromBuyer(
                _buyer,
                request.seller,
                request.payToken,
                request.price - sellFee
            );
            _forwardERC20FromBuyer(
                _buyer,
                treasury,
                request.payToken,
                sellFee + buyFee
            );
        }

        if (request.nftType == Types.NftType.ERC721) {
            _forwardERC721ToBuyer(_buyer, request.nft, request.tokenId);
        } else {
            _forwardERC1155ToBuyer(
                _buyer,
                request.nft,
                request.tokenId,
                request.amount
            );
        }

        emit Events.BuyNft(_listNftId, _buyer, block.timestamp);
    }

    function processCancel(address _seller, uint256 _requestId) internal {
        Types.ListNFT storage request = StorageLib.getListNFT(_requestId);
        ValidationLib.validateCancelListNft(
            _seller,
            request.seller,
            request.sold
        );

        request.sold = true;

        if (request.nftType == Types.NftType.ERC721) {
            _forwardERC721ToBuyer(_seller, request.nft, request.tokenId);
        } else {
            _forwardERC1155ToBuyer(
                _seller,
                request.nft,
                request.tokenId,
                request.amount
            );
        }

        emit Events.ListNftCancelled(_requestId, block.timestamp);
    }

    function _initListNft(
        address _creator,
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _payToken,
        uint256 _price,
        Types.NftType _nftType
    ) private returns (uint256 currentListNftId) {
        currentListNftId = StorageLib.getTotalListNfts();
        Types.ListNFT storage listNft = StorageLib.getListNFT(currentListNftId);

        listNft.id = currentListNftId;
        listNft.nft = _nft;
        listNft.tokenId = _tokenId;
        listNft.amount = _amount;
        listNft.seller = _creator;
        listNft.payToken = _payToken;
        listNft.price = _price;
        listNft.nftType = _nftType;

        StorageLib.setTotalListNfts(currentListNftId + 1);
    }

    function _forwardETHFromBuyer(address _seller, uint256 _amount) private {
        payable(_seller).transfer(_amount);
    }

    function _forwardERC20FromBuyer(
        address _buyer,
        address _seller,
        address _token,
        uint256 _amount
    ) private {
        if (msg.value > 0) {
            revert Errors.InvalidParameter();
        }
        IERC20(_token).safeTransferFrom(_buyer, _seller, _amount);
    }

    function _forwardERC721FromSeller(
        address _seller,
        address _nft,
        uint256 _tokenId
    ) private {
        IERC721(_nft).safeTransferFrom(_seller, address(this), _tokenId);
    }

    function _forwardERC1155FromSeller(
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

    function _forwardERC721ToBuyer(
        address _buyer,
        address _nft,
        uint256 _tokenId
    ) private {
        IERC721(_nft).safeTransferFrom(address(this), _buyer, _tokenId);
    }

    function _forwardERC1155ToBuyer(
        address _buyer,
        address _nft,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        IERC1155(_nft).safeTransferFrom(
            address(this),
            _buyer,
            _tokenId,
            _amount,
            ""
        );
    }
}
