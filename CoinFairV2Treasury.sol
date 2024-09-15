// Mozilla Public License 2.0

pragma solidity =0.6.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface ICoinFairFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB, uint8 poolType, uint fee) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,uint256 exponentA,uint256 exponentB,uint fee) external returns (address pair);

    function feeToSetter() external view returns (address);
    function setFeeToSetter(address) external;
    function setFeeTo(address) external;
    function setFeeToWeight(uint8) external;

    function hotRouterAddress() external view returns (address);

    function feeTo() external view returns (address);

    function feeToWeight() external view returns (uint8);

    function CoinFairTreasury() external view returns(address);
    
    function WETH()external view returns(address);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface ICoinFairNFT {
    function level(address) external view returns (uint256);
    function getTwoParentAddress(address sonAddress) external view returns(address, address);
}

interface ICoinFairPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function getExponents() external view returns (uint256 exponent0, uint256 exponent1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function getFee() external view returns (uint);
    function getPoolType() external view returns (uint8);
    function getProjectCommunityAddress()external view returns (address);
    function getRoolOver()external view returns (bool);
    function setIsPoolFeeOn(uint) external;
    function setRoolOver(bool) external;
    function setProjectCommunityAddress(address)external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, uint fee ,address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, uint256, uint256,uint,uint8) external;
    
}

interface ICoinFairV2Treasury {
    event CollectFee(address indexed token, address indexed owner, uint amount, address indexed pair);
    event WithdrawFee(address indexed token, address indexed owner, uint amount);

    function collectFee(address token, address owner, uint amount, address pair) external;

    function withdrawFee(address token) external;

    function setRatio(uint, uint , uint) external;

    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress) external;

    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn) external;

    function setRoolOver(address pair, bool newRoolOver) external;
}

library CoinFairLibrary {
    using SafeMath for uint;

    uint private constant pow128 = 2 ** 128;
    uint private constant pow64 = 2 ** 64;

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt_new(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log_2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        //unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        //}
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log_2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        //unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        //}
        return result;
    }


    function gcd(uint256 a, uint256 b) internal pure returns (uint256) {
        while (b > 0) {
            uint256 temp=b;
            b = a%b;
            a = temp;
        }
        return a;
    }

    // Calculate a/b power of n
    function exp(uint256 n, uint256 a, uint256 b) public pure returns (uint256) {
        if (a == b) {
            return n;
        }
        uint256 g = gcd(a, b);
        a = a/g;
        b = b/g;
        if(a==1 && b == 4){
            return sqrt_new(sqrt_new( n * pow128) * pow64);
        }

        if(a ==4 && b ==1){
             return n * n  / pow64 * n / pow64 * n / pow128;
        }

        if(a == 1 && b == 32){
            return sqrt_new(sqrt_new(sqrt_new(sqrt_new(sqrt_new(n * pow128) * pow64) * pow64) * pow64) * pow64);
        }

        if(a == 32 && b == 1){
            uint q = n * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            q = q * n / pow64;
            return q * n / pow128;
        }

        return n;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'CoinFairLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CoinFairLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, uint8 poolType, uint fee) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1, poolType, fee)),
                hex'8f1e29bc95b2267eb0e44cd1262fe2a18f03bb7d7e4f747730bd00fc0fff19a8' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB,uint8 poolType, uint fee) internal view returns (uint reserveA, uint reserveB) {
        address token0 = ICoinFairPair(pairFor(factory, tokenA, tokenB, poolType, fee)).token0();
        (uint reserve0, uint reserve1,) = ICoinFairPair(pairFor(factory, tokenA, tokenB, poolType, fee)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // fetches and sorts the exponents for a pair
    function getExponents(address factory, address tokenA, address tokenB, uint8 poolType, uint fee) internal view returns (uint exponentA, uint exponentB) {
        address token0 = ICoinFairPair(pairFor(factory, tokenA, tokenB, poolType, fee)).token0();
        (uint256 exponent0, uint256 exponent1,) = ICoinFairPair(pairFor(factory, tokenA, tokenB, poolType, fee)).getExponents();
        (exponentA, exponentB) = tokenA == token0 ? (exponent0, exponent1) : (exponent1, exponent0);
    }

    // fetches and sorts the exponents for a pair
    function getDecimals(address tokenA, address tokenB) internal view returns (uint decimalsA, uint decimalsB) {
        (decimalsA, decimalsB) = (IERC20(tokenA).decimals(), IERC20(tokenB).decimals());
    }

    // given some amount of an asset and pair reserves, returns the amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'CoinFairLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'CoinFairLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // Based on the K conservation formula, when the amountIn A token is entered, how many B tokens need to be returned after deducting the service charge, and the result is rounded down
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint256 exponentIn, uint256 exponentOut, uint fee, bool roolOver) public pure returns (uint amountOut, uint amountOutFee) {
        require(amountIn > 0, 'CoinFairLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'CoinFairLibrary: INSUFFICIENT_LIQUIDITY');
        if (exponentIn < exponentOut ||
            (exponentIn == exponentOut && roolOver)){
            // Round up the result of exp to make the output smaller
            uint256 K = (exp(reserveIn, exponentIn, 32).add(1)).mul(exp(reserveOut, exponentOut, 32).add(1));
            uint256 amountInReal = amountIn.mul(uint256(1000).sub(fee))/1000;
            // Here * 1000-ICoinFairFactory(factory).fee/1000 will be taken down to make the output smaller
            uint256 denominator = exp(reserveIn.add(amountInReal), exponentIn, 32); 
            // Round up here to make the output smaller
            uint256 tmp = K.add(denominator-1)/denominator; 
            // Round up here to make the output smaller
            tmp = exp(tmp, 32, exponentOut).add(1); 
            amountOut = reserveOut.sub(tmp);
            amountOutFee = amountIn.sub(amountInReal);
        }else{
            // Round up the result of exp to make the output smaller
            uint256 K = (exp(reserveIn, exponentIn, 32).add(1)).mul(exp(reserveOut, exponentOut, 32).add(1));
            // Here * 1000-ICoinFairFactory(factory).fee/1000 will be taken down to make the output smaller
            uint256 denominator = exp(reserveIn.add(amountIn), exponentIn, 32); 
            // Round up here to make the output smaller
            uint256 tmp = K.add(denominator-1)/denominator; 
            // Round up here to make the output smaller
            tmp = exp(tmp, 32, exponentOut).add(1);
            uint256 amountOutTotal = reserveOut.sub(tmp);
            amountOut = amountOutTotal.mul(uint256(1000).sub(fee))/1000;
            amountOutFee = amountOutTotal.sub(amountOut);
        }
        
    }


    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // Based on the K conservation formula, if you want to replace the amountOut B token, how many A tokens need to be input when the service charge is included, and the result is rounded up
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint256 exponentIn, uint256 exponentOut, uint fee, bool roolOver) public pure returns (uint amountIn, uint amountInFee) {
        require(amountOut > 0, 'CoinFairLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'CoinFairLibrary: INSUFFICIENT_LIQUIDITY');
        if (exponentIn < exponentOut ||
            (exponentIn == exponentOut && roolOver)){
            // Round up the result of exp to make the input larger
            uint256 K = (exp(reserveIn, exponentIn, 32).add(1)).mul(exp(reserveOut, exponentOut, 32).add(1));
            // The exp result itself is rounded down, and the input becomes larger
            uint256 denominator = exp(reserveOut.sub(amountOut), exponentOut, 32);
            // The result is rounded up to make the input larger
            uint256 tmp = K.add(denominator-1)/denominator;
            // The result is rounded up to make the input larger
            tmp = exp(tmp, 32, exponentIn).add(1);
            tmp = tmp.sub(reserveIn);
            // The result is rounded up to make the input larger
            amountIn = tmp.mul(1000).add(uint256(999).sub(fee)) / (uint256(1000).sub(fee));
            amountInFee = amountIn.sub(tmp);
        }else{
            // Round up the result of exp to make the input larger
            uint256 K = (exp(reserveIn, exponentIn, 32).add(1)).mul(exp(reserveOut, exponentOut, 32).add(1));
            uint amountOutTotal = amountOut.mul(uint256(1000).add(fee))/1000;
            // The exp result itself is rounded down, and the input becomes larger
            uint256 denominator = exp(reserveOut.sub(amountOutTotal), exponentOut, 32);
            // The result is rounded up to make the input larger
            uint256 tmp = K.add(denominator-1)/denominator;
            // The result is rounded up to make the input larger
            tmp = exp(tmp, 32, exponentIn).add(1);
            amountIn = tmp.sub(reserveIn);
            amountInFee = amountOutTotal.sub(amountOut);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, uint8[] memory poolTypePath, uint[] memory feePath) internal view returns (uint[] memory amounts,uint[] memory amountsFee){
        require(path.length >= 2, 'CoinFairLibrary: INVALID_PATH');
        require(path.length == poolTypePath.length + 1, 'CoinFair: INVALID_LENGTH');
        amounts = new uint[](path.length);
        amountsFee = new uint[](path.length - 1);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            require(ICoinFairFactory(factory).getPair(path[i], path[i + 1], poolTypePath[i], feePath[i]) != address(0), 'CoinFair:NO_PAIR');
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], poolTypePath[i], feePath[i]);
            (uint256 exponentIn, uint256 exponentOut) = getExponents(factory, path[i], path[i + 1], poolTypePath[i], feePath[i]);
            //(uint256 decimalsIn, uint256 decimalsOut) = getDecimals(path[i], path[i + 1]);
            // uint _fee = ICoinFairPair(ICoinFairFactory(factory).getPair(path[i], path[i + 1], poolTypePath[i], feePath[i])).getFee();
            bool roolOver = ICoinFairPair(ICoinFairFactory(factory).getPair(path[i], path[i + 1], poolTypePath[i], feePath[i])).getRoolOver();
            (amounts[i + 1], amountsFee[i]) = getAmountOut(amounts[i], reserveIn, reserveOut, exponentIn, exponentOut, feePath[i], roolOver);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path, uint8[] memory poolTypePath, uint[] memory feePath) internal view returns (uint[] memory amounts,uint[] memory amountsFee) {
        require(path.length >= 2, 'CoinFairLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amountsFee = new uint[](path.length - 1);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            require(ICoinFairFactory(factory).getPair(path[i - 1], path[i], poolTypePath[i - 1],feePath[i - 1]) != address(0), 'CoinFair:NO_PAIR');
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], poolTypePath[i - 1], feePath[i - 1]);
            (uint256 exponentIn, uint256 exponentOut) = getExponents(factory, path[i - 1], path[i], poolTypePath[i - 1], feePath[i - 1]);
            //(uint256 decimalsIn, uint256 decimalsOut) = getDecimals(path[i - 1], path[i]);
            // uint _fee = ICoinFairPair(ICoinFairFactory(factory).getPair(path[i - 1], path[i], poolTypePath[i - 1],feePath[i - 1])).getFee();
            bool roolOver = ICoinFairPair(ICoinFairFactory(factory).getPair(path[i - 1], path[i], poolTypePath[i - 1],feePath[i - 1])).getRoolOver();
            (amounts[i - 1], amountsFee[i - 1]) = getAmountIn(amounts[i], reserveIn, reserveOut, exponentIn, exponentOut, feePath[i - 1], roolOver);
        }
    }
}

contract CoinFairV2Treasury is ICoinFairV2Treasury {
    using SafeMath for uint;

    address public CoinFairFactoryAddress;
    address public CoinFairNFTAddress;
    address public CoinFairWarmRouterAddress;

    address public CoinFair;

    bool public setDEXAddressLock;

    uint public parentAddressLevel1Ratio = 300;
    uint public parentAddressLevel2Ratio = 400;
    uint public projectCommunityAddressRatio = 400;

    struct LPPrison{
        address pair;
        uint256 amount;
        uint256 dischargedTime;
    }

    uint[] public fees = [1, 3, 5, 10];

    // CoinFairUsrTreasury[owner][token]
    mapping(address => mapping(address => uint256))public CoinFairUsrTreasury;
    mapping(address => uint256)public CoinFairTotalTreasury;

    // CoinFairLPPrison[owner][token]
    mapping(address => mapping(address => LPPrison))public CoinFairLPPrison;

    event CollectFee(address indexed token, address indexed owner, uint amount, address indexed pair);
    event WithdrawFee(address indexed token, address indexed owner, uint amount);

    event LockLP(address indexed pair, address indexed locker, uint amount,uint256 lockTime, bool isFirstTimeLock);
    event ReleaseLP(address indexed pair, address indexed releaser, uint amount);

    modifier onlyCoinFair() {
        require(msg.sender == CoinFair,'CoinFairTreasury:ERROR OPERATOR');
        _;
    }

    constructor()public{
        require(parentAddressLevel2Ratio > parentAddressLevel1Ratio && 
        parentAddressLevel2Ratio.add(projectCommunityAddressRatio) < 1000, 'CoinFairTreasury:ERROR DEPLOYER');
        CoinFair = msg.sender;
    }

    // init only once
    function setDEXAddress(address _CoinFairFactoryAddress, address _CoinFairNFTAddress, address _CoinFairWarmRouterAddress)public onlyCoinFair{
        require(_CoinFairFactoryAddress != address(0) && 
                _CoinFairNFTAddress != address(0) &&
                _CoinFairWarmRouterAddress != address(0), 'CoinFairTreasury:ZERO');
        require(setDEXAddressLock == false,'CoinFairTreasury:Already set DEXAddress');

        CoinFairFactoryAddress = _CoinFairFactoryAddress;
        CoinFairNFTAddress = _CoinFairNFTAddress;
        CoinFairWarmRouterAddress = _CoinFairWarmRouterAddress;
        setDEXAddressLock = true;
    }

    // usually called by factory, 'approve' operate in factory and 'transfer' operate in treasury
    function collectFee(address token, address owner, uint amount, address pair)public override{
        require(token != address(0) && owner != address(0) && amount > 0 && pair != address(0),'CoinFairTreasury:COLLECTFEE ERROR');
        require(msg.sender == CoinFairFactoryAddress,'CoinFairTreasury:NOT FACTORY');
        (address parentAddress,) = ICoinFairNFT(CoinFairNFTAddress).getTwoParentAddress(owner);
        address protocolFeeToAddress = ICoinFairFactory(CoinFairFactoryAddress).feeTo();
        address projectCommunityAddress = ICoinFairPair(pair).getProjectCommunityAddress();

        require(protocolFeeToAddress != address(0), 'CoinFairTreasury:FeeTo Is ZERO');
        uint parentAddressRatio = ICoinFairNFT(CoinFairNFTAddress).level(parentAddress) == 0 ?
        parentAddressLevel1Ratio : parentAddressLevel2Ratio;

        if(projectCommunityAddress == address(0)){
            uint amount1;
            uint amount3;

            if(parentAddress != address(0)){
                amount1 = amount.mul(parentAddressRatio) / 1000;
                CoinFairUsrTreasury[parentAddress][token] = CoinFairUsrTreasury[parentAddress][token].add(amount1);
            }

            require(amount1 <= amount, 'CoinFairTreasury:COLLECTFEE ERROR2');

            if(amount1 < amount){
                amount3 = amount.sub(amount1);
                CoinFairUsrTreasury[protocolFeeToAddress][token] = CoinFairUsrTreasury[protocolFeeToAddress][token].add(amount3);
            }
        }else{
            uint amount1;
            uint amount2 = amount.mul(projectCommunityAddressRatio) / 1000;
            uint amount3;

            if(parentAddress != address(0)){
                amount1 = amount.mul(parentAddressRatio) / 1000;
                CoinFairUsrTreasury[parentAddress][token] = CoinFairUsrTreasury[parentAddress][token].add(amount1);
            }

            require(amount1.add(amount2) <= amount, 'CoinFairTreasury:COLLECTFEE ERROR2');

            if(amount1.add(amount2) < amount){
                amount3 = amount.sub(amount1).sub(amount2);
                CoinFairUsrTreasury[protocolFeeToAddress][token] = CoinFairUsrTreasury[protocolFeeToAddress][token].add(amount3);
            }
            CoinFairUsrTreasury[projectCommunityAddress][token] = CoinFairUsrTreasury[projectCommunityAddress][token].add(amount2);

        }
        
        CoinFairTotalTreasury[token] = CoinFairTotalTreasury[token].add(amount);
        emit CollectFee(token, owner, amount, pair);

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
    }

    // set three ratio to divide dex fee
    function setRatio(uint newParentAddressLevel1Ratio, uint newParentAddressLevel2Ratio, uint newProjectCommunityAddressRatio)public override onlyCoinFair{
        require(newParentAddressLevel2Ratio > newParentAddressLevel1Ratio && 
            newParentAddressLevel2Ratio.add(newProjectCommunityAddressRatio) <= 1000);

        parentAddressLevel1Ratio = newParentAddressLevel1Ratio;
        parentAddressLevel2Ratio = newParentAddressLevel2Ratio;
        projectCommunityAddressRatio = newProjectCommunityAddressRatio;
    }

    // set a project's community address
    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress)public override{
        require(msg.sender == CoinFair || msg.sender == CoinFairWarmRouterAddress,'CoinFairTreasury:ERROR OPERATOR');
        require(newProjectCommunityAddress != address(0),'CoinFairTreasury:ZERO');
        ICoinFairPair(pair).setProjectCommunityAddress(newProjectCommunityAddress);
    }

    // open/close one pool's liquidityfee
    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn)public override onlyCoinFair{
        ICoinFairPair(pair).setIsPoolFeeOn(newIsPoolFeeOn);
    }

    // set 'poolType = 1' pool rooover fee token
    function setRoolOver(address pair, bool newRoolOver)public override onlyCoinFair{
        ICoinFairPair(pair).setRoolOver(newRoolOver);
    }

    // manage factory
    function setFeeToSetter(address _feeToSetter) external onlyCoinFair{
        ICoinFairFactory(CoinFairFactoryAddress).setFeeToSetter(_feeToSetter);
    }

    function setFeeTo(address _feeTo) external onlyCoinFair{
        ICoinFairFactory(CoinFairFactoryAddress).setFeeTo(_feeTo);
    }

    function setFeeToWeight(uint8 _feeToWeight) external onlyCoinFair{
        ICoinFairFactory(CoinFairFactoryAddress).setFeeToWeight(_feeToWeight);
    }

    // usr use
    function withdrawFee(address token)public override{
        require(token != address(0),'CoinFairTreasury:ZERO');
        uint waiting = CoinFairUsrTreasury[msg.sender][token];
        require(waiting > 0,'CoinFairTreasury:ZERO AMOUNT');

        CoinFairUsrTreasury[msg.sender][token] = 0;
        emit WithdrawFee(token, msg.sender, waiting);

        TransferHelper.safeTransfer(token, msg.sender, waiting);
    }

    // lock
    // must approve pair to treasury
    function lockLP(address pair, uint256 amount, uint256 time)public {
        require(pair != address(0) && time > block.timestamp && amount > 0,'CoinFairTreasury:LOCK ERROR');
        LPPrison storage lpPrison = CoinFairLPPrison[msg.sender][pair];
        require(time > lpPrison.dischargedTime,'CoinFairTreasury:CANT REDUCE DISCHARGEDTIME');
        bool isFirstTimeLock;
        if(lpPrison.pair == address(0)){
            lpPrison.pair = pair;
            isFirstTimeLock = true;
        }
        lpPrison.amount = lpPrison.amount.add(amount);
        lpPrison.dischargedTime = time;

        emit LockLP(pair, msg.sender, amount, time, isFirstTimeLock);

        TransferHelper.safeTransferFrom(pair, msg.sender, address(this), amount);
    }

    function releaseLP(address pair)public {
        require(pair != address(0),'CoinFairTreasury:RELEASE ERROR');
        LPPrison storage lpPrison = CoinFairLPPrison[msg.sender][pair];
        require(lpPrison.pair != address(0) && lpPrison.amount > 0,'CoinFairTreasury:NO LOCK LP');
        require(lpPrison.dischargedTime <= block.timestamp,'CoinFairTreasury:TOO EARLY');

        uint256 releaseAmount = lpPrison.amount;

        lpPrison.amount = 0;

        emit ReleaseLP(pair, msg.sender, releaseAmount);

        TransferHelper.safeTransfer(pair, msg.sender, releaseAmount);
    }

    // return the best pool among multiple pools under a specific value
    function getBestPool(address tokenA, address tokenB, uint amount, bool isExactTokensForTokens)public view returns(uint8 bestPoolType, uint bestfee, uint finalAmount){
        for(uint8 swapN = 0;swapN < 5;swapN++){
            for(uint i = 0;i < 4;i++){
                uint fee = fees[i];

                address pair = ICoinFairFactory(CoinFairFactoryAddress).getPair(tokenA, tokenB, swapN, fee);
                if(pair == address(0)){continue;}

                uint[] memory amountFee; uint[] memory amounts;

                address[] memory path; path[0] = tokenA; path[1] = tokenB;

                uint8[] memory poolTypePath; poolTypePath[0] = swapN;

                uint[] memory feePath; feePath[0] = fee;

                if(isExactTokensForTokens){
                    (amounts , amountFee) = CoinFairLibrary.getAmountsOut(CoinFairFactoryAddress, amount, path, poolTypePath, feePath);
                }else{
                    (amounts , amountFee) = CoinFairLibrary.getAmountsIn(CoinFairFactoryAddress, amount, path, poolTypePath, feePath);
                }
                if(amounts[0] > finalAmount){
                    finalAmount = amounts[0];
                    bestPoolType = swapN;
                    bestfee = fee;
                }
            }
        }
    }
}
