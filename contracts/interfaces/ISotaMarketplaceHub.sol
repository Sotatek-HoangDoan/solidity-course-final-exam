// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface ISotaMarketplaceHub {
    function initialize() external;

    function listNft(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _paymentToken,
        uint256 _price
    ) external;

    function createAuction(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _basePrice,
        uint256 _minBid,
        uint256 _endTime
    ) external;

    function buyNft(address _nft, uint256 _tokenId) external;

    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bitAmount
    ) external;

    function withdrawToken(address _nft, uint256 _tokenId) external;
}
