// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./TraitManager.sol";
import "./IMuta721.sol";

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
// Muta721.sol                                                                                        //
// Custom ERC721 contract with pausing, burning, and trait management capabilities.                   //
// Manages dynamic traits for NFTs, allowing users to customize and transfer traits.                  //
//                                                                                                    //
// Developed with security and modularity in mind, leveraging OpenZeppelin’s libraries.               //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////

/// @title Muta721 NFT Contract
/// @notice An ERC721-based NFT contract with custom traits, pausing, and minting capabilities.
/// @dev Extends ERC721Pausable, AccessControl, ERC721Burnable, and includes custom trait management.
contract Muta721 is
    IMuta721,
    ERC721,
    ERC721Pausable,
    AccessControl,
    ERC721Burnable,
    IERC721Receiver,
    IERC1155Receiver,
    ERC721Enumerable
{
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
    uint256 public traitLength;

    // Event triggered when a token's traits are modified
    event EditTraits(uint256 tokenId, uint256[] traits_);

    ITraitManager public traitManager;

    uint256 private _nextTokenId;
    string private _imageURI;
    string public characterShadowURI;
    string private _externalURI;
    string private _htmlTemplate;
    string private _jsonName;
    string private _description;

    mapping(uint256 => uint256[]) private _traits;
    mapping(uint256 => uint256[]) private _traitTokenIds;
    mapping(uint256 => address[]) private _traitTokenAddresses;

    mapping(uint256 => mapping(uint256 => string)) private _URIbyLayer;
    mapping(uint256 => mapping(uint256 => string)) private _traitNames;
    mapping(uint256 => string) private _layerNames;

    constructor(
        string memory name_,
        string memory symbol_,
        string[] memory layers_
    ) ERC721(name_, symbol_) {
        require(
            layers_.length > 0,
            "Invalid input: layers must have at least one element."
        );
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_MANAGER_ROLE, msg.sender);
        traitLength = layers_.length;

        for (uint256 i = 0; i < layers_.length; i++) {
            _layerNames[i] = layers_[i];
        }

        _jsonName = name_;
        safeMint(msg.sender); // Mint token id 0 to the contract creator.
    }

    /// @notice Pauses all token transfers within the contract.
    /// @dev Only accessible to accounts with the `PAUSER_ROLE`.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all token transfers within the contract.
    /// @dev Only accessible to accounts with the `PAUSER_ROLE`.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Mints a new token with specific default traits.
    /// @dev Only accessible by accounts with the `MINTER_ROLE`.
    /// @param to The address that will receive the newly minted token.
    function safeMint(address to) public whenNotPaused onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _resetTraits(tokenId);
    }

    /**
     * @dev See {IMuta721}.
     */
    function editTraits(
        uint256 mutaTokenId_,
        address[] calldata traitTokenAddress_,
        uint256[] calldata traitTokenIds_
    ) external whenNotPaused {
        require(
            address(traitManager) != address(0),
            "Trait Manager contract is not setup."
        );
        require(
            ownerOf(mutaTokenId_) == msg.sender,
            "Caller is not Muta721 owner."
        );

        (
            address[] memory traitTokenAddress,
            uint256[] memory traitTokenIds,
            uint256[] memory traits
        ) = traitManager.validateAndGetTraitsValue(
                traitTokenAddress_,
                traitTokenIds_
            );
        _editTraits(mutaTokenId_, traitTokenAddress, traitTokenIds, traits);
    }

    /// @notice Internal function to modify traits with refined parameters.
    /// @param mutaTokenId_ The ID of the token whose traits are being modified.
    /// @param traitTokenAddress_ The addresses of the new trait tokens.
    /// @param traitTokenIds_ The IDs of the new trait tokens.
    /// @param traits_ The new trait values to assign to the token.
    function _editTraits(
        uint256 mutaTokenId_,
        address[] memory traitTokenAddress_,
        uint256[] memory traitTokenIds_,
        uint256[] memory traits_
    ) internal {
        require(
            traitLength == traits_.length,
            "Invalid input: check traits length."
        );
        require(
            traitLength == traitTokenIds_.length,
            "Invalid input: check trait ids length."
        );
        require(
            traitLength == traitTokenAddress_.length,
            "Invalid input: check trait addresses length."
        );

        if (_traits[mutaTokenId_].length < traitLength) {
            _resetTraits(mutaTokenId_);
        }

        for (uint i = 0; i < traitLength; i++) {
            if (
                traitTokenAddress_[i] != _traitTokenAddresses[mutaTokenId_][i] ||
                traitTokenIds_[i] != _traitTokenIds[mutaTokenId_][i]
            ) {
                if (traitTokenAddress_[i] != address(0)) {
                    require(
                        traitManager.isTraitToken(
                            traitTokenAddress_[i],
                            traitTokenIds_[i]
                        ),
                        "Trait verification failed: token is not registered as a trait."
                    );
                    IERC165 ierc165 = IERC165(traitTokenAddress_[i]);
                    require(
                        ierc165.supportsInterface(0xd9b67a26) ||
                            ierc165.supportsInterface(0x80ac58cd),
                        "Invalid token type"
                    );
                    _transferToken(
                        ownerOf(mutaTokenId_),
                        address(this),
                        traitTokenAddress_[i],
                        traitTokenIds_[i]
                    );
                }

                if (_traitTokenAddresses[mutaTokenId_][i] != address(0)) {
                    _transferToken(
                        address(this),
                        ownerOf(mutaTokenId_),
                        _traitTokenAddresses[mutaTokenId_][i],
                        _traitTokenIds[mutaTokenId_][i]
                    );
                }
            }

            if (traits_[i] != 0) {
                _traits[mutaTokenId_][i] = traits_[i];
            } else {
                _traits[mutaTokenId_][i] = 0;
            }
        }

        emit EditTraits(mutaTokenId_, traits_);

        _traitTokenAddresses[mutaTokenId_] = traitTokenAddress_;
        _traitTokenIds[mutaTokenId_] = traitTokenIds_;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setManager(
        address addr_
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addr_ != address(0), "Invalid address.");
        traitManager = ITraitManager(addr_);
    }

    /**
     * @dev See {IMuta721}.
     */
    function setJSONName(
        string memory name_
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        _jsonName = name_;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setDescription(
        string memory description_
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        _description = description_;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setImageURI(
        string memory uri
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        _imageURI = uri;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setCharacterShadowURI(
        string memory uri
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        characterShadowURI = uri;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setExternalURI(
        string memory uri
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        _externalURI = uri;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setHTMLTemplate(
        string memory htmlTamplate
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        _htmlTemplate = htmlTamplate;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setTraitURIAndName(
        uint256 layer,
        uint256 trait,
        string memory uri,
        string memory name
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        require(
            trait != 1 && trait >= 0,
            "The trait value must not be equal to 1 and must be greater than 0."
        );
        _URIbyLayer[layer][trait] = uri;
        if (bytes(name).length > 0) {
            _traitNames[layer][trait] = name;
        }
    }

    /**
     * @dev See {IMuta721}.
     */
    function setLayerName(
        uint256 layer,
        string memory name
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        require(
            layer >= 0 && layer < traitLength,
            "Invalid input: layer out of length."
        );
        _layerNames[layer] = name;
    }

    /**
     * @dev See {IMuta721}.
     */
    function setTraitLength(
        uint256 length_
    ) external whenNotPaused onlyRole(URI_MANAGER_ROLE) {
        require(
            length_ > 0,
            "Invalid input: length must be greater than zero."
        );
        traitLength = length_;
    }

    /// @notice Retrieves the URI for a specific token's metadata.
    /// @param tokenId The ID of the token to retrieve the metadata URI.
    /// @return The URI string for the specified token's metadata.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        _requireOwned(tokenId);

        string memory imageURI = string.concat(
            _imageURI,
            "address=",
            Strings.toHexString(uint256(uint160(address(this)))),
            "&tokenId=",
            Strings.toString(tokenId)
        );
        (
            string memory imageURIsvg,
            string memory attrs
        ) = _generateTokenImageAndAttr(tokenId);
        string memory htmlURI = _replaceSubstring(
            _htmlTemplate,
            "{svg}",
            imageURIsvg
        );
        string memory result = string.concat(
            '{\r\n\t"name": "',
            _jsonName,
            " #",
            Strings.toString(tokenId),
            '",\r\n\t"description": "',
            _description,
            '",\r\n\t"external_url": "',
            _externalURI,
            '",\r\n\t"image": "',
            imageURI,
            '",\r\n\t"animation_url": "data:text/html;base64,',
            Base64.encode(bytes(htmlURI)),
            '",\r\n\t"attributes": ',
            attrs,
            "\r\n}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(result))
                )
            );
    }

    /**
     * @dev See {IMuta721}.
     */
    function svgURI(
        uint256 tokenId
    ) external view returns (string memory) {
        (
            string memory imageURIsvg,
            string memory attrs
        ) = _generateTokenImageAndAttr(tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(imageURIsvg))
                )
            );
    }

    /**
     * @dev See {IMuta721}.
     */
    function getTraits(uint256 tokenId) external view returns (uint256[] memory) {
        return _traits[tokenId];
    }

    /**
     * @dev See {IMuta721}.
     */
    function getTraitTokens(
        uint256 tokenId
    ) external view returns (traitToken[] memory) {
        uint256[] memory traitTokenIds = _traitTokenIds[tokenId];
        address[] memory traitTokenAddresses = _traitTokenAddresses[tokenId];
        traitToken[] memory outputs = new traitToken[](traitTokenIds.length);
        for (uint i = 0; i < traitTokenIds.length; i++) {
            outputs[i] = traitToken(traitTokenAddresses[i], traitTokenIds[i]);
        }
        return outputs;
    }

    /**
     * @dev See {IMuta721}.
     */
    function getURIbyLayer(
        uint256 layer,
        uint256 trait
    ) external view returns (string memory) {
        return _URIbyLayer[layer][trait];
    }

    /// @dev Generates an image and metadata attributes for a token.
    /// This function is called internally.
    /// @param tokenId The ID of the token to generate data.
    function _generateTokenImageAndAttr(
        uint256 tokenId
    ) internal view returns (string memory, string memory) {
        string
            memory svg = "<svg version='1.0' width='100%' height='100%' viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg' >";
        string memory attrs = "\r\n\t[";
        uint256[] memory traits = _traits[tokenId];
        bool needRemoveTailingComma = false;

        uint256 trait0 = traits[0];
        bytes memory tempEmptyStringTest = bytes(_URIbyLayer[0][trait0]);

        if (tempEmptyStringTest.length > 0) {
            needRemoveTailingComma = true;
            string memory traitName;
            if (bytes(_traitNames[0][trait0]).length > 0) {
                traitName = _traitNames[0][trait0];
            } else {
                traitName = Strings.toString(trait0);
            }
            attrs = string.concat(
                attrs,
                '\r\n\t\t{\r\n\t\t\t"trait_type": "',
                _layerNames[0],
                '",\r\n\t\t\t"value": "',
                traitName,
                '"\r\n\t\t},'
            );
            svg = string.concat(
                svg,
                "<image class='muta721-background' width='800' height='800' href='",
                _URIbyLayer[0][trait0],
                "' />"
            );
        }

        svg = string.concat(
            svg,
            "<image class='muta721-shadow' width='800' height='800' href='",
            characterShadowURI,
            "' ></image><g class='muta721-character'>"
        );
        for (uint256 layer = 1; layer < traitLength; layer++) {
            uint256 trait = traits[layer];
            tempEmptyStringTest = bytes(_URIbyLayer[layer][trait]); // Uses memory
            if (tempEmptyStringTest.length == 0) {
                continue;
            } else {
                needRemoveTailingComma = true;
                string memory traitName;
                if (bytes(_traitNames[layer][trait]).length > 0) {
                    traitName = _traitNames[layer][trait];
                } else {
                    traitName = Strings.toString(trait);
                }
                attrs = string.concat(
                    attrs,
                    '\r\n\t\t{\r\n\t\t\t"trait_type": "',
                    _layerNames[layer],
                    '",\r\n\t\t\t"value": "',
                    traitName,
                    '"\r\n\t\t},'
                );
                svg = string.concat(
                    svg,
                    "<image width='800' height='800' href='",
                    _URIbyLayer[layer][trait],
                    "' />"
                );
            }
        }
        svg = string.concat(svg, "</g>");

        if (needRemoveTailingComma) {
            attrs = _removeTailingComma(attrs);
        }

        attrs = string.concat(attrs, "\r\n\t]");
        svg = string.concat(svg, "</svg>");

        return (svg, attrs);
    }

    /// @dev Removes the lastest trailing comma from a given string.
    /// @param str input The string from which the trailing comma will be removed.
    /// @return The modified string with the trailing comma removed.
    function _removeTailingComma(
        string memory str
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length - 1);

        for (uint i = 0; i < strBytes.length - 1; i++) {
            result[i] = strBytes[i];
        }

        return string(result);
    }

    /// @dev This function works by iterating over the bytes of the original string and checking for matches
    ///      with the search substring. It uses dynamic arrays to construct the result.
    ///      The function does not handle overlapping matches or advanced string operations.
    /// @param original The original string in which replacements will be made.
    /// @param search The substring to search for within the original string.
    ///               This must not be empty, as an empty search string would result in an invalid operation.
    /// @param replacement The string to replace each occurrence of the search substring.
    /// @return A new string where all occurrences of the search substring have been replaced by the replacement string.
    function _replaceSubstring(
        string memory original,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory) {
        bytes memory originalBytes = bytes(original);
        bytes memory searchBytes = bytes(search);
        bytes memory replacementBytes = bytes(replacement);

        require(searchBytes.length > 0, "Search string cannot be empty");

        // Dynamic array to hold the resulting bytes
        bytes memory result;
        uint256 i = 0;

        while (i < originalBytes.length) {
            // Check if we find the search string at position i
            bool matchFound = true;
            for (uint256 j = 0; j < searchBytes.length; j++) {
                if (
                    i + j >= originalBytes.length ||
                    originalBytes[i + j] != searchBytes[j]
                ) {
                    matchFound = false;
                    break;
                }
            }

            if (matchFound) {
                // Append replacement string
                result = abi.encodePacked(result, replacementBytes);
                i += searchBytes.length; // Skip past the search string
            } else {
                // Append the current character
                result = abi.encodePacked(result, originalBytes[i]);
                i++;
            }
        }

        return string(result);
    }

    /// @notice Transfers a token from one address to another.
    /// @dev Supports both ERC721 and ERC1155 token standards.
    /// @param from The address sending the token.
    /// @param to The address receiving the token.
    /// @param contractAddr The contract address of the token being transferred.
    /// @param tokenId The ID of the token to transfer.
    function _transferToken(
        address from,
        address to,
        address contractAddr,
        uint256 tokenId
    ) internal {
        IERC165 ierc165 = IERC165(contractAddr);
        if (ierc165.supportsInterface(0xd9b67a26)) {
            IERC1155 ierc1155 = IERC1155(contractAddr);
            require(
                ierc1155.balanceOf(from, tokenId) > 0,
                "ERC1155: Not enough token."
            );
            ierc1155.safeTransferFrom(from, to, tokenId, 1, "");
        } else {
            IERC721 ierc721 = IERC721(contractAddr);
            require(
                ierc721.ownerOf(tokenId) == from,
                "ERC721: Not enough token."
            );
            ierc721.safeTransferFrom(from, to, tokenId);
        }
    }

    /// @notice Resets a token's traits and returns trait tokens to their owners if necessary.
    /// @param mutaTokenId_ The ID of the token whose traits will be reset.
    function _resetTraits(uint256 mutaTokenId_) internal {
        require(
            _traits[mutaTokenId_].length == _traitTokenIds[mutaTokenId_].length,
            "Traits length of this token is not valid. (1)"
        );
        require(
            _traits[mutaTokenId_].length == _traitTokenAddresses[mutaTokenId_].length,
            "Traits length of this token is not valid. (2)"
        );

        _traits[mutaTokenId_] = new uint256[](traitLength);

        for (uint i = 0; i < _traitTokenIds[mutaTokenId_].length; i++) {
            if (_traitTokenAddresses[mutaTokenId_][i] != address(0)) {
                _transferToken(
                    address(this),
                    ownerOf(mutaTokenId_),
                    _traitTokenAddresses[mutaTokenId_][i],
                    _traitTokenIds[mutaTokenId_][i]
                );
            }
        }

        _traitTokenIds[mutaTokenId_] = new uint256[](traitLength);
        _traitTokenAddresses[mutaTokenId_] = new address[](traitLength);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Pausable, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(IERC165, ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override(IERC721Receiver) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}