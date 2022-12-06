pragma solidity 0.8.6;
import "../libraries/Margin.sol";
import "../libraries/Reserve.sol";
import "../libraries/Units.sol";

contract LibraryTest { 
	using Units for uint256;
	using Units for int128;
	mapping (address => Margin.Data) private margins;
	Margin.Data margin;

	event LogUint256(string msg, uint256 value);
	event AssertionFailed(string msg, uint256 expected, uint256 value);

	// --------------------- Margins.sol -----------------------
	function margin_deposit(uint256 riskyAmt, uint256 stableAmt) public {
		uint256 preRisky = margin.balanceRisky;
		uint256 preStable = margin.balanceStable;

		Margin.deposit(margin, riskyAmt, stableAmt);
		
		assert(margin.balanceRisky - riskyAmt == preRisky);
		assert(margin.balanceStable - stableAmt == preStable);
	}
	function margin_withdraw(uint256 riskyAmt, uint256 stableAmt) public {
		uint256 preRisky = margin.balanceRisky;
		uint256 preStable = margin.balanceStable;

		Margin.withdraw(margins, riskyAmt, stableAmt);
		
		assert(margin.balanceRisky == preRisky - riskyAmt);
		assert(margin.balanceStable == preStable - stableAmt);
	}
	// --------------------- Reserves.sol -----------------------	
	Reserve.Data private reserve;
	bool isSetup;
	function setupReserve() private {
		reserve.reserveRisky = 1 ether;
		reserve.reserveStable = 2 ether;
		reserve.liquidity = 3 ether;
		isSetup = true;
	}
	function reserve_allocate(uint256 delRisky, uint256 delStable) public returns (uint256, uint256, uint256, uint256){
		if (!isSetup) { 
			setupReserve();
		}
		uint256 preRisky = reserve.reserveRisky;
		uint256 preStable = reserve.reserveStable;
		uint256 preLiquidity = reserve.liquidity;
	
		//blank copy from allocate function
		uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky);
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable);
        uint256 delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;	
		
		Reserve.allocate(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000));

		assert(preRisky + delRisky == reserve.reserveRisky);
		assert(preStable + delStable == reserve.reserveStable);
		assert(preLiquidity + delLiquidity == reserve.liquidity);

		return (preRisky, preStable, preLiquidity, delLiquidity);
	}
	function reserve_remove(uint256 delLiquidity) public {
		if (!isSetup) { 
			setupReserve();
		}		
		delLiquidity = _between(delLiquidity, 1, type(uint64).max);		
		uint256 preRisky = reserve.reserveRisky;
		uint256 preStable = reserve.reserveStable;
		uint256 preLiquidity = reserve.liquidity;
		(uint256 delRisky, uint256 delStable) = Reserve.getAmounts(reserve,delLiquidity);		
		
		Reserve.remove(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000));

		assert(preRisky == reserve.reserveRisky + delRisky);
		assert(preStable == reserve.reserveStable + delStable );
		assert(preLiquidity == reserve.liquidity + delLiquidity);
	}

	function allocate_then_remove(uint256 delRisky, uint256 delStable) public {
		delRisky = _between(delRisky, 1, type(uint64).max);
		delStable = _between(delStable, 1, type(uint64).max);

		emit LogUint256("delRisky", delRisky);
		emit LogUint256("delStable", delStable);
		
		(uint256 preAllocateRisky, 
		uint256 preAllocateStable, 
		uint256 preAllocateLiquidity, 
		uint256 delAllocateLiquidity
		) = reserve_allocate(delRisky, delStable);

		(uint256 delRemoveRisky, uint256 delRemoveStable) = Reserve.getAmounts(reserve, delAllocateLiquidity);

		Reserve.remove(reserve,delRemoveRisky,delRemoveStable,delAllocateLiquidity,uint32(block.timestamp + 1000));
		bool shouldFail;

		if(preAllocateRisky != reserve.reserveRisky) { 
			emit AssertionFailed("preallocate risky not equivalent to current risky", preAllocateRisky, reserve.reserveRisky);
			shouldFail = true;
		}
		if(preAllocateStable  != reserve.reserveStable) {
			emit AssertionFailed("preallocate stable not equivalent to current stable", preAllocateStable, reserve.reserveStable);
			shouldFail = true;		
		}
		if(preAllocateLiquidity  != reserve.liquidity) {
			emit AssertionFailed("preallocate liq not equivalent to current liq", preAllocateLiquidity, reserve.liquidity);
			shouldFail = true;					
		}
		if (shouldFail) {
			assert(false);
		}
	}

	// // --------------------- Units.sol -----------------------
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


	function _between(uint256 random, uint256 low, uint256 high) private returns (uint256) {
		return low + random % (high-low);
	}
}