// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISafeMint {
    function safeMint(address to) external;
}

interface IMint {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

contract PoopzterOgMinter_RandomWithPoop is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private _mintCount;
    IERC20 public poop;
    ISafeMint public muta;
    IMint public trait;
    
    uint256 public mintPrice = 88 * 10**18; // 88 $POOP

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mintCount = 0;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setPoop(
        address address_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address_ != address(0), "Invalid address.");
        poop = IERC20(address_);
    }

    function setMintPrice(uint256 _newMintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _newMintPrice;
    }

    function withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(poop.transfer(msg.sender, amount), "Transfer token failed");
    }

    function setMuta(
        address address_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address_ != address(0), "Invalid address.");
        muta = ISafeMint(address_);
    }

    function setTrait(
        address address_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address_ != address(0), "Invalid address.");
        trait = IMint(address_);
    }

    function mint() external whenNotPaused {
        require(poop.balanceOf(msg.sender) >= mintPrice, "Insufficient funds");
        require(poop.transferFrom(msg.sender, address(this), mintPrice), "Payment failed");

        _randomMint(msg.sender);
    }

    function _randomMint(address to) internal whenNotPaused {
      muta.safeMint(to);
      _traitsMint(to);
    }

    function _traitsMint(address to) internal whenNotPaused {
        uint256[] memory traitTokenIds = _randomTrait();
        bool hasTrait = false;

        for (uint i = 0; i < traitTokenIds.length; i++) {
            uint randomNo = uint256(keccak256(abi.encodePacked(address(this), msg.sender, _mintCount, block.timestamp, i)));
            if (randomNo % 2 == 0) {
                hasTrait = true;
                trait.mint(to, traitTokenIds[i], 1, "");
            }
        }

        if (!hasTrait) {
            trait.mint(to, 20, 1, ""); // Leaf
        }
        _mintCount++;
    }

    function _randomTrait() internal view whenNotPaused returns (uint256[] memory) {
        uint8[5] memory bodyIds = [8, 9, 10, 11, 12];
        uint8[5] memory shoesIds = [13, 14, 15, 16, 17];
        uint8[6] memory outfitIds = [18, 19, 21, 22, 23, 24];
        uint8[17] memory poopIds = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41];
        uint8[1] memory faceIds = [42];
        uint8[8] memory mouthIds = [43, 44, 45, 46, 47, 48, 49, 50];
        uint8[9] memory eyesIds = [51, 52, 53, 54, 55, 56, 57, 58, 59];

        uint randomNo = uint256(keccak256(abi.encodePacked(address(this), msg.sender, _mintCount, block.timestamp)));
        uint[] memory traitTokenIds = new uint[](7);

        traitTokenIds[0] = bodyIds[randomNo % bodyIds.length]; // body
        traitTokenIds[1] = shoesIds[randomNo % shoesIds.length]; // shoes
        traitTokenIds[2] = outfitIds[randomNo % outfitIds.length]; // outfit
        traitTokenIds[3] = poopIds[randomNo % poopIds.length]; // poop
        traitTokenIds[4] = faceIds[randomNo % faceIds.length]; // face
        traitTokenIds[5] = mouthIds[randomNo % mouthIds.length]; // mouth
        traitTokenIds[6] = eyesIds[randomNo % eyesIds.length]; // eye

        return traitTokenIds;
    }
}