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

    function decimals() public pure override  returns (uint8) {
        return 18;
    }
}

contract StandardTokenWithFees is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalAmount, address a, address b)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, _totalAmount * (10 ** uint256(decimals()))); 
        _approve(msg.sender, a, _totalAmount * (10 ** uint256(decimals())));
        _approve(msg.sender, b, _totalAmount * (10 ** uint256(decimals())));
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value * 90 / 100);
        _transfer(from, address(this), value * 10 / 100);
        return true;
    }
}

