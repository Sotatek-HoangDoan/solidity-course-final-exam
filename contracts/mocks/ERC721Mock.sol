// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyERC721Nft is ERC721 {
    constructor(address initialOwner) ERC721("MyToken", "MTK") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
