pragma solidity 0.8.6;
import "../libraries/Reserve.sol";

contract LibraryMathEchidna { 
	Reserve.Data private reserve; // (0,0,0,0,0,0,0)
	event LogUint256(string msg, uint256);
	event AssertionFailed(string msg, uint256 expected, uint256 actualValue);
	bool isSetup;
	function setupReserve() private {
		reserve.reserveRisky = 1 ether;
		reserve.reserveStable = 2 ether;
		reserve.liquidity = 3 ether;
		isSetup = true;
	}
	//"safe"-version of reserve_allocate (1-uint128.max)
	function reserve_allocate(uint256 delRisky, uint256 delStable) public returns (Reserve.Data memory preAllocateReserves, uint256 delLiquidity){
		//************************* Pre-Conditions *************************/
		//@note PRECONDITION: isSetup has to be true (0,0,...,0)
		if (!isSetup) setupReserve();
		//@note INVARIANT: delRisky, delStable need to be >0 
		// | **1 - uint128**  | uint128-uint256 |
		// @note INVARIANT: delta liquidity needs to be >0.
		emit LogUint256("reserve.liquidity",reserve.liquidity);
		emit LogUint256("reserve.reserveRisky",reserve.reserveRisky);
        uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky); // calculate the risky token spot price 
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable); // calculate the stable token spot price
        delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1; // min(risky,stable)
		// snapshot the pool 
		preAllocateReserves= reserve; 

		//************************* Action *************************/
		uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky); // calculate the spot price on the risky token
        	uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable); // calculate the spot price on the stable token
        	delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1; //choose min(risky spot, stable spot) for liquidity change
		
		Reserve.allocate(reserve,delRisky,delStable,delLiquidity,uint32(block.timestamp + 1000)); // allocate to the reserve

		//************************* Post-Conditions *************************/
		// snapshot the pool  – "reserve" 
		// pre-allocate reserve reserveRisky + amt risky added (delRisky) ==  post-allocate reserveRisky amount
		assert(preAllocateReserves.reserveRisky + delRisky == reserve.reserveRisky);
		// pre-allocate reserve reserveStable + amt stable added (delStable) ==  post-allocate reserveStable amount
		assert(preAllocateReserves.reserveStable + delStable == reserve.reserveStable);
		// pre-allocate reserve liquidity + delLiquidity (delLiquidity) ==  post-allocate liquidity
		assert(preAllocateReserves.liquidity + delLiquidity == reserve.liquidity);
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
		delRisky = _between(delRisky, 1, type(uint64).max); 
		delStable = _between(delStable, 1, type(uint64).max); 
		
		emit LogUint256("delRisky", uint256(delRisky));
		emit LogUint256("delStable", uint256(delStable));

		//************************* Action *************************/
		// this gives us the snapshot of pre-allocate reserves, 
		(Reserve.Data memory preAllocateReserves, uint256 delAllocateLiquidity) = 
			reserve_allocate(delRisky, delStable); // this allocates to the pool, this ensures reserve balance increases
		reserve_remove(delAllocateLiquidity); // this removes funds from the pool, ensures the balance decreases 

		//************************* Post-Conditions *************************/
		// snapshot (pre-allocate).reserveRisky = current reserveRisky
		if(preAllocateReserves.reserveRisky != reserve.reserveRisky) {
			emit AssertionFailed("reserveRisky not equal",preAllocateReserves.reserveRisky,reserve.reserveRisky);
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
