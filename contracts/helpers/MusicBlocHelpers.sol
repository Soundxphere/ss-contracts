// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MusicBlocHelpers {
    enum State {
        Active,
        Complete,
        Closed
    }

    struct Seed {
        bytes32 id;
        string seed;
        bool merged;
        State state;
        uint256 boxID;
    }

    function contains(
        uint256[] memory array,
        uint256 element
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }

    function isContributor(
        address[] memory contributors,
        address sender
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < contributors.length; i++) {
            if (contributors[i] == sender) {
                return true;
            }
        }
        return false;
    }

    function appendSeed(
        Seed[] memory seeds,
        Seed memory newSeed
    ) internal pure returns (Seed[] memory) {
        Seed[] memory newSeeds = new Seed[](seeds.length + 1);

        for (uint256 i = 0; i < seeds.length; i++) {
            newSeeds[i] = seeds[i];
        }

        newSeeds[seeds.length] = newSeed;

        return newSeeds;
    }
}
