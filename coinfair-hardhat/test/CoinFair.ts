import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { Decimal } from 'decimal.js';

function calculateXperY(
    _reserve0: bigint,
    _reserve1: bigint,
    _exponent0: bigint,
    _exponent1: bigint
  ): string {
    const reserve0 = new Decimal(_reserve0.toString());
    const reserve1 = new Decimal(_reserve1.toString());
    const exponent0 = new Decimal(_exponent0.toString());
    const exponent1 = new Decimal(_exponent1.toString());
  
    const denominator = reserve1.mul(exponent0);
    const numerator = reserve0.mul(exponent1);
  
    const XperY = numerator.div(denominator);
  
    return XperY.toFixed(18);
  }

describe("Coinfair", function () {
    const zeroAddress = hre.ethers.ZeroAddress;

    async function deploy() {
        const usr = await hre.ethers.getSigners();

        const NFT = await hre.ethers.getContractFactory("CoinfairNFT");
        const nft = await NFT.deploy();
        
        const Treasury = await hre.ethers.getContractFactory("CoinfairTreasury");
        const treasury = await Treasury.deploy();

        const Factory = await hre.ethers.getContractFactory("CoinfairFactory");
        const factory = await Factory.deploy(treasury.target);

        const CoinfairLibrary = await hre.ethers.getContractFactory("CoinfairLibrary");
        const coinfairLibrary = await CoinfairLibrary.deploy();

        const Hot = await hre.ethers.getContractFactory("CoinfairHotRouter", {
            libraries: {
                CoinfairLibrary: coinfairLibrary.target,
            },
        });
        const hot = await Hot.deploy(factory.target);

        const Warm = await hre.ethers.getContractFactory("CoinfairWarmRouter", {
            libraries: {
                CoinfairLibrary: coinfairLibrary.target,
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
        console.log("\n===== ===== ===== ===== addLiquidity ===== ===== ===== =====\n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());

        const addLiquidityTypes = ["uint256", "uint256", "uint256", "uint256", "uint8", "uint256"];
        const addLiquidityvalues = [amount0, amount1, 1, 1, poolType, fee];
        const addLiquidityEncode = hre.ethers.AbiCoder.defaultAbiCoder().encode(addLiquidityTypes, addLiquidityvalues);
        const usrBalBefore1 = await token0.balanceOf(usr[0]);
        const usrBalBefore2 = await token1.balanceOf(usr[0]);
        const pairBefore = await factory.getPair(token0, token1, poolType, fee);

        // expect(pairBefore).to.equal(zeroAddress);

        const addLiquidityReceipt = await (await warm.addLiquidity(token0, token1, usr[0], 999999999999, addLiquidityEncode)).wait();
        const usrBalAfter1 = await token0.balanceOf(usr[0]);
        const usrBalAfter2 = await token1.balanceOf(usr[0]);
        console.log("addLiquidity transfered ",await token0.name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("addLiquidity transfered ",await token1.name(),":",(usrBalBefore2 - usrBalAfter2));

        const pairAfter = await factory.getPair(token0, token1, poolType, fee);
        console.log("pair: ",pairAfter);
        expect(pairAfter).to.not.equal(zeroAddress);
        
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pairAfter);
        const liquidityAmount = await pairContract.balanceOf(usr[0]);
        await pairContract.approve(warm, liquidityAmount);
        // expect(await token0.balanceOf(pairAfter)).to.equal(usrBalBefore1 - usrBalAfter1);
        // expect(await token1.balanceOf(pairAfter)).to.equal(usrBalBefore2 - usrBalAfter2);
        console.log("total liquidityAmount", liquidityAmount);
        console.log("\n===== ===== ===== ===== addLiquidity ===== ===== ===== =====\n");

        return liquidityAmount;
    }

    async function removeLiquidity(warm:any, factory:any, usr:any, token0:any, token1:any, liqAmount:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== ===== removeLiquidity ===== ===== ===== =====\n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());
        const usrBalBefore1 = await token0.balanceOf(usr[0]);
        const usrBalBefore2 = await token1.balanceOf(usr[0]);
        const pair = await factory.getPair(token0, token1, poolType, fee);

        console.log("pair: ",pair);
        expect(pair).to.not.equal(zeroAddress);
        
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);
        const removeLiquidityReceipt = await (await warm.removeLiquidity(token0, token1, liqAmount, 1, 1, usr[0], 999999999999, poolType, fee)).wait();

        const usrBalAfter1 = await token0.balanceOf(usr[0]);
        const usrBalAfter2 = await token1.balanceOf(usr[0]);
        console.log("removeLiquidity transfered: ",await token0.name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("removeLiquidity transfered: ",await token1.name(),":",(usrBalBefore2 - usrBalAfter2));
        console.log("liquidity after remove: ", await pairContract.balanceOf(usr[0]));
        console.log("\n===== ===== ===== ===== removeLiquidity ===== ===== ===== =====\n")
    }

    async function swap(nft:any, treasury:any, hot:any, factory:any, usr:any, amountIn:any, token:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== =====   swap   ===== ===== ===== =====n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());

        const usrBalBefore1 = await token[0].balanceOf(usr[0]);
        const usrBalBefore2 = await token[token.length-1].balanceOf(usr[0]);
        const pair = await factory.getPair(token[0].target, token[token.length-1].target, poolType[0], fee[0]);
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);
        const community = await pairContract.getProjectCommunityAddress()
        expect(pair).to.not.equal(zeroAddress);
        const treasuryBalBefore0 = await token[0].balanceOf(treasury);
        const treasuryBalBefore1 = await token[token.length-1].balanceOf(treasury);
        const communityTreasuryBefore0 = await treasury.CoinfairUsrTreasury(community, token[0]);
        const communityTreasuryBefore1 = await treasury.CoinfairUsrTreasury(community, token[token.length-1]);
        const feetoTreasuryBefore0 = await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[0]);
        const feetoTreasuryBefore1 = await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[token.length-1]);

        console.log(usr[0].address)
        const parentAddr = await nft.parentAddress(usr[0]);
        
        const parentTreasuryBefore0 = await treasury.CoinfairUsrTreasury(parentAddr, token[0]);
        const parentTreasuryBefore1 = await treasury.CoinfairUsrTreasury(parentAddr, token[token.length-1]);


        const swapReceipt = await(await hot.swapExactTokensForTokens(amountIn, 1, token, poolType, fee, usr[0], 999999999999)).wait()

        const usrBalAfter1 = await token[0].balanceOf(usr[0]);
        const usrBalAfter2 = await token[token.length-1].balanceOf(usr[0]);


        const {_reserve0, _reserve1,} = await pairContract.getReserves();
        const {_exponent0, _exponent1,} = await pairContract.getExponents()
        const XperY = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
        
        console.log("Price now:",XperY,await token[0].name(), "= 1",  await token[token.length-1].name());
        console.log("Price now:",(new Decimal(BigInt(1).toString())).div(XperY),await token[token.length-1].name(), "= 1", await token[0].name());

        console.log("swap transfered: ",await token[0].name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("swap transfered: ",await token[token.length-1].name(),":",(usrBalBefore2 - usrBalAfter2));
        console.log("(Notice: - pool -> usr & + usr -> pool)\n");
        console.log("**** Tracking fee income ****")
        
        console.log("Treasury Balance Change  : ",await token[0].name(),await token[0].balanceOf(treasury)-treasuryBalBefore0);
        console.log("Treasury Balance Change  : ",await token[token.length-1].name(),await token[token.length-1].balanceOf(treasury)-treasuryBalBefore1);
        console.log("community Addr           :", community);
        console.log("community Treasury Change: ",await token[0].name(),await treasury.CoinfairUsrTreasury(community, token[0])-communityTreasuryBefore0);
        console.log("community Treasury Change: ",await token[token.length-1].name(),await treasury.CoinfairUsrTreasury(community, token[token.length-1])-communityTreasuryBefore1);

        console.log("feeto Addr               :", await factory.feeTo());
        console.log("feeto Treasury Change    : ",await token[0].name(),await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[0])-feetoTreasuryBefore0);
        console.log("feeto Treasury Change    : ",await token[token.length-1].name(),await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[token.length-1])-feetoTreasuryBefore1);

        console.log("parent Addr              :", parentAddr)
        console.log("feeto Treasury Change    : ",await token[0].name(),await treasury.CoinfairUsrTreasury(parentAddr, token[0])-parentTreasuryBefore0)
        console.log("feeto Treasury Change    : ",await token[token.length-1].name(),await treasury.CoinfairUsrTreasury(parentAddr, token[token.length-1])-parentTreasuryBefore1);
        console.log("\n===== ===== ===== =====   swap   ===== ===== ===== =====n")

    }

    describe("Coinfair", function () {
        it("Should be successfully deployed", async function () {
          const {usr, nft, treasury, factory, hot, warm, cf, usdt} = await loadFixture(deploy);

          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("ownerAddress:       ",usr[0].address);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("nftAddress:         ",nft.target);
          console.log("treasuryAddress:    ",treasury.target);
          console.log("factoryAddress:     ",factory.target);
          console.log("InitCode:           ",await factory.INIT_CODE_PAIR_HASH());
          console.log("hot:                ",hot.target);
          console.log("warm:               ",warm.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("factoryfeeTo:       ",await factory.feeTo());
          console.log("factoryfeeToSetter: ",await factory.feeToSetter());
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("cf:                 ",cf.target);
          console.log("usdt:               ",usdt.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")

          const warmAddr = await treasury.CoinfairWarmRouterAddress();
          console.log(hre.ethers.AbiCoder)
          expect(hre.ethers.getAddress(warmAddr)).to.equal(warm.target);
        });

        it("Should successfully all", async function(){
            const {usr, nft, treasury, factory, hot, warm, cf, usdt} = await loadFixture(deploy);

            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,1,1);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,1,3);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,1,5);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,1,10);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,2,1);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,2,3);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,2,5);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,2,10);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,4,1);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,4,3);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,4,5);
            await addLiquidity(warm,factory,usr,cf,usdt,160000000000000000000000000n,10000000000000000000000000n,4,10);

            await addLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                160000000000000000000000000n,
                10000000000000000000000000n,
                4,
                5
            );

            await addLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                160000000000000000000000000n,
                10000000000000000000000000n,
                2,
                1
            );

            hre.network.provider.send("evm_mine")
            hre.network.provider.send("evm_mine")
            hre.network.provider.send("evm_mine")
            hre.network.provider.send("evm_mine")

            await swap(
                nft,
                treasury,
                hot,
                factory,
                usr,
                1000000000000000000n,
                [cf, usdt],
                [1],
                [5]
            )
            console.log(await treasury.getPairManagement([cf, usdt],usr[0]));
            await removeLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                await (
                    await hre.ethers.getContractAt("CoinfairPair",(
                        await factory.getPair(cf, usdt, 2, 1)))).balanceOf(usr[0]),
                2,
                1
            )
            console.log("After remove one pool", await treasury.getPairManagement([cf, usdt],usr[0]));

            // treasury.setRoolOver
            const pair = await factory.getPair(cf, usdt, 1, 5);
            const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);

            await treasury.setRoolOver(pairContract.target,true);
            console.log("roolOver: ",await pairContract.roolOver());

            const price0CumulativeLast = await pairContract.price0CumulativeLast();
            const price1CumulativeLast = await pairContract.price1CumulativeLast();
            console.log("price0CumulativeLast: ",price0CumulativeLast);
            console.log("price1CumulativeLast: ",price1CumulativeLast);

            await swap(
                nft,
                treasury,
                hot,
                factory,
                usr,
                1000000000000000000n,
                [cf, usdt],
                [1],
                [5]
            )

            await removeLiquidity(
                warm,
                factory,
                usr,
                cf,
                usdt,
                await (
                    await hre.ethers.getContractAt("CoinfairPair",(
                        await factory.getPair(cf, usdt, 1, 5)))).balanceOf(usr[0]),
                1,
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
