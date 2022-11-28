pragma solidity 0.8.1;

import "./ABDKMath64x64.sol";

contract EchidnaTemplate {

    /* ================================================================
       Library wrappers.
       These functions allow calling the ABDKMath64x64 library.
       ================================================================ */
    function debug(string calldata x, int128 y) private {
        emit Value(x, ABDKMath64x64.toInt(y));
    }

    function fromInt(int256 x) private returns (int128) {
        return ABDKMath64x64.fromInt(x);
    }

    function toInt(int128 x) private returns (int64) {
        return ABDKMath64x64.toInt(x);
    }

    function fromUInt(uint256 x) private returns (int128) {
        return ABDKMath64x64.fromUInt(x);
    }

    function toUInt(int128 x) private returns (uint64) {
        return ABDKMath64x64.toUInt(x);
    }

    function from128x128(int256 x) private returns (int128) {
        return ABDKMath64x64.from128x128(x);
    }

    function to128x128(int128 x) private returns (int256) {
        return ABDKMath64x64.to128x128(x);
    }

    function add(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.add(x, y);
    }

    function sub(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.sub(x, y);
    }

    function mul(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.mul(x, y);
    }

    function muli(int128 x, int256 y) private returns (int256) {
        return ABDKMath64x64.muli(x, y);
    }

    function mulu(int128 x, uint256 y) private returns (uint256) {
        return ABDKMath64x64.mulu(x, y);
    }

    function div(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.div(x, y);
    }

    function divi(int256 x, int256 y) private returns (int128) {
        return ABDKMath64x64.divi(x, y);
    }

    function divu(uint256 x, uint256 y) private returns (int128) {
        return ABDKMath64x64.divu(x, y);
    }

    function neg(int128 x) private returns (int128) {
        return ABDKMath64x64.neg(x);
    }

    function abs(int128 x) private returns (int128) {
        return ABDKMath64x64.abs(x);
    }

    function inv(int128 x) private returns (int128) {
        return ABDKMath64x64.inv(x);
    }

    function avg(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.avg(x, y);
    }

    function gavg(int128 x, int128 y) private returns (int128) {
        return ABDKMath64x64.gavg(x, y);
    }

    function pow(int128 x, uint256 y) private returns (int128) {
        return ABDKMath64x64.pow(x, y);
    }

    function sqrt(int128 x) private returns (int128) {
        return ABDKMath64x64.sqrt(x);
    }

    function log_2(int128 x) private returns (int128) {
        return ABDKMath64x64.log_2(x);
    }

    function ln(int128 x) private returns (int128) {
        return ABDKMath64x64.ln(x);
    }

    function exp_2(int128 x) private returns (int128) {
        return ABDKMath64x64.exp_2(x);
    }

    function exp(int128 x) private returns (int128) {
        return ABDKMath64x64.exp(x);
    }

    /* ================================================================
       64x64 fixed-point constants used for testing specific values.
       This assumes that ABDK library's fromInt(x) works as expected.
       ================================================================ */
    int128 internal ZERO_FP = ABDKMath64x64.fromInt(0);
    int128 internal ONE_FP = ABDKMath64x64.fromInt(1);
    int128 internal MINUS_ONE_FP = ABDKMath64x64.fromInt(-1);
    int128 internal TWO_FP = ABDKMath64x64.fromInt(2);
    int128 internal THREE_FP = ABDKMath64x64.fromInt(3);
    int128 internal EIGHT_FP = ABDKMath64x64.fromInt(8);
    int128 internal THOUSAND_FP = ABDKMath64x64.fromInt(1000);
    int128 internal MINUS_SIXTY_FOUR_FP = ABDKMath64x64.fromInt(-64);
    int128 internal EPSILON = 1;
    int128 internal ONE_TENTH_FP = ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

    /* ================================================================
       Constants used for precision loss calculations
       ================================================================ */
    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

    /* ================================================================
       Integer representations maximum values.
       These constants are used for testing edge cases or limits for 
       possible values.
       ================================================================ */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MAX_256 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MIN_256 =
        -0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MAX_U256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /* ================================================================
       Helper functions.
       ================================================================ */

    // This function allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // This implements an absolute value function in order to not use 
    // the implementation from the library under test.
    function equal_within_precision(int128 a, int128 b, uint256 precision_bits) private returns(bool) {
        int128 max = (a > b) ? a : b;
        int128 min = (a > b) ? b : a;
        int128 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    function equal_within_precision_u(uint256 a, uint256 b, uint256 precision_bits) private returns(bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;
        
        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 64x64 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(int128 a, int128 b, int128 error_percent) private returns(bool) {
        int128 tol_value = abs(mul(a, div(error_percent, fromUInt(100))));

        return (abs(sub(b, a)) <= tol_value);
    }

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mult(int128 a, int128 b) private returns (bool) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));

        return(lx + ly - 1 <= -64);
    }

    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_bits_after_mult(int128 a, int128 b) private returns (uint256) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = toInt(log_2(x));
        int128 ly = toInt(log_2(y));
        int256 prec = lx + ly - 1;

        if (prec < -64) return 0;
        else return(64 + uint256(prec));
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(int128 n, uint256 i) private returns (uint256) {
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2**i) - 1;

        // Get the position of the MSB set to 1 of n
        uint256 pos = uint64(toInt(log_2(n)) + 64 + 1);

        // Get the positive value of n
        uint256 value = (n>0) ? uint128(n) : uint128(-n);

        // Shift the mask to match the rightmost 1-set bit
        if(pos > i) { mask <<= (pos - i); }

        return (value & mask);
    }

    // Returns true if the n most significant bits of a and b are almost equal 
    // Uses functions from the library under test!
    function equal_most_significant_bits_within_precision(int128 a, int128 b, uint256 bits) private returns (bool) {
        uint256 a_bits = uint256(int256(toInt(log_2(a)) + 64));
        uint256 b_bits = uint256(int256(toInt(log_2(b)) + 64));

        uint256 shift_bits = (a_bits > b_bits) ? (a_bits - bits) : (b_bits - bits);

        uint256 a_msb = most_significant_bits(a, bits) >> shift_bits;
        uint256 b_msb = most_significant_bits(b, bits) >> shift_bits;

        return equal_within_precision_u(a_msb, b_msb, 1);
    }

    /* ================================================================
       Events used for debugging or showing information.
       ================================================================ */
    event Value(string reason, int128 val);
    event LogErr(bytes error);
    event Debug(int128, int128);

    /* ================================================================
    Start of tests
    ================================================================ */

    // Test for associative property
    // (x + y) + z == x + (y + z)
    function add_test_associative(int128 x, int128 y, int128 z) public {
    }












    // Test (x + y) - y == x
    function add_sub_inverse_operations(int128 x, int128 y) public {
    }
















    // Test that division is not commutative
    // (x / y) != (y / x)
    function div_test_not_commutative(int128 x, int128 y) public {
    }
}