import "../libraries/Units.sol";

contract UnitsTest{
	using Units for uint256;
	using Units for int128;

	// --------------------- Units.sol -----------------------
	function scaleUpAndScaleDownInverses(uint256 value, uint256 factor) public {
		uint256 scaledFactor = (10e18+ factor % (10e18 + 1));

		uint256 scaledUpValue = value.scaleUp(scaledFactor);
		uint256 scaledDownValue = scaledUpValue.scaleDown(scaledFactor);
		
		assert(scaledDownValue == value);
	}
	function scaleToAndFromX64Inverses(uint256 value, uint256 _decimals) public {
		// will enforce factor between 0 - 12
		uint256 factor = _decimals % (13); 
		// will enforce scaledFactor between 1 - 10**12 , because 10**0 = 1
		uint256 scaledFactor = 10**factor;

		int128 scaledUpValue = value.scaleToX64(scaledFactor);
		uint256 scaledDownValue = scaledUpValue.scaleFromX64(scaledFactor);
		
		assert(scaledDownValue == value);
	}

}