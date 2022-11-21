pragma solidity ^0.8.17;

import "./Staker.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender;
        //_spendAllowance(from, spender, amount); // allowance was disabled
        _transfer(from, to, amount);
        return true;
    }
}

// We are using an external testing methodology
contract EchidnaSolution {

    Staker stakerContract;
    MockERC20 tokenToStake;

    // setup
    constructor() {
        // Create the token
        tokenToStake = new MockERC20("Token", "TOK");
        // Mint this address a bunch of tokens
        tokenToStake.mint(address(this), type(uint128).max);
        // Create target system
        stakerContract = new Staker(address(tokenToStake));
    }

    // function-level invariants
    function testStake(uint256 _amount) public {
        // Pre-condition
        require(tokenToStake.balanceOf(address(this)) > 0);
        // Optimization: amount is now bounded between [1, balanceOf(msg.sender)]
        uint256 amount = 1 + (_amount % (tokenToStake.balanceOf(address(this))));
        // State before the "action"
        uint256 preStakedBalance = stakerContract.stakedBalances(address(this));
        // Action
        try stakerContract.stake(amount) returns(uint256 stakedAmount) {
            // Post-condition
            assert(stakerContract.stakedBalances(address(this)) == preStakedBalance + stakedAmount); 
        } catch (bytes memory err) {
            // Post-condition
            assert(false);
        }
    }

    function testUnstake(uint256 _stakedAmount) public {
        // Pre-condition
        require(stakerContract.stakedBalances(address(this)) > 0);
        // Optimization: amount is now bounded between [1, stakedBalance[address(this)]]
        uint256 stakedAmount = 1 + (_stakedAmount % (stakerContract.stakedBalances(address(this))));
        // State before the "action"
        uint256 preTokenBalance = tokenToStake.balanceOf(address(this));
        // Action
        try stakerContract.unstake(stakedAmount) returns(uint256 amount) {
            // Post-condition
            assert(tokenToStake.balanceOf(address(this)) == preTokenBalance + amount); 
        } catch (bytes memory err) {
            // Post-condition
            assert(false);
        } 
    }
}