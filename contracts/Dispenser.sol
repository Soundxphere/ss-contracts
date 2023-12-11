// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract IERC20 {
    function drip(address to) external {}
}

contract TokenDispenser is Ownable(msg.sender) {
    IERC20 public token;
    mapping(address => uint256) public lastMintTime;

    uint256 public mintCooldown = 1 days; // 24 hours cooldown period

    event FaucetSent(address indexed recipient, uint256 amount);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress); //tokenAddress
    }
    

    function setMintCooldown(uint256 _cooldown) external onlyOwner {
        mintCooldown = _cooldown;
    }

    function sendFaucet() external {
        require(
            lastMintTime[msg.sender] + mintCooldown < block.timestamp,
            "Cooldown not elapsed"
        );
        token.drip(msg.sender);
        // Update the last mint time for the recipient
        lastMintTime[msg.sender] = block.timestamp;
        emit FaucetSent(msg.sender, 1e18);
    }
}



// Sepolia = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
// Polygon = 0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40