import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("Coinfair", function () {
    const zeroAddress = hre.ethers.ZeroAddress;

    async function deploy() {
        const usr = await hre.ethers.getSigners();

        const NFT = await hre.ethers.getContractFactory("CoinFairNFT");
        const nft = await NFT.deploy();
        
        const Treasury = await hre.ethers.getContractFactory("CoinFairV2Treasury");
        const treasury = await Treasury.deploy();

        const Factory = await hre.ethers.getContractFactory("CoinFairFactory");
        const factory = await Factory.deploy(treasury.target);

        const CoinFairLibrary = await hre.ethers.getContractFactory("CoinFairLibrary");
        const coinFairLibrary = await CoinFairLibrary.deploy();

        const Hot = await hre.ethers.getContractFactory("CoinFairHotRouter", {
            libraries: {
                CoinFairLibrary: coinFairLibrary.target,
            },
        });
        const hot = await Hot.deploy(factory.target);

        const Warm = await hre.ethers.getContractFactory("CoinFairWarmRouter", {
            libraries: {
                CoinFairLibrary: coinFairLibrary.target,
            },
        });
        const warm = await Warm.deploy(factory.target);
        
        await factory.setHotRouterAddress(hot.target);

        await treasury.setDEXAddress(
            factory.target,
            nft.target,
            warm.target
        )

        const StandardToken= await hre.ethers.getContractFactory("StandardToken");
        const cf = await StandardToken.deploy("CF", "CF", 100000000000000, hot.target, warm.target);       
        const usdt = await StandardToken.deploy("USDT", "USDT", 100000000000000, hot.target, warm.target);       
        
        return {usr, nft, treasury, factory, hot, warm, cf, usdt};
    }

    async function addLiquidity(warm:any, factory:any, usr:any, token0:any, token1:any, amount0:any, amount1:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
        const addLiquidityTypes = ["uint256", "uint256", "uint256", "uint256", "uint8", "uint256"];
        const addLiquidityvalues = [amount0, amount1, 1, 1, poolType, fee];
        const addLiquidityEncode = hre.ethers.AbiCoder.defaultAbiCoder().encode(addLiquidityTypes, addLiquidityvalues);
        const usrBalBefore1 = await token0.balanceOf(usr[0]);
        const usrBalBefore2 = await token1.balanceOf(usr[0]);
        const pairBefore = await factory.getPair(token0, token1, 2, 5);

        expect(pairBefore).to.equal(zeroAddress);

        const addLiquidityReceipt = await (await warm.addLiquidity(token0, token1, usr[0], 999999999999, addLiquidityEncode)).wait();
        const usrBalAfter1 = await token0.balanceOf(usr[0]);
        const usrBalAfter2 = await token1.balanceOf(usr[0]);
        console.log("addLiquidity transfered ",await token0.name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("addLiquidity transfered ",await token1.name(),":",(usrBalBefore2 - usrBalAfter2));

        const pairAfter = await factory.getPair(token0, token1, 2, 5);
        console.log("pair: ",pairAfter);
        expect(pairAfter).to.not.equal(zeroAddress);
        
        const pairContract = await hre.ethers.getContractAt("CoinFairPair", pairAfter);
        const liquidityAmount = await pairContract.balanceOf(usr[0]);
        await pairContract.approve(warm, liquidityAmount);
        expect(await token0.balanceOf(pairAfter)).to.equal(usrBalBefore1 - usrBalAfter1);
        expect(await token1.balanceOf(pairAfter)).to.equal(usrBalBefore2 - usrBalAfter2);
        console.log("total liquidityAmount", liquidityAmount);
        console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n");

        return liquidityAmount;
    }

    async function removeLiquidity(warm:any, factory:any, usr:any, token0:any, token1:any, liqAmount:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
        const usrBalBefore1 = await token0.balanceOf(usr[0]);
        const usrBalBefore2 = await token1.balanceOf(usr[0]);
        const pair = await factory.getPair(token0, token1, 2, 5);

        console.log("pair: ",pair);
        expect(pair).to.not.equal(zeroAddress);
        
        const pairContract = await hre.ethers.getContractAt("CoinFairPair", pair);
        const removeLiquidityReceipt = await (await warm.removeLiquidity(token0, token1, liqAmount, 1, 1, usr[0], 999999999999, poolType, fee)).wait();

        const usrBalAfter1 = await token0.balanceOf(usr[0]);
        const usrBalAfter2 = await token1.balanceOf(usr[0]);
        console.log("removeLiquidity transfered: ",await token0.name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("removeLiquidity transfered: ",await token1.name(),":",(usrBalBefore2 - usrBalAfter2));
        console.log("liquidity after remove: ", await pairContract.balanceOf(usr[0]));
        console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
    }

    describe("CoinFair", function () {
        it("Should be successfully deployed", async function () {
          const {usr, nft, treasury, factory, hot, warm, cf, usdt} = await loadFixture(deploy);

          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("ownerAddress:       ",usr[0].address);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("nftAddress:         ",nft.target);
          console.log("treasuryAddress:    ",treasury.target);
          console.log("factoryAddress:     ",factory.target);
          console.log("factoryInitCode:    ",await factory.INIT_CODE_PAIR_HASH());
          console.log("hot:                ",hot.target);
          console.log("warm:               ",warm.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("factoryfeeTo:       ",await factory.feeTo());
          console.log("factoryfeeToSetter: ",await factory.feeToSetter());
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("cf:                 ",cf.target);
          console.log("usdt:               ",usdt.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")

          const warmAddr = await treasury.CoinFairWarmRouterAddress();
          console.log(hre.ethers.AbiCoder)
          expect(hre.ethers.getAddress(warmAddr)).to.equal(warm.target);
        });

        it("Should successfully addLiquidity and swap", async function(){
            const {usr, nft, treasury, factory, hot, warm, cf, usdt} = await loadFixture(deploy);

            const liquidityAmount = await addLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                160000000000000000000000000n,
                10000000000000000000000000n,
                2,
                5
            );

            await removeLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                liquidityAmount,
                2,
                5
            )
        })

    })

    // describe("Deployment", function () {
    //     it("")
    // })

    // describe("Events", function () {
    //     it("Should emit an event on withdrawals", async function () {
    //       const { lock, unlockTime, lockedAmount } = await loadFixture(
    //         deployOneYearLockFixture
    //       );
  
    //       await time.increaseTo(unlockTime);
  
    //       await expect(lock.withdraw())
    //         .to.emit(lock, "Withdrawal")
    //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
    //     });
    //   });
})
