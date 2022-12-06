# Part 4: Fuzzing Uniswap V2 (Part 4)

## Sections

Welcome to Part 3 of the Echidna streaming series. This part has two sections:

- [Uni-V2](./contracts/uni-v2/): This directory contains the logic of the Uniswap V2 Codebase. In the workshop we examined the router and its interactions with the pair. Try using Echidna in property mode and testing global system properties!
- [Crytic](./contracts/crytic/): This directory shows how to use Echidna on the Uniswap V2 Core contracts. You can use the setup as a template, try making your own tests!

## Slides

The slides for this part can be found [here](./Echidna-Streaming-Session-Part-3.pdf).

## Video Presentation

The video presentation for this part can be found on [YouTube](https://www.youtube.com/watch?v=OPDA0L9SeNI).

## Prerequisites 

Because Uniswap V2 is a Hardhat project, before being able to fuzz it with Echidna, you have to install its dependencies.

Run the following commands:

```
git clone git@github.com:crytic/echidna-streaming-series
cd part4
npm install
echidna-test . --contract EchidnaUniV2Tester --config contracts/crytic/config.yaml
```
