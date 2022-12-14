import { waffle } from 'hardhat'
import { Contracts } from '../../types'
const { createFixtureLoader } = waffle

/**
 * @notice Wraps the `describe` statement of a test to inject some context!
 * @param description Test name
 * @param hooks Tests to run
 */
export function testContext(description: string, hooks: () => void): void {
  describe(description, function () {
    before(async function () {
      this.contracts = {} as Contracts
      this.signers = await waffle.provider.getWallets()
      this.loadFixture = createFixtureLoader(this.signers, waffle.provider)
    })

    hooks()
  })
}
