// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ClimateCoin is ERC20{

    // Variables de Estado
    address public owner;
    uint256 private initialAmount = 297565 * 10 ** decimals();

    constructor(/*uint256 initialSupply*/) ERC20("ClimateCoin", "CC") {
        owner = msg.sender;
        // _mint(owner, initialSupply*10**decimals());
    }

    // Modificadores
    modifier onlyOwner {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    // Función para hacer mint de la cantidad inicial de ClimateCoins
    function initialMint(address to) public onlyOwner {
        _mint(to, initialAmount);
    }

    // Función para mintear ClimateCoins adicionales
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Función para quemar ClimateCoins
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Función para transferir la propiedad del Smart Contract
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "El creador del contrato no puede ser el address(0)");
        owner = newOwner;
    }

}