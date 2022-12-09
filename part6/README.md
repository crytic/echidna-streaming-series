# Run Echidna 

```
npx hardhat clean && npx hardhat compile && echidna-test . --contract EchidnaE2E --config contracts/crytic/E2ECore.yaml

```

## E2E Setup

Note: This only needs to be done when the target code *changes*.

1. In a terminal, run the following: 
``
etheno --ganache --ganache-args "--deterministic --gasLimit 10000000" -x ./contracts/crytic/init.json
```
1. In a separate terminal, run the following: 
```
npx hardhat test test/deploy.ts --network localhost
```
1. Go back to the terminal with Etheno (Step 1) and kill Etheno with `Ctrl+C`
