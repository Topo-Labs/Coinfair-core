# CoinFair-v2.5-合约文档

## CoinFairTreasury

- getBestPool：在tokenA和tokenB组成的20个池子中，选择能兑换出最多代币的最优池子
  - input：
    - address[] memory path：[tokenA, tokenB]，只能两个代币
    -  uint amount：输入数量
    -  bool isExactTokensForTokens
      - true：ExactTokensForTokens
      - false：TokensForExactTokens
  - output：
    - uint8 bestPoolType：最优池子的类型
    - uint bestfee：最优池子的手续费
    - uint finalAmount：最优池子能兑换出的数量

- getPairManagement：在流动性管理时，获取用户在指定两个代币下所有的pair地址和余额
  - input
    - address[] memory path：[tokenA, tokenB]，只能两个代币
  - output：
    - address[] memory pairs：所有的pair
    - uint256[] memory balances：所有pair的余额
    - pairs和balances长度相同，一一对应