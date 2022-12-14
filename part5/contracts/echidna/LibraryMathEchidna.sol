pragma solidity 0.8.6;
import "../libraries/Reserve.sol";

contract LibraryMathEchidna { 
	event LogUint256(string msg, uint256 value);
	event AssertionFailed(string msg, uint256 expected, uint256 value); 

	// --------------------- Reserves.sol -----------------------	
	Reserve.Data private reserve;
	bool isSetup; // ifSetup false -> reserve(0,0,...,0,0); otherwise setupReserve();
	function setupReserve() private {
		reserve.reserveRisky = 1 ether;
		reserve.reserveStable = 2 ether;
		reserve.liquidity = 3 ether;
		isSetup = true;
	}
	//"safe"-version of reserve_allocate
	function reserve_allocate(uint256 delRisky, uint256 delStable) public returns (Reserve.Data memory preAllocate, uint256 delLiquidity){
		//************************* Pre-Conditions *************************/
		if (!isSetup) { 
			setupReserve(); // set up the reserve with a starting value because delta liquidity value relies on non-zero reserves
		}
		Reserve.Data memory preAllocateReserves = reserve; //save the pre-allocation reserve balances
	
		//************************* Action *************************/
		uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky); // calculate the spot price on the risky token
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable); // calculate the spot price on the stable token
        delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1; //choose min(risky spot, stable spot) for liquidity change
		
		Reserve.allocate(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000)); // allocate to the reserve

		//************************* Post-Conditions *************************/
		// pre-allocation risky balance + risky amount allocated = post-allocation risky balance
		assert(preAllocateReserves.reserveRisky + delRisky == reserve.reserveRisky);
		// pre-allocation stable balance + stable amount allocated = post-allocation stable balance
		assert(preAllocateReserves.reserveStable + delStable == reserve.reserveStable);
		// pre-liquidity allocation + delta liquidity = post-allocation liquidity
		assert(preAllocateReserves.liquidity + delLiquidity == reserve.liquidity);

		return (preAllocateReserves, delLiquidity);
	}
	function reserve_remove(uint256 delLiquidity) public {
		//************************* Pre-Conditions *************************/
		if (!isSetup) {  
			setupReserve(); // set up the reserve with starting value if it has not been started before
		}	
		Reserve.Data memory preRemoveReserves = reserve; // save the pre-remove reserve balances
		
		//************************* Action *************************/
		(uint256 delRisky, uint256 delStable) = Reserve.getAmounts(reserve,delLiquidity); // calculate the amount of risky and stable tokens the incoming liquidity maps to 
		
		Reserve.remove(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000)); // call Reserve.remove

		//************************* Post-Conditions *************************/
		// pre-remove risky balance = current reserve.reserveRisky + risky amount removed
		assert(preRemoveReserves.reserveRisky == reserve.reserveRisky + delRisky);
		// pre-remove stable balance = current reserve.reserveRisky + risky amount stable
		assert(preRemoveReserves.reserveStable == reserve.reserveStable + delStable );
		// pre-remove liquidity = current reserve.liquidity + deltaLiquidity
		assert(preRemoveReserves.liquidity == reserve.liquidity + delLiquidity);
	}

	function allocate_then_remove(uint256 delRisky, uint256 delStable) public {
		//************************* Pre-Conditions *************************/
		// bound the risky and stable amounts to between 1-uint64.max
		delRisky = _between(delRisky, 1, type(uint64).max);
		delStable = _between(delStable, 1, type(uint64).max);

		// if an assertion fails, print out the delRisky and delStable values (as the actual args may not be equivalent to the incoming args)
		emit LogUint256("delRisky", delRisky);
		emit LogUint256("delStable", delStable);
		
		//************************* Action *************************/
		// call reserve allocate, saving pre-allocate reserves and associated delLiquidity value 
		(Reserve.Data memory preAllocateReserves, uint256 delAllocateLiquidity) = reserve_allocate(delRisky, delStable);
		// call reserve remove with delLiquidity from allocate
		reserve_remove(delAllocateLiquidity);

		//************************* Post-Conditions *************************/
		// pre-allocate reserveRisky = current (post-remove) reserveRisky
		if(preAllocateReserves.reserveRisky != reserve.reserveRisky) { 
			emit AssertionFailed("preallocate risky not equivalent to current risky", preAllocateReserves.reserveRisky, reserve.reserveRisky);
		}
		// pre-allocate reserveStable = current (post-remove) reserveStable 
		if(preAllocateReserves.reserveStable  != reserve.reserveStable) {
			emit AssertionFailed("preallocate stable not equivalent to current stable", preAllocateReserves.reserveStable, reserve.reserveStable);
		}
		// pre-allocate liquidity = current (post-remove) liquidity
		if(preAllocateReserves.liquidity  != reserve.liquidity) {
			emit AssertionFailed("preallocate liq not equivalent to current liq", preAllocateReserves.liquidity, reserve.liquidity);
		}
	}
	function _between(uint256 random, uint256 low, uint256 high) private returns (uint256) {
		return low + random % (high-low);
	}
}