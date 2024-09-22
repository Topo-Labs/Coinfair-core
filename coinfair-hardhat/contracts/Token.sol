// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StandardToken is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalAmount, address a, address b)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, _totalAmount * (10 ** uint256(decimals()))); 
        _approve(msg.sender, a, _totalAmount * (10 ** uint256(decimals())));
        _approve(msg.sender, b, _totalAmount * (10 ** uint256(decimals())));
    }
}