pragma solidity ^0.6.0;

import "./Setup.sol";

contract EchidnaTest is Setup {
    function testProvideLiquidity(uint amount1, uint amount2) public {
        //Preconditions: 
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2, 1000, uint(-1));

        if(!completed) {
            _mintTokens(amount1, amount2);
        }
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        (uint reserve0Before, uint reserve1Before,) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;

        (bool success1,) = user.proxy(address(testToken1),abi.encodeWithSelector(testToken1.transfer.selector, address(pair),amount1));
        (bool success2,) = user.proxy(address(testToken2),abi.encodeWithSelector(testToken2.transfer.selector, address(pair),amount2));
        require(success1 && success2);

        //Action:
        (bool success3,) = user.proxy(address(pair),abi.encodeWithSelector(bytes4(keccak256("mint(address)")), address(user)));
        
        //Postconditions:
        if(success3) {
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));
            (uint reserve0After, uint reserve1After,) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(lpTokenBalanceBefore < lpTokenBalanceAfter);
            assert(kBefore < kAfter);

        }


    }

    function testInitialLiquidity(uint amount1, uint amount2) public {
        // Precondition: user attempts to create a new pair without supplying minimum liquidity
        require(pair.totalSupply() == 0);
        amount1 = _between(amount1, 1, 1000);
        amount2 = _between(amount2, 1, 1000);

        if(!completed) {
            _mintTokens(amount1, amount2);
        }
        (bool success1, ) = user.proxy(address(testToken1), abi.encodeWithSelector(testToken1.transfer.selector, address(pair), amount1));
        (bool success2, ) = user.proxy(address(testToken2), abi.encodeWithSelector(testToken2.transfer.selector, address(pair), amount2));
        require(success1 && success2);

        // Action: attempt to get LP tokens
        (bool success3, ) = user.proxy(address(pair), abi.encodeWithSelector(bytes4(keccak256("mint(address)")), address(user)));

        // Postconditions:
        assert(!success3); // Since minimum liquidity was not provided, mint should revert with 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED'
        assert(pair.balanceOf(address(user)) == 0); // User should not be awarded any LP tokens
    }
}