import { ethers } from "hardhat";

async function main() {
  const Core = await ethers.deployContract("SoundSphereCore", [
    "0x0bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59", //ChainLink Router
    1, //Min of 1
    60, //60 Secs Interval
  ]);

  await Core.waitForDeployment();

  console.log(`Core contract deployed at ${Core.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// 0x4bf666288c7F3a223e92ccFD687395b4DE0B6fBf
