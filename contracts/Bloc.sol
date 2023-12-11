// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {MusicBloc} from "./library/MusicBloc.sol";

contract Bloc is Ownable(msg.sender), Initializable, AccessControl {
    uint256 private lastSeedBoxId;
    uint256 private statusCounter;
    uint256 public currentRound;
    string public cid;
    bool public released;

    enum State {
        Active,
        Complete,
        Closed
    }

    struct SeedBox {
        uint256 id;
        string cid;
        uint256[] participatedRounds;
        address[] contributors;
        uint256 totalShares;
        address creator;
        mapping(uint256 => bytes32[]) seedsByRound;
    }

    struct SeedBoxInfo {
        uint256 id;
        string cid;
        address[] contributors;
        uint256 totalShares;
        uint256[] participatedRounds;
        address creator;
    }

    struct SeedBoxMintProposal {
        bytes32 hash;
        address creator;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    struct Status {
        uint256 boxID;
        uint256 id;
        string message;
        address author;
    }

    mapping(uint256 => SeedBox) public seedBoxes;
    mapping(uint256 => mapping(bytes32 => MusicBloc.Seed)) public roundSeeds;
    mapping(uint256 => Status) public statuses;

    modifier onlyBlocAdmin(address sender) {
        _checkOnlyBlocAdmin(sender);
        _;
    }

    modifier onlyCreatorOrContributor(address _sender, uint256 _seedBoxId) {
        SeedBox storage seedBox = seedBoxes[_seedBoxId];
        require(
            MusicBloc.isContributor(seedBox.contributors, _sender) ||
                _sender == seedBox.creator,
            "Not a creator of this seedbox"
        );
        _;
    }

    function initialize(
        address admin,
        string memory _cid,
        address soundSphereAddress,
        string memory seed
    ) public initializer {
        _initBloc(admin, _cid, seed);
        transferOwnership(soundSphereAddress);
    }

    function createSeedBox(
        string memory _cid,
        address[] memory _contributors,
        address creator
    ) external onlyOwner returns (uint256) {
        uint256 seedBoxId = ++lastSeedBoxId;
        SeedBox storage newSeedBox = seedBoxes[seedBoxId];
        newSeedBox.id = seedBoxId;
        newSeedBox.cid = _cid;
        newSeedBox.contributors = _contributors;
        newSeedBox.creator = creator;
        return seedBoxId;
    }

    function plantSeed(
        uint256 _seedBoxId,
        address sender
    )
        external
        onlyOwner
        onlyCreatorOrContributor(sender, _seedBoxId)
        returns (bytes32, uint256)
    {
        require(released == false, "Bloc is finished");
        SeedBox storage seedBox = seedBoxes[_seedBoxId];
        require(seedBox.id != 0, "Seed box not found");
        bytes32 seedId = keccak256(abi.encodePacked(currentRound, _seedBoxId));

        require(
            roundSeeds[currentRound][seedId].id == 0 && seedId.length > 0,
            "Seed invalid or already planted for this round"
        );

        MusicBloc.Seed storage newSeed = roundSeeds[currentRound][seedId];
        newSeed.id = seedId;
        newSeed.state = MusicBloc.State.Active;

        newSeed.boxID = _seedBoxId;
        newSeed.seed = "";
        newSeed.merged = false;

        seedBox.seedsByRound[currentRound].push(seedId);
        if (!MusicBloc.contains(seedBox.participatedRounds, currentRound)) {
            seedBox.participatedRounds.push(currentRound);
        }
        return (seedId, currentRound);
    }

    function completeSeed(
        uint256 _seedBoxId,
        bytes32 _seedId,
        string memory _seed,
        address sender
    ) external onlyOwner onlyCreatorOrContributor(sender, _seedBoxId) {
        require(released == false, "Bloc is finished");
        SeedBox storage seedBox = seedBoxes[_seedBoxId];
        require(seedBox.id != 0, "Seed box not found");

        MusicBloc.Seed storage seed = roundSeeds[currentRound][_seedId];

        require(seed.id != 0, "Seed not found");

        require(seedBox.id == seed.boxID, "Invalid seed box");

        // Update the state of the seed to completed
        seed.seed = _seed;
        seed.state = MusicBloc.State.Complete;
    }

    //Only Block Admin Can Merge Seed
    function mergeSeed(
        bytes32 _seedId,
        bool _release,
        address sender
    ) external onlyOwner onlyBlocAdmin(sender) {
        require(released == false, "Bloc is finished");
        MusicBloc.Seed storage seed = roundSeeds[currentRound][_seedId];
        require(seed.id != 0, "Seed not found");
        seed.merged = true;
        if (_release) {
            released = true;
        } else {
            currentRound++;
        }
    }

    function postStatus(
        uint256 _seedBoxId,
        string memory _message,
        address sender
    ) external onlyOwner onlyCreatorOrContributor(sender, _seedBoxId) {
        SeedBox storage seedBox = seedBoxes[_seedBoxId];
        require(seedBox.id != 0, "Seed box not found");
        require(
            MusicBloc.isContributor(seedBox.contributors, sender),
            "Not a contributor"
        );

        // Increment status counter for a unique status ID
        uint256 newStatusId = ++statusCounter;

        Status storage newStatus = statuses[newStatusId];
        newStatus.boxID = _seedBoxId;
        newStatus.id = newStatusId;
        newStatus.message = _message; // cid to be updated
        newStatus.author = sender;
    }

    function getBlocMetadata()
        external
        view
        returns (string memory, bool, uint256)
    {
        return (cid, released, currentRound);
    }

    function getAllSeedBoxes() external view returns (SeedBoxInfo[] memory) {
        SeedBoxInfo[] memory seedBoxesList = new SeedBoxInfo[](lastSeedBoxId);
        for (uint256 i = 0; i < lastSeedBoxId; i++) {
            SeedBox storage seedBox = seedBoxes[i];
            seedBoxesList[i].id = seedBox.id;
            seedBoxesList[i].contributors = seedBox.contributors;
            seedBoxesList[i].totalShares = seedBox.totalShares;
            seedBoxesList[i].participatedRounds = seedBox.participatedRounds;
        }

        return seedBoxesList;
    }

    function getSeedsByRound(
        uint256 round
    ) external view returns (MusicBloc.Seed[] memory) {
        uint256 seedBoxCount = lastSeedBoxId;
        MusicBloc.Seed[] memory seeds;

        for (uint256 i = 1; i <= seedBoxCount; i++) {
            bytes32[] memory seedIds = seedBoxes[i].seedsByRound[round];

            for (uint256 j = 0; j < seedIds.length; j++) {
                MusicBloc.Seed memory seed = roundSeeds[round][seedIds[j]];
                seeds = MusicBloc.appendSeed(seeds, seed);
            }
        }

        return seeds;
    }

    function getBoxIdBySeedId(bytes32 _seedId) external view returns (uint256) {
        return roundSeeds[currentRound][_seedId].boxID;
    }

    function _initBloc(
        address _admin,
        string memory _cid,
        string memory _seed
    ) internal {
        require(currentRound == 0, "Bloc initialized already");
        currentRound = 0;
        uint256 seedBoxId = ++lastSeedBoxId;
        uint256 round = currentRound;
        //create owners box
        SeedBox storage seedBox = seedBoxes[seedBoxId];
        seedBox.id = seedBoxId;
        seedBox.cid = _cid;
        seedBox.contributors = new address[](0);
        seedBox.contributors.push(_admin);
        seedBox.creator = _admin;

        seedBox.totalShares = 100;

        bytes32 MANAGER_ROLE = keccak256(abi.encodePacked(address(this)));
        bytes32 ADMIN_ROLE = keccak256(
            abi.encodePacked(address(this), "admin")
        );

        // Grant admin roles to the musicBloc creator
        _grantRole(ADMIN_ROLE, _admin);

        // Set admin role for MANAGER_ROLE
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);

        //plant completed seed to the current round
        bytes32 seedId = keccak256(abi.encodePacked(currentRound, seedBoxId));

        MusicBloc.Seed storage newSeed = roundSeeds[round][seedId];

        newSeed.id = seedId;
        newSeed.state = MusicBloc.State.Complete;
        newSeed.boxID = seedBoxId;
        newSeed.seed = _seed;
        newSeed.merged = true;

        seedBox.seedsByRound[round].push(seedId);
        seedBox.participatedRounds.push(round);
        cid = _cid;
        released = false;
        currentRound++;
    }

    function _checkOnlyBlocAdmin(address sender) internal view {
        if (!_isBlocAdmin(sender)) revert("UNAUTHORIZED");
    }

    function _isBlocAdmin(address _address) internal view returns (bool) {
        bytes32 ADMIN_ROLE = keccak256(
            abi.encodePacked(address(this), "admin")
        );
        return hasRole(ADMIN_ROLE, _address);
    }
}
