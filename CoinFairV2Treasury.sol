// Mozilla Public License 2.0
pragma experimental ABIEncoderV2;
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

interface ICoinFairWarmRouter {
    function getAmountsOut(uint amountIn, address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath) external view returns (uint[] memory amounts,uint[] memory amountFees);
    function getAmountsIn(uint amountOut, address[] calldata path, uint8[] calldata poolTypePath, uint[] calldata feePath) external view returns (uint[] memory amounts,uint[] memory amountFees);
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

    struct usrPoolManagement{
        address usrPair;
        uint256 usrBal;
    }

    uint8[4] public fees = [1, 3, 5, 10];


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
        // require(msg.sender == CoinFairFactoryAddress,'CoinFairTreasury:NOT FACTORY');
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
    // must approve pair to treasury first
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
    function getBestPool(address[] memory path, uint amount, bool isExactTokensForTokens)public view returns(uint8 bestPoolType, uint bestfee, uint finalAmount){
        require(path.length > 1);
        for(uint8 swapN = 1;swapN < 5;swapN++){
            for(uint i = 0;i < 4;i++){
                address pair = ICoinFairFactory(CoinFairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                if(pair == address(0)){continue;}

                uint[] memory amountFee; uint[] memory amounts;

                uint8[] memory poolTypePath = new uint8[](1); poolTypePath[0] = swapN;

                uint[] memory feePath = new uint[](1); feePath[0] = fees[i];

                if(isExactTokensForTokens){
                    (amounts , amountFee) = ICoinFairWarmRouter(CoinFairWarmRouterAddress).getAmountsOut(amount, path, poolTypePath, feePath);
                    if(amounts[1] > finalAmount){
                        finalAmount = amounts[1];
                        bestPoolType = swapN;
                        bestfee = fees[i];
                    }
                }else{
                    (amounts , amountFee) = ICoinFairWarmRouter(CoinFairWarmRouterAddress).getAmountsIn(amount, path, poolTypePath, feePath);
                    if(amounts[0] > finalAmount){
                        finalAmount = amounts[0];
                        bestPoolType = swapN;
                        bestfee = fees[i];
                    }
                }

            }
        }
    }

    // return all pairs and balances belong to usr under the path
    // function getPairManagement(address[] memory path)public view returns(address[] memory pairs, uint256[] memory balances){
    function getPairManagement(address[] memory path)public view returns(usrPoolManagement[] memory UsrPoolManagement){
        uint256 index;
        UsrPoolManagement = new usrPoolManagement[](20);
        for(uint8 swapN = 1;swapN < 5;swapN++){
            for(uint i = 0;i < 4;i++){
                address pair = ICoinFairFactory(CoinFairFactoryAddress).getPair(path[0], path[1], swapN, fees[i]);
                if(pair == address(0)){continue;}
                else{
                    uint256 usrBal = ICoinFairPair(pair).balanceOf(msg.sender);

                    UsrPoolManagement[index].usrPair = pair;
                    UsrPoolManagement[index].usrBal = usrBal;

                    index = index + 1;
                }
            }
        }
    }
}
