// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ClimateCoin is ERC20 {

    address public owner;

    constructor(uint256 initialSupply) ERC20("ClimateCoin", "CC") {
        owner = msg.sender;
        _mint(owner, initialSupply*10**decimals());
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Función para mintear ClimateCoins adicionales
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Función para quemar ClimateCoins
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Función para transferir la propiedad del SC
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner can't be the zero address");
        owner = newOwner;
    }
   
}