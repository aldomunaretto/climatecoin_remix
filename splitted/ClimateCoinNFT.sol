// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ClimateCoinNFT is ERC721 {

    // Variables de Estado
    uint256 public tokenId;
    address private _owner;

    // Datos adicionales para cada ClimateCoinNFT
    struct NFTData {
        string projectName;
        string projectURL;
        uint256 credits;
    }

    mapping(uint256 => NFTData) private _nftData;

    // Eventos
    event NFTMinted(uint256 tokenId, address indexed developerAddress, string projectName, string projectURL, uint256 credits);


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
        _nftData[tokenId] = NFTData(projectName, projectURL, credits);
        emit NFTMinted(tokenId, developerAddress, projectName, projectURL, credits);
        tokenId++;
    }

    // Función para obtener los datos de un ClimateCoinNFT
    function getNFTData(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        // Revisar que existe el NFT
        NFTData memory data = _nftData[_tokenId];
        return (data.projectName, data.projectURL, data.credits);
    }

}
