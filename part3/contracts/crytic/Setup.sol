pragma solidity ^0.6.0;
import "../uni-v2/UniswapV2Factory.sol";
import "../uni-v2/UniswapV2Pair.sol";
import "../uni-v2/UniswapV2ERC20.sol";
import "../uni-v2/UniswapV2Router01.sol";

contract Users {
    function proxy(address target, bytes memory data) public returns(bool success,bytes memory retData) {
        (success, retData) = address(target).call(data);
    }
}

contract Setup {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    UniswapV2ERC20 testToken1;
    UniswapV2ERC20 testToken2;
    Users user;
    bool completed;
    event CallPassed(bool success);
    constructor() public {
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this));
        address testPair = factory.createPair(address(testToken1), address(testToken2));
        pair = UniswapV2Pair(testPair);
        user = new Users();
        user.proxy(address(testToken1),abi.encodeWithSelector(testToken1.approve.selector, address(pair),uint(-1)));
        user.proxy(address(testToken2), abi.encodeWithSelector(testToken2.approve.selector,address(pair),uint(-1)));
    }

    function _init(uint amount1, uint amount2) internal {
        testToken1.mint(address(user), amount1);
        testToken2.mint(address(user), amount2);
        completed = true;
    }

    function _between(uint val, uint low, uint high) internal pure returns(uint) {
        return low + (val % (high-low +1)); 
    }


}