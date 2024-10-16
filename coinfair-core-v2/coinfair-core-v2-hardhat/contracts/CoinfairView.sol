// Mozilla Public License 2.0
pragma experimental ABIEncoderV2;
pragma solidity =0.6.6;


interface ICoinfairFactory {
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

    function CoinfairTreasury() external view returns(address);
    
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

interface ICoinfairNFT {
    function level(address) external view returns (uint256);
    function getTwoParentAddress(address sonAddress) external view returns(address, address);
}

interface ICoinfairPair {
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

interface ICoinfairWarmRouter {
    function getAmountsOut(uint amountIn, address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath) external view returns (uint[] memory amounts,uint[] memory amountFees);
    function getAmountsIn(uint amountOut, address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath) external view returns (uint[] memory amounts,uint[] memory amountFees);
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

contract CoinfairView {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    address public CoinfairFactoryAddress;
    address public CoinfairWarmRouterAddress;

    string public constant AUTHORS = "Coinfair";

    struct usrPoolManagement{
        address usrPair;
        uint8 poolType;
        uint fee;
        uint reserve0;
        uint reserve1;
        uint256 usrBal;
        uint256 totalSupply;
    }

    uint8[4] public fees = [1, 3, 5, 10];

    constructor(address _warm, address _fac) public{
        CoinfairFactoryAddress = _fac;
        CoinfairWarmRouterAddress = _warm;
    }

    // return the best pool among multiple pools under a specific value
    function getBestPool(address[] memory path, uint amount, bool isExactTokensForTokens)public view returns(
        address bestPair, uint8 bestPoolType, uint bestfee, uint finalAmount, uint256 priceXperY){
        require(path.length > 1);
        for(uint8 swapN = 1;swapN < 5;swapN++){
            for(uint i = 0;i < 4;i++){
                // address pair = ICoinfairFactory(CoinfairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                if(ICoinfairFactory(CoinfairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]) == address(0)){continue;}

                uint[] memory amounts;

                uint8[] memory poolTypePath = new uint8[](1); poolTypePath[0] = swapN;

                uint[] memory feePath = new uint[](1); feePath[0] = fees[i];

                if(isExactTokensForTokens){
                    (amounts,) = ICoinfairWarmRouter(CoinfairWarmRouterAddress).getAmountsOut(amount, path, poolTypePath, feePath);
                    if(amounts[1] > finalAmount){
                        finalAmount = amounts[1];
                        bestPoolType = swapN;
                        bestfee = fees[i];
                        bestPair = ICoinfairFactory(CoinfairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                    }
                }else{
                    (amounts,) = ICoinfairWarmRouter(CoinfairWarmRouterAddress).getAmountsIn(amount, path, poolTypePath, feePath);
                    if(amounts[0] > finalAmount){
                        finalAmount = amounts[0];
                        bestPoolType = swapN;
                        bestfee = fees[i];
                        bestPair = ICoinfairFactory(CoinfairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                    }
                }
            }
            if(bestPair != address(0)){
                (priceXperY,) = calcPriceInstant(bestPair);
            }
        }
    }

    function calcPriceInstant(address pair) internal view returns(uint256 priceXperY, uint256 priceYperX){
        uint112 r0;
        uint112 r1;
        uint e0;
        uint e1;
        (r0, r1, ) = ICoinfairPair(pair).getReserves();
        require(r0 > 0 && r1 > 0);
        (e0, e1, ) = ICoinfairPair(pair).getExponents();
        priceXperY = uint(UQ112x112.encode(r0).uqdiv(r1)) * e1 / e0;
        priceYperX = uint(UQ112x112.encode(r1).uqdiv(r0)) * e0 / e1;
    }

    // return all pairs and balances belong to usr under the path
    // function getPairManagement(address[] memory path)public view returns(address[] memory pairs, uint256[] memory balances){
    function getPairManagement(address[] memory path, address usrAddr)public view returns(usrPoolManagement[] memory UsrPoolManagement_){
        uint256 index;
        usrPoolManagement[] memory UsrPoolManagement = new usrPoolManagement[](20);
        for(uint8 swapN = 1;swapN < 5;swapN++){
            for(uint i = 0;i < 4;i++){
                address pair = ICoinfairFactory(CoinfairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                if(pair == address(0)){continue;}
                else{
                    uint256 usrBal = ICoinfairPair(pair).balanceOf(usrAddr);
                    if(usrBal != 0){
                        (uint reserve0_, uint reserve1_, ) = ICoinfairPair(pair).getReserves();
                        UsrPoolManagement[index].usrPair = pair;
                        UsrPoolManagement[index].poolType = ICoinfairPair(pair).getPoolType();
                        UsrPoolManagement[index].fee = ICoinfairPair(pair).getFee();
                        UsrPoolManagement[index].reserve0 = reserve0_;
                        UsrPoolManagement[index].reserve1 = reserve1_;
                        UsrPoolManagement[index].usrBal = usrBal;
                        UsrPoolManagement[index].totalSupply = ICoinfairPair(pair).totalSupply();
                        index = index + 1;
                    }
                }
            }
        }
        UsrPoolManagement_ = new usrPoolManagement[](index);
        for(uint j = 0;j < index;j++){
            UsrPoolManagement_[j] = UsrPoolManagement[j];
        }
    }
}