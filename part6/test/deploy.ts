import { ethers } from 'hardhat' //uses hardhat-config 
import expect from './shared/expect'

	describe(`constructor of pool`, function () {
		let risky_18, stable_18, risky_6, stable_6
		let engine_18_18, engine_18_6, engine_6_18, engine_6_6

		before(async function () {
			// [signer, other] = await (ethers as any).getSigners()
		})

		beforeEach(async function () {
			const MockEngine = await ethers.getContractFactory("EchidnaMockEngine")
			const TokenFactory = await ethers.getContractFactory('TestToken')
			
			risky_18 = await TokenFactory.deploy('Test Risky 18', 'RISKY18', 18) 
			stable_18 = await TokenFactory.deploy('Test Stable 18', 'STABLE18', 18)
			engine_18_18 = await MockEngine.deploy(
											risky_18.address,  // risky token with 18 decimals address
											stable_18.address, // stable token with 18 decimals address
											1, // scale factor for risky token
											1,  // scale factor for stable token
											1000 // minimum liquidity
										); 

			risky_6 = await TokenFactory.deploy('Test Risky 6', 'RISKY6', 6) 
			stable_6 = await TokenFactory.deploy('Test Stable 6', 'STABLE6', 6) 

			engine_18_6 = await MockEngine.deploy(risky_18.address, stable_6.address, 1, 1000000000000, 10);
			engine_6_18 = await MockEngine.deploy(risky_6.address, stable_18.address, 1000000000000, 1, 10);
			engine_6_6 = await MockEngine.deploy(risky_6.address, stable_6.address, 1000000000000, 1000000000000, 10);

			pretty_print_address("TestToken", "risky_18", risky_18.address)
			pretty_print_address("TestToken", "stable_18", stable_18.address)
			pretty_print_address("EchidnaMockEngine", "engine_18_18", engine_18_18.address)
			console.log("------------------------------------------------");
			pretty_print_address("TestToken", "mockStable18", stable_18.address)      
			pretty_print_address("TestToken", "mockStable6", stable_6.address)
			pretty_print_address("TestToken", "mockRisky18", risky_6.address)      
			pretty_print_address("EchidnaMockEngine", "engine_18_6", engine_18_6.address)
			pretty_print_address("EchidnaMockEngine", "engine_6_18", engine_6_18.address)
			pretty_print_address("EchidnaMockEngine", "engine_6_6", engine_6_6.address)
		})

		describe('when the contract is deployed', function () {
			it('contract addresses', async function () {
				expect(await engine_18_18.risky()).to.equal(risky_18.address)
			})
		})

		function pretty_print_address(type, name, address) { 
			console.log(`${type} ${name} = ${type}(${address});`);
		}
	})