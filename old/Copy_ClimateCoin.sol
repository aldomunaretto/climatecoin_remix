// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ClimateCoin is ERC20 {

    address private _owner;

    constructor(uint256 initialSupply) ERC20("ClimateCoin", "CC") {
        _owner = msg.sender;
        _mint(_owner, initialSupply);
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "You're not the owner of the SC.");
        _;
    }

    // Función para mintear tokens adicionales
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
   
}