// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ClimateCoin is ERC20 {

    // Variables de Estado
    address public owner;

    //Contructor
    constructor() ERC20("ClimateCoin", "CC") {
        owner = msg.sender;
    }

    // Modificadores
    modifier onlyOwner {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
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

    // Función para transferir la propiedad del Smart Contract
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "El creador del contrato no puede ser el address(0)");
        owner = newOwner;
    }

}

contract ClimateCoinNFT is ERC721 {

    // Variables de Estado
    uint256 public tokenId;
    address private owner;

    // Datos adicionales para cada ClimateCoinNFT
    struct NFTData {
        string projectName;
        string projectURL;
        uint256 credits;
    }

    mapping(uint256 => NFTData) private _nftData;

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    constructor() ERC721("ClimateCoinNFT", "CCNFT") {
        owner = msg.sender;
    }

    // Función para Mintear ClimateCoinNFT
    function mint(address developerAddress, string memory projectName, string memory projectURL, uint256 credits) onlyOwner external returns (uint256) {
        uint256 thisToken = tokenId;
        _mint(developerAddress, thisToken);
        _nftData[thisToken] = NFTData(projectName, projectURL, credits);
        tokenId++;
        return thisToken;
    }

    // Función para obtener los datos de un ClimateCoinNFT
    function getNFTData(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        // Revisar que existe el NFT
        NFTData memory data = _nftData[_tokenId];
        return (data.projectName, data.projectURL, data.credits);
    }

    function approveOperator(address _operator, address _tokenOwner ,uint256 _tokenId) onlyOwner external {
        // _setApprovalForAll(msg.sender, operator, approved);
        _approve(_operator, _tokenId, _tokenOwner, false);
    }

    // function safeTransferFrom(address from, address to, uint256 _tokenId) public override {
    //     //require(_isApprovedOrOwner(owner, _tokenId), "ERC721: transfer caller is not owner nor approved");
    //     _safeTransfer(from, to, tokenId, "");
    // }

}

contract ClimateCoinExchange {

    //Variables de estado
    address private owner;
    ClimateCoin public climateCoin;
    ClimateCoinNFT public climateCoinNFT;
    uint256 public feePercentage = 1;

    // Eventos
    event NFTMinted(uint256 indexed tokenId, address indexed developerAddress, string projectName, string projectURL, uint256 credits);
    event NFTExchanged(address indexed nftAddress, uint256 indexed tokenId, address indexed user, uint256 credits);
    event CCBurn(uint256 indexed tokenId, uint256 ccAmount);

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    constructor() {
        owner = msg.sender;
        climateCoin = new ClimateCoin();
        climateCoinNFT = new ClimateCoinNFT();
    }

    // Función para Mintear ClimateCoinNFT
    function mintNFT(uint256 credits, string memory projectName, string memory projectURL, address developerAddress) public onlyOwner {
        uint256 _tokenId = climateCoinNFT.mint(developerAddress, projectName, projectURL, credits);
        emit NFTMinted(_tokenId, developerAddress, projectName, projectURL, credits);
    }

    // Función para cambiar el porcentaje de la comisión
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    // function approveTransferNFT(uint256 nftId) public {
    //     require(climateCoinNFT.ownerOf(nftId) == msg.sender, "No eres el propietario del climateCoinNFT");
    //     climateCoinNFT.approve(address(this), nftId);
    // }

    //Función de Intercambio de ClimateCoinNFT por ClimateCoins
    function exchangeNFTForCC(address nftAddress, uint256 nftId) public {
        // Lógica para intercambiar ClimateCoinNFT por ClimateCoins, teniendo en cuenta la comisión
        // Transferir NFT al contrato y CC al usuario
        require(climateCoinNFT.ownerOf(nftId) == msg.sender, "No eres el propietario del climateCoinNFT");
        climateCoinNFT.approveOperator(address(this), msg.sender, nftId);
        (,,uint256 credits) = climateCoinNFT.getNFTData(nftId);
        climateCoinNFT.transferFrom(msg.sender, address(this), nftId);
        climateCoin.mint(address(this), credits * 10 ** climateCoin.decimals());
        uint256 ccAmount = climateCoin.balanceOf(address(this));
        uint256 fee = (ccAmount * feePercentage) / 100;
        uint256 finalAmount = ccAmount - fee;
        climateCoin.transfer(msg.sender, finalAmount);
        climateCoin.transfer(owner, fee);
        // climateCoin.transferFrom(msg.sender, owner, fee);
        emit NFTExchanged(nftAddress, nftId, msg.sender, finalAmount);
    }

    //Función de Quema de ClimateCoins y ClimateCoinNFT
    function burnCCAndNFT(uint256 ccAmount) public {
        // Lógica para seleccionar y destruir un ClimateCoinNFT y quemar los ClimateCoins asociados al mismo. ¿Como vinculo el ccAmount a un tokenId?
        // require(climateCoin.balanceOf(msg.sender) >= ccAmount, "Not enough CC");
        // climateCoin.burn(ccAmount);
        // uint256 tokenId = climateNFT.totalSupply();
        // climateNFT.burn(tokenId);
        // emit CCBurn(tokenId, ccAmount);
    }

}

