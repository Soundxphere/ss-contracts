// IMusicBloc.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISoundSphere {
    function createMusicBloc(
        string memory _cid,
        address[] memory _managers,
        // uint256 blocInitStake,
        uint256 _maxSeedContribution
    ) external;

    function joinMusicBloc(
        address blocAddress,
        string calldata cid,
        address[] calldata contributors
    ) external returns (uint256);

    function startContributoon(
        address blocAddress,
        uint256 _seedBoxId
    ) external returns (bytes32, uint256);

    function completeSeed(
        uint256 _seedBoxId,
        bytes32 _seedId,
        string memory _seed,
        address sender
    ) external;

    function postStatus(
        address blocAddress,
        uint256 _seedBoxId,
        string memory message
    ) external;

    function merge(address blocAddress, bytes32 seedId, bool release) external;
}
