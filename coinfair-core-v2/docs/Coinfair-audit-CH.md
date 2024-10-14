# Coinfair-audit

10.15 更新：

1. CFC-05：修正了warmRouter中的`_addLiquidityAssist_()`函数

   ```solidity
       function _addLiquidityAssist_(bytes memory _addLiquidityCmd)internal virtual returns(uint reserveA, uint reserveB, uint8 poolType, uint fee){
           (address tokenA, address tokenB, uint256 exponentA, uint256 exponentB, uint _fee) = abi.decode(_addLiquidityCmd,(address, address, uint256, uint256, uint));
           fee = _fee;
   
           if(tokenA < tokenB){
               if(exponentA == 32 && exponentB == 32){poolType=1;}
               else if (exponentA == 32 && exponentB == 8){poolType = 2;}
               else if (exponentA == 8 && exponentB == 32){poolType = 3;}
               else if (exponentA == 32 && exponentB == 1){poolType = 4;}
               else if (exponentA == 1 && exponentB == 32){poolType = 5;}
           }else{
               if(exponentA == 32 && exponentB == 32){poolType=1;}
               else if (exponentA == 32 && exponentB == 8){poolType = 3;}
               else if (exponentA == 8 && exponentB == 32){poolType = 2;}
               else if (exponentA == 32 && exponentB == 1){poolType = 5;}
               else if (exponentA == 1 && exponentB == 32){poolType = 4;}
           }
           
           // create the pair if it doesn't exist yet
           if (ICoinfairFactory(factory).getPair(tokenA, tokenB, poolType, _fee) == address(0)) {
               ICoinfairFactory(factory).createPair(tokenA, tokenB, exponentA, exponentB, _fee);
           }
   
           (reserveA, reserveB) = CoinfairLibrary.getReserves(factory, tokenA, tokenB, poolType, _fee);
       }
   ```

   

10-11 回复：

之前已经和BD沟通过，本次审计基于的代码仓库如下

https://github.com/Topo-Labs/Coinfair-core

1. TCF-01：Token.sol、WETH.sol和CoinfairView.sol无需审计，CoinfairNFT.sol已经审计过，之前与BD已经沟通过。

2. CRC-04：对于ERC20和ERC20组成的池子，允许的类型有1/2/4。对于ERC20和ETH组成的池子，允许的类型有1/2/3/4/5。这是因为addLiquidityETH()中，erc20总是在eth的前面

   ```solidity
       function _addLiquidityETHAssist(address token, uint fee, bytes memory addLiquidityETHCmd)internal returns(uint,uint,uint8,uint){
           (uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,uint8 swapN) = abi.decode(addLiquidityETHCmd,(uint,uint,uint,uint8));
           require(fee == 1 || fee == 3 || fee == 5 || fee == 10, "ERROR FEE");
           bytes memory _addLiquidityCmd;
           if(swapN == 1){
               _addLiquidityCmd = abi.encode(token, WETH, 32, 32, fee);
           }else if(swapN == 2){
               // sequence == 0 && swapN == 2;
               _addLiquidityCmd = abi.encode(token, WETH, 32, 8, fee);
           }else if(swapN == 3){
               // sequence != 0 && swapN == 2;
               _addLiquidityCmd = abi.encode(token, WETH, 8, 32, fee);
           }else if(swapN == 4){
               // sequence == 0 && swapN == 3;
               _addLiquidityCmd = abi.encode(token, WETH, 32, 1, fee);
           }else if(swapN == 5){
               // sequence != 0 && swapN == 3;
               _addLiquidityCmd = abi.encode(token, WETH, 1, 32, fee);
           }else{
               revert();
           }
           return _addLiquidity(_addLiquidityCmd, amountTokenDesired,msg.value,amountTokenMin,amountETHMin);
       }
   ```

   本质上` _addLiquidityCmd = abi.encode(token, WETH, 8, 32, fee);`和`_addLiquidityCmd = abi.encode(WETH, token, 32, 8, fee);`是相同的。如果用户提供了Coinfair不支持的类型，将不会成功添加流动性。

3. CFT-01：在我们提供的仓库中，代码已经修改：

   ```solidity
       function _swapAssist(address to, uint amount0Out, uint amount1Out, uint fee_, bytes memory data)internal returns(uint,uint){
           address _token0 = token0;
           address _token1 = token1;
           require(to != _token0 && to != _token1, 'Coinfair: INVALID_TO');
   
           if(exponent0 < exponent1 || (exponent0 == exponent1 && roolOver)){
               TransferHelper.safeApprove(_token0, CoinfairTreasury, fee_);
               ICoinfairTreasury(CoinfairTreasury).collectFee(_token0, to, fee_, address(this));
           }else{
               TransferHelper.safeApprove(_token1, CoinfairTreasury, fee_);
               ICoinfairTreasury(CoinfairTreasury).collectFee(_token1, to, fee_, address(this));
           }
           if (amount0Out > 0)  _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
           if (amount1Out > 0)  _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
   
           if (data.length > 0) ICoinfairCallee(to).CoinfairCall(msg.sender, amount0Out, amount1Out, data);
           return (IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)));
       }
   ```

   手续费的说明：对于类型为2/3/4/5的池子，手续费手续exponent大的代币，例如`token0 = abc,token1 = usdt, exponent0 = 8, exponent1 = 32`那么usdt将作为交易的手续费，由`collectFee()`函数收集到到CoinfairTreasury中。对于类型为1的池子，无法通过exponent0和exponent1的大小判断，因此会默认收取token1。但是作为项目方，可以向Coinfair申请通过管理员权限修改roolOver来修改手续费为token0。（我们认为手续费收取token0或token1本质上是相同的，但是过多的收取erc20而非eth/usdt等作为手续费，会在一定程度上引起价格的突然下跌）

4. CFC-06 ：factory和Treasury的地址不仅在factory中存储，也会在pair中存储，对于已经创建的pair，我们很难修改其中的factory和Treasury。同样在Treasury中修改factory也会代表放弃了所有已经创建的pair，这比较困难。如果出现问题我们可能更倾向于重新部署整套合约。此外factory和Treasury中我们是允许修改Router的，这便于日后更新。

5. GLOBAL-01：正在完成更复杂的测试，尽力覆盖所有代码。

6. CTC-03：注释已经删除。

7. CRC-03：开发时修改功能后，注释错误的保留了，目前已经修改。

8. CFV-07：理论上price0CumulativeLast和price1CumulativeLast的计算中是会出现溢出，这取决于timeElapsed的值，在现实情况下，溢出的条件比较苛刻，对于4/5类池子，要求新交易距离上一笔交易至少(2^32 / 32) 秒，约4.26年，对于2/3类池子，这个数字是34年，对于1类池子不会出现这种情况。为了避免以上情况，我们增加了限制：如果确实发生以上情况，我们允许不累计价格，此刻开始price0CumulativeLast和price1CumulativeLast的计数会出错。

9. CFC-05：我们只在router中对池子类型进行了限制，却没有禁止用户直接调用createPair去创建不符合规定的池子类型。我们已经增加了限制：

   ```solidity
          ...
           if(exponent0 == 32 && exponent1 == 32){poolType = 1;}
           else if (exponent0 == 32 && exponent1 == 8){poolType = 2;}
           else if (exponent0 == 8 && exponent1 == 32){poolType = 3;}
           else if (exponent0 == 32 && exponent1 == 1){poolType = 4;}
           else if (exponent0 == 1 && exponent1 == 32){poolType = 5;}
           else{revert();}
          ...
   ```

   

10. CTC-02：已经修改手续费收取逻辑，确保对特殊的手续费代币也可以正确收取手续费

11. CTC-01：前端逻辑调整，getBestPool()函数已经从Treasury中删除

12. CRC-02：已经将projectCommunityAddress的设置转移至createPair，确保项目方不会错过成为项目方

13. CFC-04：同CFT-01代码，由于在收取手续费时存在兑换方向的判断，确保四种兑换方向下都不会revert，可参考测试

14. CFV-05：createPair()函数中应该使用exponent0和exponent1来判断类型，而非exponentA和exponentB

    ```solidity
            if(exponent0 == 32 && exponent1 == 32){poolType = 1;}
            else if (exponent0 == 32 && exponent1 == 8){poolType = 2;}
            else if (exponent0 == 8 && exponent1 == 32){poolType = 3;}
            else if (exponent0 == 32 && exponent1 == 1){poolType = 4;}
            else if (exponent0 == 1 && exponent1 == 32){poolType = 5;}
            else{revert();}
    ```

    假设有tokenA和，且tokenA < tokenB，`createPair(tokenB, tokenA, 32, 1, fee);`会创建4类型池，而`createPair(tokenB, tokenA, 32, 1, fee);`会创建5类型池

    ```solidity
    addLiquidity(tokenA, tokenB, abi.encode(amountADesired, amountBDesired, amountAMin, amountBMin, 4, fee));
    // then
    createPair(tokenA, tokenB, 32, 1, fee);
    // then
    getpair[tokenA][tokenB][4][fee];
    // equals
    getpair[tokenB][tokenA][4][fee];
    // token0 = tokenA, token1 = tokenB, exponent0 = 32, exponent1 = 1
    
    // different
    
    addLiquidity(tokenB, tokenA, abi.encode(amountADesired, amountBDesired, amountAMin, amountBMin, 4, fee));
    // then
    createPair(tokenB, tokenA, 1, 32, fee);
    // then
    getpair[tokenA][tokenB][5][fee];
    // equals
    getpair[tokenB][tokenA][5][fee];
    // token0 = tokenA, token1 = tokenB, exponent0 = 1, exponent1 = 32
    
    
    ```

    

---

---

从终审v2开始回复，对于：

1. CCK-03、BAC-04、CFV-09、CCK-02、CFC-02，可以保持解决程度为`Acknowledged`

2. CFV-05、CFV-07、CFR-02、GLOBAL-01、CFV-03 、CFR-01，我们希望可以通过回复和讨论，最终修改为`Resolved`

- Acknowledged

  - CCK-03 -- Centralization Risks

    - 中心化问题
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：Coinfair项目在保持高度透明化的基础上，保留了少部分中心化内容，用于修改手续费地址/部分错误的项目方地址/用于展示的图片等用户体验内容，不存在任何可以操控价格等可能引起项目信任崩塌的权力。同时项目上线时会权限移交给多重签名钱包，保证安全的同时防止权力过于集中，并会考虑引入DAO并及时与用户分享信息，进一步提高我们的透明度。（代码保持不变，修改Alleviation回复）

  - CFV-05 -- Potential DOS Attack

    - 潜在的 DOS 攻击
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：最新版本中通过大量修改，已经允许在两个代币间创建多个代币对，阻止了可能的dos攻击（代码已做修改）

  - BAC-04 -- Identical URIs For Different Levels In BindAddress Contract

    - 合约中不同层级的 URI 相同
    - 解决程度：**Acknowledged**
    - 最新解决方案：虽然合约不同层级的URI应该是不同的，但是由于这不是严重的问题，并且可以随时进行修改，故不做修改。（代码保持不变，修改Alleviation回复）

  - CFV-07 -- Cumulative Price May Be Incorrect In Some Cases

    - 在某些情况下累计价格可能不正确
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：修改了累计价格的计算方式，目前累计价格已经正确（代码已做修改）

  - CFV-09 -- Potential Rounding Error Issues In Invariant Check

    - 不变性检查中的潜在舍入误差问题
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：理论上舍入误差会导致下一个用户用 0 x 个代币换取非常少量的 y。这个数量级估计至少是 10^-10。目前来看这个数量的 y 还不足以覆盖 gas 成本，不会引起严重的问题。Coinfair会时刻关注这个问题（代码保持不变，修改Alleviation回复）

  - CCK-02 -- Lack Of The Lower Boundary For The Value

    - maxMintAmount缺乏下限
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：该变量限制了用户单次铸造nft的上限，这是出于区块大小，并且为了交易尽可能成功等原因进行的设计。描述中提到的抢先交易攻击/拒绝服务等几乎不会存在，因为这种攻击几乎不会造成损失，也不会有攻击者从中获利。（代码保持不变，修改Alleviation回复）

  - CFC-02 -- Discussion On exp() 

    - 关于 exp() 的讨论

    - 终审v2解决程度：**Acknowledged**

    - 最新解决方案：关于 exp 函数，我们在计算时采用先扩容后去精度的方法。具体来说，因为公式中计算的是高次幂，所以很容易导致溢出，丢失精度。例如计算 x^32 时，我们通过多次平方后去精度，一步步得到需要的值。

      例子中提到的exp(1, 4, 1)确实会给出不正确的值，但是n=1的情况不在我们允许的交换范围内，我们只能保证绝大多数在正常流动性下产生的交易在这种算法下产生的误差非常小，并且极度不建议用户在流动性不足的池子内进行交易，这会导致过大的误差，并可能导致交易失败。（代码保持不变，修改Alleviation回复）

  - CFR-02 -- Amount Out And Amount In Derevations

    - 支出金额和收入金额偏差

    - 终审v2解决程度：**Acknowledged**

    - 最新解决方案：

    - ```
      In particular, we recommend ensuring that the repeated rounding does not result in users getting an amountOut that is less than the optimal amount out they could receive or an amountIn that is greater than the optimal amount in they need to receive the desired output amount.
      ```

      我们认为合约内`INSUFFICIENT_INPUT_AMOUNT`和`INSUFFICIENT_OUTPUT_AMOUNT`已经确保了这一点。

      关于误差问题，参考CFC-02回复。

      关于简化相关操作，暂不修改。

      （代码保持不变，修改Alleviation回复）

  - CFV-03 -- Discussion On Initial Liquidity 

    - 关于初始流动性的讨论
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：Coinfair认为：对于不同的曲线，只需保证其在流动性的铸造和销毁等操作上，都保持相同的公式，并严格按照`balance0`和`balance1`的比例计算`amount0`和`amount1`，就不会产生问题。对于初始流动性是这样，对于后续的流动性添加和移除也是这样。此外，对于曲线x^32*y=k，通过sqrt(k)来计算流动性是不现实的。（代码保持不变，修改Alleviation回复）

  - GLOBAL-01 -- Discussion On Testing ：

    - 测试讨论
    - 终审v2解决程度：**Acknowledged**
    - 最新解决方案：已添加hardhat测试代码，对合约中主要功能进行了测试。在`coinfair-hardhat`目录下运行`npx hardhat test`即可运行测试内容，并在docs文件夹下添加了合约文档，用于说明本次更新和上次更新的主要不同。（代码已做修改）

- Partially Resolved

  - CFR-01 -- Quote Functionality Is Inconsistent
    - 报价功能不一致
    
    - 终审v2解决程度：**Partially Resolved**
    
    - 最新解决方案：
    
    - ```
       The function returns the amount of the other token needed to add to the liquidity pool to keep the price unchanged, which is only the case if the original constant product formula is used.”
      ```
    
      这可能是不对的，并不是`original constant product formula`中才会这么计算，和CFV-03提到的一样，`x^4*y=k`和`x^32*y=k`两个公式下都可以这么计算。
    
      我们修改了注释，以便可以更好的说明函数的功能。
    
      ```
          // given some amount of an asset and pair reserves, returns the amount of another asset
      ```
    
      （代码已做修改）

