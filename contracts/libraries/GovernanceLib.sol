// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {Events} from "contracts/libraries/constants/Events.sol";
import {StorageLib} from "contracts/libraries/StorageLib.sol";

library GovernanceLib {
    uint16 internal constant BPS_MAX = 10000;

    function setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) {
            revert Errors.InitParamsInvalid();
        }

        Types.TreasuryData storage _treasuryData = StorageLib.getTreasuryData();

        address prevTreasury = _treasuryData.treasury;
        _treasuryData.treasury = newTreasury;

        emit Events.TreasurySet(prevTreasury, newTreasury, block.timestamp);
    }

    function setTreasuryBuyFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee > BPS_MAX / 2) {
            revert Errors.InitParamsInvalid();
        }

        Types.TreasuryData storage _treasuryData = StorageLib.getTreasuryData();

        uint16 prevTreasuryFee = _treasuryData.treasuryBuyFeeBPS;
        _treasuryData.treasuryBuyFeeBPS = newTreasuryFee;

        emit Events.TreasuryFeeSet(
            1,
            prevTreasuryFee,
            newTreasuryFee,
            block.timestamp
        );
    }

    function setTreasurySellFee(uint16 newTreasuryFee) internal {
        if (newTreasuryFee > BPS_MAX / 2) {
            revert Errors.InitParamsInvalid();
        }

        Types.TreasuryData storage _treasuryData = StorageLib.getTreasuryData();

        uint16 prevTreasuryFee = _treasuryData.treasurySellFeeBPS;
        _treasuryData.treasurySellFeeBPS = newTreasuryFee;

        emit Events.TreasuryFeeSet(
            2,
            prevTreasuryFee,
            newTreasuryFee,
            block.timestamp
        );
    }

    function setBlacklistUser(address account) internal {
        if (account == address(0)) {
            revert Errors.InvalidParameter();
        }
        StorageLib.setBlacklistUser(account);
        emit Events.BlacklistedAccount(account, block.timestamp);
    }
}
