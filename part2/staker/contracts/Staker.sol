pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staker {
    // stakedBalances holds the staked balance of a user
    mapping(address => uint256) public stakedBalances;

    IERC20 public tokenToStake;

    // Set the token that will be staked
    constructor(address _tokenToStake) {
        tokenToStake = IERC20(_tokenToStake);
    }

    /// @dev stake function will stake some amount of tokenToStake and update the user balance
    function stake(uint256 amount) public returns(uint256 stakedAmount) {
        // This is not safe, use safeTransferFrom
        bool success = tokenToStake.transferFrom(msg.sender, address(this), amount);
        require(success == true, "transferFrom failed");

        // The exchange rate of token to staked token is 1:1
        stakedAmount = amount;
        // Update the balance of the sender
        stakedBalances[msg.sender] += stakedAmount;
    }

    /// @dev unstake function will unstake some amount and transfer the associated amount of tokenToStake to the user
    function unstake(uint256 stakedAmount) public returns(uint256 amount) {
        // Make sure msg.sender has staked more than stakedAmount
        require(stakedBalances[msg.sender] >= stakedAmount, "Cannot unstake more than you have");
        // Update the balance of the sender
        stakedBalances[msg.sender] -= stakedAmount;
        // You get back what you deposited
        amount = stakedAmount;
        bool success = tokenToStake.transfer(msg.sender, amount);
        require(success == true, "transfer failed");
    }
}