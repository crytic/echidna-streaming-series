pragma solidity ^0.6.0;

import "../uni-v2/UniswapV2Pair.sol";
import "../uni-v2/UniswapV2ERC20.sol";
import "../uni-v2/UniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";
import "../uni-v2/UniswapV2Router01.sol";

contract Users {
    function proxy(address target, bytes memory _calldata)
        public
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = address(target).call(_calldata);
    }
}

contract Setup {
    UniswapV2ERC20 testToken1;
    UniswapV2ERC20 testToken2;
    UniswapV2Pair testPair;
    UniswapV2Factory factory;
    UniswapV2Router01 router;
    Users user;
    bool complete;

    constructor() public {
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this)); //this contract will be the fee setter
        router = new UniswapV2Router01(address(factory), address(0)); // we don't need to test WETH pairs for now
        address pair = factory.createPair(
            address(testToken1),
            address(testToken2)
        );
        testPair = UniswapV2Pair(pair);
        user = new Users();
        // Sort the test tokens we just created, for clarity when writing invariant tests later
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(address(testToken1), address(testToken2));
        testToken1 = UniswapV2ERC20(testTokenA);
        testToken2 = UniswapV2ERC20(testTokenB);
    }

    function _doApprovals() internal {
        user.proxy(
            address(testToken1),
            abi.encodeWithSelector(
                testToken1.approve.selector,
                address(router),
                uint256(-1)
            )
        );
        user.proxy(
            address(testToken2),
            abi.encodeWithSelector(
                testToken2.approve.selector,
                address(router),
                uint256(-1)
            )
        );
    }

    function _init(uint256 amount1, uint256 amount2) internal {
        testToken2.mint(address(user), amount2);
        testToken1.mint(address(user), amount1);
        _doApprovals();
        complete = true;
    }

    function _between(
        uint256 val,
        uint256 lower,
        uint256 upper
    ) internal pure returns (uint256) {
        return lower + (val % (upper - lower + 1));
    }
}
