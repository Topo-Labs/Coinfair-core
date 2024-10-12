# CoinFair-core-v2 Contract Documentation

## Latest Contract Addresses & ABI

### OPNBNB:

- **CoinfairLibrary**：
  - 0x6db0173e31f7d95e0fd4f54bed1cf65f8ce19c0c

- **CoinFairHotRouter**：
  - 0xc9F603dd4974FDFe9F7DEE5B825bc02b4c36C0CD
- **CoinFairWarmRouter**：
  - 0xd0752eE9167d99a4E62318fA99d6868D0F8262b8
- **Factory**:
  - 0x837A7dBb71aa66f155642d619c08f5C11e73dCe8
- **Initcode**:
  - 0x33452d76f30738d058c15cb9e9f2547a7085b5c3c4090d0806ba0c58520a5d7e
- **CoinFairTreasury**:
  - 0xB49a81Ce0F950Fa00910d73309F996CA6CEC3575
- **CoinFairNFT**:
  - 0x729B7D8562a8f95AD10AD3a68D8bE5a91932296b
- **ABI**:
  - https://github.com/Topo-Labs/Coinfair-core

Last updated: 10-9 3:20

### Base:

- **Deployer Wallet**: 0x7eb9cfa85f4bfe5ffd352ec417ba9011d755a7c0

- **CoinfairLibrary**:
  - 0xa66e1d6c0888b314ad2355931172948e408dbfd0

- **CoinFairHotRouter**:
  - 0x7E37d250De9575Cf207Fc30324e4a5152D903Ff7
  - https://basescan.org/address/0x7E37d250De9575Cf207Fc30324e4a5152D903Ff7
- **CoinFairWarmRouter**:
  - 0xdaA62d650cfcbaa2230bd1777C420546ca1002e6
  - https://basescan.org/address/0xdaA62d650cfcbaa2230bd1777C420546ca1002e6
- **Factory**:
  - 0xD6f617c9109af947E3dD119984cf84371AA2c80c
  - https://basescan.org/address/0xD6f617c9109af947E3dD119984cf84371AA2c80c
- **Initcode**:
  - 0x1bb5d0e3a08ac3c368eb7b52745b3eff9b4d4166cd47c2fbe07bd242bd39fb5b
- **CoinFairTreasury**:
  - 0x2845CB324A29bF5Ccaa808C269a5966066547269
  - https://basescan.org/address/0x2845CB324A29bF5Ccaa808C269a5966066547269
- **CoinFairNFT**:
  - 0xbbD06F6B432B45F9A12c2fa293e1A65ABeD3c9E1
  - https://basescan.org/address/0xbbD06F6B432B45F9A12c2fa293e1A65ABeD3c9E1
- **ABI**:
  - https://github.com/Topo-Labs/Coinfair-core

Last updated: 9-27 4:40

## Contract Structure & Key Functions

- **`CoinFairV2Treasury`**: Treasury

  - `collectFee`: Collect fees
  - `withdrawFee(address token)`: Withdraw fees
  - `CoinFairUsrTreasury[owner][token]`: Query pending fee balance to withdraw
  - `lockLP(address pair, uint256 amount, uint256 time)`: Lock liquidity pool (LP) tokens
  - `releaseLP(address pair)`: Unlock liquidity pool tokens
  - `getBestPool(address[] memory path, uint amount, bool isExactTokensForTokens)`: Get the best pool type and fee for swapping between two tokens with a given amount and swap direction
  - `getPairManagement(address[] memory path)`: Retrieve all liquidity held by the user in pairs formed by two tokens

- **`CoinFairFactory`**: Factory

  - `getPair[tokenA][tokenB][poolType][fee]`: Get the pair address
    - `poolType` = 1/2/3/4/5
    - `fee` = 1/3/5/10

- **`CoinFairHotRouter`**: Hot Router, handles swap-related routing

  - `swapExactTokensForTokens`
  - `swapTokensForExactTokens`
  - `swapExactETHForTokens`
  - `swapTokensForExactETH`
  - `swapExactTokensForETH`
  - `swapETHForExactTokens`
  - `swapExactTokensForTokensSupportingFeeOnTransferTokens`
  - `swapExactETHForTokensSupportingFeeOnTransferTokens`
  - `swapExactTokensForETHSupportingFeeOnTransferTokens`

- **`CoinFairWarmRouter`**: Warm Router, handles liquidity-related routing

  - `addLiquidity`
  - `addLiquidityETH`
  - `removeLiquidity`
  - `removeLiquidityETH`
  - `removeLiquidityETHSupportingFeeOnTransferTokens`

  ```
  🔴 The authorization of CoinFairHotRouter and CoinFairWarmRouter needs to be checked separately.
  ```

- **`CoinFairNFT`**: NFT

## CoinFairV2Treasury

- **`calcPriceInstant`**:
  - **Input**:
    - `address pair`: The pair to query
  - **Output**:
    - `uint256 priceXperY`: Current price of 1 unit of Y in terms of X
    - `uint256 priceYperX`: Current price of 1 unit of X in terms of Y

- **`getBestPool`**: Selects the best pool that provides the maximum token output for swaps between `tokenA` and `tokenB` across 20 pools.
  
  - **Input**:
    - `address[] memory path`: `[tokenA, tokenB]`, only supports two tokens
    - `uint amount`: The input amount
    - `bool isExactTokensForTokens`
      - `true`: `ExactTokensForTokens`
      - `false`: `TokensForExactTokens`
      - Determines the exact function to call based on whether you are using `ExactTokensForTokens` or `TokensForExactTokens`.
    
  - **Output**:
    - `address bestPair`: The best pair's address
    - `uint8 bestPoolType`: The best pool type
    - `uint bestFee`: The best pool fee
    - `uint finalAmount`: The output amount from the best pool
    - `*uint256* priceXperY`: Price with 112-bit precision, representing the pre-swap price.

    ```
    Example: priceXperY = 2596148429267413814265248164610048n
    This means the current price is 2596148429267413814265248164610048n / 2^112 = 0.5.
    Assuming x is cf and y is usdt, 0.5 represents that 0.5 cf = 1 usdt. The reverse price is the reciprocal.
    ```

```
🔴 When performing swaps, always obtain the best pool for tokenA and tokenB first.

- If multi-hop is not enabled:
  Call `getBestPool` to get the best pool for tokenA and tokenB, and perform the swap.
  tokenA -- tokenB

- If multi-hop is enabled, for instance with tokens like ETH and USDT:
  The frontend should calculate various possible paths:
  tokenA -- tokenB
  tokenA -- usdt -- tokenB
  tokenA -- eth -- tokenB
  tokenA -- eth -- usdt -- tokenB
  tokenA -- usdt -- eth -- tokenB

  For example, for the path tokenA -- eth -- usdt -- tokenB, `getBestPool` should be called for each pair, forming a confirmed path like:
  path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10].
  Then the swap operation is executed.
```

- **`getPairManagement`**: Retrieve the liquidity data for a user across all pairs formed by two specified tokens.

  - **Input**:
    - `address[] memory path`: `[tokenA, tokenB]`, only supports two tokens
    - `address usrAddr`: The user's address

  - **Output**:
    - `usrPoolManagement[] memory UsrPoolManagement`: The liquidity information for the user.

  - The structure of

 `usrPoolManagement`:
    ```solidity
    struct usrPoolManagement{
        address usrPair;    // Address of the pair
        uint8 poolType;     // Type of the pool
        uint fee;           // Fee of the pool
        uint reserve0;      // Reserve0 of the pool
        uint reserve1;      // Reserve1 of the pool
        uint256 usrBal;     // User's balance of LP tokens
        uint256 totalSupply;// Total supply of the LP tokens in the pool
    }
    ```

```
🔴 When importing user liquidity, the user first selects two tokens `[tokenA, tokenB]`, and `getPairManagement` retrieves all liquidity data for pairs formed by these two tokens. If multiple results are returned, the user can choose which to import (displaying `usrBal`), and based on their choice, manage the liquidity for the selected pair.
```

- **`withdrawFee`**: Withdraw the accumulated pending fees for a specified token from the treasury.

  - **Input**:
    - `address token`: The token for which to withdraw fees.
  - **Output**:
    - None

- **`CoinFairUsrTreasury`**: Query the accumulated pending fees of a specified token for any user in the treasury.

  - **Input**:
    - `address owner`: The user's address
    - `address token`: The token address

  - **Output**:
    - `uint256 amount`: The amount of fees to withdraw

    ```
    🔴 On the fee withdrawal page, the frontend should first list common fee tokens for easy access and withdrawal. When the user refreshes or requests the page, it retrieves these balances and displays them. Additionally, an input box should be provided for the user to enter a contract address to check the accumulated balance of an uncommon fee token. When querying, it calls `CoinFairUsrTreasury[owner][token]`, passing the user's own address for `owner` and the token address for `token`. If the balance is greater than zero, the withdrawal button becomes active for the user to call `withdrawFee` and claim their fees.
    ```

## CoinFairWarmRouter

- **`addLiquidity`**:

  - **Input**:
    - `address tokenA,`
    - `address tokenB,`
    - `address to,`
    - `uint deadline,`
    - `bytes calldata addLiquidityCmd`

      - **`addLiquidityCmd`** format:
        ```solidity
        addLiquidityCmd = abi.encode(uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,uint8 swapN,uint fee);
        ```

        - `uint amountADesired,`
        - `uint amountBDesired,`
        - `uint amountAMin,`
        - `uint amountBMin,`
        - `uint8 swapN,`

          ```
          🔴 For two-token liquidity pools, swapN will only be 1/2/4. If adding liquidity between a token and ETH, swapN can be 1/2/3/4/5.
          ```

        - `uint fee`

  - **Output**:
    - `uint amountA,`
    - `uint amountB,`
    - `uint liquidity`

- **`addLiquidityETH`**:

  - **Input**:
    - `address token,`
    - `bytes calldata addLiquidityETHCmd,`

    - **`addLiquidityETHCmd`** format:
      ```solidity
      addLiquidityETHCmd = abi.encode(uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,uint8 swapN);
      ```

      - `uint amountTokenDesired,`
      - `uint amountTokenMin,`
      - `uint amountETHMin,`
      - `uint8 swapN`

    - `address to,`
    - `uint deadline,`
    - `uint fee`

  - **Output**:
    - `uint amountToken,`
    - `uint amountETH,`
    - `uint liquidity`

- **`removeLiquidity`** (similar to `removeLiquidityETH` / `removeLiquidityETHSupportingFeeOnTransferTokens`):

  - **Input**:
    - `address tokenA`
    - `address tokenB`
    - `uint liquidity`
    - `uint amountAMin`
    - `uint amountBMin`
    - `address to`
    - `uint deadline`
    - `uint8 poolType`
    - `uint fee`
  
  - **Output**:
    - `uint amountA`
    - `uint amountB`

## CoinFairFactory

- **`getPair[tokenA][tokenB][poolType][fee]`**: Retrieve the pair address.

  - **Input**:
    - `address tokenA`: The address of tokenA
    - `address tokenB`: The address of tokenB (order doesn't matter)
    - `uint8 poolType`: The pool type, closely related to the exponents of `tokenA` and `tokenB`. Generally, poolType will be 1/2/3/4/5, where 1 corresponds to ESIII, 2/3 corresponds to ESI, and 4/5 corresponds to ESII.
    
      **Solidity logic**:
      ```solidity
      if(exponentA == 32 && exponentB == 32){poolType = 1;}
      else if (exponentA == 32 && exponentB == 8){poolType = 2;}
      else if (exponentA == 8 && exponentB == 32){poolType = 3;}
      else if (exponentA == 32 && exponentB == 1){poolType = 4;}
      else if (exponentA == 1 && exponentB == 32){poolType = 5;}
      ```

    - `uint fee`: Fee type, which can be 1/3/5/10.

## CoinFairHotRouter

- **`swapETHForExactTokens`** (similar to other swap functions):

  - **Input**:
    - `uint amountOut`
    - `address[] calldata path`: The token path for the swap
    - `uint8[] calldata poolTypePath`: The pool type path for the swap
    - `uint[] calldata feePath`: The fee path for the swap
    - `address to`
    - `uint deadline`

    ```
    🔴 Example: path = [tokenA, eth, usdt, tokenB], poolTypePath = [2,2,1], feePath = [3, 3, 10]. Here, poolTypePath[0] = 2 represents the pool type for tokenA and eth, and feePath[0] = 3 represents the fee for that pool. These four tokens will form three pools in pairs.
    ```

  - **Output**:
    - `uint[] memory amounts`

## CoinFairNFT
