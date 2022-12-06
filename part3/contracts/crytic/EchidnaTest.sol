pragma solidity ^0.6.0;

import "./Setup.sol";
import '../libraries/Math.sol';
import '../libraries/SafeMath.sol';

contract EchidnaTest is Setup {
    using SafeMath for uint;

    function testProvideLiquidity(uint amount1, uint amount2) public {
        //Preconditions: 
        amount1 = _between(amount1, 1, uint(-1));
        amount2 = _between(amount2, 1, uint(-1));

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
        // success3 should only be true if:
        // - the minimimum liquidity was met, AND
        // - token amount transferred is less than 2**112 - 1
        if(success3) {
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));
            (uint reserve0After, uint reserve1After,) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;
            assert(lpTokenBalanceBefore < lpTokenBalanceAfter);
            assert(kBefore < kAfter);

        }
        // If any failure condition is met, user should not be awarded any LP tokens
        else {
            assert(pair.balanceOf(address(user)) == 0);
            assert(amount1 > 2**112 - 1 || amount2 > 2**112 - 1 || Math.sqrt(amount1 * amount2) < 10**3);
        }


    }

    event SqrtInputs(uint,uint);
    event SqrtRoots(uint,uint);
    event SqrtProduct(uint,uint);
    event SqrtQuotient(uint,uint);
    function testSqrt(uint a, uint b) public {
        require(a > 0 && b > 0);
        emit SqrtInputs(a, b);
        emit SqrtRoots(Math.sqrt(a), Math.sqrt(b));

        // Validate the product property: sqrt(a) * sqrt(b) == sqrt(a * b)
        emit SqrtProduct(Math.sqrt(a).mul(Math.sqrt(b)), Math.sqrt(a.mul(b)));
        assert(Math.sqrt(a).mul(Math.sqrt(b)) == Math.sqrt(a.mul(b)));

        // Validate the quotient property: sqrt(a) / sqrt(b) == sqrt(a / b)
        emit SqrtQuotient(Math.sqrt(a) / Math.sqrt(b), Math.sqrt(a / b));
        assert(Math.sqrt(a) / Math.sqrt(b) == Math.sqrt(a / b));
    }
}