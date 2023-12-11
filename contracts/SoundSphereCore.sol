// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {MusicBlocLib} from "./DeployMusicBloc.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./interface/IMusicBloc.sol";

contract SoundSphereCore is AutomationCompatibleInterface, CCIPReceiver {
    using MusicBlocLib for *;

    enum Operation {
        createMusicBloc,
        joinMusicBloc,
        startContribution,
        completeSeed,
        postStatus,
        merge
    }

    uint256 public constant maxReleasePeriod = 30 days; //Publish your Bloc in maximum 30 Days
    uint256 public minBlocRequirement;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    bytes32[] public salts;
    uint256 public musicBlocsCounter;
    IERC20 private immutable _asset;
    // IMusicBlocFactory public blocFactory;

    struct MusicBlocParams {
        string cid;
        uint256 seedboxCap;
        address blocAddress;
        address[] contributors;
        uint256 seedBoxId;
        bytes32 seedId;
        string seed;
        address sender;
        string message;
        bool release;
    }

    struct CreateMusicBlocParams {
        string cid;
        uint256 seedboxCap;
        string seed;
        address sender;
    }

    struct JoinMusicBlocParams {
        address blocAddress;
        string cid;
        address[] contributors;
        address sender;
    }

    struct StartContributionParams {
        address blocAddress;
        uint256 seedBoxId;
        address sender;
    }

    struct CompleteSeedParams {
        address blocAddress;
        uint256 seedBoxId;
        bytes32 seedId;
        string seed;
        address sender;
    }

    struct PostStatusParams {
        address blocAddress;
        uint256 seedBoxId;
        string message;
        address sender;
    }

    struct MergeParams {
        address blocAddress;
        bytes32 seedId;
        bool release;
        address sender;
    }

    struct InitBlocParam {
        string seed;
        string cid;
        uint256 blocAmount;
        address creator;
    }

    mapping(uint256 => address) public musicBlocs;
    mapping(bytes32 => InitBlocParam) private initBlocParam;

    //Events
    event CreatingMusicBloc(bytes32 indexed bloc, address indexed creator);
    event NewMusicBloc(address indexed bloc, address indexed creator);
    event JoinedMusicBloc(
        address indexed bloc,
        uint256 indexed seedBox,
        address indexed creator
    );
    event NewSeedStarted(
        address indexed bloc,
        bytes32 indexed seed,
        uint256 indexed round
    );
    event SeedCompleted(address indexed musicBloc, bytes32 indexed seedId);

    event StatusPosted(
        address indexed bloc,
        string indexed message,
        address indexed author
    );
    event Merged(address indexed bloc, bytes32 indexed seedId);

    constructor(
        address router,
        uint256 _minBlocRequirement,
        uint256 updateInterval
    ) CCIPReceiver(router) {
        minBlocRequirement = _minBlocRequirement;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        musicBlocsCounter = 0;
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
    {
        (Operation operation, MusicBlocParams memory params) = decodeMessage(
            any2EvmMessage.data
        );
        if (operation == Operation.createMusicBloc) {
            _createMusicBloc(params);
        } else if (operation == Operation.joinMusicBloc) {
            _joinMusicBloc(params);
        } else if (operation == Operation.startContribution) {
            _startContribution(params);
        } else if (operation == Operation.completeSeed) {
            _completeSeed(params);
        } else if (operation == Operation.postStatus) {
            _postStatus(params);
        } else if (operation == Operation.merge) {
            _merge(params);
        } else {
            revert("INVALID OPERATION");
        }
    }

    //Deploy new MusicBloc Contract
    function createMusicBloc(
        string memory cid,
        string memory seed,
        uint256 blocAmount //use this as staking amount
    ) external {
        require(
            blocAmount >= minBlocRequirement,
            "Staking amount is less than the required minimum"
        );

        bytes32 salt = keccak256(abi.encodePacked(cid, ++musicBlocsCounter));

        address newMusicBloc = deployMusicBloc(salt);
        IMusicBloc(newMusicBloc).initialize(
            msg.sender,
            cid,
            blocAmount,
            address(this),
            seed
        );
        musicBlocs[musicBlocsCounter] = newMusicBloc;
        emit NewMusicBloc(newMusicBloc, msg.sender);
    }

    // Creates new SeedBox in bloc
    function joinMusicBloc(
        address bloc,
        string memory cid,
        address[] memory contributors
    ) external {
        MusicBlocParams memory params = MusicBlocParams(
            cid,
            0,
            bloc,
            contributors,
            0,
            bytes32(0),
            "",
            msg.sender,
            "",
            false
        );
        _joinMusicBloc(params);
    }

    // Plant a new Seed
    function startContribution(address bloc, uint256 seedBox) external {
        MusicBlocParams memory params = MusicBlocParams(
            "",
            0,
            bloc,
            new address[](0),
            seedBox,
            bytes32(0),
            "",
            msg.sender,
            "",
            false
        );
        _startContribution(params);
    }

    // Complete seed / Mint NFT
    function completeSeed(
        address bloc,
        uint256 seedBox,
        bytes32 seedID,
        string memory seed
    ) external {
        MusicBlocParams memory params = MusicBlocParams(
            "",
            0,
            bloc,
            new address[](0),
            seedBox,
            seedID,
            seed,
            msg.sender,
            "",
            false
        );
        _completeSeed(params);
    }

    // Post new Status
    function postStatus(
        address bloc,
        string memory message,
        uint256 seedBox
    ) external {
        MusicBlocParams memory params = MusicBlocParams(
            "",
            0,
            bloc,
            new address[](0),
            seedBox,
            bytes32(0),
            "",
            msg.sender,
            message,
            false
        );
        _postStatus(params);
    }

    function merge(
        address bloc,
        bytes32 seedID,
        bool release
    ) internal {
        MusicBlocParams memory params = MusicBlocParams(
            "",
            0,
            bloc,
            new address[](0),
            0,
            seedID,
            "",
            address(0),
            "",
            release
        );
        _merge(params);
    }

    function _createMusicBloc(MusicBlocParams memory params) internal {
        bytes32 salt = keccak256(
            abi.encodePacked(params.cid, ++musicBlocsCounter)
        );
        salts.push(salt);
        InitBlocParam memory _initParams = InitBlocParam(
            params.seed,
            params.cid,
            params.seedboxCap,
            params.sender
        );
        initBlocParam[salt] = _initParams;
        emit CreatingMusicBloc(salt, params.sender);
    }

    function _joinMusicBloc(MusicBlocParams memory params) internal {
        IMusicBloc musicBloc = IMusicBloc(params.blocAddress);
        uint256 seedBoxId = musicBloc.createSeedBox(
            params.cid,
            params.contributors,
            params.sender
        );
        emit JoinedMusicBloc(params.blocAddress, seedBoxId, params.sender);
    }

    function _startContribution(MusicBlocParams memory params) internal {
        IMusicBloc musicBloc = IMusicBloc(params.blocAddress);
        (bytes32 seedId, uint256 currentRound) = musicBloc.plantSeed(
            params.seedBoxId,
            msg.sender
        );
        emit NewSeedStarted(params.blocAddress, seedId, currentRound);
    }

    function _completeSeed(MusicBlocParams memory params) internal {
        IMusicBloc musicBloc = IMusicBloc(params.blocAddress);
        musicBloc.completeSeed(
            params.seedBoxId,
            params.seedId,
            params.seed,
            params.sender
        );
        emit SeedCompleted(params.blocAddress, params.seedId);
    }

    function _postStatus(MusicBlocParams memory params) internal {
        IMusicBloc musicBloc = IMusicBloc(params.blocAddress);
        musicBloc.postStatus(params.seedBoxId, params.message, params.sender);
        emit StatusPosted(params.blocAddress, params.message, params.sender);
    }

    function _merge(MusicBlocParams memory params) internal {
        IMusicBloc musicBloc = IMusicBloc(params.blocAddress);
        // uint256 seedBoxID = musicBloc.getBoxIdBySeedId(params.seedId);
        musicBloc.mergeSeed(params.seedId, params.release, params.sender);
        emit Merged(params.blocAddress, params.seedId);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded =
            (block.timestamp - lastTimeStamp) > interval &&
            salts.length > 0;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastTimeStamp) > interval && salts.length > 0) {
            // Create a new array to store salts that you want to keep
            bytes32[] memory remainingSalts = new bytes32[](salts.length);

            for (uint256 i = 0; i < salts.length; i++) {
                //deploy musicBloc

                address musicBloc = deployMusicBloc(salts[i]);
                InitBlocParam storage params = initBlocParam[salts[i]];

                //approve Bloc to transfer amount from  vault
                // _asset.approve(musicBloc, params.blocAmount);

                //init Bloc
                IMusicBloc(musicBloc).initialize(
                    params.creator,
                    params.cid,
                    params.blocAmount,
                    address(this), //set soundsphere as owner
                    params.seed
                );

                musicBlocs[musicBlocsCounter] = musicBloc;
                emit NewMusicBloc(musicBloc, params.creator);

                // Don't remove the salt in the loop, just copy it to the new array
                remainingSalts[i] = salts[i];
            }

            // Update the original salts array with the new empty array
            salts = new bytes32[](0);
            lastTimeStamp = block.timestamp;
        }
    }

    function decodeMessage(bytes memory data)
        internal
        pure
        returns (Operation operation, MusicBlocParams memory params)
    {
        (uint8 functionSelector, bytes memory remainingData) = abi.decode(
            data,
            (uint8, bytes)
        );

        operation = Operation(functionSelector);

        if (operation == Operation.createMusicBloc) {
            CreateMusicBlocParams memory createParams = abi.decode(
                remainingData,
                (CreateMusicBlocParams)
            );

            params = MusicBlocParams(
                createParams.cid,
                createParams.seedboxCap,
                address(0),
                new address[](0),
                0,
                bytes32(0),
                createParams.seed,
                createParams.sender,
                "",
                false
            );
        } else if (operation == Operation.joinMusicBloc) {
            JoinMusicBlocParams memory joinParams = abi.decode(
                remainingData,
                (JoinMusicBlocParams)
            );

            params = MusicBlocParams(
                joinParams.cid,
                0,
                joinParams.blocAddress,
                joinParams.contributors,
                0,
                bytes32(0),
                "",
                joinParams.sender,
                "",
                false
            );
        } else if (operation == Operation.startContribution) {
            StartContributionParams memory startParams = abi.decode(
                remainingData,
                (StartContributionParams)
            );

            params = MusicBlocParams(
                "",
                0,
                startParams.blocAddress,
                new address[](0),
                startParams.seedBoxId,
                bytes32(0),
                "",
                startParams.sender,
                "",
                false
            );
        } else if (operation == Operation.completeSeed) {
            CompleteSeedParams memory completeSeedParams = abi.decode(
                remainingData,
                (CompleteSeedParams)
            );

            params = MusicBlocParams(
                "",
                0,
                completeSeedParams.blocAddress,
                new address[](0),
                completeSeedParams.seedBoxId,
                completeSeedParams.seedId,
                completeSeedParams.seed,
                completeSeedParams.sender,
                "",
                false
            );
        } else if (operation == Operation.postStatus) {
            PostStatusParams memory postStatusParams = abi.decode(
                remainingData,
                (PostStatusParams)
            );

            params = MusicBlocParams(
                "",
                0,
                postStatusParams.blocAddress,
                new address[](0),
                postStatusParams.seedBoxId,
                bytes32(0),
                "",
                postStatusParams.sender,
                postStatusParams.message,
                false
            );
        } else if (operation == Operation.merge) {
            MergeParams memory mergeParams = abi.decode(
                remainingData,
                (MergeParams)
            );

            params = MusicBlocParams(
                "",
                0,
                mergeParams.blocAddress,
                new address[](0),
                0,
                mergeParams.seedId,
                "",
                mergeParams.sender,
                "",
                mergeParams.release
            );
        } else {
            revert("Invalid operation");
        }

        return (operation, params);
    }

    function deployMusicBloc(bytes32 salt) internal returns (address) {
        address newMusicBloc = MusicBlocLib.deployMusicBloc(salt);
        return newMusicBloc;
    }
}
// 0xF10F9Cd0dc03b6335629FdE7beEdE708F18eD58A
