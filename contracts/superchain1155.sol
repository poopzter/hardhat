// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {Base1155} from "./base1155.sol";
import {IL2ToL2CrossDomainMessenger} from "@eth-optimism/contracts-bedrock/src/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "@eth-optimism/contracts-bedrock/src/libraries/Predeploys.sol";

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

/// @notice Thrown when a function is called by an address other than the L2ToL2CrossDomainMessenger.
error CallerNotL2ToL2CrossDomainMessenger();

/// @notice Thrown when the cross-domain sender is not this contract's address on another chain.
error InvalidCrossDomainSender();

/// @notice Thrown when attempting to hit to an invalid chain
error InvalidDestination();

contract Superchain1155 is Base1155 {
  /// @dev The L2 to L2 cross domain messenger predeploy to handle message passing
  IL2ToL2CrossDomainMessenger internal messenger =
      IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

  /// @dev Modifier to restrict a function to only be a cross-domain callback into this contract
  modifier onlyCrossDomainCallback() {
    _onlyCrossDomain();

    _;
  }

  modifier onlyCrossDomainOrHasRole(bytes32 role) {
    if (!hasRole(role, _msgSender())) {
      _onlyCrossDomain();
    }

      _;
  }

  event SafeCrossTransferFrom(uint256 chainId, address from, address to, uint256 id, uint256 amount, bytes data);
  event CrossMint(address to, uint256 id, uint256 amount, bytes data);

  uint256 _parentChainId;
  uint256[] _childChainIds;

  constructor(
      uint256 parentChainId,
      string memory name_,
      string memory symbol_,
      address defaultAdmin,
      address uriSetter,
      address pauser,
      address minter,
      address royaltyRecipient,
      uint96 feeNumerator
  ) Base1155(name_, symbol_, defaultAdmin, uriSetter, pauser, minter, royaltyRecipient, feeNumerator) {
      _parentChainId = parentChainId;
      if (block.chainid != parentChainId) {
        messenger.sendMessage(parentChainId, address(this), abi.encodeCall(this.addClientChainIds, (block.chainid)));
      }
  }

  function _onlyCrossDomain() internal view {
      if (msg.sender != address(messenger)) revert CallerNotL2ToL2CrossDomainMessenger();
      if (messenger.crossDomainMessageSender() != address(this)) revert InvalidCrossDomainSender();
  }

  function addClientChainIds(uint256 chainId) external virtual onlyCrossDomainOrHasRole(DEFAULT_ADMIN_ROLE) {
    require(block.chainid == _parentChainId, "Can only be called from parentChainId.");
    require(chainId != _parentChainId, "Invalid chainId.");
    require(_findChainIdIndex(chainId) == _childChainIds.length, "The chainId is duplicated with an existing one.");
    
    _childChainIds.push(chainId);

    string memory uri_ = uri(0);
    if (bytes(uri_).length > 0) {
      messenger.sendMessage(chainId, address(this), abi.encodeCall(this.setURI, (uri_)));
    }
  }

  function removeClientChainIds(uint256 chainId) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    require(block.chainid == _parentChainId, "Can only be called from parentChainId.");

    uint256 index = _findChainIdIndex(chainId);
    _removeChainIdByIndex(index);
  }

  function setURI(string memory newuri) public override {
    if (block.chainid == _parentChainId) {
      if (!hasRole(URI_SETTER_ROLE, _msgSender())) revert AccessControlUnauthorizedAccount(_msgSender(), URI_SETTER_ROLE);
    } else {
      _onlyCrossDomain();
    }
    _setURI(newuri);

    if (block.chainid == _parentChainId) {
      _syncURI(newuri);
    }
  }

  function getChildChainIds() external virtual view returns (uint256[] memory) {
    return _childChainIds;
  }

  function _syncURI(string memory newuri) internal {
    for (uint i = 0; i < _childChainIds.length; i++) {
      messenger.sendMessage(_childChainIds[i], address(this), abi.encodeCall(this.setURI, (newuri)));
    }
  }

  function crossMint(address to, uint256 id, uint256 amount, bytes memory data) external virtual onlyCrossDomainCallback{
     _mint(to, id, amount, data);

     emit CrossMint(to, id, amount, data);
  }

  function safeCrossTransferFrom(uint256 chainId, address from, address to, uint256 id, uint256 amount, bytes memory data) external virtual {
    address sender = _msgSender();
    if (from != sender && !isApprovedForAll(from, sender)) {
      revert ERC1155MissingApprovalForAll(sender, from);
    }
    _safeCrossTransferFrom(chainId, from, to, id, amount, data);
  }

  function _safeCrossTransferFrom(uint256 chainId, address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
    require(block.chainid != chainId, "Can't perform a cross-chain transfer to the same chain.");
    require(_isSupportedChain(chainId), "Invalid chainId.");
    if (to == address(0)) revert ERC1155InvalidReceiver(address(0));
    if (from == address(0)) revert ERC1155InvalidSender(address(0));
    if (to.code.length > 0) revert ERC1155InvalidReceiver(to); // Only allow cross-chain transfers to EOA wallets.

    _burn(from, id, amount); // Burn before calling sendMessage, so if insufficientBalance occurs, it will be detected at this point.
    messenger.sendMessage(chainId, address(this), abi.encodeCall(this.crossMint, (to, id, amount, data)));

    emit SafeCrossTransferFrom(chainId, from, to, id, amount, data);
  }

  function _isSupportedChain(uint256 chainId) internal view returns (bool) {
    if (chainId == _parentChainId) return true;
    else if (_findChainIdIndex(chainId) < _childChainIds.length) return true;
    else return false;
  }

  // Helper function to find the index of a chainId
  function _findChainIdIndex(uint256 value) internal view returns (uint256) {
    for (uint256 i = 0; i < _childChainIds.length; i++) {
      if (_childChainIds[i] == value) {
        return i;
      }
    }
    return _childChainIds.length; // Not found
  }

  // Function to remove an chainId by index
  function _removeChainIdByIndex(uint256 index) internal {
    require(index > 0 && index < _childChainIds.length, "ChainId not found.");
    for (uint256 i = index; i < _childChainIds.length - 1; i++) {
      _childChainIds[i] = _childChainIds[i + 1];
    }
    _childChainIds.pop();
  }
}
