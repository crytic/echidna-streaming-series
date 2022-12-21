## Writing Tests 

1. Unzip the corpus.zip file 
2. Update addresses in the E2E Contract
3. Start writing assertion properties 

# Run Echidna 

```
rm -rf crytic-compile artifacts cache && echidna-test . --contract EchidnaE2E --config contracts/crytic/E2ECore.yaml
```

## E2E Setup

Note: This only needs to be done when the target code *changes*.

1. In a terminal, run the following: 
```
etheno --ganache --ganache-args "--deterministic --gasLimit 10000000" -x ./contracts/crytic/init.json
```
2. In a separate terminal, run the following: 
```
npx hardhat test test/deploy.ts --network localhost
```
3. Go back to the terminal with Etheno (Step 1) and kill Etheno with `Ctrl+C`
4. Let's start writing properties! 
