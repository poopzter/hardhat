// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BarBored1155 is ERC1155, ERC1155Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name;
    string public symbol;
    string private baseURI = "";

    constructor(string memory name_, string memory symbol_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        name = name_;
        symbol = symbol_;
    }

    /* ─────────────  Events  ───────────── */
    event MonsterMint(address indexed to, uint256 indexed tokenId);
    event MonsterEvolve(address indexed to, uint256 indexed tokenId);

    // flow control
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // for minter
    function mint(address to, uint256 id, uint256 value, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintWithEvent(to, id, value, data);
    }

    function randomMint(address account, uint256 nonce)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintWithEvent(account, randomId(nonce), 1, "");
    }

    function _mintWithEvent(address to, uint256 id, uint256 value, bytes memory data)
        internal
    {
        _mint(to, id, value, data);
        emit MonsterMint(to, id);
    }

    function randomId(uint256 nonce) public view returns (uint256) { // 1-5
        return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao, nonce))) % 5) + 1;
    }

    // metadata
    function setBaseURI(string calldata _newBaseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "admin only");
        baseURI = _newBaseURI;
    }
    function tokenURI(uint tokenId) public view returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }
    function uri(uint256 id) public view override returns (string memory) {
        return tokenURI(id);
    }

    // evolution
    function evolve(uint256 id) external {
        require(id >= 1 && id <= 20, "token id must be 1-20");
        require(balanceOf(msg.sender, id) >= 2, "you need at least 2 of token");

        // burn 2 tokens
        _burn(msg.sender, id, 2);

        // mint evo to sender
        _mint(msg.sender, id+5, 1, "");
        emit MonsterEvolve(msg.sender, id+5);
    }
    function getEvolvableIDs(address user) external view returns (uint256[] memory) {
        uint256[] memory full = new uint256[](20);
        uint256 count = 0;

        // full scan
        for (uint256 id = 1; id <= 20; id++) {
            if (balanceOf(user, id) >= 2) {
                full[count] = id;
                count++;
            }
        }
        // compact result
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = full[i];
        }
        return result;
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}