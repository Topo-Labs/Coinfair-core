# CoinFair-v2.5-合约文档

## 最新合约地址&abi

opbnb：

- CoinfairLibrary：
  - 0x9cd68fb2a51792927e6c8e25a71bb3e4e2e1eff3

- CoinFairHotRouter：
  - 0x477De57C348168f84B456934f1F6C76eb6c4734b
- CoinFairWarmRouter：
  - 0x4F46010eD9E92075B36c2a656e4828d9B22ff6CD
- Factory：
  - 0x837A7dBb71aa66f155642d619c08f5C11e73dCe8
- Initcode：
  - 0x33452d76f30738d058c15cb9e9f2547a7085b5c3c4090d0806ba0c58520a5d7e
- CoinFairTreasury：
  - 0xB49a81Ce0F950Fa00910d73309F996CA6CEC3575
- CoinFairNFT：
  - 0x729B7D8562a8f95AD10AD3a68D8bE5a91932296b
- abi
  - https://github.com/Topo-Labs/CoinFair-v2.5-core



更新时间：10-9 3:20



base：

部署钱包：0x7eb9cfa85f4bfe5ffd352ec417ba9011d755a7c0

- CoinfairLibrary：
  - 0xa66e1d6c0888b314ad2355931172948e408dbfd0

- CoinFairHotRouter：
  - 0x7E37d250De9575Cf207Fc30324e4a5152D903Ff7
  - https://basescan.org/address/0x7E37d250De9575Cf207Fc30324e4a5152D903Ff7
- CoinFairWarmRouter：
  - 0xdaA62d650cfcbaa2230bd1777C420546ca1002e6
  - https://basescan.org/address/0xdaA62d650cfcbaa2230bd1777C420546ca1002e6
- Factory：
  - 0xD6f617c9109af947E3dD119984cf84371AA2c80c
  - https://basescan.org/address/0xD6f617c9109af947E3dD119984cf84371AA2c80c
- Initcode：
  - 0x1bb5d0e3a08ac3c368eb7b52745b3eff9b4d4166cd47c2fbe07bd242bd39fb5b
- CoinFairTreasury：
  - 0x2845CB324A29bF5Ccaa808C269a5966066547269
  - https://basescan.org/address/0x2845CB324A29bF5Ccaa808C269a5966066547269
- CoinFairNFT：
  - 0xbbD06F6B432B45F9A12c2fa293e1A65ABeD3c9E1
  - https://basescan.org/address/0xbbD06F6B432B45F9A12c2fa293e1A65ABeD3c9E1
- abi
  - https://github.com/Topo-Labs/CoinFair-v2.5-core



更新时间：9-27 4:40



## 合约结构&关键函数

- `CoinFairV2Treasury`：国库

  - `collectFee`：收集手续费
  - `withdrawFee(address token)`：领取手续费
  - `CoinFairUsrTreasury[owner][token]`：查询待领取手续费余额
  - `lockLP(address pair, uint256 amount, uint256 time)`：锁仓
  - `releaseLP(address pair)`：解锁
  - `getBestPool(address[] memory path, uint amount, bool isExactTokensForTokens)`：获取两个token的兑换中，在指定的amount和兑换方向下，最优的poolType和fee
  - `getPairManagement(address[] memory path)`：获取用户在两个token形成的所有pair中，拥有的流动性

- `CoinFairFactory`：工厂

  - `getPair[tokenA][tokenB][poolType][fee]`：获取pair地址
    - `poolType` = 1/2/3/4/5
    - `fee` = 1/3/5/10

- `CoinFairHotRouter`：热路由，完成与swap相关的路由

  - `swapExactTokensForTokens`
  - `swapTokensForExactTokens`
  - `swapExactETHForTokens`
  - `swapTokensForExactETH`
  - `swapExactTokensForETH`
  - `swapETHForExactTokens`
  - `swapExactTokensForTokensSupportingFeeOnTransferTokens`
  - `swapExactETHForTokensSupportingFeeOnTransferTokens`
  - `swapExactTokensForETHSupportingFeeOnTransferTokens`

- `CoinFairWarmRouter`：暖路由，完成与流动性相关的路由

  - `addLiquidity`
  - `addLiquidityETH`
  - `removeLiquidity`
  - `removeLiquidityETH`
  - `removeLiquidityETHSupportingFeeOnTransferTokens`

  ```
  🔴 CoinFairHotRouter和CoinFairWarmRouter的授权需要分别检查
  ```

- `CoinFairNFT`：NFT



## CoinFairV2Treasury

- `calcPriceInstant`
  - input:
    - `address pair`：输入pair
  - output:
    - `uint256 priceXperY`：获取当前1个y能换多少x
    - `uint256 priceYperX`：获取当前1个x能换

- `getBestPool`：在`tokenA`和`tokenB`组成的20个池子中，选择能兑换出最多代币的最优池子
  
  - input：
    - `address[] memory path`：`[tokenA, tokenB]`，只能两个代币
    -  `uint amount`：输入数量
    -  `bool isExactTokensForTokens`
      - `true`：`ExactTokensForTokens`
      - `false`：`TokensForExactTokens`
      - 具体是哪种可以参考接下来要调用的函数时`ExactTokensForTokens`还是`TokensForExactTokens`。
    
  - output：
    - `address bestPair`：最优池子的pair
    
    - `uint8 bestPoolType`：最优池子的类型
    
    - `uint bestfee`：最优池子的手续费
    
    - `uint finalAmount`：最优池子能兑换出的数量
    
    - `*uint256* priceXperY`：价格，带112精度，是交易前的价格
    
      ```
      🌰：priceXperY = 2596148429267413814265248164610048n
      那么当前价格为 2596148429267413814265248164610048n/2^112 = 0.5
      假设pair中x是cf， y是usdt，则0.5代表：0.5 cf = usdt。另一个方向的价格求个倒数。
      
      ```
    
      <img src="https://p.ipic.vip/o646aj.png" alt="image-20240928065745210" style="zoom: 50%;" />

```
🔴在执行swap时，首选获取用户输入的tokenA和tokenB

- 假设未开启多跳
调用getBestPool获取tokenA和tokenB的最佳池子，执行swap操作
tokenA -- tokenB

- 假设开启多跳，如多跳代币为eth和usdt
前端首先计算多种可能的路径
tokenA -- tokenB
tokenA -- usdt -- tokenB
tokenA -- eth -- tokenB
tokenA -- eth -- usdt -- tokenB
tokenA -- usdt -- eth -- tokenB

以tokenA -- eth -- usdt -- tokenB为例，分别调用getBestPool获取两两代币间的最佳池子，组合成一个确定的路径
即三个数组 address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath
在此例中为：path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10]
path长度比poolTypePath和feePath长1
执行swap操作


// TODO：getBestPool的计算上有一些可以优化
```



- `getPairManagement`：在流动性管理时，获取用户在指定两个代币下所有的pair数据

  - input

    - `address[] memory path`：`[tokenA, tokenB]`，只能两个代币
    - `address usrAddr`:  用户地址

  - output：

    - `usrPoolManagement[] memory UsrPoolManagement`：用户所有的流动性

  - ```solidity
        // 输出的结构体，用户的一组流动性数据由以下组成
        struct usrPoolManagement{
        		// pair的地址
            address usrPair;
            // 此pair的池子类型
            uint8 poolType;
            // 此pair的手续费
            uint fee;
            // reserve0
            uint reserve0;
            // reserve1
            uint reserve1;
            // 用户持有的lp代币数量
            uint256 usrBal;
            // 总lp数量，用于计算share of the pool
            uint256 totalSupply;
        }
    ```

```
🔴在导入用户的流动性数据时，用户先输入两个币[tokenA, tokenB]，通过getPairManagement函数获取用户拥有的，在tokenA和tokenB中所组成的pair中的所有流动性的数据。如返回多个，可允许用户选择导入哪一个（此时要展示每一个的usrBal），再根据用户的选择导入pair进行流动性管理
```



- `withdrawFee`：领取用户在国库中累积的指定代币的待领取手续费

  - input
    - `address token`：指定要领取的手续费的代币
  - output

- `CoinFairUsrTreasury`：查询任意用户在国库中累积的指定代币的待领取手续费的余额

  - input

    - `address owner`：用户地址
    - `address token`：代币地址

  - output

    - `uint256 amount`：数额

    ```
    🔴领取手续费界面，首先应列出几个常见的手续费代币，用于快速查看和领取。前端在用户刷新/请求网站的时候获取这些余额并展示。同时也提供了一个输入框，供用户输入合约地址查询不常见的手续费代币的累积余额，查询时调用CoinFairUsrTreasury[owner][token],owner传入用户自己的地址，token传入用户输入的代币的地址。查询后如果余额大于0，右侧领取亮起供用户调用withdrawFee领取自己的反佣手续费。
    ```

    

## CoinFairWarmRouter

- `addLiquidity`

  - input

    - `address tokenA,`

    - `address tokenB,`

    - `address to,`

    - `uint deadline,`

    - `bytes calldata addLiquidityCmd`

      - ```solidity
        addLiquidityCmd = abi.encode(uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,uint8 swapN,uint fee);
        ```

        - `uint amountADesired,`

        - `uint amountBDesired,`

        - `uint amountAMin,`

        - `uint amountBMin,`

        - `uint8 swapN,`

          ```
          🔴对于两个token的流动性，swapN只会等于1/2/4。如果token和eth的流动性，才会出现1/2/3/4/5
          ```

        - `uint fee`

  - output

    - `uint amountA,`
    - `uint amountB,`
    - `uint liquidity`

- `addLiquidityETH`

  - Input：

    - `address token,`

    - `bytes calldata addLiquidityETHCmd,`

    - ```solidity
      addLiquidityETHCmd = abi.encode(uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,uint8 swapN)
      ```

      - `uint amountTokenDesired,`
      - `uint amountTokenMin,`
      - `uint amountETHMin,`
      - `uint8 swapN`

    - `address token,`

    - `address to,`

    - `uint deadline,`

    - `uint fee`

  - output：

    - `uint amountToken,`
    - `uint amountETH,` 
    - `uint liquidity`

- ​    `removeLiquidity`

  （同`removeLiquidityETH` / `removeLiquidityETHSupportingFeeOnTransferTokens`）

  - input：
    - `address tokenA`
    - `address tokenB`
    - `uint liquidity`
    - `uint amountAMin`
    - `uint amountBMin`
    - `address to`
    - `uint deadline`
    - `uint8 poolType`
    - `uint fee`
  - output
    - `uint amountA`
    - `uint amountB`

## CoinFairFactory

- `getPair[tokenA][tokenB][poolType][fee]`：获取pair地址

  - input：

    - `address tokenA`：tokenA地址

    - `address tokenB`：tokenB地址（和tokenA地址不分先后顺序）

    - `uint8 poolType`：池子类型，expoentA和exponentB和poolType强相关。一般来说，poolType为1/2/3/4/5，1对应ESIII，2/3对应ESI，4/5对应ESII

      ```solidity
              if(exponentA == 32 && exponentB == 32){poolType = 1;}
              else if (exponentA == 32 && exponentB == 8){poolType = 2;}
              else if (exponentA == 8 && exponentB == 32){poolType = 3;}
              else if (exponentA == 32 && exponentB == 1){poolType = 4;}
              else if (exponentA == 1 && exponentB == 32){poolType = 5;}
      ```

    - `uint fee`：手续费类型，1/3/5/10



## CoinFairHotRouter

- `swapETHForExactTokens`

  同其他swap函数

  - input

    - `uint amountOut`
    - `address[] calldata path`：兑换的代币路径
    - `uint8[] calldata poolTypePath`：兑换的池子类型路径
    - `uint[] calldata feePath`：兑换的手续费路径
    - `address to`
    - `uint deadline`

    ```
    🔴如path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10]，poolTypePath[0] = 2是tokenA和eth所组成池子的池子类型，feePath[0] = 3是tokenA和eth所组成池子的手续费，即四个币会两两组成三个池子。
    ```

  - output：

    - `uint[] memory amounts`

## CoinFairNFT
