pragma solidity 0.8.6;
import "../libraries/Margin.sol";
import "../libraries/Reserve.sol";
import "../libraries/Units.sol";

contract LibraryMathEchidna { 
	using Units for uint256;
	using Units for int128;
	mapping (address => Margin.Data) private margins;
	Margin.Data margin;

	event LogUint256(string msg, uint256 value);
	event AssertionFailed(string msg, uint256 expected, uint256 value);

	// --------------------- Reserves.sol -----------------------	
	Reserve.Data private reserve;
	bool isSetup;
	function setupReserve() private {
		reserve.reserveRisky = 1 ether;
		reserve.reserveStable = 2 ether;
		reserve.liquidity = 3 ether;
		isSetup = true;
	}
	function reserve_allocate(uint256 delRisky, uint256 delStable) public returns (Reserve.Data memory preAllocate, uint256 delLiquidity){
		//************************* Pre-Conditions *************************/
		if (!isSetup) { 
			setupReserve(); // set up the reserve with a starting value because delta liquidity value relies on non-zero reserves
		}
		Reserve.Data memory preAllocateReserves; //save the pre-allocation reserve balances
	
		//************************* Action *************************/
		uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky); // calculate the spot price on the risky token
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable); // calculate the spot price on the stable token
        uint256 delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1; //choose min(risky spot, stable spot) for liquidity change
		
		Reserve.allocate(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000)); // allocate to the reserve

		//************************* Post-Conditions *************************/
		/* Asserts: 
		  - pre-allocation risky balance + risky amount allocated = post-allocation risky balance
		  - pre-allocation stable balance + stable amount allocated = post-allocation stable balance 
		  - pre-liquidity allocation + delta liquidity = post-allocation liquidity
		*/
		assert(preAllocateReserves.reserveRisky + delRisky == reserve.reserveRisky);
		assert(preAllocateReserves.reserveStable + delStable == reserve.reserveStable);
		assert(preAllocateReserves.liquidity + delLiquidity == reserve.liquidity);

		return (preAllocateReserves, delLiquidity);
	}
	function reserve_remove(uint256 delLiquidity) public {
		//************************* Pre-Conditions *************************/
		if (!isSetup) {  
			setupReserve(); // set up the reserve with starting value if it has not been started before
		}		
		// delLiquidity = _between(delLiquidity, 1, type(uint64).max);		
		Reserve.Data memory preRemoveReserves; // save the pre-remove reserve balances
		
		//************************* Action *************************/
		(uint256 delRisky, uint256 delStable) = Reserve.getAmounts(reserve,delLiquidity); // calculate the amount of risky and stable tokens the incoming liquidity maps to 
		
		Reserve.remove(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000)); // call Reserve.remove

		//************************* Post-Conditions *************************/
		/** Asserts: 
			- pre-remove risky balance = current reserve.reserveRisky + risky amount removed
			- pre-remove stable balance = current reserve.reserveRisky + risky amount stable
			- pre-remove liquidity = current reserve.liquidity + deltaLiquidity
		 */
		assert(preRemoveReserves.reserveRisky == reserve.reserveRisky + delRisky);
		assert(preRemoveReserves.reserveStable == reserve.reserveStable + delStable );
		assert(preRemoveReserves.liquidity == reserve.liquidity + delLiquidity);
	}

	function allocate_then_remove(uint256 delRisky, uint256 delStable) public {
		//************************* Pre-Conditions *************************/
		delRisky = _between(delRisky, 1, type(uint64).max);
		delStable = _between(delStable, 1, type(uint64).max);

		emit LogUint256("delRisky", delRisky);
		emit LogUint256("delStable", delStable);
		
		//************************* Action *************************/
		/**
			- call reserve allocate, saving pre-allocat reserves and associated delLiquidity value 
			- call reserve remove with delLiquidity from allocate
		 */
		(Reserve.Data memory preAllocateReserves,
		uint256 delAllocateLiquidity
		) = reserve_allocate(delRisky, delStable);

		reserve_remove(delAllocateLiquidity);

		//************************* Post-Conditions *************************/
		/*
			- pre-allocate reserveRisky = current (post-remove) reserveRisky
			- pre-allocate reserveStable = current (post-remove) reserveStable 
			- pre-allocate liquidity = current (post-remove) liquidity
		*/
		bool shouldFail;
		if(preAllocateReserves.reserveRisky != reserve.reserveRisky) { 
			emit AssertionFailed("preallocate risky not equivalent to current risky", preAllocateReserves.reserveRisky, reserve.reserveRisky);
			shouldFail = true;
		}
		if(preAllocateReserves.reserveStable  != reserve.reserveStable) {
			emit AssertionFailed("preallocate stable not equivalent to current stable", preAllocateReserves.reserveStable, reserve.reserveStable);
			shouldFail = true;		
		}
		if(preAllocateReserves.liquidity  != reserve.liquidity) {
			emit AssertionFailed("preallocate liq not equivalent to current liq", preAllocateReserves.liquidity, reserve.liquidity);
			shouldFail = true;					
		}
		if (shouldFail) {
			assert(false);
		}
	}

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

	function _between(uint256 random, uint256 low, uint256 high) private returns (uint256) {
		return low + random % (high-low);
	}
}