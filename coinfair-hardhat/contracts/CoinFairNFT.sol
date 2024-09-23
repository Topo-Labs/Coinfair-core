// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CoinFairNFT is ERC721, Ownable{
    using Address for address payable;

    mapping(address => address) public parentAddress;

    mapping(address => uint256) public level; 

    mapping(address => uint256[]) public waitingClaim;

    mapping(address => uint256) public totalMint;

    mapping(address => uint256) public addrToNftId;
    
    uint256 public mintCost = 1 wei; 
    uint256 public claimCost = 1 wei; 
    uint256 public maxMintAmount = 500;
    uint256 public total;

    string public l1Uri = "";
    string public l2Uri = "";
    string public l3Uri = "";

    address internal CoinFairAddr;

    event Claim(address indexed minter, address indexed claimer);

    modifier onlyCoinFair() {
        require(msg.sender == CoinFairAddr,"CoinFairNFT:Only CoinFair");
        _;
    }

    constructor() ERC721("CoinFairNFT", "CF_NFT") Ownable(msg.sender){
        CoinFairAddr = msg.sender;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from == address(this), "CoinFairNFT:SBT");
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    function getMCInfo(address minter) public view returns(uint256,uint256){
        require(totalMint[minter] >= waitingClaim[minter].length, "CoinFairNFT:Unexpected Error");
        return (totalMint[minter] - waitingClaim[minter].length, totalMint[minter]);
    }

    function getTwoParentAddress(address sonAddress)public view returns(address, address){
        return (parentAddress[sonAddress],parentAddress[parentAddress[sonAddress]]);
    }

    function mint(uint256 mintAmount) public payable{
        require(msg.value >= mintAmount * mintCost, "CoinFairNFT:Incorrect ETH amount");
        require (mintAmount > 0 && mintAmount <= maxMintAmount,"CoinFairNFT:Invalid mint amount");

        totalMint[msg.sender] += mintAmount;

        for(uint256 i = 0; i < mintAmount; i++){
            total += 1;
            waitingClaim[msg.sender].push(total);
            _mint(address(this), total);
        }

        uint256 overPayAmount = msg.value - mintAmount * mintCost;
        if (overPayAmount > 0){
            payable(msg.sender).sendValue(overPayAmount);
        }
    }

    function claim(address parent) public payable{
        require((parentAddress[parent] != msg.sender) && 
            (parentAddress[parentAddress[parent]] != msg.sender) &&
            (parent != msg.sender)
            , "CoinFairNFT:Loop inhibit");
        require(msg.value >= claimCost, "CoinFairNFT:Incorrect ETH amount");
        require(balanceOf(msg.sender) == 0 && parentAddress[msg.sender] == address(0), "CoinFairNFT:Already claimed");
        require(waitingClaim[parent].length > 0,"CoinFairNFT:No remaining nft is available for collection");

        addrToNftId[msg.sender] = waitingClaim[parent][waitingClaim[parent].length - 1];
        waitingClaim[parent].pop();
        parentAddress[msg.sender] = parent;

        emit Claim(parent, msg.sender);

        _safeTransfer(address(this), msg.sender, addrToNftId[msg.sender]);
        uint256 overPayAmount = msg.value - claimCost;
        if (overPayAmount > 0){
            payable(msg.sender).sendValue(overPayAmount);
        }
    }

    function setLevel(address aimAddress, uint256 newLevel) public onlyCoinFair{
        require(newLevel <= 2, "CoinFairNFT:Invalid new level");
        level[aimAddress] = newLevel;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address owner = ownerOf(tokenId);
        if (owner == address(this)) {
            revert("CoinFairNFT:Not claimed");
        }

        uint256 tokenLevel = level[parentAddress[owner]];

        if(tokenLevel == 0){
            return l1Uri;
        }else if(tokenLevel == 1){
            return l2Uri;
        }else if(tokenLevel == 2){
            return l3Uri;
        } else {
            return "CoinFairNFT:Invalid level";
        }

    }

    function setCoinFairAddr(address CoinFairAddr_) public onlyCoinFair {
        CoinFairAddr = CoinFairAddr_;
    }

    function setL1Uri(string memory newUri) public onlyCoinFair {
        l1Uri = newUri;
    }

    function setL2Uri(string memory newUri) public onlyCoinFair {
        l2Uri = newUri;
    }

    function setL3Uri(string memory newUri) public onlyCoinFair {
        l3Uri = newUri;
    }

    function setMintCost(uint256 newCost) public onlyCoinFair {
        mintCost = newCost;
    }

    function setClaimCost(uint256 newCost) public onlyCoinFair {
        claimCost = newCost;
    }

    function setMaxMintAmount(uint256 newMaxMintAmount) public onlyCoinFair {
        maxMintAmount = newMaxMintAmount;
    }

    function collectTreasury() public onlyCoinFair {
        require(address(this).balance > 0, "CoinFairNFT:Zero ETH");
        payable(msg.sender).sendValue(address(this).balance);
    }

}