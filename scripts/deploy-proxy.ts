import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const SotaMarketplace = await ethers.getContractFactory("SotaMarketplaceHub");
  console.log("Deploying Marketplace ...");
  const sotaMarketplace = await upgrades.deployProxy(
    SotaMarketplace,
    [deployer.address, deployer.address],
    { initializer: "initialize", kind: "uups" }
  );
  await sotaMarketplace.deploymentTransaction();
  console.log(sotaMarketplace.target, " box(proxy) address");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
