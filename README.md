# Echidna Streaming Workshop

Welcome to the 6-part series on how to use Echidna to fuzz like a pro! This repository has 6 folders, each of which maps to a specific workshop in the series.


To learn more about how these workshops will work, please read this [blogpost](https://blog.trailofbits.com/2022/11/14/livestream-workshop-fuzzing-echidna-slither/).


Note that each workshop will be live streamed on Trail of Bits' [Twitch channel](https://www.twitch.tv/trailofbits) and [YouTube channel](https://www.youtube.com/user/trailofbits) at **12 PM EST** on the following days:

## Beginner

[Part 1](part1/README.md): The Basics (streaming on **Nov 16, 2022**)

[Part 2](part2/README.md): Fuzzing arithmetics and functions (streaming on **Nov 22, 2022**)

## Intermediate

[Part 3](part3/README.md): Introduction to AMM’s invariants (streaming on **Nov 30, 2022**)

[Part 4](part4/README.md): AMM fuzzing (streaming on **Dec 6, 2022**)

## Advanced

[Part 5](part5/README.md): Introduction to advanced DeFi’s invariants (streaming on **Dec 14, 2022**)

[Part 6](part6/README.md): Advanced DeFi invariants (streaming on **Dec 21, 2022**)

### Additional Notes
- This repository will be migrated to the [`building-secure-contracts`](https://github.com/crytic/building-secure-contracts) repository at the end of the series. We will update
this README when that time comes.
- This repository will be updated as the series continues. Thus, there might be some incomplete folders / broken links in the process.

# Try your own invariants! 

**ABDK Math** 
- Associative property of multiplication – `(x * y) * z = x * (y * z) `
- Distributive property of multiplication – `x * (y + z) = (x * y) + (x * z) `
- Multiplication of inverses (using the `inv` function) – `inv(x * y) = inv(x) * inv(y)`
- Square roots – `sqrt(x) * sqrt(x) = x`
- Logarithms – `log2(x * y) = log2(x) * log2(y)`
- Average `gavg()`
- Power `pow()`
- Natural logarithm – `ln()`
- Exponentiation – `exp()`

**Uniswap V2**
- Path independence for swaps
- Pool invariant always increases
- LP tokens are minted differently based on existing pool liquidity 
- An LP provider's underlying asset balances are monotonically increasing
- Path independence for LPs

# Echidna Installation

- Download [relevant binaries for your system](https://github.com/crytic/echidna/releases/tag/v2.0.4) 
- Add to PATH* (All commands in respective README documents assume `echidna-test` refers to the binary) 

