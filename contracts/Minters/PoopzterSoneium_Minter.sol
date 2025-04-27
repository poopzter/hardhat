// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IMint {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract PoopzterSoneium_Minter is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public tokenId;
    IMint public trait;

    mapping(bytes32 => mapping(uint256 => bool)) private _freeMintUsed;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        tokenId = 0;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setTokenId(
        uint256 tokenId_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenId = tokenId_;
    }

    function setTrait(
        address address_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address_ != address(0), "Invalid address.");
        trait = IMint(address_);
    }

    function grantFreeMintQuota(
        bytes32 hashAddr,
        uint256 tokenId_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _freeMintUsed[hashAddr][tokenId_] = false;
    }

    function getHasFreeMintQuota(
        bytes32 hashAddr,
        uint256 tokenId_
    ) public view returns (bool) {
        return !_freeMintUsed[hashAddr][tokenId_];
    }

    function mint() external whenNotPaused {
        bytes32 hashAddr = keccak256(bytes(Strings.toHexString(msg.sender)));
        require(tokenId != 0, "The minter has not set the token ID.");
        require(
            !_freeMintUsed[hashAddr][tokenId],
            "This address has already claimed its free mint."
        );

        trait.mint(msg.sender, tokenId, 1, "");
        _freeMintUsed[hashAddr][tokenId] = true;
    }
}
