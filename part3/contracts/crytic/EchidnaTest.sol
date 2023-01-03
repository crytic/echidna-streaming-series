pragma solidity ^0.6.0;

import "./Setup.sol";

contract EchidnaTest is Setup {
    event logUints(uint unit1, uint unit2);
    function testProvideLiquidity(uint amount1, uint amount2) public {
        //Preconditions: 
        amount1 = _between(amount1, 1000, uint(-1));
        amount2 = _between(amount2, 1000, uint(-1));

        if(!completed) {
            _init(amount1, amount2);
        }
        ( ,bytes memory balanceDataBefore) = user.proxy(testPair, abi.encodeWithSignature("balanceOf(address)", address(user))); //pair.balanceOf(address(user));
        uint lpTokenBalanceBefore = abi.decode(balanceDataBefore, (uint));

        (, bytes memory reserveDataBefore) = user.proxy(testPair, abi.encodeWithSignature("getReserves()")); //pair.getReserves();
        (uint reserve0Before,uint reserve1Before) = abi.decode(reserveDataBefore, (uint,uint));
        uint kBefore = reserve0Before * reserve1Before;

        (bool success1,) = user.proxy(address(testToken1),abi.encodeWithSelector(testToken1.transfer.selector, testPair,amount1));
        (bool success2,) = user.proxy(address(testToken2),abi.encodeWithSelector(testToken2.transfer.selector, testPair,amount2));
        require(success1 && success2);

        //Action:
        (bool success3,) = user.proxy(testPair,abi.encodeWithSelector(bytes4(keccak256("mint(address)")), address(user)));
        
        //Postconditions:
        if(success3) {
            ( ,bytes memory balanceDataAfter) = user.proxy(testPair, abi.encodeWithSignature("balanceOf(address)", address(user))); //pair.balanceOf(address(user));
            uint lpTokenBalanceAfter = abi.decode(balanceDataAfter, (uint));
           
            (, bytes memory reserveDataAfter) = user.proxy(testPair, abi.encodeWithSignature("getReserves()")); //pair.getReserves();
            (uint reserve0After,uint reserve1After) = abi.decode(reserveDataAfter, (uint,uint));
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
        user.proxy(testPair, abi.encodeWithSignature("sync()")); //pair.sync(); // we matched the balances with reserves

        (, bytes memory pairBalanceData) = user.proxy(testPair, abi.encodeWithSignature("balanceOf(address)", address(user)));
        uint pairBalance = abi.decode(pairBalanceData, (uint));
        require(pairBalance > 0); //there is liquidity for the swap

        //Call:
        (bool success1,) = user.proxy(testPair,abi.encodeWithSignature("swap(uint256,uint256,address,bytes)", amount1,amount2,address(user),""));
        //(bool success1,) = user.proxy(testPair, abi.encodeWithSelector(pair.swap.selector, amount1,amount2,address(user),""));

        //Postcondition:
        assert(!success1); //call should never succeed


    
    }
}
