# Rust Token Contract

This is a Rust smart contract implementing an ERC-20 token on the StarkNet blockchain. The contract includes functionalities for token transfers, approvals, and minting based on a specific algorithm.

## ERC-20 Interface

The contract implements the ERC-20 interface with the following methods:

- `name()`: Returns the name of the token.
- `symbol()`: Returns the symbol of the token.
- `decimals()`: Returns the number of decimal places the token has.
- `totalSupply()`: Returns the total supply of the token.
- `balanceOf(account)`: Returns the balance of the specified account.
- `allowance(owner, spender)`: Returns the allowance granted by the owner to the spender.
- `transfer(recipient, amount)`: Transfers a specified amount of tokens to the recipient.
- `transferFrom(sender, recipient, amount)`: Transfers a specified amount of tokens from one account to another.
- `approve(spender, amount)`: Approves the spender to spend a specified amount of tokens on behalf of the owner.

## Additional Features

The contract includes some additional features:

- **Minting**: The contract allows for minting new tokens based on a specific algorithm. Minting can be triggered by eligible candidates.

- **Block Rewards**: The contract defines a block reward mechanism that adjusts over time.

- **Candidate Application**: Addresses can apply to become minting candidates, and the contract tracks and applies the minting process accordingly.

## Contract Parameters

- `BLOCK_TIME`: The time (in seconds) between blocks.
- `BLOCK_HALVE_INTERVAL`: The block interval after which the block rewards halve.
- `MAX_SUPPLY`: The maximum supply limit for the token.

## How to Use

1. Deploy the contract by providing the `name` and `symbol` parameters.
2. Interact with the contract through the defined ERC-20 methods.
3. Mint new tokens by applying as a candidate and triggering the minting process.

## Adjustments Made

The initial code was adjusted to modify the block time, block halve interval, max supply, and block rewards to better suit specific requirements.

Feel free to explore and modify the code according to your project needs.
