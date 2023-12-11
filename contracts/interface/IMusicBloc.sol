// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMusicBloc {
    function deployBloc(bytes32 salt) external;

    function initBloc(
        address musicBloc,
        address sender,
        string memory cid,
        string memory seed,
        uint256 blocAmount
    ) external;



    function initialize(
        address _admin,
        string memory _cid,
        address soundSphereAddress,
        string memory seed
    ) external;

    function createSeedBox(
        string calldata _cid,
        address[] calldata _contributors,
        address creator
    ) external returns (uint256);

    function plantSeed(
        uint256 _seedBoxId,
        address sender
    ) external returns (bytes32, uint256);

    function completeSeed(
        uint256 _seedBoxId,
        bytes32 _seedId,
        string memory _seed,
        address sender
    ) external;

    function mergeSeed(bytes32 _seedId, bool _release, address sender) external;

    function postStatus(
        uint256 _seedBoxId,
        string memory _message,
        address _sender
    ) external;

    function getBlocMetadata()
        external
        view
        returns (string memory, bool, uint256, uint256);

    function getAllSeedBoxes() external view returns (uint256[] memory);

    function getSeedsByRound(
        uint256 _round
    ) external view returns (bytes32[] memory);

    function getBoxIdBySeedId(bytes32 _seedId) external returns (uint256);
}
