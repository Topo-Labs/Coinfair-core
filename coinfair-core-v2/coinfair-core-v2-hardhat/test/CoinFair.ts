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

        const View = await hre.ethers.getContractFactory("CoinfairView");
        const view = await View.deploy(warm.target, factory.target);

        await treasury.setDEXAddress(
            factory.target,
            nft.target
        )

        const StandardToken= await hre.ethers.getContractFactory("StandardToken");
        // const usdt = await StandardToken.deploy("USDT", "USDT", 100000000000000, hot.target, warm.target);    
        const cf = await StandardToken.deploy("CF", "CF", 100000000000000, hot.target, warm.target);       
        const usdt = await StandardToken.deploy("USDT", "USDT", 100000000000000, hot.target, warm.target);    
        
        const WETH= await hre.ethers.getContractFactory("WETH");
        const weth = await WETH.deploy();
        
        return {usr, nft, treasury, factory, hot, warm, cf, usdt, weth, view};
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
        if(BigInt(token0.target) > BigInt(token1.target)){
            if(poolType === 2){
                poolType = 3;
            }else if(poolType === 4){
                poolType = 5;
            }
        }
        console.log(token0.target, token1.target, poolType)
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

    async function swapExactTFTSupportFeeOn(nft:any, treasury:any, hot:any, factory:any, usr:any, amountIn:any, token:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== =====   swap   ===== ===== ===== =====n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());

        const usrBalBefore1 = await token[0].balanceOf(usr[0]);
        const usrBalBefore2 = await token[token.length-1].balanceOf(usr[0]);
        const pair = await factory.getPair(token[0].target, token[token.length-1].target, poolType[0], fee[0]);
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);
        console.log("pair: ", pairContract.target)
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


        const swapReceipt = await(await hot.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 1, token, poolType, fee, usr[0], 999999999999)).wait()

        const usrBalAfter1 = await token[0].balanceOf(usr[0]);
        const usrBalAfter2 = await token[token.length-1].balanceOf(usr[0]);


        const {_reserve0, _reserve1,} = await pairContract.getReserves();
        const {_exponent0, _exponent1,} = await pairContract.getExponents();
        const token0 = await pairContract.token0();
        let XperY;
        console.log("token info: ", token0, token[0].target, _exponent0, _exponent1)
        if(token0 === token[0].target){
            XperY = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
        }else{
            const YperX = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
            XperY = (new Decimal(BigInt(1).toString())).div(YperX);
        }

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

    async function swapExactTFT(nft:any, treasury:any, hot:any, factory:any, usr:any, amountIn:any, token:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== =====   swap   ===== ===== ===== =====n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());

        const usrBalBefore1 = await token[0].balanceOf(usr[0]);
        const usrBalBefore2 = await token[token.length-1].balanceOf(usr[0]);
        const pair = await factory.getPair(token[0].target, token[token.length-1].target, poolType[0], fee[0]);
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);
        console.log("pair: ", pairContract.target)
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
        const {_exponent0, _exponent1,} = await pairContract.getExponents();
        const token0 = await pairContract.token0();
        let XperY;
        console.log("token info: ", token0, token[0].target, _exponent0, _exponent1)
        if(token0 === token[0].target){
            XperY = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
        }else{
            const YperX = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
            XperY = (new Decimal(BigInt(1).toString())).div(YperX);
        }

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

    async function swapTFExactT(nft:any, treasury:any, hot:any, factory:any, usr:any, amountIn:any, token:any, poolType:any, fee:any){
        console.log("\n===== ===== ===== =====   swap   ===== ===== ===== =====n")
        console.log("BlockNumber:",await hre.ethers.provider.getBlockNumber());

        const usrBalBefore1 = await token[0].balanceOf(usr[0]);
        const usrBalBefore2 = await token[token.length-1].balanceOf(usr[0]);
        const pair = await factory.getPair(token[0].target, token[token.length-1].target, poolType[0], fee[0]);
        const pairContract = await hre.ethers.getContractAt("CoinfairPair", pair);
        console.log("pair: ", pairContract.target)
        const community = await pairContract.getProjectCommunityAddress()
        expect(pair).to.not.equal(zeroAddress);
        const treasuryBalBefore0 = await token[0].balanceOf(treasury);
        const treasuryBalBefore1 = await token[token.length-1].balanceOf(treasury);
        const communityTreasuryBefore0 = await treasury.CoinfairUsrTreasury(community, token[0]);
        const communityTreasuryBefore1 = await treasury.CoinfairUsrTreasury(community, token[token.length-1]);
        const feetoTreasuryBefore0 = await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[0]);
        const feetoTreasuryBefore1 = await treasury.CoinfairUsrTreasury(await factory.feeTo(), token[token.length-1]);

        // console.log(usr[0].address)
        const parentAddr = await nft.parentAddress(usr[0]);
        
        const parentTreasuryBefore0 = await treasury.CoinfairUsrTreasury(parentAddr, token[0]);
        const parentTreasuryBefore1 = await treasury.CoinfairUsrTreasury(parentAddr, token[token.length-1]);


        const swapReceipt = await(await hot.swapTokensForExactTokens(amountIn, 1000000000000000000000000000000000000000n, token, poolType, fee, usr[0], 999999999999)).wait()

        const usrBalAfter1 = await token[0].balanceOf(usr[0]);
        const usrBalAfter2 = await token[token.length-1].balanceOf(usr[0]);


        const {_reserve0, _reserve1,} = await pairContract.getReserves();
        const {_exponent0, _exponent1,} = await pairContract.getExponents();

        const token0 = await pairContract.token0();
        const token1 = await pairContract.token1();
        let XperY;
        console.log("token info: ", token0, token[0].target, _exponent0, _exponent1)
        if(token0 === token[0].target){
            XperY = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
        }else{
            const YperX = calculateXperY(_reserve0, _reserve1, BigInt(_exponent0), BigInt(_exponent1));
            XperY = (new Decimal(BigInt(1).toString())).div(YperX);
        }

        console.log("Price now:",XperY,await token[0].name(), "= 1",  await token[token.length-1].name());
        console.log("Price now:",(new Decimal(BigInt(1).toString())).div(XperY),await token[token.length-1].name(), "= 1", await token[0].name());

        console.log("usr swap transfered: ",await token[0].name(),":",(usrBalBefore1 - usrBalAfter1));
        console.log("usr swap transfered: ",await token[token.length-1].name(),":",(usrBalBefore2 - usrBalAfter2));

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
          const {usr, nft, treasury, factory, hot, warm, cf, usdt, weth, view} = await loadFixture(deploy);

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
          console.log("view:             : ",await view.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")
          console.log("cf:                 ",cf.target);
          console.log("usdt:               ",usdt.target);
          console.log("weth:               ",weth.target);
          console.log("\n===== ===== ===== ===== ===== ===== ===== ===== ===== =====\n")

          console.log(hre.ethers.AbiCoder)
        });

        it("Should successfully all (no fee/no eth)", async function(){
            const {usr, nft, treasury, factory, hot, warm, cf, usdt} = await loadFixture(deploy);

            console.log("test normal pool")
            await addLiquidity(warm,factory,usr,cf,usdt,200000000000000000000000n,25000000000000000000000n,2,3);

            const pair23 = await factory.getPair(cf, usdt, 2, 3);
            const pairContract23 = await hre.ethers.getContractAt("CoinfairPair", pair23);
            let poolType_ = 2;
            if(BigInt(cf.target) > BigInt(usdt.target)){
                if(poolType_ === 2){
                    poolType_ = 3;
                }else if(poolType_ === 4){
                    poolType_ = 5;
                }
            }
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[poolType_],[3])
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[poolType_],[3])          
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[poolType_],[3])
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[poolType_],[3])     

            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[poolType_],[3])
            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[poolType_],[3])             

            await removeLiquidity(warm,factory,usr,cf,usdt,
                await (await hre.ethers.getContractAt("CoinfairPair",(await factory.getPair(cf, usdt, poolType_, 3))))
                    .balanceOf(usr[0]),poolType_,3)

            // ========================================================================
            console.log("test pool 1, 10 without roolover")
            await addLiquidity(warm,factory,usr,cf,usdt,200000000000000000000000n,25000000000000000000000n,1,10);
            const pair110 = await factory.getPair(cf, usdt, 1, 10);
            const pairContract110 = await hre.ethers.getContractAt("CoinfairPair", pair110);

            await treasury.setRoolOver(pairContract110.target,false);
            console.log("test pool 1, 10 without roolover 1")
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])
            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])
            await treasury.setRoolOver(pairContract110.target,true);
            console.log("test pool 1, 10 and roolover 1")
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])
            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])

            await treasury.setRoolOver(pairContract110.target,false);
            console.log("test pool 1, 10 without roolover 2")
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])
            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])
            await treasury.setRoolOver(pairContract110.target,true);
            console.log("test pool 1, 10 and roolover 2")
            await swapExactTFT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])
            await swapExactTFTSupportFeeOn(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])

            await treasury.setRoolOver(pairContract110.target,false);
            console.log("test pool 1, 10 without roolover 3")
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])
            await treasury.setRoolOver(pairContract110.target,true);
            console.log("test pool 1, 10 and roolover 3")
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[cf, usdt],[1],[10])
            
            await treasury.setRoolOver(pairContract110.target,false);
            console.log("test pool 1, 10 without roolover 4")
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])
            await treasury.setRoolOver(pairContract110.target,true);
            console.log("test pool 1, 10 and roolover 4")
            await swapTFExactT(nft,treasury,hot,factory,usr,1000000000000000000n,[usdt, cf],[1],[10])       

            await removeLiquidity(warm,factory,usr,cf,usdt,
                await (await hre.ethers.getContractAt("CoinfairPair",(await factory.getPair(cf, usdt, 1, 10))))
                    .balanceOf(usr[0]),1,10)
        })
    })
})
