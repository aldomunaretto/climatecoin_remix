// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "ClimateCoin.sol";
import "ClimateCoinNFT.sol";

contract ClimateCoinExchange {
    ClimateCoin public climateCoin;
    ClimateCoinNFT public climateCoinNFT;
    uint256 public feePercentage = 1; // 1% por defecto

    // Events
    event NFTExchanged(address indexed nftAddress, uint256 indexed nftId, address indexed user);
    event CCBurn(uint256 ccAmount, uint256 indexed nftId);

    constructor(address _climateCoin, address _climateCoinNFT) {
        climateCoin = ClimateCoin(_climateCoin);
        climateCoinNFT = ClimateCoinNFT(_climateCoinNFT);
    }

    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        // Verificar que el msg.sender sea el propietario del contrato
        feePercentage = newFeePercentage;
    }

    function exchangeNFTForCC(address nftAddress, uint256 nftId) external {
        // Lógica para intercambiar NFT por ClimateCoins, teniendo en cuenta la fee
        // Transferir NFT al contrato y CC al usuario
        emit NFTExchanged(nftAddress, nftId, msg.sender);
    }

    function burnCCAndNFT(uint256 ccAmount) external {
        // Lógica para seleccionar y destruir un NFT y quemar CC
        // emit CCBurn(ccAmount, nftId);
    }

}
