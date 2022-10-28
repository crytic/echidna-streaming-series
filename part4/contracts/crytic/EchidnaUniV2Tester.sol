pragma solidity 0.5.16;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {
    function testSwapInvariant(uint swapAmountIn) public {
         if(!liquidityProvided) {
            _provideInitialLiquidity();
        }
        swapAmountIn = _between(swapAmountIn, 1, MockERC20.balanceOf(address(users[1]))); //need to swap at least 1 wei
       //TODO: calculate amount out, transfer that amount to pair, then call thisgit  
        (bool success, bytes memory ret) = users[1].proxy(address(testPair), abi.encodeWithSelector(testPair.swap.selector, swapAmountIn,0,users[1],""));

        
    }
}