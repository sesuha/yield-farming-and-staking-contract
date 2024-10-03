// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldFarm {
    using SafeMath for uint256;

    IERC20 public stakingToken;
    uint256 public rewardRatePerSecond;
    uint256 public totalStaked;

    struct Staker {
        uint256 stakedAmount;
        uint256 stakeTimestamp;
        uint256 pendingRewards;
    }

    mapping(address => Staker) public stakers;

    constructor(IERC20 _stakingToken, uint256 _rewardRatePerSecond) {
        stakingToken = _stakingToken;
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    event TokensStaked(address indexed user, uint256 amount);

    event TokensWithdrawn(address indexed user, uint256 amount, uint256 rewards);

    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        Staker storage staker = stakers[msg.sender];

        if (staker.stakedAmount > 0) {
            staker.pendingRewards = staker.pendingRewards.add(
                _calculateRewards(msg.sender)
            );
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        staker.stakedAmount = staker.stakedAmount.add(_amount);
        staker.stakeTimestamp = block.timestamp;
        totalStaked = totalStaked.add(_amount);

        emit TokensStaked(msg.sender, _amount);
    }

    function withdrawTokens() external {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedAmount > 0, "No tokens to withdraw");

        uint256 rewards = staker.pendingRewards.add(
            _calculateRewards(msg.sender)
        );

        uint256 amountToWithdraw = staker.stakedAmount;

        staker.stakedAmount = 0;
        staker.pendingRewards = 0;
        staker.stakeTimestamp = 0;
        totalStaked = totalStaked.sub(amountToWithdraw);

        stakingToken.transfer(msg.sender, amountToWithdraw);
        stakingToken.transfer(msg.sender, rewards);

        emit TokensWithdrawn(msg.sender, amountToWithdraw, rewards);
    }

    function _calculateRewards(address _user) internal view returns (uint256) {
        Staker storage staker = stakers[_user];
        uint256 stakedDuration = block.timestamp.sub(staker.stakeTimestamp);
        uint256 rewards = staker.stakedAmount.mul(stakedDuration).mul(rewardRatePerSecond).div(1e18);
        return rewards;
    }

    function getPendingRewards(address _user) external view returns (uint256) {
        Staker storage staker = stakers[_user];
        return staker.pendingRewards.add(_calculateRewards(_user));
    }
}
