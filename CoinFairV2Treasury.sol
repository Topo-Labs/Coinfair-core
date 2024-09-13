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

// File: contracts\interfaces\ICoinFairFactory.sol

pragma solidity =0.6.6;

interface ICoinFairFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB, uint8 poolType, uint fee) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB,uint256 exponentA,uint256 exponentB,uint fee) external returns (address pair);

    function feeToSetter() external view returns (address);
    function setFeeToSetter(address) external;

    function routerAddress() external view returns (address);

    function feeTo() external view returns (address);

    function feeToWeight() external view returns (uint8);
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

    function setRatio(uint newParentAddressRatio, uint newProjectCommunityAddressRatio) external;

    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress) external;

    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn) external;

    function setRoolOver(address pair, bool newRoolOver) external;

    function getCoinFair()external view returns(address);
}

contract CoinFairV2Treasury is ICoinFairV2Treasury {
    using SafeMath for uint;

    address public CoinFairFactoryAddress;
    address public CoinFairNFTAddress;

    address public CoinFair;

    bool public setDEXAddressLock;

    uint public parentAddressRatio = 300;
    uint public projectCommunityAddressRatio = 400;

    // CoinFairUsrTreasury[owner][token]
    mapping(address => mapping(address => uint256))public CoinFairUsrTreasury;
    mapping(address => uint256)public CoinFairTotalTreasury;

    event CollectFee(address indexed token, address indexed owner, uint amount, address indexed pair);
    event WithdrawFee(address indexed token, address indexed owner, uint amount);

    modifier onlyCoinFair() {
        require(msg.sender == CoinFair,'CoinFairTreasury:ERROR OPERATOR');
        _;
    }

    constructor()public{
        require(parentAddressRatio.add(projectCommunityAddressRatio) < 1000, 'CoinFairTreasury:ERROR DEPLOYER');
        CoinFair = msg.sender;
    }

    function getCoinFair()public view override returns(address){
        return CoinFair;
    }

    function collectFee(address token, address owner, uint amount, address pair)public override{
        require(token != address(0) && owner != address(0) && amount > 0 && pair != address(0),'CoinFairTreasury:COLLECTFEE ERROR1');

        (address parentAddress,) = ICoinFairNFT(CoinFairNFTAddress).getTwoParentAddress(owner);
        address protocolFeeToAddress = ICoinFairFactory(CoinFairFactoryAddress).feeTo();
        address projectCommunityAddress = ICoinFairPair(pair).getProjectCommunityAddress();

        require(protocolFeeToAddress != address(0), 'CoinFairTreasury:FeeTo Is ZERO');

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

    function setRatio(uint newParentAddressRatio, uint newProjectCommunityAddressRatio)public override onlyCoinFair{
        require(newParentAddressRatio.add(newProjectCommunityAddressRatio) <= 1000);

        parentAddressRatio = newParentAddressRatio;
        projectCommunityAddressRatio = newProjectCommunityAddressRatio;
    }

    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress)public override onlyCoinFair{
        require(newProjectCommunityAddress != address(0),'CoinFairTreasury:ZERO');
        ICoinFairPair(pair).setProjectCommunityAddress(newProjectCommunityAddress);
    }

    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn)public override onlyCoinFair{
        ICoinFairPair(pair).setIsPoolFeeOn(newIsPoolFeeOn);
    }

    function setRoolOver(address pair, bool newRoolOver)public override onlyCoinFair{
        ICoinFairPair(pair).setRoolOver(newRoolOver);
    }

    function setDEXAddress(address _CoinFairFactoryAddress, address _CoinFairNFTAddress)public onlyCoinFair{
        require(_CoinFairFactoryAddress != address(0) && 
                _CoinFairNFTAddress != address(0),'CoinFairTreasury:ZERO');
        require(setDEXAddressLock == false,'CoinFairTreasury:Already set DEXAddress');

        CoinFairFactoryAddress = _CoinFairFactoryAddress;
        CoinFairNFTAddress = _CoinFairNFTAddress;
        setDEXAddressLock = true;
    }

    // usr use
    function withdrawFee(address token)public override{
        require(token != address(0),'CoinFairTreasury:ZERO');
        uint waiting = CoinFairUsrTreasury[msg.sender][token];
        require(waiting > 0,'CoinFairTreasury:ZERO AMOUNT');
        CoinFairUsrTreasury[msg.sender][token] = 0;
        TransferHelper.safeTransfer(token, msg.sender, waiting);
    }
}