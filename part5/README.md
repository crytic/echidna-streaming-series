# List of Invariants 

## Invariants to test for Part 5: 
- [Allocating to a pool increases its respective reserve balance](https://github.com/crytic/echidna-streaming-series/blob/9e1aca6efc057fd729d3c27145490fb15971fba8/part5/contracts/echidna/LibraryMathEchidna.sol#L43-L63)
- [Removing from a pool decreases its respective reserve balance](https://github.com/crytic/echidna-streaming-series/blob/9e1aca6efc057fd729d3c27145490fb15971fba8/part5/contracts/echidna/LibraryMathEchidna.sol#L64-L79)
- [Allocating then removing from a pool should result in the same pre- and post- balances](https://github.com/crytic/echidna-streaming-series/blob/9e1aca6efc057fd729d3c27145490fb15971fba8/part5/contracts/echidna/LibraryMathEchidna.sol#L81-L114)

## "In-English" Invariants of the System
Note: Implementations for these will be implemented in Part 6. Due to to time limitations, code for some of these will provided in Part 6 streams.

**System Deployment**
- PRECISION() constant = 10**18
- MIN_LIQUIDITY() should be > 0
- One deployed, engine's tokens should map to the correct tokens 
- Last timestamp on engine should never exceed timestamp's maturity 
- Gamma should never exceed 10000

**Engine Creation** 
- Correct preconditions should never revert 
  - Strike > 0 
  - Sigma is between [1, 1e7]
  - Gamma is between [9000,10000]
  - Maturity is in the future
- Invalid engine creation states 
  - Gamma > 10000 should always revert 
  - Maturity in the past should always revert 
  - Strike = 0 should always revert 
  - Sigma < 1 should always revert

## Deposits and Withdrawals 

**Engine Deposit**
- Users can never deposit 0 tokens into the system 
- Under correct preconditions, deposit should always increase a recipient's balance 
- Engine's risky and stable balance should always increase

**Engine Withdrawals** 
- Users can never withdraw 0 tokens 
- A withdrawal should reduce msg.sender's margin balance 
- Engine's risky and stable balances should always decrease

**Inter-related Operations** 
- A deposit and withdrawal should result in the same pre- and post-margin balances 

## Remove and Allocate
**Engine Allocate** 
- Liquidity chooses the minimum of the liquidity factors 
- An allocation to a pool should result in an increase to pool reserves 

**Engine Remove** 
- Removing from a pool should result in a decrease to pool reserves 

## Running Code (for Part 5)

```
rm -rf cache artifacts && echidna-test . --contract LibraryMathEchidna --corpus-dir  corpus --test-mode assertion --format text 
```

**Configuration Options**:
- `--corpus-dir` is used to specify the directory to save the corpus 
- `--test-mode assertion` specifies echidna to search for `assert()` statements in their codebase