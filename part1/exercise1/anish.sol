pragma solidity ^0.7.0;

// inherit Token so we inherit Token's state as well as state of 
// ownable and pausable contracts
// we can also call all the functions in token, ownable, and 
// pausable

import "./token.sol";

contract TestToken is Token {
    address echidna_caller = msg.sender;

    constructor() {
        balances[echidna_caller] = 10_000;
    }

    // property
    // function echidna_*() public returns (bool) {
    
    function echidna_test_balance() public returns (bool) {
        return balances[echidna_caller] <= 10_000;
    }
}