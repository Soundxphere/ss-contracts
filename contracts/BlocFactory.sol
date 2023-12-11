// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Bloc} from "../Bloc.sol";

library MusicBlocLib {
    // address public lastBloc;
    function deployMusicBloc(bytes32 salt) internal returns (address) {
        bytes memory bytecode = type(Bloc).creationCode;
        address musicBloc = Create2.computeAddress(salt, keccak256(bytecode));
        address newMusicBloc = Create2.deploy(0, salt, bytecode);
        // lastBloc = address(newMusicBloc);
        return newMusicBloc;
    }

    // function getLast() public view returns (address) {
    // return lastBloc;
    // }
}
