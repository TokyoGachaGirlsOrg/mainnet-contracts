// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IGirl.sol";
import "../interfaces/IAttunement.sol";

contract ElementalStone is ERC1155Supply, Ownable, ERC1155Burnable, IERC2981 {
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    // 1 = flame; 2 = terra; 3 = aqua
    IAttunement public attunement;
    IGirl public girl;

    uint256 public tokenCount = 6;
    uint256[] public upgradeIDs = [4, 5, 6];

    string public baseURI;

    string[] public elementString = ["", "Flame", "Terra", "Aqua"];

    mapping(address => bool) public isGachaMachine;

    // testing
    // uint256[] testids = [1, 2, 3, 4, 5, 6];
    // uint256[] testamounts = [100, 100, 100, 100, 100, 100];

    // royalty
    address private _recipient;

    event CosmicLevelUpgraded(uint256 id, uint256 toTier);

    constructor(
        address _gachaMachine,
        address _girl,
        string memory _baseURI,
        address _royalty
    ) ERC1155("TGG Elemental Stone") {
        isGachaMachine[_gachaMachine] = true;
        setGirlContract(_girl);
        setBaseURI(_baseURI);
        setRoyalties(_royalty);
        _recipient = msg.sender;
    }

    // function mintDev(address _to) external onlyOwner {
    //     _mintBatch(_to, testids, testamounts, "");
    // }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setTokenCount(uint256 newCount) external onlyOwner {
        tokenCount = newCount;
    }

    function uri(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenID = Strings.toString(_tokenID);
        return string(abi.encodePacked(baseURI, tokenID));
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyGachaMachine {
        _mint(account, id, amount, "");
    }

    function setGirlContract(address _girl) public onlyOwner {
        girl = IGirl(_girl);
    }

    function stake(uint256 id, uint256 girlId) external {
        require(id >= 1 && id <= 3, "ES: only dormant stones can be staked");
        address _user;
        bool _isPaired;
        uint256 _el;
        (_user, _isPaired, _el) = girl.checkStake(girlId);
        require(msg.sender == _user, "ES: cant pair with girl.. not owner");
        require(!_isPaired, "ES: girl is already staking");
        safeTransferFrom(msg.sender, address(attunement), id, 1, "");
        attunement.stake(msg.sender, id, girlId, (id == _el));
        girl.setPaired(girlId, true);
    }

    function attune(
        address account,
        uint256 id,
        uint256 girlId
    ) external onlyAttunement {
        // burn old id
        _mint(account, id + 3, 1, "");
        girl.setPaired(girlId, false);
    }

    function getWalletBalance(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory all = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; ++i) {
            all[i] = balanceOf(_user, i + 1);
        }
        return all;
    }

    function setAttunementContract(address _contract) external onlyOwner {
        attunement = IAttunement(_contract);
    }

    function setGachaMachineContract(address _contract) external onlyOwner {
        isGachaMachine[_contract] = true;
    }

    modifier onlyGachaMachine() {
        require(isGachaMachine[msg.sender], "Only gacha machine can mint");
        _;
    }

    modifier onlyAttunement() {
        require(
            msg.sender == address(attunement),
            "Only attunement can attune"
        );
        _;
    }

    function upgradeCosmicLevel(uint256 id, uint256 toTier) external {
        // get cost
        uint256[] memory amounts = girl.getCosmicLevelUpgradeCost(id, toTier);

        // check user balance
        require(
            balanceOf(msg.sender, 4) >= amounts[0] &&
                balanceOf(msg.sender, 5) >= amounts[1] &&
                balanceOf(msg.sender, 6) >= amounts[2],
            "Upgrade: not enough stones"
        );

        // check owner of girl
        require(
            girl.ownerOf(id) == msg.sender,
            "Elemental: upgrade caller not owner"
        );

        // burn amount
        burnBatch(msg.sender, upgradeIDs, amounts);

        // upgrade stats
        girl.handleUpgradeCosmicLevel(id, toTier);

        emit CosmicLevelUpgraded(id, toTier);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /** @dev EIP2981 royalties */

    function _setRoyalties(address newRecipient) internal {
        require(
            newRecipient != address(0),
            "Royalties: new recipient is the zero address"
        );
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) public onlyOwner {
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
        royaltyAmount = (_salePrice * 6) / 100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}
