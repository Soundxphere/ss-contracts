// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SoundSphere {
    struct MusicBlocParams {
        string cid;
        string name;
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
        string name;
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
        string name;
        address creator;
    }
}
