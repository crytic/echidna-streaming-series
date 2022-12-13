pragma solidity ^0.6.0;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {
    
    event logUints(uint kBefore, uint kAfter);
    function testProvideLiquidityInvariants(uint amount1, uint amount2) public {
        //PRECONDITIONS:
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2, 1000, uint(-1));
        if(!complete) {
            _init(amount1,amount2);
        }
        
        //uint pairBalanceBefore = testPair.balanceOf(address(user));
        ( ,bytes memory balanceDataBefore) = user.proxy(pair, abi.encodeWithSignature("balanceOf(address)", address(user)));  //pair.balanceOf(address(user));
        uint pairBalanceBefore = abi.decode(balanceDataBefore, (uint));

        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        
        uint kBefore = reserve1Before * reserve2Before;
       
        //CALL:
        
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.addLiquidity.selector, address(testToken1), address(testToken2), amount1, amount2, 0, 0, address(user), uint(-1)));
        
        //POSTCONDITIONS
       
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));

            //uint pairBalanceAfter = testPair.balanceOf(address(user));
            (, bytes memory balanceDataAfter) = user.proxy(pair, abi.encodeWithSignature("balanceOf(address)", address(user)));  //pair.balanceOf(address(user));
            uint pairBalanceAfter= abi.decode(balanceDataAfter, (uint));
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

        //uint pairBalanceBefore = testPair.balanceOf(address(user));
        ( ,bytes memory balanceDataBefore) = user.proxy(pair, abi.encodeWithSignature("balanceOf(address)", address(user)));  //pair.balanceOf(address(user));
        uint pairBalanceBefore = abi.decode(balanceDataBefore, (uint));
        //user needs some LP tokens to burn
        require(pairBalanceBefore > 0);
        lpAmount = _between(lpAmount, 1, pairBalanceBefore);
        
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        //need to provide more than min liquidity
        uint kBefore = reserve1Before * reserve2Before;
        //(bool success1,) = user.proxy(testPair,abi.encodeWithSelector(testPair.approve.selector,address(router),uint(-1)));
        (bool success1,) = user.proxy(address(pair), abi.encodeWithSignature("approve(address,uint256)", address(router),uint(-1)));
        require(success1);
        //CALL:

        
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.removeLiquidity.selector, address(testToken1), address(testToken2),lpAmount, 0, 0, address(user), uint(-1)));
        
        //POSTCONDITIONS
        
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            
            //uint pairBalanceAfter = testPair.balanceOf(address(user));
            (, bytes memory balanceDataAfter) = user.proxy(pair, abi.encodeWithSignature("balanceOf(address)", address(user)));  //pair.balanceOf(address(user));
            uint pairBalanceAfter= abi.decode(balanceDataAfter, (uint));

            uint kAfter = reserve1After*reserve2After;
            assert(kBefore > kAfter);
            assert(pairBalanceBefore > pairBalanceAfter);
        }
    }
}