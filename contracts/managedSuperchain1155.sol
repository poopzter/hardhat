// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {Superchain1155} from "./superchain1155.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

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

contract ManagedSuperchain1155 is Superchain1155 {
    event AuthorityUpdated(address authority);

    error AccessManagedInvalidAuthority(address authority);

    address private _authority;

    constructor(uint256 parentChainId, address authority_, string memory name_, string memory symbol_, address defaultAdmin, address uriSetter, address pauser, address minter, address royaltyRecipient, uint96 feeNumerator) 
        Superchain1155(parentChainId, name_, symbol_, defaultAdmin, uriSetter, pauser, minter, royaltyRecipient, feeNumerator)
    {
       _setAuthority(authority_);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override(ERC1155) {
        address sender = _msgSender();
        if (from != sender && _authority != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    function authority() public view virtual returns (address) {
        return _authority;
    }

    function setAuthority(address newAuthority) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newAuthority.code.length == 0) {
            revert AccessManagedInvalidAuthority(newAuthority);
        }
        _setAuthority(newAuthority);
    }

    function _setAuthority(address newAuthority) internal {
        _authority = newAuthority;
        emit AuthorityUpdated(newAuthority);
    }
}
