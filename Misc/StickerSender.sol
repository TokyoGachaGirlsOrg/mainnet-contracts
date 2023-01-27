// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/Ownable.sol";

// interface IStickers {
//     function mint(address _to) external;
// }

// contract StickerSender {
//     IStickers public stickers;
//     address public admin;

//     constructor(address _s, address _a) {
//         stickers = IStickers(_s);
//         admin = _a;
//     }

//     function mintBatch(address[] calldata receiver) external onlyAdmin {
//         for (uint256 i = 0; i < receiver.length; ++i) {
//             stickers.mint(receiver[i]);
//         }
//     }

//     modifier onlyAdmin() {
//         require(msg.sender == admin, "Sender: only admin");
//         _;
//     }
// }
