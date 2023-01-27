// SPDX-License-Identifier: MIT

// Author: toto
// Discord: toto#6175
// Email: toto.ilebinted@gmail.com
// Org: Tokyo Gacha Girls

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IOrbRarity {
    function setRarity(uint256 amount) external;

    function getRarity(uint256 token) external view returns (uint256);

    function getRarityString(uint256 token)
        external
        view
        returns (string memory);

    function getAllRarities() external view returns (uint256[] memory);
}

contract Orb is ERC721Enumerable, Ownable, IERC2981 {
    IOrbRarity public rarityContract;

    using Strings for uint256;

    string notRevealed = "Unknown";
    string baseURI;
    uint256 public maxSupply;
    address private _recipient;

    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    event Minted(address minter, uint256 id);
    event Revealed(string revealed);

    constructor(string memory _initBaseURI, uint256 _maxSupply)
        ERC721("Tokyo Gacha Girls - WL Orb", "TGGWLORB")
    {
        setBaseURI(_initBaseURI);
        maxSupply = _maxSupply;
        _recipient = owner();
    }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // mint

    function _mint(address _to) internal {
        uint256 supply = totalSupply();
        require(supply < maxSupply, "Mint complete");

        _safeMint(_to, supply + 1);

        emit Minted(_to, supply + 1);
    }

    function mint(uint256 _amount, address _to) external onlyOwner {
        for (uint256 i = 0; i < _amount; ++i) {
            _mint(_to);
        }
    }

    // utils

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    // only owner

    function setBaseURI(string memory _newBaseURI) private onlyOwner {
        baseURI = _newBaseURI;
    }

    function reveal() external onlyOwner {
        emit Revealed("WL Rarity Revealed");
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    // handle rarities

    function setRarityContract(address _rarityContract) external onlyOwner {
        rarityContract = IOrbRarity(_rarityContract);
    }

    function getRarity(uint256 token) public view returns (uint256) {
        return rarityContract.getRarity(token);
    }

    function getRarityString(uint256 token)
        public
        view
        returns (string memory)
    {
        return rarityContract.getRarityString(token);
    }

    function getAllRarities() external view returns (uint256[] memory) {
        return rarityContract.getAllRarities();
    }

    /** @dev EIP2981 royalties */

    function _setRoyalties(address newRecipient) internal {
        require(
            newRecipient != address(0),
            "Royalties: new recipient is the zero address"
        );
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _recipient;
        royaltyAmount = _salePrice / 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}
