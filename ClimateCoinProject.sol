// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title Desarrollo de DApp ClimateCoin en Solidity.
/// @author Aldo Munaretto.
/// @notice Este contrato implementa la funcionalidad de un token ERC20 y un token ERC721 para el proyecto ClimateCoin, así como la función de intercambio de los mismos.
/// @dev Utiliza bibliotecas de OpenZeppelin para implementar los estándares ERC20 y ERC721 de manera segura.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Contrato para el token ERC20 ClimateCoin.
/// @notice Este contrato maneja la emisión y quema del token ERC20 ClimateCoin, así como asegura que dichas funciones solo sean llamadas por el propietario.
contract ClimateCoin is ERC20 {

    /// @notice La dirección del propietario del contrato.
    address public owner;

    /// @notice Contructor para crear un nuevo token ClimateCoin.
    /// @dev Asigna al creador del contrato todas las monedas iniciales.
    /// @param initialSupply La cantidad inicial de tokens.
    constructor(uint256 initialSupply) ERC20("ClimateCoin", "CC") {
        owner = msg.sender;
        _mint(owner, initialSupply*10**decimals());
    }

    /// @notice Modificador que asegura que solo el propietario del contrato puede llamar a una función.
    modifier onlyOwner {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    /// @notice Crea nuevos tokens ClimateCoin y los asigna a una dirección.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param _to La dirección que recibirá los nuevos tokens.
    /// @param _amount La cantidad de nuevos tokens a crear.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Función que destruye tokens ClimateCoin de una dirección.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param _sender La dirección de la que se quemarán los tokens.
    /// @param _amount La cantidad de tokens a quemar.
    function burn(address _sender, uint256 _amount) public onlyOwner {
        _burn(_sender, _amount);
    }

}

/// @title Contrato para el token ERC721 ClimateCoinNFT.
/// @notice Este contrato maneja la emisión, almacenado de información adicional y quema del token ERC721 ClimateCoinNFT.
contract ClimateCoinNFT is ERC721 {

    /// @notice El ID del token ClimateCoinNFT.
    uint256 public tokenId;
    /// @notice La dirección del propietario del contrato.
    address private owner;
    /// @notice Datos adicionales para cada ClimateCoinNFT.
    struct NFTData {
        string projectName;
        string projectURL;
        uint256 credits;
    }

    /// @notice Un mapeo del ID del token ClimateCoinNFT con sus datos adicionales.
    mapping(uint256 => NFTData) private _nftData;

    /// @notice Modificador que asegura que solo el propietario del contrato puede llamar a una función.
    modifier onlyOwner() {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    /// @notice Constructor para crear un nuevo token ClimateCoinNFT.
    /// @dev Asigna al creador del contrato como propietario.
    constructor() ERC721("ClimateCoinNFT", "CCNFT") {
        owner = msg.sender;
    }

    /// @notice Crea un nuevo token ClimateCoinNFT y lo asigna a una dirección.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param developerAddress La dirección a la que se asignará al nuevo token ClimateCoinNFT.
    /// @param projectName El nombre del proyecto asociado al token ClimateCoinNFT.
    /// @param projectURL La URL del proyecto asociado al token ClimateCoinNFT.
    /// @param credits La cantidad de créditos asignados al token ClimateCoinNFT.
    /// @return El ID del token ClimateCoinNFT recién creado.
    function mint(address developerAddress, string memory projectName, string memory projectURL, uint256 credits) onlyOwner external returns (uint256) {
        uint256 thisToken = tokenId;
        _mint(developerAddress, thisToken);
        _nftData[thisToken] = NFTData(projectName, projectURL, credits);
        tokenId++;
        return thisToken;
    }

    /// @notice Obtiene los datos adicionales de un ClimateCoinNFT.
    /// @param _tokenId El ID del token ClimateCoinNFT.
    /// @return El nombre del proyecto, la URL del proyecto y la cantidad de créditos asignados al token ClimateCoinNFT.
    function getNFTData(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        require(_ownerOf(_tokenId) != address(0), "El token solicitado no existe");
        NFTData memory data = _nftData[_tokenId];
        return (data.projectName, data.projectURL, data.credits);
    }

    /// @notice Aprueba al Smart Contract de Intercambio a transferir el ClimateCoinNFT.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param _operator La dirección del Smart Contract de Intercambio.
    /// @param _tokenOwner La dirección del propietario del token ClimateCoinNFTa intercambiar.
    /// @param _tokenId El ID del token ClimateCoinNFTa intercambiar.
    function approveOperator(address _operator, address _tokenOwner ,uint256 _tokenId) onlyOwner external {
        _approve(_operator, _tokenId, _tokenOwner, false);
    }

    /// @notice Destruye un ClimateCoinNFT.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param _tokenId El ID del token ClimateCoinNFT a quemar.
    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

}

/// @title Contrato para el intercambio de tokens ClimateCoinNFT por su correpondiente cantidad de ClimateCoins.
/// @notice Este contrato permite crear el ClimateCoinNFT y asignarlo al propietario del proyecto, así como maneja el intercambio de tokens ClimateCoinNFT por su correpondiente cantidad de ClimateCoins a razón de un ClimateCoin por crédito de Carbono.
contract ClimateCoinExchange {

    /// @notice La dirección del propietario del contrato.
    address private owner;
    /// @notice Variable para almacenar nuevo contrato ClimateCoin.
    ClimateCoin public climateCoin;
    /// @notice Variable para almacenar nuevo contrato ClimateCoinNFT.
    ClimateCoinNFT public climateCoinNFT;
    /// @notice Porcentaje de comisión por transacción (valor inicial 1%).
    uint256 public feePercentage = 1;
    /// @notice Array de tokens ClimateCoinNFT transferidos a este contrato.
    uint256[] private contractNFTs;

    /// @notice Evento que se emite cuando se genera un nuevo ClimateCoinNFT.
    event NFTMinted(uint256 indexed tokenId, address indexed developerAddress, string projectName, string projectURL, uint256 credits);
    /// @notice Evento que se emite cuando se intercambia un ClimateCoinNFT por su correspondiente cantidad de ClimateCoins.
    event NFTExchanged(address indexed nftAddress, uint256 indexed tokenId, address indexed user, uint256 credits);
    /// @notice Evento que se emite cuando se queman una cantidad determinmada de ClimateCoins y un token ClimateCoinNFT con una cantidad igual o superior en creditos.
    event CCBurn(uint256 indexed tokenId, uint256 ccAmount);
    /// @notice Evento que se emite cuando ocurre un error.
    event ErrorMessage(string errorMessage);

    /// @notice Modificador que asegura que solo el propietario del contrato puede llamar a una función.
    modifier onlyOwner() {
        require(msg.sender == owner, "Esta funcion solo puede ser llamada por el creador del contrato");
        _;
    }

    /// @notice Constructor que crea un nuevo contrato ClimateCoinExchange.
    /// @dev Asigna al creador del contrato como propietario y crea nuevos contratos ClimateCoin(con un cantidad inicial de CC) y ClimateCoinNFT.
    constructor() {
        owner = msg.sender;
        climateCoin = new ClimateCoin(10000000);
        climateCoinNFT = new ClimateCoinNFT();
    }

    /// @notice Cambia el porcentaje de la comisión.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param newFeePercentage El nuevo porcentaje de la comisión por intercambiar un ClimateCoinNFT.
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    /// @notice Transfiere la propiedad del Smart Contract a una nueva dirección.
    /// @dev Solo el propietario del contrato puede llamar a esta función. El nuevo propietario no puede ser la dirección 0.
    /// @param newOwner La dirección del nuevo propietario.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "El propietario del contrato no puede ser el address(0)");
        owner = newOwner;
    }

    /// @notice Genera un nuevo token ClimateCoinNFT.
    /// @dev Solo el propietario del contrato puede llamar a esta función.
    /// @param credits La cantidad de créditos del que se van a asociar al ClimateCoinNFT.
    /// @param projectName El nombre del proyecto que acredita la obtención del ClimateCoinNFT.
    /// @param projectURL La URL del proyecto que acredita la obtención del ClimateCoinNFT.
    /// @param developerAddress La dirección del desarrollador del proyecto que acredita la obtención del ClimateCoinNFT.
    function mintNFT(uint256 credits, string memory projectName, string memory projectURL, address developerAddress) public onlyOwner {
        uint256 _tokenId = climateCoinNFT.mint(developerAddress, projectName, projectURL, credits);
        emit NFTMinted(_tokenId, developerAddress, projectName, projectURL, credits);
    }

    /// @notice Permite intercambiar un token ClimateCoinNFT por tokens ClimateCoin, por una pequeña comisión.
    /// @dev El nuevo propietario del  token ClimateCoinNFT debe ser este Smart Contract.
    /// @param nftAddress La dirección del contrato del ClimateCoinNFT.
    /// @param nftId El ID del token ClimateCoinNFT a ser intercambiado.
    function exchangeNFTForCC(address nftAddress, uint256 nftId) public {
        require(climateCoinNFT.ownerOf(nftId) == msg.sender, "No eres el propietario del climateCoinNFT");
        climateCoinNFT.approveOperator(address(this), msg.sender, nftId);
        (,,uint256 credits) = climateCoinNFT.getNFTData(nftId);
        uint256 ccAmount = credits * 10 ** climateCoin.decimals();
        climateCoinNFT.transferFrom(msg.sender, address(this), nftId);
        climateCoin.mint(address(this), ccAmount);
        uint256 fee = (ccAmount * feePercentage) / 100;
        uint256 finalAmount = ccAmount - fee;
        climateCoin.transfer(msg.sender, finalAmount);
        climateCoin.transfer(owner, fee);
        contractNFTs.push(nftId);
        emit NFTExchanged(nftAddress, nftId, msg.sender, finalAmount);
    }

    /// @notice Permite destruir tokens ClimateCoin y un token ClimateCoinNFT con la cantidad igual o superior en créditos.
    /// @dev El remitente debe tener suficientes tokens ClimateCoin para hacer la quema de los mismos.
    /// @param ccAmount La cantidad de tokens ClimateCoin a quemar.
    function burnCCAndNFT(uint256 ccAmount) public {
        uint256 _amount = ccAmount*10**climateCoin.decimals();
        require(climateCoin.balanceOf(msg.sender) >= _amount, "No tienes suficientes CC");
        (bool matched, uint256 tokenId) = seekAndDestroy(_amount);
        if (matched) {
            climateCoinNFT.burn(tokenId);
            climateCoin.burn(msg.sender, _amount);
            emit CCBurn(tokenId, ccAmount);
        } else {
            emit ErrorMessage("Error al quemar los ClimateCoins");
        }
    }

    /// @notice Busca el ClimateCoinsNFT con la cantidad mas cercana (por arriba) a la cantidad de ClimateCoins especificados.
    /// @dev La función es interna.
    /// @param _wantedValue El valor del NFT a buscar y destruir.
    /// @return un booleano indicando si se consiguio un token ClimateCoinNFT con un valor igual o superior al valor de ClimateCoins especificado y el ID de dicho token.
    function seekAndDestroy(uint256 _wantedValue) internal returns (bool, uint256) {
        bool _match = false;
        uint256 _matchId;
        uint256 _minDiff = type(uint256).max; // Inicializar a un valor muy grande para poder obtener la mínima diferencia

        // Verificar si el elemento a eliminar existe y es el más cercano por arriba al valor buscado
        for (uint256 i = 0; i < contractNFTs.length; i++) {
            (,,uint256 remainingCC) = climateCoinNFT.getNFTData(contractNFTs[i]);
            if (remainingCC >= _wantedValue) {
                uint256 diff = remainingCC - _wantedValue;
                if (diff < _minDiff) {
                    _match = true;
                    _matchId = i;
                    _minDiff = diff;
                }
            }
        }

        require(_match, "Ningun ClimateCoinNFT tiene la cantidad de ClimateCoins a quemar");
        // Movemos el elemento seleccionado a la última posición del array
        contractNFTs[_matchId] = contractNFTs[contractNFTs.length-1];
        // Eliminar el elemento seleccionado de la lista de NFTs del contrato
        contractNFTs.pop();
        return (true, _matchId);
    }

}
