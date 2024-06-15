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
import {ISotaMarketplaceHub} from "contracts/interfaces/ISotaMarketplaceHub.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract SotaMarketplaceHub is
    ISotaMarketplaceHub,
    SotaMarketplaceStorage,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721Holder,
    ERC1155Holder
{
    constructor() {}

    function initialize(
        address _owner,
        address _treasury
    ) external initializer {
        ValidationLib.validateOwnerAddress(_owner);
        __Ownable_init(_owner);
        GovernanceLib.setTreasury(_treasury);
    }

    // ============================ EXTERNAL =====================================
    // ============= FIXED PRICE ===============
    function listERC721Nft(
        Types.ListERC721Params calldata params
    ) external isBlacklisted {
        FixedPriceNftLib.processListERC721(msg.sender, params);
    }

    function listERC1155Nft(
        Types.ListERC1155Params calldata params
    ) external isBlacklisted {
        FixedPriceNftLib.processListERC1155(msg.sender, params);
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
        AuctionNftLib.processInitERC721Auction(msg.sender, params);
    }

    function initERC1155Auction(
        Types.AuctionERC1155Params calldata params
    ) external isBlacklisted {
        AuctionNftLib.processInitERC1155Auction(msg.sender, params);
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

    function claimToken(uint256 _auctionId) external {
        AuctionNftLib.processClaimToken(msg.sender, _auctionId);
    }

    function claimNft(uint256 _auctionId) external {
        AuctionNftLib.processClaimNft(msg.sender, _auctionId);
    }

    // ============== GOVERNANCE ===============
    function treasury() external view returns (address) {
        return StorageLib.getTreasuryData().treasury;
    }

    function buyFee() external view returns (uint16) {
        return StorageLib.getTreasuryData().treasuryBuyFeeBPS;
    }

    function sellFee() external view returns (uint16) {
        return StorageLib.getTreasuryData().treasurySellFeeBPS;
    }

    function setTreasuryBuyFee(uint16 newTreasuryFee) external onlyOwner {
        GovernanceLib.setTreasuryBuyFee(newTreasuryFee);
    }

    function setTreasurySellFee(uint16 newTreasuryFee) external onlyOwner {
        GovernanceLib.setTreasurySellFee(newTreasuryFee);
    }

    function setTreasury(address _treasury) external onlyOwner {
        GovernanceLib.setTreasury(_treasury);
    }

    function blockUser(address _user) external onlyOwner {
        GovernanceLib.setBlacklistUser(_user, true);
    }

    function unblockUser(address _user) external onlyOwner {
        GovernanceLib.setBlacklistUser(_user, false);
    }

    // =========================== INTERNAL ======================================
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // =========================== MODIFIER ======================================
    modifier isBlacklisted() {
        ValidationLib.validateBlacklistUser();
        _;
    }
}
