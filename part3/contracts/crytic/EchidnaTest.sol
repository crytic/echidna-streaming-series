pragma solidity ^0.6.0;

import "./Setup.sol";

contract EchidnaTest is Setup {
    event logUints(uint unit1, uint unit2);

    
    function mintLiquidity(uint amount1, uint amount2) public returns (bool,uint,uint)  {
        //precondition
        if(!notInitialLiquidityMint) {
            amount1 = _between(amount1, 1000, uint(-1));
            amount2 = _between(amount2, 1000, uint(-1));
            notInitialLiquidityMint = true;
        }

        _init(amount1, amount2);

        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        (uint reserve0Before, uint reserve1Before,) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;
        
        (bool success1,) = user.proxy(address(testToken1),abi.encodeWithSelector(testToken1.transfer.selector, address(pair),amount1));
        (bool success2,) = user.proxy(address(testToken2),abi.encodeWithSelector(testToken2.transfer.selector, address(pair),amount2));
        require(success1 && success2);

        //Action:
        (bool success3,) = user.proxy(address(pair),abi.encodeWithSelector(bytes4(keccak256("mint(address)")), address(user)));
        
        return (success3, lpTokenBalanceBefore, kBefore);
    }
    //Allows to mint liquidity not just on initial scenario and extend coverage
    function testProvideLiquidity(uint amount1, uint amount2) public {
        //perform preconditions and action on mintLiquidity
        (bool success, uint lpTokenBalanceBefore, uint kBefore) = mintLiquidity(amount1, amount2);
        //Postconditions:
        if(success) {
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));
            (uint reserve0After, uint reserve1After,) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(lpTokenBalanceBefore < lpTokenBalanceAfter);
            assert(kBefore < kAfter);

        }

    }
    
    function testSwap(uint amount1, uint amount2) public {
        
        if(!completed) {
            _init(amount1, amount2);
        }
        
        //Preconditions
        pair.sync(); // we matched the balances with reserves
        require(pair.balanceOf(address(user)) > 0); //there is liquidity for the swap
        //Call:
        (bool success1,) = user.proxy(address(pair), abi.encodeWithSelector(pair.swap.selector, amount1,amount2,address(user),""));

        //Postcondition:
        assert(!success1); //call should never succeed
    }
    
}
