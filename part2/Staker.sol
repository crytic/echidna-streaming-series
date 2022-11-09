pragma solidity 0.8.1;

contract Staker {
    // stakedBalances holds the staked balance of a user
    mapping(address => uint256) public stakedBalances;

    IERC20 public tokenToStake;

    // Set the token that will be staked
    constructor(address _tokenToStake) {
        require(_tokenToStake != address(0));
        tokenToStake = address(_tokenToStake);
    }

    function stake(uint256 amount) public returns(uint256 stakedAmount) {
        // This is not safe, use safeTransferFrom
        bool success = tokenToStake.transferFrom(msg.sender, address(this), amount);
        require(success == true);

        // The exchange rate of token to staked token is 1:1
        stakedAmount = amount;
        // Update the balance of the sender
        stakedBalances[msg.sender] += stakedAmount;
    }

    function unstake(uint256 stakedAmount) public returns(uint256 amount) {
    // Make sure msg.sender has staked more than stakedAmount
    require(stakedBalances[msg.sender] >= stakedAmount, "Cannot unstake more than you have");
    // Update the balance of the sender
    stakedBalances[msg.sender] -= stakedAmount;
    // You get back what you deposited
    amount = stakedAmount;
    bool success = tokenToStake.transfer(msg.sender, amount);
    require(success == true);
    }
}

contract EchidnaStaker is Staker {

    function testStake(uint256 _amount) public {
        // Pre-condition
        require(tokenToStake.balanceOf(msg.sender) > 0);
        // Optimization: amount is now bounded between [0, balanceOf(msg.sender)]
        uint256 amount = _amount % (tokenToStake.balanceOf(msg.sender) + 1);
        // State before the "action"
        uint256 preStakedBalance = stakedBalances[msg.sender];
        try this.stake(amount) returns(uint256 stakedAmount) {
            // Make sure my staked balance increased
            assert(stakedBalances[msg.sender] == preStakedBalance + amount); 
        } catch (bytes memory err) {
            assert(false);
        }
    }

    function testStake(uint256 _stakedAmount) public {
        // Pre-condition
        require(stakedBalances[msg.sender] > 0);
        // Optimization: amount is now bounded between [0, stakedBalance[msg.sender]]
        uint256 stakedAmount = _stakedAmount % (stakedBalances[msg.sender] + 1);
        // State before the "action"
        uint256 preTokenBalance = tokenToStake.balanceOf(msg.sender);
        try this.unstake(stakedAmount) returns(uint256 amount) {
            // Make sure my staked balance decreased
            assert(tokenToStake.balanceOf(msg.sender) == preTokenBalance + amount); 
        } catch (bytes memory err) {
            assert(false);
        }
    }
}