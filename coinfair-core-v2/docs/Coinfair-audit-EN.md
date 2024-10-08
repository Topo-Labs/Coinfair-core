# Coinfair Audit

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