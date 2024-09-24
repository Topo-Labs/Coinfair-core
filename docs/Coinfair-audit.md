# Coinfair-audit

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
    - 最新解决方案：已添加hardhat测试代码，对合约中主要功能进行了测试。在`coinfair-hardhat`目录下运行`npx hardhat test`即可运行测试内容，并在docs文件夹下添加了合约文档（本文档），用于说明本次更新和上次更新的主要不同。（代码已做修改）

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

