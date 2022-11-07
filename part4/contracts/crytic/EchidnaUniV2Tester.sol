pragma solidity 0.5.16;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {
    function testSwapInvariant(uint swapAmountIn) public {
         if(!liquidityProvided) {
            _provideInitialLiquidity(); //we need liquidity before a swap
        }
        swapAmountIn = _between(swapAmountIn, 1, testToken1.balanceOf(address(users[1]))); //need to swap at least 1 wei
       //PRECONDITIONS:
        uint kBefore = testPair.kLast(); 
        (uint reserveBefore1, uint reserveBefore2) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        uint productBefore = reserveBefore1 * reserveBefore2;
       //CALL:
        (bool success, bytes memory ret) = users[1].proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, swapAmountIn,0,[address(testToken1),address(testToken2)],users[1],block.timestamp));
        //POSTCONDITIONS:
        if(success) {
            uint[] memory amounts = abi.decode(ret,(uint[] memory));
            uint kAfter = testPair.kLast(); 
            (uint reserveAfter1, uint reserveAfter2) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint productAfter = reserveAfter1*reserveAfter2;
            assert(productBefore == productAfter);
            assert(kBefore == kAfter);
        }
       
        
    }
}