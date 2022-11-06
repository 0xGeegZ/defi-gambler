# Introduction
Defi Gambler is my first project developed to learn Solidity and Web3. Il is a game like pooltogether where pepole deposit funds that are used to generate yeld by farming on DEX PancakeSwap. User can win his yeld for the last 10 days directly if he is lucky enought. 

There are multiple games with differents probability to won and different yield correlation with probability of won.

Working on two version : 
- One with native Blockchain Token (BNB for BNB Chain)
- One with ERC20/BEP20 tokens (PancakeSwap in our cas)

# Current Working Branch : POC

Working FIles :
- Contract : contracts/GameCAKE.sol
- Test : test/GameCAKE.test.js

# HOW TO USE IT

## Instal dependencies
```bash
yarn
```

## Test

```bash
yarn test
```

## Coverage

```bash
yarn coverage
```

I tried to implement project with both Truffle and Hardhat to check differences between those two main tools for develoipping smart contracts. 

TODO : 
Finalize test coverage and manage multiple contracts implementation to handle 
