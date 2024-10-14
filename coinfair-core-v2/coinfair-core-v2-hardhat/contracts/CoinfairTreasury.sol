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

    function sendValue(address payable recipient, uint256  amount) internal {
        if (address(this).balance < amount) {
            revert();
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert();
        }
    }
}

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

interface ICoinfairTreasury {
    event CollectFee(address indexed token, address indexed owner, uint amount, address indexed pair);
    event WithdrawFee(address indexed token, address indexed owner, uint amount);

    function collectFee(address token, address owner, uint amount, address pair) external;

    function withdrawFee(address token) external;

    function setRatio(uint, uint , uint, uint, uint) external;

    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress) external;

    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn) external;

    function setRoolOver(address pair, bool newRoolOver) external;
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

contract CoinfairTreasury is ICoinfairTreasury {
    using SafeMath for uint;

    string public constant AUTHORS = "Coinfair";

    address public CoinfairFactoryAddress;
    address public CoinfairNFTAddress;

    address public Coinfair;

    uint public parentAddressLevel1Ratio = 300;
    uint public parentAddressLevel2Ratio = 400;
    uint public grandParentAddressLevel1Ratio = 0;
    uint public grandParentAddressLevel2Ratio = 0;
    uint public projectCommunityAddressRatio = 400;

    struct LPPrison{
        address pair;
        uint256 amount;
        uint256 dischargedTime;
    }

    // CoinfairUsrTreasury[owner][token]
    mapping(address => mapping(address => uint256))public CoinfairUsrTreasury;
    // CoinfairUsrTreasuryTotal[owner][token]
    mapping(address => mapping(address => uint256))public CoinfairUsrTreasuryTotal;
    // CoinfairTotalTreasury[token]
    mapping(address => uint256)public CoinfairTotalTreasury;

    // CoinfairLPPrison[owner][token]
    mapping(address => mapping(address => LPPrison))public CoinfairLPPrison;

    event CollectFee(address indexed token, address indexed owner, uint amount, address indexed pair);
    event WithdrawFee(address indexed token, address indexed owner, uint amount);

    event LockLP(address indexed pair, address indexed locker, uint amount,uint256 lockTime, bool isFirstTimeLock);
    event ReleaseLP(address indexed pair, address indexed releaser, uint amount);

    modifier onlyCoinfair() {
        require(msg.sender == Coinfair,'CoinfairTreasury:ERROR OPERATOR');
        _;
    }

    constructor()public{
        require(parentAddressLevel2Ratio >= parentAddressLevel1Ratio && grandParentAddressLevel2Ratio >= grandParentAddressLevel1Ratio
        && parentAddressLevel2Ratio.add(projectCommunityAddressRatio) <= 1000, 'CoinfairTreasury:ERROR DEPLOYER');
        Coinfair = msg.sender;
    }

    // init only once
    function setDEXAddress(address _CoinfairFactoryAddress, address _CoinfairNFTAddress)public onlyCoinfair{
        require(_CoinfairFactoryAddress != address(0) && 
                _CoinfairNFTAddress != address(0), 'CoinfairTreasury:ZERO');

        CoinfairFactoryAddress = _CoinfairFactoryAddress;
        CoinfairNFTAddress = _CoinfairNFTAddress;
    }

    // usually called by factory, 'approve' operate in factory and 'transfer' operate in treasury
    function collectFee(address token, address owner, uint amount, address pair)public override{
        require(token != address(0) && owner != address(0) && amount > 0 && pair != address(0),'CoinfairTreasury:COLLECTFEE ERROR');
        address protocolFeeToAddress = ICoinfairFactory(CoinfairFactoryAddress).feeTo();
        require(protocolFeeToAddress != address(0), 'CoinfairTreasury:FeeTo Is ZERO');
        address projectCommunityAddress = ICoinfairPair(pair).getProjectCommunityAddress();

        uint256 amountBefore = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        amount = IERC20(token).balanceOf(address(this)).sub(amountBefore);

        if(projectCommunityAddress == address(0)){
            // parent
            uint amount1 = _parentCollectFee(token, owner, amount);
            // FeeTo
            uint amount3 = amount.sub(amount1);

            CoinfairUsrTreasury[protocolFeeToAddress][token] = CoinfairUsrTreasury[protocolFeeToAddress][token].add(amount3);
            CoinfairUsrTreasuryTotal[protocolFeeToAddress][token] = CoinfairUsrTreasuryTotal[protocolFeeToAddress][token].add(amount3);

        }else{
            // parent
            uint amount1 = _parentCollectFee(token, owner, amount);
            // community
            uint amount2 = amount.mul(projectCommunityAddressRatio) / 1000;
            // FeeTo
            uint amount3 = amount.sub(amount1).sub(amount2);

            CoinfairUsrTreasury[protocolFeeToAddress][token] = CoinfairUsrTreasury[protocolFeeToAddress][token].add(amount3);
            CoinfairUsrTreasuryTotal[protocolFeeToAddress][token] = CoinfairUsrTreasuryTotal[protocolFeeToAddress][token].add(amount3);

            CoinfairUsrTreasury[projectCommunityAddress][token] = CoinfairUsrTreasury[projectCommunityAddress][token].add(amount2);
            CoinfairUsrTreasuryTotal[projectCommunityAddress][token] = CoinfairUsrTreasuryTotal[projectCommunityAddress][token].add(amount2);
        }
        
        CoinfairTotalTreasury[token] = CoinfairTotalTreasury[token].add(amount);
        
        emit CollectFee(token, owner, amount, pair);
    }

    function _parentCollectFee(address token, address owner, uint amount) internal returns(uint amount1){
        (address parentAddress,address grandParentAddress) = ICoinfairNFT(CoinfairNFTAddress).getTwoParentAddress(owner);
        uint amount10;
        uint amount11;
        if(parentAddress != address(0)){
            uint parentAddressRatio = ICoinfairNFT(CoinfairNFTAddress).level(parentAddress) == 0 ?
                                        parentAddressLevel1Ratio : parentAddressLevel2Ratio;
            amount10 = amount.mul(parentAddressRatio) / 1000;
            CoinfairUsrTreasury[parentAddress][token] = CoinfairUsrTreasury[parentAddress][token].add(amount10);
            CoinfairUsrTreasuryTotal[parentAddress][token] = CoinfairUsrTreasuryTotal[parentAddress][token].add(amount10);
        }

        if(grandParentAddress != address(0)){
            uint grandParentAddressRatio = ICoinfairNFT(CoinfairNFTAddress).level(grandParentAddress) == 0 ?
                                        grandParentAddressLevel1Ratio : grandParentAddressLevel2Ratio;
            amount11 = amount.mul(grandParentAddressRatio) / 1000;
            CoinfairUsrTreasury[grandParentAddress][token] = CoinfairUsrTreasury[grandParentAddress][token].add(amount11);
            CoinfairUsrTreasuryTotal[grandParentAddress][token] = CoinfairUsrTreasuryTotal[grandParentAddress][token].add(amount11);
        }

        amount1 = amount11.add(amount11);
    }

    // set three ratio to divide dex fee
    function setRatio(uint newParentAddressLevel1Ratio, uint newParentAddressLevel2Ratio, uint newProjectCommunityAddressRatio, 
                        uint newGrandParentAddressLevel1Ratio, uint newGrandParentAddressLevel2Ratio)public override onlyCoinfair{
        require(newParentAddressLevel2Ratio >= newParentAddressLevel1Ratio && newGrandParentAddressLevel2Ratio >= newGrandParentAddressLevel1Ratio
           && newParentAddressLevel2Ratio.add(newProjectCommunityAddressRatio).add(newGrandParentAddressLevel2Ratio) <= 1000);

        parentAddressLevel1Ratio = newParentAddressLevel1Ratio;
        parentAddressLevel2Ratio = newParentAddressLevel2Ratio;
        grandParentAddressLevel1Ratio = newGrandParentAddressLevel1Ratio;
        grandParentAddressLevel2Ratio = newGrandParentAddressLevel2Ratio;
        projectCommunityAddressRatio = newProjectCommunityAddressRatio;
    }

    // set a project's community address
    function setProjectCommunityAddress(address pair, address newProjectCommunityAddress)public override{
        require(msg.sender == Coinfair || msg.sender == CoinfairFactoryAddress,'CoinfairTreasury:ERROR OPERATOR');
        require(newProjectCommunityAddress != address(0),'CoinfairTreasury:ZERO');
        ICoinfairPair(pair).setProjectCommunityAddress(newProjectCommunityAddress);
    }

    // open/close one pool's liquidityfee
    function setIsPoolFeeOn(address pair, uint newIsPoolFeeOn)public override onlyCoinfair{
        ICoinfairPair(pair).setIsPoolFeeOn(newIsPoolFeeOn);
    }

    // set 'poolType = 1' pool rooover fee token
    function setRoolOver(address pair, bool newRoolOver)public override onlyCoinfair{
        ICoinfairPair(pair).setRoolOver(newRoolOver);
    }

    // manage factory
    function setFeeToSetter(address _feeToSetter) external onlyCoinfair{
        ICoinfairFactory(CoinfairFactoryAddress).setFeeToSetter(_feeToSetter);
    }

    function setFeeTo(address _feeTo) external onlyCoinfair{
        ICoinfairFactory(CoinfairFactoryAddress).setFeeTo(_feeTo);
    }

    function setFeeToWeight(uint8 _feeToWeight) external onlyCoinfair{
        ICoinfairFactory(CoinfairFactoryAddress).setFeeToWeight(_feeToWeight);
    }

    // usr use
    function withdrawFee(address token)public override{
        require(token != address(0),'CoinfairTreasury:ZERO');
        uint waiting = CoinfairUsrTreasury[msg.sender][token];
        require(waiting > 0,'CoinfairTreasury:ZERO AMOUNT');

        CoinfairUsrTreasury[msg.sender][token] = 0;
        emit WithdrawFee(token, msg.sender, waiting);

        TransferHelper.safeTransfer(token, msg.sender, waiting);  
    }

    // lock
    // must approve pair to treasury first
    function lockLP(address pair, uint256 amount, uint256 time)public {
        require(pair != address(0) && time > block.timestamp && amount > 0,'CoinfairTreasury:LOCK ERROR');
        LPPrison storage lpPrison = CoinfairLPPrison[msg.sender][pair];
        require(time > lpPrison.dischargedTime,'CoinfairTreasury:CANT REDUCE DISCHARGEDTIME');
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
        require(pair != address(0),'CoinfairTreasury:RELEASE ERROR');
        LPPrison storage lpPrison = CoinfairLPPrison[msg.sender][pair];
        require(lpPrison.pair != address(0) && lpPrison.amount > 0,'CoinfairTreasury:NO LOCK LP');
        require(lpPrison.dischargedTime <= block.timestamp,'CoinfairTreasury:TOO EARLY');

        uint256 releaseAmount = lpPrison.amount;

        lpPrison.amount = 0;

        emit ReleaseLP(pair, msg.sender, releaseAmount);

        TransferHelper.safeTransfer(pair, msg.sender, releaseAmount);
    }
    
    // Receive the eth accidentally entered into the contract
    function collectETH() public onlyCoinfair {
        require(address(this).balance > 0, "CoinfairTreasury:Zero ETH");
       TransferHelper.sendValue(payable(msg.sender), address(this).balance);
    }

    receive() external payable {}

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