// IMusicBloc.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMusicBlocFactory {
    function deployBloc(bytes32 salt) external returns  (address);

    function initBloc(
        address musicBloc,
        address sender,
        string memory cid,
        string memory seed,
        uint256 blocAmount
    ) external;

    // function initialize(
    //     address _admin,
    //     string memory _cid,
    //     uint256 _maxStakeRequirement,
    //     address soundSphereAddress,
    //     string memory seed
    // ) external;
}
