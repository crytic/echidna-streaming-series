pragma solidity 0.8.6;
import "../PrimitiveFactory.sol";
import "../interfaces/IERC20.sol";
import "../test/engine/EchidnaMockEngine.sol";
import "../test/TestRouter.sol";
import "../test/TestToken.sol";
import "../libraries/Margin.sol";

contract EchidnaE2E {
	// ********************* Addresses *********************
	TestToken risky = TestToken(0x1dC4c1cEFEF38a777b15aA20260a54E584b16C48);
	TestToken stable = TestToken(0x1D7022f5B17d2F8B695918FB48fa1089C9f85401);
	EchidnaMockEngine engine = EchidnaMockEngine(0x871DD7C2B4b25E1Aa18728e9D5f2Af4C4e431f5c);

	event AssertionFailed(string msg, uint256 expected, uint256 actual);
	event LogBytes(string msg, bytes data);
	event LogUint256(string msg, uint256 value);

	// ********************* Deposit/Withdraw *********************
	// Deposit with safe range (1-uint64.max)
	function deposit_with_safe_range(address recipient, uint256 delRisky, uint256 delStable) public {
		//************************* Pre-Conditions *************************/
		// delRisky, delStable != 0 
		Margin.Data memory preDeposit = retrieve_engine_margin(recipient); // save pre-deposit snapshot 
		delRisky = between(delRisky, 1, type(uint64).max); // bound delRisky between 1-uint64.max
		delStable = between(delStable, 1, type(uint64).max); // bound delRisky between 1-uint64.max
		mint_tokens(delRisky,delStable); // mint amount of delRisky and delStable tokens to this engine

		BalanceSnapshot memory senderBefore = retrieve_token_balances(address(this)); // save pre-deposit sender balance
		BalanceSnapshot memory engineBefore = retrieve_token_balances(address(engine)); // save pre-deposit engine balance

 		//************************* Action *************************/    
		// see try-catch documentation on solidity: https://docs.soliditylang.org/en/v0.8.17/control-structures.html?highlight=try%2Fcatch#try-catch
		try engine.deposit(recipient, delRisky, delStable, abi.encode(0)) { // call deposit 
			// happy path – post-conditions
			{
			// margin[recipient] should increase by delRisky, delstable             
			Margin.Data memory postDeposit = retrieve_engine_margin(recipient);
			assert(preDeposit.balanceRisky + delRisky == postDeposit.balanceRisky);
			assert(preDeposit.balanceStable + delStable == postDeposit.balanceStable);
			}

			{
			// sender's token balance of both tokens should decrease
			BalanceSnapshot memory senderAfter = retrieve_token_balances(address(this));
			assert(senderAfter.risky == senderBefore.risky - delRisky);
			assert(senderAfter.stable == senderBefore.stable - delStable);     
			}

			{
			// engine token balance of both tokens should increase 
			BalanceSnapshot memory engineAfter = retrieve_token_balances(address(engine));
			assert(engineAfter.risky == engineBefore.risky + delRisky);
			assert(engineAfter.stable == engineBefore.stable + delStable);
			}
		} 
		catch { // deposit should never fail with these safe bounds – note: this is an invariant as well 
			assert(false);
		}

		//************************* Post-Conditions *************************/                  

		// engine token balance of both tokens should increase 
			// post-deposit engine's risky == pre-deposit risky + delRisky
			// post-deposit engine's stable == pre-deposit stable + delStable

			// post-deposit sender's risky == pre-deposit risky - delRisky
			// post-deposit sender's stable == pre-deposit stable - delStable        

	}
	event WithdrawFailed(string msg);
	function withdraw_with_safe_range(address recipient, uint256 delRisky, uint256 delStable) public {
		require(recipient != address(0));
		//************************* Pre-Conditions *************************/
		/*
			- sender must have sufficient balance in margins to withdraw amount 
			- withdrawal amounts for both token are non-zero 
		*/ 
		Margin.Data memory preSenderMargin = retrieve_engine_margin(address(this)); // save the pre-withdrawal sender margins
		Margin.Data memory preEngineMargin = retrieve_engine_margin(address(engine)); // save the pre-withdrawal engine margins
		Margin.Data memory preRecipientMargin = retrieve_engine_margin(address(recipient)); // save the pre-withdrawal recipient margins 

		BalanceSnapshot memory preSenderTokenBalance = retrieve_token_balances(address(this)); // save the pre-withdrawal sender balance
		BalanceSnapshot memory preEngineTokenBalance = retrieve_token_balances(address(engine)); // save the pre-withdrawal engine balance
		BalanceSnapshot memory preRecipientTokenBalance = retrieve_token_balances(recipient); // save the pre-withdrawal recipient balance

		// if the sender's margin amount for either token is = 0, then deposit to increase margin amounts
		if (preSenderMargin.balanceRisky == 0 || preSenderMargin.balanceStable == 0) { 
			deposit_with_safe_range(address(this),delRisky,delStable);
		}

		delRisky = between(delRisky,1,preSenderMargin.balanceRisky); // bound delRisky to between 1-amount of delrisky the sender has
		delStable = between(delStable,1,preSenderMargin.balanceStable); // bound delStable to between 1-amount of delstable the sender has

		emit LogUint256("delRisky",delRisky);
		emit LogUint256("delStable",delStable);
		emit LogUint256("sender margin risky",preSenderMargin.balanceRisky);
		emit LogUint256("sender margin stable",preSenderMargin.balanceStable);

		//************************* Action *************************/
		// call the engine.withdraw function 
		(bool success, bytes memory rt) = address(engine).call(abi.encodeWithSignature("withdraw(address,uint256,uint256)",recipient,delRisky,delStable));
		if (!success) { // if the call is not successful, this property is broken. with a safe range, withdraw should always succeed.
			emit LogBytes("withdrawal call:", rt);
			emit AssertionFailed("Assertion failed",0);
		}

		//************************* Post-Conditions *************************/

		// check sender preconditions 
		{ 
			// ensure that the sender margins have decreased according to withdrawn amount
			Margin.Data memory postSenderMargin = retrieve_engine_margin(address(this));
			assert(preSenderMargin.balanceRisky - delRisky == postSenderMargin.balanceRisky);
			assert(preSenderMargin.balanceStable - delStable == postSenderMargin.balanceStable);
			// ensure that the sender token balance **does not change**
			BalanceSnapshot memory postSenderTokenBalance = retrieve_token_balances(address(this));
			assert(preSenderTokenBalance.risky == postSenderTokenBalance.risky);
			assert(preSenderTokenBalance.stable == postSenderTokenBalance.stable);
		}
		// check recipient's preconditions
		{
			// ensure that the recipient's margins are unchanged
			Margin.Data memory postRecipientMargin = retrieve_engine_margin(recipient);
			assert(preRecipientMargin.balanceRisky == postRecipientMargin.balanceRisky);
			assert(preRecipientMargin.balanceStable == postRecipientMargin.balanceStable);
			
			// ensure that the recipient's token balance has increased
			BalanceSnapshot memory postRecipientTokenBalance = retrieve_token_balances(recipient);
			assert(preRecipientTokenBalance.risky+delRisky == postRecipientTokenBalance.risky);
			assert(preRecipientTokenBalance.stable+delStable == postRecipientTokenBalance.stable);
		} 
		// check engine's preconditions
		{
			// ensure engine's margins are unchanged
			Margin.Data memory postEngineMargin = retrieve_engine_margin(address(engine));
			assert(preEngineMargin.balanceRisky == postEngineMargin.balanceRisky);
			assert(preEngineMargin.balanceStable == postEngineMargin.balanceStable);

			// expect that the engine's token balance should decrease
			BalanceSnapshot memory postEngineTokenBalance = retrieve_token_balances(address(engine));
			assert(preEngineTokenBalance.risky-delRisky == postEngineTokenBalance.risky);
			assert(preEngineTokenBalance.stable-delStable == postEngineTokenBalance.stable);

		}
	}
	function depositCallback(
		uint256 delRisky,
		uint256 delStable,
		bytes calldata data
	) external {
		executeCallback(delRisky, delStable);
	}    
	event AssertionFailed(string msg, uint256 number);
	
	// ********************* Check proper deployments *********************
	// Check the correct precision and liquidity; if someone can change it, it would be a bug 
	function check_precision_and_liquidity() public {
		assert(engine.scaleFactorRisky() == 1);
		assert(engine.scaleFactorStable() == 1);
		assert(engine.MIN_LIQUIDITY() == 1000);
	}

	// Check the proper deployment of the engine
	function check_proper_deployment_of_engine() public {
		address engine_risky = engine.risky();
		address engine_stable = engine.stable();

		assert(engine_risky == address(risky));
		assert(engine_stable == address(stable));
	}
	// ********************* Helper Functions *********************
	function retrieve_engine_margin(address target) internal returns (Margin.Data memory margin) {
		(uint128 riskyAmount, uint128 stableAmount) = engine.margins(target);
		margin = Margin.Data({ balanceRisky: riskyAmount, balanceStable: stableAmount });
	} 
	struct BalanceSnapshot{
		uint256 risky;
		uint256 stable;
	}
	function retrieve_token_balances(address target) internal returns (BalanceSnapshot memory snapshot){
		uint256 riskyBalance = risky.balanceOf(address(target));
		uint256 stableBalance  = stable.balanceOf(address(target));
		snapshot = BalanceSnapshot(riskyBalance,stableBalance);
	}
	function mint_tokens(uint256 riskyAmt, uint256 stableAmt) internal {
		mint_helper(address(this), riskyAmt, stableAmt);
	}
	function mint_tokens_sender(uint256 riskyAmt, uint256 stableAmt) internal {
		mint_helper(msg.sender, riskyAmt, stableAmt);
	}
	function approve_tokens_sender(address recipient, uint256 riskyAmt, uint256 stableAmt) internal {
		risky.approve(recipient, riskyAmt);
		stable.approve(recipient, stableAmt);
	}
	function mint_helper(address recip, uint256 riskyAmt, uint256 stableAmt) internal {
		risky.mint(recip,riskyAmt);
		stable.mint(recip, stableAmt);
	}
	function executeCallback(uint256 delRisky, uint256 delStable) internal {
		if (delRisky > 0) {
			risky.transfer(address(engine), delRisky);
		}
		if (delStable > 0) {
			stable.transfer(address(engine), delStable);
		}
	}
	function one_to_max_uint64(uint256 random) internal returns (uint256) {
		return 1 + (random % (type(uint64).max - 1));
	}
	function between(uint256 random, uint256 low, uint256 high) private returns (uint256) {
		return low + random % (high-low);
	}    
}
