// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./Muta721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                            .::^^^^^^::.                                            //
//                                      .:~7?JJJYYYYYYYYYJJ?7~:.                                      //
//                                   :~?JYYYYYYYYYYYYYYYYYYYYYYJ?~:                                   //
//                                .~?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.                                //
//                              .~JYYYYYYYYYJ?7!~^^^^^^~!7?JYYYYYYYYYJ~.                              //
//                             ^JYYYYYYYYYJ~.              .~JYYYYYYYYYJ^                             //
//                            !YYYYYYYYYYJ:                  :JYYYYYYYYYY!                            //
//                           7YYYYYYYYYYJ:                    :JYYYYYYYYYY7                           //
//                          !YYYYYYYYYYY^     :!!!!~^.         ^YYYYYYYYYYY!                          //
//                         :YYYYYYYYYY?:      :?YYYYYJ?~        :?YYYYYYYYYY:                         //
//                         7YYYYYYYYY7.         !YYYYYYY?:       .7YYYYYYYYY7                         //
//                        .JYYYYYYYY7        .   ~JYYYYYYJ^        7YYYYYYYYJ.                        //
//                        .JYYYYYYYJ.      .!J?^  :JYYYYYYY!       .JYYYYYYYJ.                        //
//                         ?YYYYYYY7      :?YYYY!. .7YYYYYYY7.      7YYYYYYY?.                        //
//                         !YYYYYYY!     .?YJYYYY?^  :~7JJJYYJ~.    !YYYYYYY!                         //
//                         :JYYYYYY?.     .::::::::     ..:::::    .?YYYYYYJ:                         //
//                          ~YYYYYYYJ~                            ~JYYYYYYY~                          //
//                           !YYYYYYYJ^                          ^JYYYYYYY!                           //
//                            ~JYYYYYYJ!.                      .!JYYYYYYJ~                            //
//                             :7YYYYYYYJ7^      .!??!.      ^7JYYYYYYY7:                             //
//                               ^7YYYYYYYY?!!!!!?YYYY?!!!!!?YYYYYYYY7^                               //
//                                 :!JYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ!:                                 //
//                                   .^!?JYYYYYYYYYYYYYYYYYYYYJ?!^.                                   //
//                                       .:~!7?JJJJJJJJJJ?7!~:.                                       //
//                                              ........                                              //
//                                                                                                    //
//                                                                                                    //
//                   ..        ......       ..       ..      ..    .........  ..     ...              //
//                 .7JJ~       ?J?????!.    7J7.    ^JJ^    ~Y7   :???JJ???^  ~J?:  ^J?:              //
//                 7Y~7Y~      ?Y~  .?Y7    7YYJ^  ~YYY~    ~Y?      :YY^      ^JJ^~Y?.               //
//                7Y?:^JY~     ?Y?!!7J?^    7Y!7Y~7Y~?Y~    ~Y?      .JY:       :?YY!                 //
//              .7Y?!7!!JY~    ?Y7^~JY~     ?Y~ !YJ: ?Y~    ~Y?      :YY^        ~YJ                  //
//              :7!.    :!!.   ~7^  .!7^    ~7^  ..  ~7:    ^7~      .!!:        :7!                  //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
// TraitManager.sol                                                                                   //
//                                                                                                    //
// A trait management contract designed for use with Muta721 NFTs. This contract enables              //
// management of custom trait tokens, including their addition, removal, and validation.              //
//                                                                                                    //
// The TraitManager facilitates secure and flexible NFT customization, allowing specific              //
// attributes to be dynamically adjusted according to predefined traits. The contract                 //
// leverages OpenZeppelin’s Pausable and AccessControl libraries, ensuring controlled                 //
// access and robust role management for trait updates and queries.                                   //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////

interface ITraitManager {
    function isTraitToken(
        address address_,
        uint256 id_
    ) external view returns (bool);
    function addTraitToken(
        address address_,
        uint256 id_,
        uint256 trait_,
        uint256[] calldata layer
    ) external;
    function removeTraitToken(address address_, uint256 id_) external;
    function getTraitLayers(
        address address_,
        uint256 id_
    ) external view returns (uint256[] memory);
    function validateAndGetTraitsValue(
        address[] calldata traitTokenAddress_,
        uint256[] calldata traitTokenIds_
    )
        external
        view
        returns (address[] memory, uint256[] memory, uint256[] memory);
}

/// @title Trait Manager Contract
/// @notice Handles trait tokens for Muta721 NFTs, allowing traits to be added, removed, and queried.
/// @dev Implements the ITraitManager interface with pausing and access control features.
contract TraitManager is ITraitManager, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(bytes32 => uint256) private _traitsMapper;
    mapping(bytes32 => uint256[]) private _layerMapper;
    Muta721 public muta721;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    modifier onlyMuta721() {
        require(
            address(muta721) != address(0),
            "Muta721 contract is not setup."
        );
        require(
            msg.sender == address(muta721),
            "This function can only be called from Muta721."
        );
        _;
    }

    /// @notice Pauses the TraitManager contract, disabling state-changing functions.
    /// @dev Only accessible to accounts with the `PAUSER_ROLE`.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the TraitManager contract, re-enabling state-changing functions.
    /// @dev Only accessible to accounts with the `PAUSER_ROLE`.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Sets the Muta721 contract associated with the TraitManager.
    /// @dev Only accessible to accounts with the `MANAGER_ROLE`.
    /// @param mutaAddress_ The address of the Muta721 contract.
    function setMuta721(
        address mutaAddress_
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        require(mutaAddress_ != address(0), "Invalid address.");
        muta721 = Muta721(mutaAddress_);
    }

    /// @notice Adds a trait token to the TraitManager.
    /// @param address_ The address of the trait token contract.
    /// @param id_ The ID of the trait token.
    /// @param trait_ The trait value associated with the token.
    /// @param layers_ The layers affected by this trait token.
    function addTraitToken(
        address address_,
        uint256 id_,
        uint256 trait_,
        uint256[] calldata layers_
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        require(address_ != address(0), "Invalid address.");
        require(trait_ > 1, "Trait value must be greater than 1.");
        require(layers_.length > 0, "Layer not found.");
        IERC165 ierc165 = IERC165(address_);
        require(
            ierc165.supportsInterface(0xd9b67a26) ||
                ierc165.supportsInterface(0x80ac58cd),
            "Invalid token standard."
        );

        for (uint i = 0; i < layers_.length; i++) {
            if (i == 0) {
                continue;
            }
            require(layers_[i - 1] > layers_[i], "Layers is not sorted.");
        }

        bytes32 mapKey = keccak256(abi.encodePacked(address_, id_));
        _traitsMapper[mapKey] = trait_;
        _layerMapper[mapKey] = layers_;
    }

    /// @notice Removes a trait token from the TraitManager.
    /// @param address_ The address of the trait token contract.
    /// @param id_ The ID of the trait token to remove.
    function removeTraitToken(
        address address_,
        uint256 id_
    ) external whenNotPaused onlyRole(MANAGER_ROLE) {
        bytes32 mapKey = keccak256(abi.encodePacked(address_, id_));
        delete _traitsMapper[mapKey];
        delete _layerMapper[mapKey];
    }

    /// @notice Validate the input and return trait values to Muta721.
    /// @param traitTokenAddress_ An array of trait token contract addresses.
    /// @param traitTokenIds_ An array of trait token IDs.
    function validateAndGetTraitsValue(
        address[] calldata traitTokenAddress_,
        uint256[] calldata traitTokenIds_
    )
        external
        view
        whenNotPaused
        onlyMuta721
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 traitLength = muta721.traitLength();
        require(
            traitTokenAddress_.length == traitTokenIds_.length,
            "Invalid input: the lengths of the trait token IDs and trait addresses are not equal."
        );
        require(
            traitTokenAddress_.length <= traitLength,
            "Too much trait tokens."
        );

        uint256[] memory traits = new uint256[](traitLength);
        address[] memory traitTokenAddress = new address[](traitLength);
        uint256[] memory traitTokenIds = new uint256[](traitLength);

        uint256 previousLayer;

        for (uint i = traitTokenAddress_.length; i > 0; i--) {
            uint index = i - 1;
            bytes32 mapKey = keccak256(
                abi.encodePacked(
                    traitTokenAddress_[index],
                    traitTokenIds_[index]
                )
            );
            uint256[] memory layers = _layerMapper[mapKey];
            require(layers.length > 0, "Layer not found.");
            if (index != traitTokenAddress_.length - 1) {
                require(layers[0] < previousLayer, "Invalid token order.");
            }
            previousLayer = layers[0];
            uint256 trait = _traitsMapper[mapKey];
            for (uint j = 0; j < layers.length; j++) {
                require(
                    traits[layers[j]] == 0,
                    "Invalid input: There is a trait with duplicate layers."
                );
                if (j == 0) {
                    traits[layers[j]] = trait;
                } else {
                    traits[layers[j]] = 1; // 1 for reserve.
                }
            }
            traitTokenAddress[layers[0]] = traitTokenAddress_[index];
            traitTokenIds[layers[0]] = traitTokenIds_[index];
        }

        return (traitTokenAddress, traitTokenIds, traits);
    }

    /// @notice Checks if a given token is a trait token.
    /// @param address_ The address of the token contract.
    /// @param id_ The ID of the token to check.
    /// @return True if the token is a registered trait token, false otherwise.
    function isTraitToken(
        address address_,
        uint256 id_
    ) external view returns (bool) {
        bytes32 mapKey = keccak256(abi.encodePacked(address_, id_));
        return _traitsMapper[mapKey] > 0;
    }

    /// @notice Retrieves the trait value associated with a specific trait token.
    /// @param address_ The address of the token contract.
    /// @param id_ The ID of the trait token.
    /// @return The trait value associated with the specified token.
    function getTraitValue(
        address address_,
        uint256 id_
    ) external view returns (uint256) {
        require(address_ != address(0), "Invalid address.");
        bytes32 mapKey = keccak256(abi.encodePacked(address_, id_));
        return _traitsMapper[mapKey];
    }

    /// @notice Retrieves the layers associated with a specific trait token.
    /// @param address_ The address of the token contract.
    /// @param id_ The ID of the trait token.
    /// @return An array of layer indices associated with the specified trait token.
    function getTraitLayers(
        address address_,
        uint256 id_
    ) external view returns (uint256[] memory) {
        require(address_ != address(0), "Invalid address.");
        bytes32 mapKey = keccak256(abi.encodePacked(address_, id_));
        return _layerMapper[mapKey];
    }
}