import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { MyToken } from "../typechain-types/contracts/mocks/ERC20Mock.sol/MyToken";
import { MyERC721Nft } from "../typechain-types/contracts/mocks/ERC721Mock.sol/MyERC721Nft";
import { MyERC1155Nft } from "../typechain-types/contracts/mocks/ERC1155Mock.sol/MyERC1155Nft";

describe("SotaMarketplaceHub", () => {
  let sotaMarketplaceHub: any;
  let myToken: MyToken;
  let myERC721Nft: MyERC721Nft;
  let myERC1155Nft: MyERC1155Nft;
  let owner: HardhatEthersSigner;
  let treasury: HardhatEthersSigner;
  let addr1: HardhatEthersSigner;
  let addr2: HardhatEthersSigner;

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  beforeEach(async () => {
    const SotaMarketplaceHubFactory = await ethers.getContractFactory(
      "SotaMarketplaceHub"
    );
    [owner, treasury, addr1, addr2] = await ethers.getSigners();

    sotaMarketplaceHub = await upgrades.deployProxy(
      SotaMarketplaceHubFactory,
      [owner.address, treasury.address],
      { initializer: "initialize", kind: "uups" }
    );

    const myTokenFactory = await ethers.getContractFactory("MyToken");
    myToken = await myTokenFactory.deploy(owner.address);
    const myERC721NftFactory = await ethers.getContractFactory("MyERC721Nft");
    myERC721Nft = await myERC721NftFactory.deploy(owner.address);
    const myERC1155NftFactory = await ethers.getContractFactory("MyERC1155Nft");
    myERC1155Nft = await myERC1155NftFactory.deploy(owner.address);
  });

  describe("Deployment", () => {
    it("Should set the right owner", async () => {
      expect(await sotaMarketplaceHub.owner()).to.equal(owner.address);
      expect(await sotaMarketplaceHub.treasury()).to.equal(treasury.address);
    });

    it("Should revert when initializing owner with zero address", async () => {
      await expect(
        sotaMarketplaceHub.initialize(ZERO_ADDRESS, treasury.address)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "InvalidInitialization"
      );
    });

    it("Should revert when initializing treasury with zero address", async () => {
      await expect(
        sotaMarketplaceHub.initialize(owner.address, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "InvalidInitialization"
      );
    });
  });

  describe("Fixed Price Listing", function () {
    it("Should list and buy an ERC721 NFT by native token", async function () {
      await sotaMarketplaceHub.connect(owner).setTreasuryBuyFee(500); // 5%
      await sotaMarketplaceHub.connect(owner).setTreasurySellFee(500); // 5%
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);
      const listERC721Params = {
        nft: myERC721Nft.target,
        tokenId: 1,
        price: ethers.parseEther("1"),
        payToken: ZERO_ADDRESS,
      };

      await sotaMarketplaceHub.connect(addr1).listERC721Nft(listERC721Params);
      expect(await sotaMarketplaceHub.totalListNfts()).to.equal(1);
      expect(await myERC721Nft.ownerOf(1)).to.equal(sotaMarketplaceHub.target);
      await expect(
        sotaMarketplaceHub
          .connect(addr2)
          .buyNft(0, { value: ethers.parseEther("1") })
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "InsufficientBalance"
      );
      await expect(
        sotaMarketplaceHub
          .connect(addr1)
          .buyNft(0, { value: ethers.parseEther("1.05") })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      const addr1Balance = await ethers.provider.getBalance(addr1.address);
      const treasuryBalance = await ethers.provider.getBalance(
        treasury.address
      );
      await sotaMarketplaceHub
        .connect(addr2)
        .buyNft(0, { value: ethers.parseEther("1.05") }); // 1 + 5% * 1 (fee)
      const newAddr1Balance = await ethers.provider.getBalance(addr1.address);
      const newTreasuryBalance = await ethers.provider.getBalance(
        treasury.address
      );
      expect(addr1Balance + ethers.parseEther("0.95")).to.equal(
        newAddr1Balance
      );
      expect(treasuryBalance + ethers.parseEther("0.1")).to.equal(
        newTreasuryBalance
      );
      expect(await myERC721Nft.ownerOf(1)).to.equal(addr2.address);
      await expect(
        sotaMarketplaceHub
          .connect(addr2)
          .buyNft(0, { value: ethers.parseEther("1.05") })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await expect(
        sotaMarketplaceHub.connect(addr1).cancelListNft(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
    });

    it("Should list and buy an ERC721 NFT by ERC20 token", async function () {
      await sotaMarketplaceHub.connect(owner).setTreasuryBuyFee(500); // 5%
      await sotaMarketplaceHub.connect(owner).setTreasurySellFee(500); // 5%
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);
      const listERC721Params = {
        nft: myERC721Nft.target,
        tokenId: 1,
        price: ethers.parseEther("1"),
        payToken: myToken.target,
      };

      await sotaMarketplaceHub.connect(addr1).listERC721Nft(listERC721Params);
      await myToken.connect(owner).mint(addr2.address, ethers.parseEther("2"));
      await myToken
        .connect(addr2)
        .approve(sotaMarketplaceHub.target, ethers.parseEther("2"));
      const addr1Balance = await myToken.balanceOf(addr1.address);
      const treasuryBalance = await myToken.balanceOf(treasury.address);
      await sotaMarketplaceHub.connect(addr2).buyNft(0); // 1 + 5% * 1 (fee)
      const newAddr1Balance = await myToken.balanceOf(addr1.address);
      const newTreasuryBalance = await myToken.balanceOf(treasury.address);
      expect(addr1Balance + ethers.parseEther("0.95")).to.equal(
        newAddr1Balance
      );
      expect(treasuryBalance + ethers.parseEther("0.1")).to.equal(
        newTreasuryBalance
      );
      expect(await myERC721Nft.ownerOf(1)).to.equal(addr2.address);
    });

    it("Should list and buy an ERC1155 NFT", async function () {
      await myERC1155Nft.connect(owner).mint(addr1.address, 1, 10);
      await myERC1155Nft
        .connect(addr1)
        .setApprovalForAll(sotaMarketplaceHub.target, true);

      const listERC1155Params = {
        nft: myERC1155Nft.target,
        tokenId: 1,
        price: ethers.parseEther("1"),
        payToken: ZERO_ADDRESS,
        amount: 10,
      };

      await sotaMarketplaceHub.connect(addr1).listERC1155Nft(listERC1155Params);
      expect(await sotaMarketplaceHub.totalListNfts()).to.equal(1);

      await sotaMarketplaceHub
        .connect(addr2)
        .buyNft(0, { value: ethers.parseEther("1") });

      expect(await myERC1155Nft.balanceOf(addr2.address, 1)).to.equal(10);
    });

    it("Should cancel a listed ERC721 NFT", async function () {
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);

      const listERC721Params = {
        nft: myERC721Nft.target,
        tokenId: 1,
        price: ethers.parseEther("1"),
        payToken: ZERO_ADDRESS,
      };

      await sotaMarketplaceHub.connect(addr1).listERC721Nft(listERC721Params);

      await expect(
        sotaMarketplaceHub.connect(addr2).cancelListNft(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");

      await sotaMarketplaceHub.connect(addr1).cancelListNft(0);

      expect(await myERC721Nft.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should cancel a listed ERC1155 NFT", async function () {
      await myERC1155Nft.connect(owner).mint(addr1.address, 1, 10);
      await myERC1155Nft
        .connect(addr1)
        .setApprovalForAll(sotaMarketplaceHub.target, true);
      const listERC1155Params = {
        nft: myERC1155Nft.target,
        tokenId: 1,
        price: ethers.parseEther("1"),
        payToken: ZERO_ADDRESS,
        amount: 10,
      };

      await sotaMarketplaceHub.connect(addr1).listERC1155Nft(listERC1155Params);

      await sotaMarketplaceHub.connect(addr1).cancelListNft(0);

      expect(await myERC1155Nft.balanceOf(addr1.address, 1)).to.equal(10);
    });
  });

  describe("Auction NFT Operations", () => {
    it("Should ERC721 auction with native token", async function () {
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);
      const now = await ethers.provider
        .getBlock("latest")
        .then((res) => res?.timestamp ?? Math.floor(Date.now() / 1000));

      const auctionParams = {
        nft: myERC721Nft.target,
        tokenId: 1,
        initialPrice: ethers.parseEther("1"),
        minBid: ethers.parseEther("0.1"),
        endTime: now + 3600,
        payToken: ZERO_ADDRESS,
      };

      // await expect(
      await sotaMarketplaceHub.connect(addr1).initERC721Auction(auctionParams);
      // ).to.emit(sotaMarketplaceHub, "AuctionNftCreated");
      expect(await myERC721Nft.ownerOf(1)).to.equal(sotaMarketplaceHub.target);
      expect(await sotaMarketplaceHub.totalAuctionNfts()).to.equal(1);
      await expect(
        sotaMarketplaceHub
          .connect(addr1)
          .bidNft(0, ethers.parseEther("1"), { value: ethers.parseEther("1") })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await expect(
        sotaMarketplaceHub.connect(addr2).bidNft(0, ethers.parseEther("1"), {
          value: ethers.parseEther("0.5"),
        })
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "InsufficientBalance"
      );
      expect(
        await sotaMarketplaceHub
          .connect(owner)
          .bidNft(0, ethers.parseEther("1"), { value: ethers.parseEther("1") })
      ).to.emit(sotaMarketplaceHub, "BidNft");
      expect((await sotaMarketplaceHub.auctionNfts(0))[9]).to.equals(
        owner.address
      );
      await expect(
        sotaMarketplaceHub
          .connect(addr2)
          .bidNft(0, ethers.parseEther("1"), { value: ethers.parseEther("1") })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");

      await expect(
        sotaMarketplaceHub.connect(addr2).bidNft(0, ethers.parseEther("1.05"), {
          value: ethers.parseEther("1.05"),
        })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");

      await sotaMarketplaceHub
        .connect(addr2)
        .bidNft(0, ethers.parseEther("1.1"), {
          value: ethers.parseEther("1.1"),
        });

      expect(
        (await sotaMarketplaceHub.bidPlaces(0, addr2.address))[0]
      ).to.equal(ethers.parseEther("1.1"));
      await expect(
        sotaMarketplaceHub.connect(addr1).cancelAuction(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");
      await expect(
        sotaMarketplaceHub.connect(addr2).bidNft(0, ethers.parseEther("1.5"), {
          value: ethers.parseEther("0.4"),
        })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await expect(
        sotaMarketplaceHub.connect(addr1).claimNft(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await expect(sotaMarketplaceHub.connect(addr2).claimNft(0)).to.be.emit(
        sotaMarketplaceHub,
        "NftClaimed"
      );
      expect(await myERC721Nft.ownerOf(1)).to.equal(addr2.address);
      await expect(
        sotaMarketplaceHub.connect(addr2).claimToken(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      await expect(sotaMarketplaceHub.connect(addr1).claimToken(0)).to.be.emit(
        sotaMarketplaceHub,
        "AmountClaimed"
      );
      await expect(sotaMarketplaceHub.connect(owner).claimToken(0)).to.be.emit(
        sotaMarketplaceHub,
        "AmountClaimed"
      );
      await expect(
        sotaMarketplaceHub.connect(owner).claimToken(0)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
    });

    it("Should ERC721 auction with ERC20", async function () {
      await myToken.connect(owner).mint(addr2, ethers.parseEther("10"));
      await myToken.connect(owner).mint(owner, ethers.parseEther("10"));
      await myToken
        .connect(addr2)
        .approve(sotaMarketplaceHub.target, ethers.parseEther("10"));
      await myToken
        .connect(owner)
        .approve(sotaMarketplaceHub.target, ethers.parseEther("10"));
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);
      const now = await ethers.provider
        .getBlock("latest")
        .then((res) => res?.timestamp ?? Math.floor(Date.now() / 1000));

      const auctionParams = {
        nft: myERC721Nft.target,
        tokenId: 1,
        initialPrice: ethers.parseEther("1"),
        minBid: ethers.parseEther("0.1"),
        endTime: now + 3600,
        payToken: myToken.target,
      };

      // await expect(
      await sotaMarketplaceHub.connect(addr1).initERC721Auction(auctionParams);
      // ).to.emit(sotaMarketplaceHub, "AuctionNftCreated");
      expect(await myERC721Nft.ownerOf(1)).to.equal(sotaMarketplaceHub.target);
      expect(await sotaMarketplaceHub.totalAuctionNfts()).to.equal(1);
      await expect(
        sotaMarketplaceHub
          .connect(owner)
          .bidNft(0, ethers.parseEther("1"), { value: ethers.parseEther("1") })
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
      expect(
        await sotaMarketplaceHub
          .connect(owner)
          .bidNft(0, ethers.parseEther("1"))
      ).to.emit(sotaMarketplaceHub, "BidNft");

      await sotaMarketplaceHub
        .connect(addr2)
        .bidNft(0, ethers.parseEther("1.1"));

      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");
      await expect(sotaMarketplaceHub.connect(addr2).claimNft(0)).to.be.emit(
        sotaMarketplaceHub,
        "NftClaimed"
      );
      await expect(sotaMarketplaceHub.connect(addr1).claimToken(0)).to.be.emit(
        sotaMarketplaceHub,
        "AmountClaimed"
      );
      await expect(sotaMarketplaceHub.connect(owner).claimToken(0)).to.be.emit(
        sotaMarketplaceHub,
        "AmountClaimed"
      );
    });

    it("Should ERC1155 auction", async function () {
      await myERC1155Nft.connect(owner).mint(addr1.address, 1, 10);
      await myERC1155Nft
        .connect(addr1)
        .setApprovalForAll(sotaMarketplaceHub.target, true);
      const now = await ethers.provider
        .getBlock("latest")
        .then((res) => res?.timestamp ?? Math.floor(Date.now() / 1000));

      const auctionParams = {
        nft: myERC1155Nft.target,
        tokenId: 1,
        amount: 10,
        initialPrice: ethers.parseEther("1"),
        minBid: ethers.parseEther("0.1"),
        endTime: now + 3600,
        payToken: ZERO_ADDRESS,
      };

      // await expect(
      await sotaMarketplaceHub.connect(addr1).initERC1155Auction(auctionParams);
      // ).to.emit(sotaMarketplaceHub, "AuctionNftCreated");
      expect(
        await myERC1155Nft.balanceOf(sotaMarketplaceHub.target, 1)
      ).to.equal(10);
      expect(
        await sotaMarketplaceHub
          .connect(owner)
          .bidNft(0, ethers.parseEther("1"), { value: ethers.parseEther("1") })
      ).to.emit(sotaMarketplaceHub, "BidNft");

      await sotaMarketplaceHub
        .connect(addr2)
        .bidNft(0, ethers.parseEther("1.1"), {
          value: ethers.parseEther("1.1"),
        });
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");
      // await expect(sotaMarketplaceHub.connect(addr2).claimNft(0)).to.be.emit(
      //   sotaMarketplaceHub,
      //   "NftClaimed"
      // );
      // expect(await myERC1155Nft.balanceOf(addr2.address, 1)).to.equal(10);
    });

    it("Should cancel auction", async function () {
      await myERC721Nft.connect(owner).mint(addr1.address, 1);
      await myERC721Nft.connect(addr1).approve(sotaMarketplaceHub.target, 1);
      const now = await ethers.provider
        .getBlock("latest")
        .then((res) => res?.timestamp ?? Math.floor(Date.now() / 1000));

      const auctionParams = {
        nft: myERC721Nft.target,
        tokenId: 1,
        initialPrice: ethers.parseEther("1"),
        minBid: ethers.parseEther("0.1"),
        endTime: now + 3600,
        payToken: ZERO_ADDRESS,
      };

      // await expect(
      await sotaMarketplaceHub.connect(addr1).initERC721Auction(auctionParams);
      // ).to.emit(sotaMarketplaceHub, "AuctionNftCreated");
      await expect(
        sotaMarketplaceHub.connect(addr1).cancelAuction(0)
      ).to.be.emit(sotaMarketplaceHub, "AuctionNftCancelled");
      expect(await myERC721Nft.ownerOf(1)).to.equal(addr1.address);
    });
  });

  describe("Governance - setTreasury", () => {
    it("Should set a new treasury address", async () => {
      await sotaMarketplaceHub.connect(owner).setTreasury(addr1.address);
      const newTreasury = await sotaMarketplaceHub.treasury(); // getFeeInfo returns treasury as the third element
      expect(newTreasury).to.equal(addr1.address);
    });

    it("Should revert when setting treasury is not from owner", async () => {
      await expect(
        sotaMarketplaceHub.connect(addr1).setTreasury(treasury.address)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "OwnableUnauthorizedAccount"
      );
    });

    it("Should revert when setting treasury to the zero address", async () => {
      await expect(
        sotaMarketplaceHub.connect(owner).setTreasury(ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InitParamsInvalid");
    });
  });

  describe("Governance - setTreasuryBuyFee", () => {
    it("Should set a new buy fee", async () => {
      const newFee = 500; // 5%
      await sotaMarketplaceHub.connect(owner).setTreasuryBuyFee(newFee);
      const newBuyFee = await sotaMarketplaceHub.buyFee();
      expect(newBuyFee).to.equal(500);
    });

    it("Should revert when setting buy fee is not from owner", async () => {
      await expect(
        sotaMarketplaceHub.connect(addr1).setTreasuryBuyFee(500)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "OwnableUnauthorizedAccount"
      );
    });

    it("Should revert when setting a buy fee greater than 100%", async () => {
      const invalidFee = 11000; // 110%
      await expect(
        sotaMarketplaceHub.connect(owner).setTreasuryBuyFee(invalidFee)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InitParamsInvalid");
    });
  });

  describe("Governance - setTreasurySellFee", () => {
    it("Should set a new sell fee", async () => {
      const newFee = 500; // 5%
      await sotaMarketplaceHub.connect(owner).setTreasurySellFee(newFee);
      const newSellFee = await sotaMarketplaceHub.sellFee();
      expect(newSellFee).to.equal(500);
    });

    it("Should revert when setting sell fee is not from owner", async () => {
      await expect(
        sotaMarketplaceHub.connect(addr1).setTreasurySellFee(500)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "OwnableUnauthorizedAccount"
      );
    });

    it("Should revert when setting a sell fee greater than 100%", async () => {
      const invalidFee = 11000; // 110%
      await expect(
        sotaMarketplaceHub.connect(owner).setTreasurySellFee(invalidFee)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InitParamsInvalid");
    });
  });

  describe("Governance - setBlacklistUser", () => {
    it("Should blacklist a user", async () => {
      await sotaMarketplaceHub.connect(owner).blockUser(addr1.address);
      expect(await sotaMarketplaceHub.blacklist(addr1.address)).to.be.true;
      await sotaMarketplaceHub.connect(owner).unblockUser(addr1.address);
      expect(await sotaMarketplaceHub.blacklist(addr1.address)).to.be.false;
    });

    it("Should revert when setting blacklist is not from owner", async () => {
      await expect(
        sotaMarketplaceHub.connect(addr1).blockUser(addr1.address)
      ).to.be.revertedWithCustomError(
        sotaMarketplaceHub,
        "OwnableUnauthorizedAccount"
      );
    });

    it("Should revert when blacklisting the zero address", async () => {
      await expect(
        sotaMarketplaceHub.connect(owner).blockUser(ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(sotaMarketplaceHub, "InvalidParameter");
    });
  });
});
