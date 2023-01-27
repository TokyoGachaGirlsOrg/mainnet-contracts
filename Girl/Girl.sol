// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./CalculateUpgrade.sol";
import "./Whitelist.sol";
import "../interfaces/IAttunement.sol";
import "../interfaces/IEmissions.sol";

contract Girl is
    ERC721Enumerable,
    IERC721Receiver,
    CalculateUpgrade,
    Whitelist,
    ReentrancyGuard,
    IERC2981
{
    // strings
    using Strings for uint256;
    // royalty
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    // interface
    IERC20 public moonstone;
    IAttunement public attunement;
    IEmissions public emissions;
    // state
    string baseURI;
    uint256 public maxSupply = 5000;
    uint256 public startTime = 1674871200;
    address payable dev;
    address private _recipient;
    // event
    event GirlMinted(
        address minter,
        uint256 indexed id,
        bool indexed usingOrb,
        uint256 indexed rarity
    );
    event StatsInitialized(uint256 id, uint256 cl, uint256 el);
    // mapping
    mapping(address => bool) public isElementalStone;
    mapping(uint256 => bool) public paired;
    mapping(address => bool) public isWorker;

    constructor(
        string memory _initBaseURI,
        address _orb,
        address _emissions,
        address payable _dev,
        address _royalty
    ) ERC721("Tokyo Test Girl", "TTG") {
        orb = IERC721(_orb);
        setBaseURI(_initBaseURI);
        setEmissions(_emissions);
        setRoyalties(_royalty);
        setWorker(msg.sender, true);

        // payment
        setCost(5 ether);
        dev = _dev;
        _recipient = _dev;
    }

    function setOrbRarity(address _orbRarity) external onlyOwner {
        orbRarity = IOrbRarity(_orbRarity);
    }

    // attunement

    function isPaired(uint256 girlId) external view returns (bool) {
        return paired[girlId];
    }

    function setPaired(uint256 _id, bool _paired) external onlyAttuneOrES {
        paired[_id] = _paired;
    }

    function checkStake(uint256 girlId)
        external
        view
        returns (
            address,
            bool,
            uint256
        )
    {
        return (ownerOf(girlId), paired[girlId], element[girlId]);
    }

    // mint one to owner for marketing purpose
    function mintDev(address _to) external onlyOwner {
        uint256 supply = totalSupply();
        uint256 id = supply + 1;
        require(id <= maxSupply, "Girl: sold out");
        _safeMint(_to, id);
        emit GirlMinted(_to, id, false, 6);
    }

    // public mint
    function mint(
        bool usingOrb,
        uint256 orbId,
        uint256 amount
    ) external payable nonReentrant {
        require(block.timestamp >= startTime, "Girl: mint not started");

        address user = msg.sender;
        uint256 supply = totalSupply();
        uint256 id = supply + 1;
        uint256 rarity;

        require(amount >= 1 && amount <= 5, "Girl: amount 1 to 5 only");
        require(supply + amount <= maxSupply, "Girl: sold out");

        if (usingOrb) {
            require(orb.ownerOf(orbId) == user, "Girl: not orb owner");
            require(
                amount <= getChargesRemaining(orbId),
                "Girl: amount must be <= charges"
            );
            require(
                msg.value >= getDiscountCost() * amount,
                "Girl: send correct price"
            );

            for (uint256 i = 0; i < amount; ++i) {
                rarity = queueCharge(orbId);
                if (rarity != 6) {
                    // last charge take orb - needs approval
                    orb.transferFrom(user, address(this), orbId);
                    require(
                        orb.ownerOf(orbId) == address(this),
                        "Girl: orb not recieved"
                    );
                }
                _safeMint(user, id + i);
                emit GirlMinted(user, id + i, usingOrb, rarity);
            }
        } else {
            require(msg.value >= cost * amount, "Girl: send correct price");

            for (uint256 i = 0; i < amount; ++i) {
                _safeMint(user, id + i);
                emit GirlMinted(user, id + i, usingOrb, 6);
            }
        }
    }

    // sends girl to user
    function initStats(
        uint256 id,
        uint256 cl,
        uint256 el
    ) external onlyWorker {
        _initStats(id, cl, el);
        emissions.newGirl(id);
        emit StatsInitialized(id, cl, el);
    }

    // withdraw mint fees

    function withdraw(address payable _rest) external onlyOwner {
        uint256 bal = address(this).balance;

        // send dev fee
        dev.transfer(getDevFee(bal));

        // payment rest to team
        _rest.transfer(address(this).balance);
    }

    // helpers

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // upgrades

    function getCosmicLevelUpgradeCost(uint256 id, uint256 toTier)
        external
        view
        returns (uint256[] memory)
    {
        require(
            toTier > cosmicLevel[id] && toTier <= 10,
            "Upgrade: tier must be between current level and 10"
        );
        return calcCosmicLevelUpgradeCost(id, toTier);
    }

    function handleUpgradeCosmicLevel(uint256 id, uint256 toTier)
        external
        nonReentrant
        onlyElementalStone
    {
        uint256 oldGs = gamerScore[id];
        uint256 oldCl = cosmicLevel[id];

        emissions.claimBeforeUpgrade(id);
        _upgradeCosmicLevel(id, toTier); // do the upgrade
        // help calculate in emissions
        emissions.updateTotalRewardsPerDay(id, oldGs, oldCl);
    }

    function getGamerScoreUpgradeCost(uint256 id, uint256 toTier)
        external
        view
        returns (uint256 cost)
    {
        require(
            toTier >= 1 && toTier <= maxGamerScore,
            "Upgrade: toTier must be between 1 and 25"
        );
        require(
            toTier > gamerScore[id],
            "Upgrade: toTier must be greater than current level"
        );
        cost = calcGamerScoreUpgradeCost(id, toTier);
    }

    function handleUpgradeGamerScore(uint256 id, uint256 toTier)
        external
        nonReentrant
        onlyMoonstone
    {
        uint256 oldGs = gamerScore[id];
        uint256 oldCl = cosmicLevel[id];

        emissions.claimBeforeUpgrade(id);

        _upgradeGamerScore(id, toTier);
        emissions.updateTotalRewardsPerDay(id, oldGs, oldCl);
    }

    // constructor/setter functions

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setEmissions(address _e) public onlyOwner {
        emissions = IEmissions(_e);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setElementalStoneContract(address _es) external onlyOwner {
        isElementalStone[_es] = true;
    }

    function setAttunementContract(address _a) external onlyOwner {
        attunement = IAttunement(_a);
    }

    function setMoonstoneContract(address _moonstone) external onlyOwner {
        moonstone = IERC20(_moonstone);
    }

    function setWorker(address _worker, bool _isWorker) public onlyOwner {
        isWorker[_worker] = _isWorker;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    // modifiers

    modifier onlyElementalStone() {
        require(isElementalStone[msg.sender], "Girl: only ES can call");
        _;
    }

    modifier onlyAttuneOrES() {
        require(
            isElementalStone[msg.sender] || msg.sender == address(attunement),
            "Girl: only ES or Att can call"
        );
        _;
    }

    modifier onlyMoonstone() {
        require(
            msg.sender == address(moonstone),
            "Girl: only moonstone can upgrade gamerscore"
        );
        _;
    }

    modifier onlyWorker() {
        require(isWorker[msg.sender], "Girl: only worker can call");
        _;
    }

    // transfer overrides cancels attunement

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
        attunement.girlTransferred(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        safeTransferFrom(from, to, tokenId, "");
        attunement.girlTransferred(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
        attunement.girlTransferred(tokenId);
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
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    // required by solidity
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
