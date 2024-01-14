// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ClimateCoin is ERC20{

    // Variables de Estado
    address public owner;

    constructor(uint256 initialSupply) ERC20("ClimateCoin", "CC") {
        owner = msg.sender;
        _mint(owner, initialSupply*10**decimals());
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
    address private _owner;
    uint256 private feePercentage = 1; // 1% por defecto
    ClimateCoin public climateCoin;
    uint256 private initialClimateCoins = 297565 * 10 ** climateCoin.decimals();

    // Datos adicionales para cada ClimateCoinNFT
    struct NFTData {
        string projectName;
        string projectURL;
        uint256 credits;
    }

    mapping(uint256 => NFTData) private _nftData;



    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == _owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    constructor() ERC721("ClimateCoinNFT", "CCNFT") {
        _owner = msg.sender;
    }

    // Función para Mintear ClimateCoinNFT
    function mintNFT(address developerAddress, string memory projectName, string memory projectURL, uint256 credits) onlyOwner external {
        _mint(developerAddress, tokenId);
        tokenId++;
        _nftData[tokenId] = NFTData(projectName, projectURL, credits);
        emit NFTMinted(tokenId, developerAddress, projectName, projectURL, credits);
    }

    // Función para obtener los datos de un ClimateCoinNFT
    function getNFTData(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        // Revisar que existe el NFT
        require(_exists(_tokenId), "Error!");
        NFTData memory data = _nftData[_tokenId];
        return (data.projectName, data.projectURL, data.credits);
    }





}

contract ClimateCoinExchange {

    //Variables de estado
    ClimateCoin public climateCoin;
    ClimateNFT public climateNFT;
    uint256 public feePercentage = 1;

    // Eventos
    event NFTMinted(uint256 indexed tokenId, address indexed developerAddress, string projectName, string projectURL, uint256 credits);
    event NFTExchanged(address indexed nftAddress, uint256 indexed tokenId, address indexed user);
    event CCBurn(uint256 indexed tokenId, uint256 ccAmount);

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == _owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    constructor() {
        climateCoin = new ClimateCoin();
        climateNFT = new ClimateNFT();
    }

    function mintNFT(uint256 credits, string memory projectName, string memory projectURL, address developerAddress) public onlyOwner {
        uint256 tokenId = climateNFT.totalSupply() + 1;
        climateNFT.mint(developerAddress, tokenId, projectURL);
        climateCoin.mint(developerAddress, credits);
        emit NFTMinted(developerAddress, tokenId, credits);
    }

    // Función para cambiar el porcentaje de la comisión
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    function exchangeNFTForCC(address nftAddress, uint256 nftId) public {
        require(climateNFT.ownerOf(nftId) == msg.sender, "Not the owner");
        climateNFT.transferFrom(msg.sender, address(this), nftId);
        uint256 credits = climateCoin.balanceOf(msg.sender);
        uint256 fee = (credits * feePercentage) / 100;
        uint256 finalAmount = credits - fee;
        climateCoin.transfer(msg.sender, finalAmount);
        climateCoin.transfer(owner(), fee);
        emit NFTExchanged(msg.sender, nftId, finalAmount);
    }


    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        feePercentage = newFeePercentage;
    }

    //Función de Intercambio de ClimateCoinNFT por ClimateCoins
    function exchangeNFTForCC(address nftAddress, uint256 _tokenId) external {
        // Lógica para intercambiar ClimateCoinNFT por ClimateCoins, teniendo en cuenta la comisión
        // Transferir NFT al contrato y CC al usuario
        climateCoin = ClimateCoin(initialClimateCoins);
        emit NFTExchanged(nftAddress, _tokenId, msg.sender);
    }

    //Función de Quema de ClimateCoins y ClimateCoinNFT
    function burnCCAndNFT(uint256 ccAmount) public {
        // Lógica para seleccionar y destruir un ClimateCoinNFT y quemar los ClimateCoins asociados al mismo. ¿Como vinculo el ccAmount a un tokenId?
        require(climateCoin.balanceOf(msg.sender) >= ccAmount, "Not enough CC");
        climateCoin.burn(ccAmount);
        uint256 tokenId = climateNFT.totalSupply();
        climateNFT.burn(tokenId);
        emit CCBurn(tokenId, ccAmount);
    }

}








contract IntercambioSeguro {
    address public seller;
    uint256 public price; // Cantidad del ERC20 para poder comprar el NFT
    address public erc20TokenAddress; // Dirección del token (por ej USDC)
    address public erc721TokenAddress; // Dirección del contrato del NFT
    uint public erc721TokenId; // Id del NFT dentro del contrato ERC721



    constructor (uint _price, address _erc20TokenAddress, address _erc721TokenAddress, uint _erc721TokenId) {
        seller = msg.sender;
        price = _price;
        erc20TokenAddress = _erc20TokenAddress;
        erc721TokenAddress = _erc721TokenAddress;
        erc721TokenId = _erc721TokenId;
    }

    function executeTrade() public {
        IERC20 erc20Token = IERC20(erc20TokenAddress);
        IERC721 erc721Token = IERC721(erc721TokenAddress);

        bool erc20TransferSuccessful = erc20Token.transferFrom(msg.sender, seller, price);
        require(erc20TransferSuccessful, "Transferencia del ERC20 no satisfactoria. Recuerda que debes de tener fondos suficientes y de hacer el allowance de minimo el precio a este contrato.");

        erc721Token.transferFrom(seller, msg.sender, erc721TokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClimateCoin is ERC20 {
    constructor() ERC20("ClimateCoin", "CC") {}
}

contract ClimateNFT is ERC721 {
    constructor() ERC721("ClimateNFT", "CNFT") {}

    function mint(address to, uint256 tokenId, string memory tokenURI) public {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
}

