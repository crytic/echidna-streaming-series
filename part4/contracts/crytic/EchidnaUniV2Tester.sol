pragma solidity ^0.6.0;
import "./Setup.sol";

contract EchidnaUniV2Tester is Setup {
     event AssertionFailed(bool result);
     event failed(uint num);
     event testAddr(address addr);
    event createCode(bytes32 code);
    event logBalances(uint b1,uint b2);
    //add remove liquidity test 
    function testProvideLiquidityInvariants(uint amount1, uint amount2) public {
        uint index = amount1 % 3;
        Users user = users[index];
        if(!complete) {
            _init(amount1,amount2);
        }
        //bytes32 code = keccak256(type(UniswapV2Pair).creationCode);
        //emit createCode(code);
        uint balance1Before = testToken1.balanceOf(address(user));
        uint balance2Before = testToken2.balanceOf(address(user));
        require(balance1Before > 10**3 && balance2Before > 10**3);
        //uint pairBalanceBefore = testPair.balanceOf(address(user));
        //emit failed(balance1Before);
        //emit failed(balance2Before);
        //emit failed(pairBalanceBefore);
        //emit testAddr(IUniswapV2Factory(factory).getPair(address(testToken1), address(testToken2)));
        //emit testAddr(address(testPair));
        //emit testAddr(UniswapV2Library.pairFor(address(factory), address(testToken1), address(testToken2)));
        //assert(false);
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        //need to provide more than min liquidity
       uint kBefore = reserve1Before * reserve2Before;
        amount1 = _between(amount1, 10**3, balance1Before); 
        amount2 = _between(amount2, 10**3, balance2Before); 
        //CALL:
        
        (bool success, ) = user.proxy(address(router),abi.encodeWithSelector(router.addLiquidity.selector, address(testToken1), address(testToken2), amount1, amount2, 0, 0, address(users[0]), uint(-1)));
        //emit AssertionFailed(success);
        //POSTCONDITIONS
        
        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            //uint balance1After = testToken1.balanceOf(address(user));
            //uint balance2After  = testToken2.balanceOf(address(user));
           //uint pairBalanceAfter = testPair.balanceOf(address(user));
            uint kAfter = reserve1After*reserve2After;
           assert(kBefore < kAfter);
            //assert(pairBalanceBefore < pairBalanceAfter);
            //assert(balance1Before > balance1After && balance2Before > balance2After);

        }
       
        
    }
   /* function testSwapToken1For2(uint swapAmountIn) public {
        //testProvideLiquidityInvariants(swapAmountIn, swapAmountIn);
        //here testPair.balanceOf(users[0]) represents the total liquidity in the pool - we can't swap more than that 
        Users user = users[1];
        require(testPair.balanceOf(address(users[0]))> 0);
        swapAmountIn = _between(swapAmountIn, 1, testToken1.balanceOf(address(user))); //need to swap at least 1 wei
        //assert(false);
       //PRECONDITIONS:
       
        uint balance1Before = testToken1.balanceOf(address(user));
        uint balance2Before = testToken2.balanceOf(address(user));
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
        uint amountOut = UniswapV2Library.getAmountOut(swapAmountIn, reserve1Before, reserve2Before);
        uint kBefore = reserve1Before * reserve2Before; 
        
    ) 
       //CALL: 
        (bool success, ) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, swapAmountIn,0,[address(testToken1),address(testToken2)],address(users[1]),uint(-1)));
        //emit AssertionFailed(success);
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
       
        
    } */
    function testSwapTokens(uint swapAmountIn, uint tokenSelect) public {
       if(!complete) {
            _init(swapAmountIn,swapAmountIn);
        }
        uint index = swapAmountIn % 3;
        Users user = users[index];
        address[] memory path = new address[](2);
        path[0] = tokenSelect % 2 == 0 ? (address(testToken2)): (address(testToken1)) ;
        path[1] = path[0] == (address(testToken1)) ? (address(testToken2)) : (address(testToken1));

        uint prevBal1 = UniswapV2ERC20(path[0]).balanceOf(address(user));
        uint prevBal2 = UniswapV2ERC20(path[1]).balanceOf(address(user));
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));

        //here testPair.balanceOf(users[0]) represents the total liquidity in the pool - we can't swap more than that 
        require(testPair.totalSupply()>0);
        require(prevBal1 < UniswapV2ERC20(path[0]).balanceOf(address(testPair)) && prevBal1 >0);
        //todo debug
        swapAmountIn = _between(swapAmountIn, 1, prevBal1); //need to swap at least 1 wei
        //assert(false);
       //PRECONDITIONS:
        
        //assert(false);
        uint amountOut = UniswapV2Library.getAmountOut(swapAmountIn, reserve1Before, reserve2Before);
        uint kBefore = reserve1Before * reserve2Before; 
       //CALL: 
       
       emit logBalances(swapAmountIn, amountOut);
        (bool success, ) = user.proxy(address(router), abi.encodeWithSelector(router.swapExactTokensForTokens.selector, swapAmountIn,0,path,address(user),uint(-1)));
        //emit AssertionFailed(success);
        //POSTCONDITIONS:
           
        if(success) {
            //assert(false);

            uint balance1After = UniswapV2ERC20(path[0]).balanceOf(address(user));
            uint balance2After  = UniswapV2ERC20(path[1]).balanceOf(address(user));
            (uint reserve1After, uint reserve2After) = UniswapV2Library.getReserves(address(factory), address(testToken1), address(testToken2));
            uint kAfter = reserve1After*reserve2After;
            emit logBalances(prevBal1, prevBal2);
            emit logBalances(balance1After, balance2After);
            assert(kBefore <= kAfter); //change later 
            assert(prevBal2 < balance2After);
            assert(prevBal1 > balance1After);
            
        }
       
        
    }
    //better way to do this
   /* function testSwapToandBack(uint swapAmountIn) public {
        uint balance1Before = testToken1.balanceOf(address(users[1]));
        uint balance2Before = testToken2.balanceOf(address(users[1]));
        testSwapToken1For2(swapAmountIn);
        testSwapToken2For1(swapAmountIn);
        uint balance1After = testToken1.balanceOf(address(users[1]));
        uint balance2After  = testToken2.balanceOf(address(users[1]));
        assert(balance1Before == balance1After);
        assert(balance2Before == balance2After);

    } */
    
    
   
}