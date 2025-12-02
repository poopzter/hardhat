// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IMintableERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract AirdropMinter is AccessControl {
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
    }

    // ฟังก์ชันสำหรับ Airdrop ให้หลายคน (คนละเท่าๆ กัน)
    function airdrop(
        address tokenContract,
        address[] calldata recipients,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(AIRDROP_ROLE) {
        IMintableERC1155 token = IMintableERC1155(tokenContract);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.mint(recipients[i], tokenId, amount, "");
        }
    }

    // ฟังก์ชันเผื่อกรณีแต่ละคนได้จำนวนไม่เท่ากัน
    function airdropVariable(
        address tokenContract,
        address[] calldata recipients,
        uint256 tokenId,
        uint256[] calldata amounts
    ) external onlyRole(AIRDROP_ROLE) {
        require(recipients.length == amounts.length, "Length mismatch");
        IMintableERC1155 token = IMintableERC1155(tokenContract);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.mint(recipients[i], tokenId, amounts[i], "");
        }
    }
}
