// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SSoundSphere is OwnerIsCreator {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();

    IRouterClient private s_router;
    address private sst_token;
    LinkTokenInterface private s_linkToken;
    address private s_receiver;
    uint64 private s_destinationChainSelector;

    constructor(
        address _router,
        address _link,
        address _receiver,
        // address _sstToken,
        uint64 _destinationChain
    ) {
        s_router = IRouterClient(_router);
        s_linkToken = LinkTokenInterface(_link);
        s_receiver = _receiver;
        s_destinationChainSelector = _destinationChain;
        // sst_token = _sstToken;
        transferOwnership(_receiver);
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

    function sendCreateMusicBloc(
        string memory cid,
        uint256 seedboxCap,
        string memory seed
    ) external returns (uint256 fees, bytes32 messageId) {
        CreateMusicBlocParams memory params = CreateMusicBlocParams({
            cid: cid,
            seedboxCap: seedboxCap,
            seed: seed,
            sender: msg.sender
        });

        return sendMessage(0, abi.encode(params));
    }

    function sendJoinMusicBloc(
        address blocAddress,
        string memory cid,
        address[] memory contributors
    ) external returns (uint256 fees, bytes32 messageId) {
        JoinMusicBlocParams memory params = JoinMusicBlocParams({
            blocAddress: blocAddress,
            cid: cid,
            contributors: contributors,
            sender: msg.sender
        });

        return sendMessage(1, abi.encode(params));
    }

    function sendStartContribution(address blocAddress, uint256 seedBoxId)
        external
        returns (uint256 fees, bytes32 messageId)
    {
        StartContributionParams memory params = StartContributionParams({
            blocAddress: blocAddress,
            seedBoxId: seedBoxId,
            sender: msg.sender
        });

        return sendMessage(2, abi.encode(params));
    }

    function sendMessage(uint8 functionSelector, bytes memory params)
        internal
        returns (uint256 fees, bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage;

        if (functionSelector == 0) {
            evm2AnyMessage = Client.EVM2AnyMessage({
                receiver: abi.encode(s_receiver),
                data: abi.encode(functionSelector, params),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 1_000_000, strict: false})
                ),
                feeToken: address(s_linkToken)
            });
        } else if (functionSelector == 1) {
            evm2AnyMessage = Client.EVM2AnyMessage({
                receiver: abi.encode(s_receiver),
                data: abi.encode(functionSelector, params),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false})
                ),
                feeToken: address(s_linkToken)
            });
        } else if (functionSelector == 2) {
            evm2AnyMessage = Client.EVM2AnyMessage({
                receiver: abi.encode(s_receiver),
                data: abi.encode(functionSelector, params),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false})
                ),
                feeToken: address(s_linkToken)
            });
        } else {
            revert("Invalid function selector. Range is between 0-2");
        }

        fees = s_router.getFee(s_destinationChainSelector, evm2AnyMessage);

        s_linkToken.approve(address(s_router), fees);

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        messageId = s_router.ccipSend(
            s_destinationChainSelector,
            evm2AnyMessage
        );

        return (fees, messageId);
    }

    receive() external payable {}

    function withdrawToken(address _beneficiary) public onlyOwner {
        uint256 amount = LinkTokenInterface(s_linkToken).balanceOf(
            address(this)
        );
        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();
        LinkTokenInterface(s_linkToken).transfer(_beneficiary, amount);
    }
}
