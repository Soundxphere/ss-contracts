// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import "../Bloc.sol";


library MusicBlocLib {
    function deployMusicBloc(bytes32 salt) internal returns (address) {
        bytes memory bytecode = type(MusicBloc).creationCode;
        address musicBloc = Create2.computeAddress(salt, keccak256(bytecode));
        Create2.deploy(0, salt, bytecode);
        return musicBloc;
    }
}


