pragma solidity 0.8.6;
import "../PrimitiveFactory.sol";
import "../interfaces/IERC20.sol";
import "../test/engine/EchidnaMockEngine.sol";
import "../test/TestRouter.sol";
import "../test/TestToken.sol";
import "../libraries/Margin.sol";

contract EchidnaE2E {
    // ********************* Addresses *********************
    TestToken risky = TestToken(0x1dC4c1cEFEF38a777b15aA20260a54E584b16C48); // 18 decimal risky
    TestToken stable = TestToken(0x1D7022f5B17d2F8B695918FB48fa1089C9f85401); // 18 decimal stable
    EchidnaMockEngine engine = EchidnaMockEngine(0x48BaCB9266a570d521063EF5dD96e61686DbE788); // 18-18 engine
    event AssertionFailed(string msg, uint256 expected, uint256 actual);
    event LogBytes(string msg, bytes data);
    event LogUint256(string msg, uint256 value);
    // ********************* Deposit/Withdraw *********************
    // Deposit with safe range
    function deposit_with_safe_range(address recipient, uint256 delRisky, uint256 delStable) public {
		//************************* Pre-Conditions *************************/
             // delRisky != 0; delStable != 0
            //  mint_tokens(type(uint64).max,type(uint64).max);
             // sufficient balance of both tokens in sender's 
            Margin.Data memory preDeposit = retrieve_engine_margin(recipient);
            delRisky = between(delRisky, 1, type(uint64).max);
            delStable = between(delStable, 1, type(uint64).max);
            mint_tokens(delRisky, delStable);  // investigate why this failed on dry run             
            BalanceSnapshot memory senderBefore = retrieve_token_balances(address(this));
            BalanceSnapshot memory engineBefore = retrieve_token_balances(address(engine));
 		//************************* Action *************************/    
            try engine.deposit(recipient, delRisky, delStable, abi.encode(0)) {
                // Recipient margin's should increase by added amounts
                { 
                    Margin.Data memory postDeposit = retrieve_engine_margin(recipient);
                    assert(preDeposit.balanceRisky + delRisky == postDeposit.balanceRisky);
                    assert(preDeposit.balanceStable + delStable == postDeposit.balanceStable);
                } 
                // Sender balance of both tokens should decrease
                { 
                    BalanceSnapshot memory senderAfter = retrieve_token_balances(address(this));
                    assert(senderAfter.risky == senderBefore.risky - delRisky);
                    assert(senderAfter.stable == senderBefore.stable - delStable);
                } 
                // Engine balance of both tokens should increase
                { 
                    BalanceSnapshot memory engineAfter = retrieve_token_balances(address(engine));
                    assert(engineAfter.risky == engineBefore.risky + delRisky);
                    assert(engineAfter.stable == engineBefore.stable + delStable);
                }
            } catch {
                emit AssertionFailed("deposit failed", delRisky, delStable);
            }
		//************************* Post-Conditions *************************/                  
            /* - post-deposit sender token balance 
                - (risky -= delRisky)
                - (stable -= delStable)
               - post-deposit engine token balance 
                - (risky += delRisky)
                - (stable += delStable)               
               - recipient's margin risky += delRisky; stable += delStable                
            */ 
    }
    event WithdrawFailed(string msg);
    function withdraw_with_safe_range(address recipient, uint256 delRisky, uint256 delStable) public {
        require(recipient != address(0));
		//************************* Pre-Conditions *************************/
        /*
            - sender must have sufficient balance in margins to withdraw amount 
            - withdrawal amounts for both token are non-zero 
        */ 
        Margin.Data memory preSenderMargin = retrieve_engine_margin(address(this));
        Margin.Data memory preEngineMargin = retrieve_engine_margin(address(engine));
        Margin.Data memory preRecipientMargin = retrieve_engine_margin(address(recipient));

        // Save Snapshots of what the Balances of each token
        BalanceSnapshot memory preRecipientTokenBalance = retrieve_token_balances(recipient);
        BalanceSnapshot memory preSenderTokenBalance = retrieve_token_balances(address(this));
        BalanceSnapshot memory preEngineTokenBalance = retrieve_token_balances(address(engine));

        if (preSenderMargin.balanceRisky == 0 || preSenderMargin.balanceStable == 0) {
            deposit_with_safe_range(address(this),delRisky,delStable);
        }

        delRisky = between(delRisky,1,preSenderMargin.balanceRisky);
        delStable = between(delStable,1,preSenderMargin.balanceStable);

        emit LogUint256("delRisky",delRisky);
        emit LogUint256("delStable",delStable);
        emit LogUint256("sender margin risky",preSenderMargin.balanceRisky);
        emit LogUint256("sender margin stable",preSenderMargin.balanceStable);

		//************************* Action *************************/
        (bool success, bytes memory rt) = address(engine).call(abi.encodeWithSignature("withdraw(address,uint256,uint256)",recipient,delRisky,delStable));
        if (!success) {
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
    // Check the correct precision and liquidity
    function check_precision_and_liquidity() public {
        assert(engine.scaleFactorRisky() == 1);
        assert(engine.scaleFactorStable() == 1);
        assert(engine.MIN_LIQUIDITY() > 0 ); // double check what was used in the actual test; and change the config
    }

    // Check the proper deployment of the engine
    function check_proper_deployment_of_engine() public {
        assert(engine.risky() == address(risky));
        assert(engine.stable() == address(stable));
    }

    // Check the created pool timestamp is greater than zero 
    function check_created_pool_timestamp_greater_zero(uint256 id) public {
    }
    // ********************* Create *********************
    struct CreateHelper {
        uint128 strike;
        uint32 sigma;
        uint32 maturity;
        uint256 riskyPerLp;
        uint256 delLiquidity;
        uint32 gamma;
    }

    function create_new_pool_should_not_revert(
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity
    ) public {
        strike = uint128(between(strike, 1 ether, 10000 ether));
        sigma = uint32(between(sigma, 100, 1e7 - 100));
        gamma = uint32(between(gamma, 9000, 10000));
        delLiquidity = between(delLiquidity, engine.MIN_LIQUIDITY()+1,10 ether);
        uint32 maturity = (31556952 + maturity);
        require(maturity >= uint32(engine.time()));
        CreateHelper memory args = CreateHelper({
            strike: strike,
            sigma: sigma,
            maturity: maturity,
            delLiquidity: delLiquidity,
            riskyPerLp: riskyPerLp,
            gamma: gamma
        });
        (uint256 delRisky, uint256 delStable) = calculate_del_risky_and_stable(args);
        mint_tokens(delRisky, delStable);

        create_helper(args, abi.encode(0));
    }
    function create_should_revert(CreateHelper memory params, bytes memory data) internal {
        try
            engine.create(
                params.strike,
                params.sigma,
                params.maturity,
                params.gamma,
                params.riskyPerLp,
                params.delLiquidity,
                abi.encode(0)
            )
        {
            assert(false);
        } catch {
            assert(true);
        }
    }

    function create_helper(
        CreateHelper memory params,
        bytes memory data

    ) internal {
        try engine.create(params.strike, params.sigma, params.maturity, params.gamma, params.riskyPerLp, params.delLiquidity, data) {
            bytes32 poolId = keccak256(abi.encodePacked(address(engine), params.strike, params.sigma, params.maturity, params.gamma));
            add_to_created_pool(poolId);
            (
                uint128 calibrationStrike,
                uint32 calibrationSigma,
                uint32 calibrationMaturity,
                uint32 calibrationTimestamp,
                uint32 calibrationGamma
            ) = engine.calibrations(poolId);
            assert(calibrationTimestamp == engine.time());
            assert(calibrationGamma == params.gamma);
            assert(calibrationStrike == params.strike);
            assert(calibrationSigma == params.sigma);
            assert(calibrationMaturity == params.maturity);
        } catch {
            assert(false);
        }
    }

    function calculate_del_risky_and_stable(CreateHelper memory params)
        internal
        returns (uint256 delRisky, uint256 delStable)
    {
        uint256 factor0 = engine.scaleFactorRisky();
        uint256 factor1 = engine.scaleFactorStable();
        uint32 tau = params.maturity - uint32(engine.time()); // time until expiry
        require(params.riskyPerLp <= engine.PRECISION() / factor0);

        delStable = ReplicationMath.getStableGivenRisky(
            0,
            factor0,
            factor1,
            params.riskyPerLp,
            params.strike,
            params.sigma,
            tau
        );
        delRisky = (params.riskyPerLp * params.delLiquidity) / engine.PRECISION(); // riskyDecimals * 1e18 decimals / 1e18 = riskyDecimals
        require(delRisky > 0);
        delStable = (delStable * params.delLiquidity) / engine.PRECISION();
        require(delStable > 0);
    }

    function createCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external {
        executeCallback(delRisky, delStable);
    }
    // ********************* Helper Functions *********************
    function retrieve_engine_margin(address target) internal returns (Margin.Data memory margin) {
        (uint128 risky, uint128 stable) = engine.margins(target);
        margin = Margin.Data({ balanceRisky: risky, balanceStable: stable });
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
    // Created Pool Trackers
	bytes32[] poolIds;
	function add_to_created_pool(bytes32 poolId) internal {
		// createdPoolIds[address(engine)].push(poolId);
		poolIds.push(poolId);
	}
    function retrieve_created_pool(uint256 id) internal returns (bytes32) {
		// require(createdPoolIds[address(engine)].length > 0);
        // uint256 index = id % (createdPoolIds[address(engine)].length);
        // return createdPoolIds[address(engine)][index];
		require(poolIds.length > 0);
		uint256 index = id % (poolIds.length);
		return poolIds[index];
    }    
	function between(uint256 random, uint256 low, uint256 high) private returns (uint256) {
		return low + random % (high-low);
	}    
}
