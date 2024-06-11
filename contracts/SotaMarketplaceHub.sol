// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SotaMarketplaceStorage} from "contracts/SotaMarketplaceStorage.sol";
import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {StorageLib} from "contracts/libraries/StorageLib.sol";
import {ValidationLib} from "contracts/libraries/ValidationLib.sol";
import {FixedPriceNftLib} from "contracts/libraries/FixedPriceNftLib.sol";
import {AuctionNftLib} from "contracts/libraries/AuctionNftLib.sol";
import {GovernanceLib} from "contracts/libraries/GovernanceLib.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SotaMarketplaceHub is SotaMarketplaceStorage, Initializable {
    constructor(address _owner) {
        if (_owner == address(0)) {
            revert Errors.InvalidOwner();
        }

        StorageLib.setProtocolOwner(_owner);
    }

    // ============================ EXTERNAL =====================================
    // ============= FIXED PRICE ===============
    function listERC721Nft(
        Types.ListERC721Params calldata params
    ) external isBlacklisted {
        FixedPriceNftLib.processListNft(msg.sender, params);
    }

    function listERC1155Nft(
        Types.ListERC1155Params calldata params
    ) external isBlacklisted {
        FixedPriceNftLib.processListNft(msg.sender, params);
    }

    function buyNft(uint256 _listNftId) external payable isBlacklisted {
        FixedPriceNftLib.processBuyNft(msg.sender, _listNftId);
    }

    function cancelListNft(uint256 _listNftId) external {
        FixedPriceNftLib.processCancel(msg.sender, _listNftId);
    }

    // ============= AUCTION NFT ===============
    function initERC721Auction(
        Types.AuctionERC721Params calldata params
    ) external isBlacklisted {
        AuctionNftLib.processInitAuction(msg.sender, params);
    }

    function initERC1155Auction(
        Types.AuctionERC1155Params calldata params
    ) external isBlacklisted {
        AuctionNftLib.processInitAuction(msg.sender, params);
    }

    function cancelAuction(uint256 _auctionId) external {
        AuctionNftLib.processCancelAuction(msg.sender, _auctionId);
    }

    function bidNft(
        uint256 _auctionId,
        uint256 _amount
    ) external isBlacklisted {
        AuctionNftLib.processBidNft(msg.sender, _auctionId, _amount);
    }

    function finishAuction(uint256 _auctionId) external {
        AuctionNftLib.processFinishAuction(msg.sender, _auctionId);
    }

    function withdrawToken(uint256 _auctionId) external {
        AuctionNftLib.processWithdrawAmount(msg.sender, _auctionId);
    }

    // ============== GOVERNANCE ===============
    function setTreasuryBuyFee(
        uint16 newTreasuryFee
    ) external onlyProtocolOwner {
        GovernanceLib.setTreasuryBuyFee(newTreasuryFee);
    }

    function setTreasurySellFee(
        uint16 newTreasuryFee
    ) external onlyProtocolOwner {
        GovernanceLib.setTreasurySellFee(newTreasuryFee);
    }

    function setTreasury(address treasury) external onlyProtocolOwner {
        GovernanceLib.setTreasury(treasury);
    }

    //  =========================== MODIFIER ======================================
    modifier onlyProtocolOwner() {
        ValidationLib.validateCallerIsProtocolOwner();
        _;
    }

    modifier isBlacklisted() {
        ValidationLib.validateBlacklistUser();
        _;
    }
}
