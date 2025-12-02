// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IPoints {
    /// @dev mint non-transferable points
    function mint(address account, uint256 amount) external;
}

contract PoopTreasury is AccessControl, IPoints {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    IERC20 public poopToken;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address _poopToken, address _admin) {
        require(_poopToken != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        
        poopToken = IERC20(_poopToken);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows the admin to update the Poop token address.
     */
    function setPoopToken(address _poopToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_poopToken != address(0), "Invalid token address");
        poopToken = IERC20(_poopToken);
    }

    /**
     * @dev Acts as a mint function for the reward mechanism, but actually transfers tokens from the treasury.
     * Requires MINTER_ROLE.
     */
    function mint(address account, uint256 amount) external override onlyRole(MINTER_ROLE) {
        require(poopToken.balanceOf(address(this)) >= amount, "PoopTreasury: Insufficient balance");
        bool success = poopToken.transfer(account, amount);
        require(success, "PoopTreasury: Transfer failed");
    }

    /**
     * @dev Allows anyone to deposit Poop tokens into the treasury.
     * The caller must have approved this contract to spend the tokens beforehand.
     */
    function deposit(uint256 amount) external {
        bool success = poopToken.transferFrom(msg.sender, address(this), amount);
        require(success, "PoopTreasury: Transfer failed");
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Allows the admin to withdraw Poop tokens from the treasury.
     */
    function withdraw(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "Invalid recipient");
        bool success = poopToken.transfer(to, amount);
        require(success, "PoopTreasury: Transfer failed");
        emit Withdrawn(to, amount);
    }

    /**
     * @dev Allows the admin to recover other ERC20 tokens sent to this contract by mistake.
     */
    function recoverToken(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "Invalid recipient");
        bool success = IERC20(token).transfer(to, amount);
        require(success, "Token recovery failed");
    }
}
