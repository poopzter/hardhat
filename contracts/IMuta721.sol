// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct traitToken {
    address addr;
    uint256 tokenId;
}

interface IMuta721 {
    /// @notice Allows modification of a token's traits and associated trait tokens.
    /// @dev Only accessible by the owner of the Muta tokenId.
    /// @param mutaTokenId_ The ID of the token whose traits are being modified.
    /// @param traitTokenAddress_ The addresses of the new trait tokens.
    /// @param traitTokenIds_ The IDs of the new trait tokens.
    function editTraits(
        uint256 mutaTokenId_,
        address[] calldata traitTokenAddress_,
        uint256[] calldata traitTokenIds_
    ) external;

    /// @notice Sets the TraitManager contract address.
    /// @dev Replaces the previous TraitManager contract if already set.
    /// @param addr_ The address of the new TraitManager contract.
    function setManager(address addr_) external;

    /// @dev Sets the name attribute in json.
    /// @param name_ The new name to be set.
    function setJSONName(string memory name_) external;

    /// @dev Sets the description attribute in json.
    /// @param description_ The new description to be set.
    function setDescription(string memory description_) external;

    /// @dev Sets the URI for image attribute in json.
    /// @param uri The new URI to be set for the token image.
    function setImageURI(string memory uri) external;

    /// @dev Sets the URI for the character shadow in the dynamic image.
    /// @param uri The new URI to be set for the character shadow image.
    function setCharacterShadowURI(string memory uri) external;

    /// @dev Sets the external URI for external_url attribute in json.
    /// @param uri The new external URI to be set.
    function setExternalURI(string memory uri) external;

    /// @dev Sets the HTML template to be used in the animation_url.
    /// @param htmlTamplate The new html template value to be set.
    function setHTMLTemplate(string memory htmlTamplate) external;

    /// @dev Sets the URI and name for a specific trait.
    /// @param layer The layer to be assigned.
    /// @param trait The trait of the layer to be assigned.
    /// @param uri The URI string to be associated with the trait.
    /// @param name The name string to be associated with the trait.
    function setTraitURIAndName(
        uint256 layer,
        uint256 trait,
        string memory uri,
        string memory name
    ) external;

    /// @dev Assigns a name to a specific layer in the metadata structure.
    /// @param layer The layer to name.
    /// @param name The name to be assigned to the layer.
    function setLayerName(uint256 layer, string memory name) external;

    /// @notice Sets the total number of traits for tokens.
    /// @dev Only accessible by the admin and only when contract is not paused.
    /// @param length_ The new number of traits for each token.
    function setTraitLength(uint256 length_) external;

    /// @notice Retrieves the SVG URI.
    /// @param tokenId The ID of the token for which to retrieve the SVG URI.
    /// @return The URI string of the SVG.
    function svgURI(uint256 tokenId) external view returns (string memory);

    /// @notice Retrieves the current traits for a token.
    /// @param tokenId The ID of the token to retrieve traits.
    /// @return An array of trait values assigned to the specified token.
    function getTraits(
        uint256 tokenId
    ) external view returns (uint256[] memory);

    /// @notice Retrieves the current trait tokens (token ID and contract address) associated with a token.
    /// @param tokenId The ID of the token to retrieve trait tokens.
    /// @return An array of traitToken structs representing trait token data for the specified token.
    function getTraitTokens(
        uint256 tokenId
    ) external view returns (traitToken[] memory);

    /// @notice Retrieves the layer URI based on the specified layer and trait value.
    /// @param layer The target layer.
    /// @param trait The trait value for the specified layer.
    /// @return The URI string of the corresponding layer.
    function getURIbyLayer(
        uint256 layer,
        uint256 trait
    ) external view returns (string memory);
}