pragma solidity ^0.6.0;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {
    using SafeMath for uint;
    event logUints(uint kBefore, uint kAfter);
    function testProvideLiquidityInvariants(uint amount1, uint amount2) public {
        //PRECONDITIONS:
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2, 1000, uint(-1));
        if(!complete) {
            _init(amount1,amount2);
        }
        
        uint pairBalanceBefore = testPair.balanceOf(address(user));
        
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        
        uint kBefore = reserve1Before * reserve2Before;
       
        //CALL:
        
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.addLiquidity.selector, address(testToken1), address(testToken2), amount1, amount2, 0, 0, address(user), uint(-1)));
        
        //POSTCONDITIONS
       
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint pairBalanceAfter = testPair.balanceOf(address(user));
            uint kAfter = reserve1After*reserve2After;
            assert(kBefore < kAfter);
            assert(pairBalanceBefore < pairBalanceAfter);
        }
       
        
    }
   
    function testSwapTokens(uint swapAmountIn) public {
       //PRECONDITIONS:

       if(!complete) {
            _init(swapAmountIn,swapAmountIn);
        }
        
        address[] memory path = new address[](2);
        path[0] = address(testToken1);
        path[1] = address(testToken2);

        uint prevBal1 = UniswapV2ERC20(path[0]).balanceOf(address(user));
        uint prevBal2 = UniswapV2ERC20(path[1]).balanceOf(address(user));

        require(prevBal1 > 0);
        swapAmountIn = _between(swapAmountIn, 1, prevBal1);
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        uint kBefore = reserve1Before * reserve2Before; 
        //CALL: 
        (bool success, ) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, swapAmountIn,0,path,address(user),uint(-1)));
        //POSTCONDITIONS:
           
        if(success) {
            uint balance1After = UniswapV2ERC20(path[0]).balanceOf(address(user));
            uint balance2After  = UniswapV2ERC20(path[1]).balanceOf(address(user));
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint kAfter = reserve1After*reserve2After;
            emit logUints(kBefore, kAfter);
            assert(kBefore <= kAfter); 
            assert(prevBal2 < balance2After);
            assert(prevBal1 > balance1After);
            
        }
       
        
    }

    function testRemoveLiquidityInvariants(uint lpAmount) public {
        //PRECONDITIONS:

        uint pairBalanceBefore = testPair.balanceOf(address(user));
        //user needs some LP tokens to burn
        require(pairBalanceBefore > 0);
        lpAmount = _between(lpAmount, 1, pairBalanceBefore);
        
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        //need to provide more than min liquidity
        uint kBefore = reserve1Before * reserve2Before;
       (bool success1,) = user.proxy(address(testPair),abi.encodeWithSelector(testPair.approve.selector,address(router),uint(-1)));
        require(success1);
        //CALL:

        
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.removeLiquidity.selector, address(testToken1), address(testToken2),lpAmount, 0, 0, address(user), uint(-1)));
        
        //POSTCONDITIONS
        
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint pairBalanceAfter = testPair.balanceOf(address(user));
            uint kAfter = reserve1After*reserve2After;
            assert(kBefore > kAfter);
            assert(pairBalanceBefore > pairBalanceAfter);
        }
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) 
    {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) 
    {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    /*
    Swapping x of testToken1 for y token of testToken2 and back should (roughly) give user x of testToken1.
    The following function checks this condition by assessing that the resulting x is no more than 3% from the original x.
    
    However, this condition may be false when the pool has roughly the same amount of A and B and user swaps minimal amount of tokens.
    For instance, if pool consists of:
    - 1000 A
    - 1500 B
    then user can swap 2 A for 2 B (1002 * 1497 = 1 499 994 < 1 500 000 = k, so the user won't get 3 B).
    Then, while user swaps back 2 B in the pool, he will get only 1 A, which is 50% loss from initial 2 A. 

    Similar situation may happen if the user pays for some constant amount of testToken2 more than he needs to.
    For instance, consider a pool with:
    - 20 000 of token A
    - 5 of token B
    Then, k = 100 000. If user pays 10 000 of A, we will get only 1 token B (since otherwise new k < 100 000).
    Now, k = 120 000, and the pool consists of 30 000 A and 4 B. 
    If he swaps back 1 B for A, he gets only 6 000 A back (pool consists of 5 B and 24 000 A and k stays the same).
    So, after the trades, he lost 4 000 of A, which is 40% of his initial balance.
    But this wouldn't happen if user swapped initially 5 000 of A for 1 B.
    
    To prevent such situations, the following function imposes following limits on the user's input:
    1. It has to be greater than MINIMUM_AMOUNT = 100.
    2. For some amount y of testToken2, it has to be minimal among all inputs giving the user y testTokens2 from the swap.
    */
    function testPathIndependenceForSwaps(uint x) public
    {
        // PRECONDITIONS:
        if (!complete) 
            _init(1_000_000_000, 1_000_000_000);

         (uint reserve1, uint reserve2) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        // if reserve1 or reserve2 <= 1, then we cannot even make a swap
        require(reserve1 > 1);
        require(reserve2 > 1);

        uint MINIMUM_AMOUNT = 100;
        uint userBalance1 = testToken1.balanceOf(address(user));
        require(userBalance1 > MINIMUM_AMOUNT);

        x = _between(x, MINIMUM_AMOUNT, uint(-1) / 100); // uint(-1) / 100 needed in POSTCONDITIONS to avoid overflow
        x = _between(x, MINIMUM_AMOUNT, userBalance1);
        
        // use optimal x - it makes no sense to pay more for a given amount of tokens than necessary
        // nor it makes sense to "buy" 0 tokens
        // scope created to prevent "stack too deep" error
        {
            uint yOut = getAmountOut(x, reserve1, reserve2);
            if (yOut == 0)
                yOut = 1;
            // x can only decrease here
            x = getAmountIn(yOut, reserve1, reserve2);
        }
        address[] memory path12 = new address[](2);
        path12[0] = address(testToken1);
        path12[1] = address(testToken2);
        address[] memory path21 = new address[](2);
        path21[0] = address(testToken2);
        path21[1] = address(testToken1);
        
        bool success;
        bytes memory returnData;
        uint[] memory amounts;
        uint xOut;
        uint y;

        // CALLS:
        (success, returnData) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, x, 0, path12, address(user), uint(-1)));
        if (!success)
            return;
        amounts = abi.decode(returnData, (uint[]));
        // y should be the same as yOut computed previously
        y = amounts[1];
        (success, returnData) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, y, 0, path21, address(user), uint(-1)));
        if (!success)
            return;
        amounts = abi.decode(returnData, (uint[]));
        xOut = amounts[1];

        // POSTCONDITIONS:
        assert(x > xOut); // user cannot get more than he gave
        // 100 * (x - xOut) will not overflow since we constrained x to be < uint(-1) / 100 before
        assert((x - xOut) * 100 <= 3 * x); // (x - xOut) / x <= 0.03; no more than 3% loss of funds
    }
}