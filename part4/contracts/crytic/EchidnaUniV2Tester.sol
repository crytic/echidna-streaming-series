pragma solidity ^0.6.0;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {

    function testProvideLiquidityInvariants(uint amount1, uint amount2) public {
        uint balance1Before = testToken1.balanceOf(address(users[0]));
        uint balance2Before = testToken2.balanceOf(address(users[0]));
        
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        //need to provide more than min liquidity
        uint kBefore = reserve1Before * reserve2Before;
        amount1 = _between(amount1, 10**3, balance1Before); 
        amount2 = _between(amount2, 10**3, balance2Before);
        //CALL:
        (bool success, bytes memory ret) = users[0].proxy(address(router),abi.encodeWithSelector(router.addLiquidity.selector, address(testToken1), address(testToken2), amount1, amount2, 0, 0, address(users[0]), block.timestamp));
        //POSTCONDITIONS
        
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint balance1After = testToken1.balanceOf(address(users[0]));
            uint balance2After  = testToken2.balanceOf(address(users[0]));
            
            uint kAfter = reserve1After*reserve2After;
            assert(kBefore < kAfter);
            assert(balance1Before > balance1After && balance2Before > balance2After);

        }
        
    }
    function testSwapInvariants(uint swapAmountIn) public {
        //here testPair.balanceOf(users[0]) represents the total liquidity in the pool - we can't swap more than that 
        swapAmountIn = _between(swapAmountIn, 1, testPair.balanceOf(address(users[0]))); //need to swap at least 1 wei
       //PRECONDITIONS:
        uint balance1Before = testToken1.balanceOf(address(users[1]));
        uint balance2Before = testToken2.balanceOf(address(users[1]));
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        uint amountOut = UniswapV2Library.getAmountOut(swapAmountIn, reserve1Before, reserve2Before);
        uint kBefore = reserve1Before * reserve2Before; 
       //CALL: 
        (bool success, bytes memory ret) = users[1].proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, swapAmountIn,0,[address(testToken1),address(testToken2)],address(users[1]),block.timestamp));
        //POSTCONDITIONS:
        if(success) {
            
            uint balance1After = testToken1.balanceOf(address(users[1]));
            uint balance2After  = testToken2.balanceOf(address(users[1]));
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint kAfter = reserve1After*reserve2After;
            assert(kBefore == kAfter);
            assert(balance2Before + amountOut == balance2After);
            assert(balance2Before < balance2After);
            assert(balance1Before > balance1After);
            
        }
       
        
    }
}