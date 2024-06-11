// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library Errors {
    error InvalidTreasury();
    error InvalidOwner();
    error NotOwnerOrApproved();
    error InitParamsInvalid();
    error InvalidParameter();
    error NotProtocolOwner();
    error InsufficientBalance();
}
