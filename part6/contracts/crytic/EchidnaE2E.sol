pragma solidity 0.8.6;
import "../PrimitiveFactory.sol";
import "../interfaces/IERC20.sol";
import "../test/engine/EchidnaMockEngine.sol";
import "../test/TestRouter.sol";
import "../test/TestToken.sol";
import "./EchidnaPrimitiveManager.sol";

// npx hardhat clean && npx hardhat compile && echidna-test-2.0 . --contract EchidnaE2E --config contracts/crytic/E2ECore.yaml
contract EchidnaE2E {
    TestToken risky_18 = TestToken(0x1dC4c1cEFEF38a777b15aA20260a54E584b16C48);
    TestToken stable_18 = TestToken(0x1D7022f5B17d2F8B695918FB48fa1089C9f85401);

    TestToken risky_6 = TestToken(0x871DD7C2B4b25E1Aa18728e9D5f2Af4C4e431f5c);
    TestToken stable_6 = TestToken(0x0B1ba0af832d7C05fD64161E0Db78E85978E8082);

    EchidnaMockEngine engine_18_18= EchidnaMockEngine(0x48BaCB9266a570d521063EF5dD96e61686DbE788);

    EchidnaMockEngine engine_18_6 = EchidnaMockEngine(0x34D402F14D58E001D8EfBe6585051BF9706AA064);

    EchidnaMockEngine engine_6_18 = EchidnaMockEngine(0x25B8Fe1DE9dAf8BA351890744FF28cf7dFa8f5e3);

    EchidnaMockEngine engine_6_6 = EchidnaMockEngine(0xcdB594a32B1CC3479d8746279712c39D18a07FC0);

	TestToken risky = risky_18;
	TestToken stable = stable_18;
	EchidnaMockEngine engine = engine_18_18;
    function test() public {
        assert(false);
    }
}