use starknet::ContractAddress;

#[abi]
trait IERC20 {
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn decimals() -> u8;
    fn totalSupply() -> u256;
    fn balanceOf(account: ContractAddress) -> u256;
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(recipient: ContractAddress, amount: u256) -> bool;
    fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(spender: ContractAddress, amount: u256) -> bool;
}

#[contract]
mod Token {
    use super::IERC20;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_tx_info};
    use zeroable::Zeroable;

    const DECIMAL_PART: u128 = 1_000_000_000_000_000_000;

    const BLOCK_TIME: u64 = 60; // Increased block time to 60 seconds
    const BLOCK_HALVE_INTERVAL: u64 = 500_000; // Increased block halve interval
    const MAX_SUPPLY: u128 = 10_000_000_000_000_000_000_000_000; // Increased max supply

    struct Storage {
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        start_time: u64,
        mint_count: u64,
        mint_candidates_count: u64,
        mint_candidates: LegacyMap<ContractAddress, u64>,
        mint_candidates_index: LegacyMap<u64, ContractAddress>,
        mint_flag: u64,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    #[event]
    fn Apply(candidate: ContractAddress, mint_flag: u64) {}
    fn RepeatApply(candidate: ContractAddress, mint_flag: u64) {}

    impl Token of IERC20 {
        fn name() -> felt252 {
            Storage::name
        }

        fn symbol() -> felt252 {
            Storage::symbol
        }

        fn decimals() -> u8 {
            18
        }

        fn totalSupply() -> u256 {
            Storage::total_supply
        }

        fn balanceOf(account: ContractAddress) -> u256 {
            Storage::balances[account]
        }

        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
            Storage::allowances[(owner, spender)]
        }

        fn transfer(recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            Storage::_transfer(sender, recipient, amount);
            true
        }

        fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            Storage::_spend_allowance(sender, caller, amount);
            Storage::_transfer(sender, recipient, amount);
            true
        }

        fn approve(spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            Storage::_approve(caller, spender, amount);
            true
        }
    }

    #[constructor]
    fn constructor(name: felt252, symbol: felt252) {
        Storage::name = name;
        Storage::symbol = symbol;
        Storage::start_time = get_block_timestamp();
        Storage::mint_flag = 1;
    }

    #[view]
    fn name() -> felt252 {
        Token::name()
    }

    #[view]
    fn symbol() -> felt252 {
        Token::symbol()
    }

    #[view]
    fn decimals() -> u8 {
        Token::decimals()
    }

    #[view]
    fn totalSupply() -> u256 {
        Token::totalSupply()
    }

    #[view]
    fn balanceOf(account: ContractAddress) -> u256 {
        Token::balanceOf(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        Token::allowance(owner, spender)
    }

    #[view]
    fn start_time() -> u64 {
        Storage::start_time
    }

    #[view]
    fn mint_count() -> u64 {
        Storage::mint_count
    }

    #[view]
    fn mint_candidates_count() -> u64 {
        Storage::mint_candidates_count
    }

    #[view]
    fn is_mint_candidate(candidate: ContractAddress) -> bool {
        if Storage::available_mint_count() > 0 {
            return false;
        }
        Storage::mint_candidates[candidate] == Storage::mint_flag
    }

    #[view]
    fn available_mint_count() -> u64 {
        let now = get_block_timestamp();
        let can_mint_count = (now - Storage::start_time) / BLOCK_TIME;
        can_mint_count - Storage::mint_count
    }

    #[view]
    fn block_time() -> u64 {
        BLOCK_TIME
    }

    #[view]
    fn max_supply() -> u256 {
        u256 { low: MAX_SUPPLY, high: 0 }
    }

    #[view]
    fn block_halve_interval() -> u64 {
        BLOCK_HALVE_INTERVAL
    }

    #[view]
    fn block_reward() -> u256 {
        let already_minted = Storage::mint_count;
        let n = already_minted / BLOCK_HALVE_INTERVAL;
        match n {
            0 => u256 { low: 8_000_000_000_000_000_000_000_u128, high: 0 }, // Adjusted block rewards
            1 => u256 { low: 4_000_000_000_000_000_000_000_u128, high: 0 },
            2 => u256 { low: 2_000_000_000_000_000_000_000_u128, high: 0 },
            3 => u256 { low: 1_000_000_000_000_000_000_000_u128, high: 0 },
            4 => u256 { low: 500_000_000_000_000_000_000_u128, high: 0 },
            5 => u256 { low: 250_000_000_000_000_000_000_u128, high: 0 },
            6 => u256 { low: 125_000_000_000_000_000_000_u128, high: 0 },
            7 => u256 { low: 62_500_000_000_000_000_000_u128, high: 0 },
            8 => u256 { low: 31_250_000_000_000_000_000_u128, high: 0 },
            9 => u256 { low: 15_625_000_000_000_000_000_u128, high: 0 },
            _ => u256 { low: 8_000_000_000_000_000_000_000_u128, high: 0 },
        }
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) -> bool {
        Token::transfer(recipient, amount)
    }

    #[external]
    fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
        Token::transferFrom(sender, recipient, amount)
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool {
        Token::approve(spender, amount)
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        Storage::_increase_allowance(spender, added_value)
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        Storage::_decrease_allowance(spender, subtracted_value)
    }

    #[external]
    fn apply_mint() {
        let recipient = get_caller_address();
        Storage::_try_mint();
        Storage::_add_candidate(recipient);
    }

    #[internal]
    fn _increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        let caller = get_caller_address();
        Storage::_approve(caller, spender, Storage::allowances[(caller, spender)] + added_value);
        true
    }

    #[internal]
    fn _decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        let caller = get_caller_address();
        Storage::_approve(caller, spender, Storage::allowances[(caller, spender)] - subtracted_value);
        true
    }

    #[internal]
    fn _add_candidate(recipient: ContractAddress) {
        let candidate_flag = Storage::mint_candidates[recipient];
        let mint_flag = Storage::mint_flag;

        if candidate_flag != mint_flag {
            let mint_candidates_count = Storage::mint_candidates_count + 1;
            Storage::mint_candidates_count = mint_candidates_count;
            Storage::mint_candidates[recipient] = mint_flag;
            Storage::mint_candidates_index[mint_candidates_count] = recipient;
            Apply(recipient, mint_flag);
        } else {
            RepeatApply(recipient, mint_flag);
        }
    }

    #[internal]
    fn _clear_candidates() {
        Storage::mint_candidates_count = 0;
        Storage::mint_flag += 1;
    }

    #[internal]
    fn _get_seed() -> u128 {
        let transaction_hash: u256 = get_tx_info().unbox().transaction_hash.into();
        let ts_felt: felt252 = get_block_timestamp().into();
        let block_timestamp: u256 = ts_felt.into();
        (transaction_hash + block_timestamp).low
    }

    #[internal]
    fn _try_mint() {
        let candidates_count = Storage::mint_candidates_count;

        if candidates_count == 0 || Storage::available_mint_count() == 0 {
            return;
        }

        let max_supply = Storage::max_supply();
        let mint_times = min(Storage::available_mint_count(), candidates_count);
        let mut i: u64 = 0;
        let mut seed = Storage::_get_seed() % u128::from(u64::MAX);

        loop {
            if i >= mint_times || max_supply - Storage::total_supply < Storage::block_reward() {
                break;
            }

            i += 1;
            seed = (seed * 1103515245 + 12345) % 2147483648;
            let seed_felt: felt252 = seed.into();
            let seed_u64: u64 = seed_felt.try_into().unwrap();
            let index = (seed_u64 % candidates_count) + 1;

            let recipient = Storage::mint_candidates_index[index];
            Storage::mint_count += 1;
            Storage::_mint(recipient, Storage::block_reward());
        }

        Storage::_clear_candidates();
    }

    #[internal]
    fn _mint(recipient: ContractAddress, amount: u256) {
        assert!(Storage::total_supply + amount <= Storage::max_supply(), "max supply reached");
        Storage::total_supply += amount;
        Storage::balances[recipient] += amount;
        Transfer(Zeroable::zero(), recipient, amount);
    }

    #[internal]
    fn _burn(account: ContractAddress, amount: u256) {
        assert!(!account.is_zero(), "Token: burn from 0");
        assert!(Storage::balances[account] >= amount, "burn amount exceeds balance");

        Storage::total_supply -= amount;
        Storage::balances[account] -= amount;
        Transfer(account, Zeroable::zero(), amount);
    }

    #[internal]
    fn _approve(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert!(!owner.is_zero(), "Token: approve from 0");
        assert!(!spender.is_zero(), "Token: approve to 0");
        Storage::allowances[(owner, spender)] = amount;
        Approval(owner, spender, amount);
    }

    #[internal]
    fn _transfer(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert!(!sender.is_zero(), "Token: transfer from 0");
        assert!(!recipient.is_zero(), "Token: transfer to 0");
        Storage::balances[sender] -= amount;
        Storage::balances[recipient] += amount;
        Transfer(sender, recipient, amount);
    }

    #[internal]
    fn _spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = Storage::allowances[(owner, spender)];
        if current_allowance != BoundedInt::max() {
            Storage::_approve(owner, spender, current_allowance - amount);
        }
    }
}
