pragma solidity ^0.6.0;

import "./Setup.sol";

contract EchidnaTest is Setup {
    event log(uint one, uint two);
    function provideLiquidityTest(uint amount1, uint amount2) public {
        //PRECONDITION:
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2,1000, uint(-1));
        if(!completed) {
            _init(amount1,amount2);
        }
        uint prevBalanceOf1 = testToken1.balanceOf(address(user));
        uint prevBalanceOf2 = testToken2.balanceOf(address(user));
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        
        amount1 = _between(amount1, 1000,prevBalanceOf1);
        amount2 = _between(amount2, 1000,prevBalanceOf2);

        (uint prevReserve1, uint prevReserve2,) = pair.getReserves();
        uint kPrev= prevReserve1 * prevReserve2;
        
        //CALL:
        user.proxy(address(testToken1), abi.encodeWithSelector(testToken1.transfer.selector, address(pair),amount1));
        user.proxy(address(testToken2), abi.encodeWithSelector(testToken2.transfer.selector, address(pair),amount2));

        (bool success,) = user.proxy(address(pair), abi.encodeWithSelector(bytes4(keccak256("mint(address)")), address(user)));

        if(success) {
            //POSTCONDITIONS:
            (uint afterReserve1, uint afterReserve2,) = pair.getReserves();
            uint kAfter = afterReserve1 * afterReserve2;
            
           // uint afterBalanceOf1 = testToken1.balanceOf(address(user));
            //uint afterBalanceOf2 = testToken2.balanceOf(address(user));
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));
            emit log(kPrev, kAfter);
            emit log(lpTokenBalanceBefore, lpTokenBalanceAfter);
            assert(kPrev < kAfter);
            //assert(afterBalanceOf1 < prevBalanceOf1);
            //assert(afterBalanceOf2 < prevBalanceOf2);
            assert(lpTokenBalanceAfter > lpTokenBalanceBefore);
        }



    }

    function testSwap(uint amount1,uint amount2) public {
       
        if(!completed) {
            _init(amount1,amount2);
        }
         //preconditions: 
        require(pair.balanceOf(address(user)) >0); //there is liquidity 
        (uint reserveBefore1, uint reserveBefore2,) = pair.getReserves();
        //let's try swapping without putting anything in the contract
        amount1 = _between(amount1, reserveBefore1, uint(-1));
        amount2 = _between(amount2, reserveBefore2, uint(-1));

        uint balanceBefore1 = testToken1.balanceOf(address(user));
        uint balanceBefore2 = testToken2.balanceOf(address(user));

        (bool success, ) = user.proxy(address(pair), abi.encodeWithSelector(pair.swap.selector, amount1,amount2,address(user),""));
        emit CallPassed(success);
        assert(!success);
        if(success) {
            uint balanceAfter1 = testToken1.balanceOf(address(user));
            uint balanceAfter2 = testToken2.balanceOf(address(user));

            assert(balanceBefore1 >= balanceAfter1);
            assert(balanceBefore2 >= balanceAfter2);
        }    
        




    } 
}