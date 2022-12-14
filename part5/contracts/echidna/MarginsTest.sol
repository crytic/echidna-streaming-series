import "../libraries/Margin.sol";

contract MarginsTest { 
	mapping (address => Margin.Data) private margins;
	Margin.Data margin;	
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
}
