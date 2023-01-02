pragma solidity ^0.6.0;

import "../uni-v2/UniswapV2ERC20.sol";
import "../uni-v2/UniswapV2Pair.sol";
import "../uni-v2/UniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";

contract Users {
    function proxy(address target, bytes memory data) public returns (bool success, bytes memory retData) {
        return target.call(data);
    }
}

contract Setup {
    UniswapV2ERC20 testToken1;
    UniswapV2ERC20 testToken2;
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    Users user;
    bool completed;

    constructor() public {
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this));
        pair = UniswapV2Pair(factory.createPair(address(testToken1), address(testToken2)));
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(address(testToken1), address(testToken2));
        testToken1 = UniswapV2ERC20(testTokenA);
        testToken2 = UniswapV2ERC20(testTokenB);
        user = new Users();
    }

    function _init(uint amount1, uint amount2) internal {
        testToken1.mint(address(user), amount1);
        testToken2.mint(address(user), amount2);
        completed = true;
    }

    function _between(uint value, uint low, uint high) internal pure returns (uint) {
        return (low + (value % (high - low + 1)));
    }
}