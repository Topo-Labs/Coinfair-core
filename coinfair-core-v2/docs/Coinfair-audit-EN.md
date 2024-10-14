# Coinfair-audit

10.15 Update：

1. CFC-05：Update warmRouter function`_addLiquidityAssist_()`

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

   

October 11th Reply:

We have previously communicated with BD, and this audit is based on the following code repository:

https://github.com/Topo-Labs/Coinfair-core

1. **TCF-01**: `Token.sol`, `WETH.sol`, and `CoinfairView.sol` do not require auditing. `CoinfairNFT.sol` has already been audited, as previously discussed with BD.

2. **CRC-04**: For pools composed of ERC20 and ERC20, the allowed types are 1/2/4. For pools composed of ERC20 and ETH, the allowed types are 1/2/3/4/5. This is because in `addLiquidityETH()`, the ERC20 token always comes before ETH.

   ```solidity
   function _addLiquidityETHAssist(address token, uint fee, bytes memory addLiquidityETHCmd) internal returns (uint, uint, uint8, uint) {
       (uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, uint8 swapN) = abi.decode(addLiquidityETHCmd, (uint, uint, uint, uint8));
       require(fee == 1 || fee == 3 || fee == 5 || fee == 10, "ERROR FEE");
       bytes memory _addLiquidityCmd;
       if (swapN == 1) {
           _addLiquidityCmd = abi.encode(token, WETH, 32, 32, fee);
       } else if (swapN == 2) {
           // sequence == 0 && swapN == 2;
           _addLiquidityCmd = abi.encode(token, WETH, 32, 8, fee);
       } else if (swapN == 3) {
           // sequence != 0 && swapN == 2;
           _addLiquidityCmd = abi.encode(token, WETH, 8, 32, fee);
       } else if (swapN == 4) {
           // sequence == 0 && swapN == 3;
           _addLiquidityCmd = abi.encode(token, WETH, 32, 1, fee);
       } else if (swapN == 5) {
           // sequence != 0 && swapN == 3;
           _addLiquidityCmd = abi.encode(token, WETH, 1, 32, fee);
       } else {
           revert();
       }
       return _addLiquidity(_addLiquidityCmd, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
   }
   ```

   Essentially, `_addLiquidityCmd = abi.encode(token, WETH, 8, 32, fee);` and `_addLiquidityCmd = abi.encode(WETH, token, 32, 8, fee);` are the same. If a user provides a type that Coinfair does not support, adding liquidity will not succeed.

3. **CFT-01**: In the repository we provided, the code has been modified:

   ```solidity
   function _swapAssist(address to, uint amount0Out, uint amount1Out, uint fee_, bytes memory data) internal returns (uint, uint) {
       address _token0 = token0;
       address _token1 = token1;
       require(to != _token0 && to != _token1, 'Coinfair: INVALID_TO');

       if (exponent0 < exponent1 || (exponent0 == exponent1 && roolOver)) {
           TransferHelper.safeApprove(_token0, CoinfairTreasury, fee_);
           ICoinfairTreasury(CoinfairTreasury).collectFee(_token0, to, fee_, address(this));
       } else {
           TransferHelper.safeApprove(_token1, CoinfairTreasury, fee_);
           ICoinfairTreasury(CoinfairTreasury).collectFee(_token1, to, fee_, address(this));
       }
       if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
       if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

       if (data.length > 0) ICoinfairCallee(to).CoinfairCall(msg.sender, amount0Out, amount1Out, data);
       return (IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)));
   }
   ```

   **Fee Explanation**: For pools of types 2/3/4/5, the fee is charged in the token with the larger exponent. For example, if `token0 = abc`, `token1 = usdt`, `exponent0 = 8`, `exponent1 = 32`, then USDT will be used as the transaction fee, collected into `CoinfairTreasury` via the `collectFee()` function. For pools of type 1, we cannot determine based on the sizes of `exponent0` and `exponent1`, so by default, fees will be charged in `token1`. However, as project owners, we can apply to Coinfair to modify `roolOver` via admin privileges to change the fee to `token0`. (We believe that charging fees in `token0` or `token1` is essentially the same, but excessively charging fees in ERC20 tokens rather than ETH/USDT may cause sudden price drops to some extent.)

4. **CFC-06**: The addresses of `factory` and `Treasury` are stored not only in the `factory` but also in each `pair`. For pairs that have already been created, it is difficult for us to modify their `factory` and `Treasury`. Similarly, modifying the `factory` in `Treasury` would mean abandoning all previously created pairs, which is rather challenging. If issues arise, we might prefer to redeploy the entire set of contracts. Additionally, we allow modifying the `Router` in `factory` and `Treasury`, which facilitates future updates.

5. **GLOBAL-01**: We are conducting more comprehensive testing to cover all the code as much as possible.

6. **CTC-03**: The comments have been deleted.

7. **CRC-03**: After modifying functionalities during development, incorrect comments were inadvertently retained; we have now corrected this.

8. **CFV-07**: In theory, the calculations of `price0CumulativeLast` and `price1CumulativeLast` can overflow, which depends on the value of `timeElapsed`. In practical scenarios, the conditions for overflow are quite stringent. For pools of types 4/5, the new transaction would need to be at least (2^32 / 32) seconds (approximately 4.26 years) after the previous transaction. For pools of types 2/3, this number is 34 years. For pools of type 1, this situation does not occur. To avoid the above situations, we have added a restriction: if such a situation does occur, we allow not accumulating the price; from this point on, the counting of `price0CumulativeLast` and `price1CumulativeLast` will be incorrect.

9. **CFC-05**: We previously only restricted pool types in the `router`, but did not prevent users from directly calling `createPair` to create pool types that do not meet the specifications. We have now added restrictions:

   ```solidity
   ...
   if (exponent0 == 32 && exponent1 == 32) { poolType = 1; }
   else if (exponent0 == 32 && exponent1 == 8) { poolType = 2; }
   else if (exponent0 == 8 && exponent1 == 32) { poolType = 3; }
   else if (exponent0 == 32 && exponent1 == 1) { poolType = 4; }
   else if (exponent0 == 1 && exponent1 == 32) { poolType = 5; }
   else { revert(); }
   ...
   ```

10. **CTC-02**: We have modified the fee collection logic to ensure that fees can be correctly collected for special fee tokens.

11. **CTC-01**: Adjusted frontend logic; the `getBestPool()` function has been removed from `Treasury`.

12. **CRC-02**: We have moved the setting of `projectCommunityAddress` to `createPair`, ensuring that project parties do not miss becoming the project owner.

13. **CFC-04**: Similar to the code in **CFT-01**, due to the judgment of the exchange direction when collecting fees, we ensure that no `revert` occurs under all four exchange directions. You can refer to the tests.

14. **CFV-05**: In the `createPair()` function, `exponent0` and `exponent1` should be used to determine the type, not `exponentA` and `exponentB`.

    ```solidity
    if (exponent0 == 32 && exponent1 == 32) { poolType = 1; }
    else if (exponent0 == 32 && exponent1 == 8) { poolType = 2; }
    else if (exponent0 == 8 && exponent1 == 32) { poolType = 3; }
    else if (exponent0 == 32 && exponent1 == 1) { poolType = 4; }
    else if (exponent0 == 1 && exponent1 == 32) { poolType = 5; }
    else { revert(); }
    ```

    Suppose we have `tokenA` and `tokenB`, and `tokenA < tokenB`. Calling `createPair(tokenA, tokenB, 32, 1, fee);` will create a type 4 pool, while `createPair(tokenB, tokenA, 1, 32, fee);` will create a type 5 pool.

    ```solidity
    addLiquidity(tokenA, tokenB, abi.encode(amountADesired, amountBDesired, amountAMin, amountBMin, 4, fee));
    // then
    createPair(tokenA, tokenB, 32, 1, fee);
    // then
    getPair[tokenA][tokenB][4][fee];
    // equals
    getPair[tokenB][tokenA][4][fee];
    // token0 = tokenA, token1 = tokenB, exponent0 = 32, exponent1 = 1
    
    // different
    
    addLiquidity(tokenB, tokenA, abi.encode(amountADesired, amountBDesired, amountAMin, amountBMin, 4, fee));
    // then
    createPair(tokenB, tokenA, 1, 32, fee);
    // then
    getPair[tokenA][tokenB][5][fee];
    // equals
    getPair[tokenB][tokenA][5][fee];
    // token0 = tokenA, token1 = tokenB, exponent0 = 1, exponent1 = 32
    ```
    
    

---

---



Starting from the final review v2 response regarding:

1. For CCK-03, BAC-04, CFV-09, CCK-02, CFC-02, the resolution level can remain as `Acknowledged`.

2. For CFV-05, CFV-07, CFR-02, GLOBAL-01, CFV-03, and CFR-01, we hope to modify the resolution to `Resolved` through replies and discussions.

- Acknowledged

  - CCK-03 -- Centralization Risks

    - Centralization issues
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: The Coinfair project retains a small amount of centralized content while maintaining high transparency, used for modifying fee addresses/incorrect project addresses/user experience content like display images, without any power to manipulate prices that could undermine project trust. Additionally, upon launch, permissions will be transferred to a multi-signature wallet to ensure security and prevent power concentration, and the introduction of DAO will be considered to timely share information with users, further improving our transparency. (Code remains unchanged; Alleviation reply modified)

  - CFV-05 -- Potential DOS Attack

    - Potential DOS attack
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: The latest version has allowed the creation of multiple token pairs between two tokens through significant modifications, preventing potential DOS attacks (code has been modified).

  - BAC-04 -- Identical URIs For Different Levels In BindAddress Contract

    - Identical URIs at different levels in the contract
    - Resolution level: **Acknowledged**
    - Latest resolution: Although URIs at different levels of the contract should be different, this is not a severe issue and can be modified at any time; therefore, no changes are made. (Code remains unchanged; Alleviation reply modified)

  - CFV-07 -- Cumulative Price May Be Incorrect In Some Cases

    - Cumulative price may be incorrect in some cases
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: The calculation method for cumulative price has been modified, and the cumulative price is now correct (code has been modified).

  - CFV-09 -- Potential Rounding Error Issues In Invariant Check

    - Potential rounding error issues in invariant check
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: Theoretically, rounding errors may lead to the next user swapping 0 x tokens for a very small amount of y. This order of magnitude is estimated to be at least 10^-10. Currently, this amount of y is not enough to cover gas costs and will not cause serious issues. Coinfair will continuously monitor this issue (code remains unchanged; Alleviation reply modified).

  - CCK-02 -- Lack Of The Lower Boundary For The Value

    - Lack of a lower boundary for maxMintAmount
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: This variable limits the upper limit for users to mint NFTs in a single transaction, designed for block size and to maximize transaction success. The mentioned front-running attack/service denial issues are almost nonexistent because such attacks would cause negligible loss, and attackers would not benefit from them. (Code remains unchanged; Alleviation reply modified).

  - CFC-02 -- Discussion On exp()

    - Discussion on exp()
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: Regarding the exp function, we adopt a method of expanding first and then reducing precision during calculations. Specifically, since the formula involves high powers, it is easy to cause overflow and lose precision. For example, when calculating x^32, we repeatedly square and reduce precision to stepwise obtain the required value.

      The example of exp(1, 4, 1) indeed yields an incorrect value; however, the case of n=1 is not within our allowed exchange range. We can only guarantee that the errors from transactions generated under normal liquidity using this algorithm are very small, and we strongly advise users against trading in pools with insufficient liquidity, as this may lead to excessive errors and potentially cause transaction failures. (Code remains unchanged; Alleviation reply modified).

  - CFR-02 -- Amount Out And Amount In Derivations

    - Amount out and amount in deviations
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution:

    - ```
      In particular, we recommend ensuring that the repeated rounding does not result in users getting an amountOut that is less than the optimal amount out they could receive or an amountIn that is greater than the optimal amount in they need to receive the desired output amount.
      ```

      We believe that the `INSUFFICIENT_INPUT_AMOUNT` and `INSUFFICIENT_OUTPUT_AMOUNT` checks in the contract already ensure this.

      Regarding the error issue, please refer to the response for CFC-02.

      As for simplifying related operations, no changes will be made.

      (Code remains unchanged; Alleviation reply modified).

  - CFV-03 -- Discussion On Initial Liquidity

    - Discussion on initial liquidity
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: Coinfair believes that for different curves, ensuring that the same formulas are used for liquidity minting and burning operations, and strictly calculating `amount0` and `amount1` based on `balance0` and `balance1`, will not cause issues. This applies to both initial liquidity and subsequent liquidity additions and removals. Additionally, for the curve `x^32*y=k`, calculating liquidity via sqrt(k) is unrealistic. (Code remains unchanged; Alleviation reply modified).

  - GLOBAL-01 -- Discussion On Testing:

    - Testing discussion
    - Final review v2 resolution level: **Acknowledged**
    - Latest resolution: Hardhat test code has been added, testing the main functionalities in the contract. Running `npx hardhat test` in the `coinfair-hardhat` directory will execute the tests, and a document explaining the major differences between this and the previous update has been added in the docs folder. (Code has been modified).

- Partially Resolved

  - CFR-01 -- Quote Functionality Is Inconsistent

    - Inconsistent quote functionality
    - Final review v2 resolution level: **Partially Resolved**
    - Latest resolution:

    - ```
      The function returns the amount of the other token needed to add to the liquidity pool to keep the price unchanged, which is only the case if the original constant product formula is used.”
      ```

      This may be incorrect, as it does not necessarily apply only to the `original constant product formula`, and as mentioned in CFV-03, it can be calculated under both `x^4*y=k` and `x^32*y=k` formulas.

      We have modified the comments to better explain the function's purpose.

      ```
          // given some amount of an asset and pair reserves, returns the amount of another asset
      ```

      (Code has been modified).