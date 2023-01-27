// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract Stickers is ERC721, ERC721Enumerable, Ownable {
//     // strings
//     using Strings for uint256;

//     // state
//     string baseURI;
//     uint256 currentType = 1;

//     // mapping
//     mapping(address => bool) public isWhitelisted; // address to perform mint/transfer
//     mapping(uint256 => uint256) public nftType; // takes id and gives type
//     mapping(uint256 => string) public uri;

//     constructor(address _admin, string memory _initBaseURI)
//         ERC721("Tokyo Gacha Girls - Stickers", "TGGSTICKER")
//     {
//         isWhitelisted[msg.sender] = true;
//         isWhitelisted[_admin] = true;
//         uri[currentType] = "ella";
//         setBaseURI(_initBaseURI);
//     }

//     function mint(address _to) external onlyWhitelisted {
//         uint256 supply = totalSupply();

//         uint256 id = supply + 1;
//         nftType[id] = currentType;
//         _safeMint(_to, id);
//     }

//     function mintType(uint256 _type, address _to) external onlyWhitelisted {
//         require(nftType[_type] != 0, "Stamps: cant mint non-type");
//         uint256 supply = totalSupply();

//         uint256 id = supply + 1;
//         nftType[id] = _type;
//         _safeMint(_to, id);
//     }

//     // sets new stamps image

//     function newType(string memory _name) external onlyOwner {
//         ++currentType;
//         uri[currentType] = _name;
//     }

//     function updateType(uint256 _a, uint256 _b) external onlyOwner {
//         nftType[_a] = _b;
//     }

//     // uri stuff

//     function tokenURI(uint256 tokenId)
//         public
//         view
//         virtual
//         override
//         returns (string memory)
//     {
//         require(
//             _exists(tokenId),
//             "ERC721Metadata: URI query for nonexistent token"
//         );

//         string memory currentBaseURI = _baseURI();
//         return
//             bytes(currentBaseURI).length > 0
//                 ? string(
//                     abi.encodePacked(currentBaseURI, uri[nftType[tokenId]])
//                 )
//                 : "";
//     }

//     function setBaseURI(string memory _newBaseURI) public onlyOwner {
//         baseURI = _newBaseURI;
//     }

//     function _baseURI() internal view virtual override returns (string memory) {
//         return baseURI;
//     }

//     // transfer overrides

//     function addWhitelisted(address _a) external onlyOwner {
//         isWhitelisted[_a] = true;
//     }

//     function removeWhitelisted(address _a) external onlyOwner {
//         isWhitelisted[_a] = false;
//     }

//     modifier onlyWhitelisted() {
//         require(isWhitelisted[msg.sender], "Stamps: only admin can call");
//         _;
//     }

//     function transferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) public virtual override(ERC721) onlyWhitelisted {
//         require(
//             _isApprovedOrOwner(_msgSender(), tokenId),
//             "ERC721: transfer caller is not owner nor approved"
//         );

//         _transfer(from, to, tokenId);
//     }

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) public virtual override(ERC721) onlyWhitelisted {
//         safeTransferFrom(from, to, tokenId, "");
//     }

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory _data
//     ) public virtual override(ERC721) onlyWhitelisted {
//         require(
//             _isApprovedOrOwner(_msgSender(), tokenId),
//             "ERC721: transfer caller is not owner nor approved"
//         );
//         _safeTransfer(from, to, tokenId, _data);
//     }

//     // withdraw any money sent

//     function withdraw(address payable _u) external onlyOwner {
//         _u.transfer(balanceOf(address(this)));
//     }

//     function withdrawOther(address _u, address _t) external onlyOwner {
//         IERC20 t = IERC20(_t);
//         t.transfer(_u, t.balanceOf(address(this)));
//     }

//     // The following functions are overrides required by Solidity.

//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal override(ERC721, ERC721Enumerable) {
//         super._beforeTokenTransfer(from, to, tokenId);
//     }

//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         override(ERC721, ERC721Enumerable)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }
