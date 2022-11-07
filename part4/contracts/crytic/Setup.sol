pragma solidity 0.5.16;

import "../UniswapV2Pair.sol";
import "../UniswapV2ERC20.sol";
import "../UniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";
import "../UniswapV2Router01.sol";

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
    Users[] users;
    bool liquidityProvided;

    constructor() {
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this)); //this contract will receive fees
        router = new UniswapV2Router01(address(factory),address(0)); // we don't need to test WETH pairs for now
        //address pair = factory.createPair(address(testToken1), address(testToken2));
        //testPair = UniswapV2Pair(pair);
        _createUsers();
        _mintTokens();

    }
    function _createUsers() internal {
        for(uint i; i < 2; ++i) {
            users.push(new Users()); // user 0 is LP, user 1 is user
        }
    }
    function _mintTokens() internal {
            testToken2.mint(address(users[0]), 200000e18);
            testToken1.mint(address(users[0]), 200000e18); 
            testToken2.mint(address(users[1]), 20000e18);
            testToken1.mint(address(users[1]), 20000e18);
            
        
    }
    
    function _provideInitialLiquidity() internal {
        router.addLiquidity(address(testToken1), address(testToken2), 100000e18, 100000e18, 0, 0, address(user[0]), block.timestamp);
        liquidityProvided = true;
    }
     function _between(
    uint256 val,
    uint256 lower,
    uint256 upper
  ) internal pure returns (uint256) {
    return lower + (val % (upper - lower + 1));
  }
    
}