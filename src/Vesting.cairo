use std::cmp::min;
use std::convert::TryInto;
use zeroable::Zeroable;
use starknet::ContractAddress;
use starknet::felt::{felt252, u256};
use starknet::get_block_timestamp;
use starknet::get_caller_address;

const VESTING_INTERVAL: u64 = 60 * 60 * 24 * 30; // 30 days

#[abi]
trait IVesting {
    fn vest(amount: u256, start_timestamp: u64, duration: u64);
    fn claim();
}

#[contract]
mod Vesting {
    use super::IVesting;
    use starknet::ContractAddress;
    use starknet::felt::u256;
    use starknet::get_block_timestamp;

    struct VestingInfo {
        beneficiary: ContractAddress,
        total_amount: u256,
        start_timestamp: u64,
        duration: u64,
        claimed_amount: u256,
    }

    struct Storage {
        vesting_info: LegacyMap<ContractAddress, VestingInfo>,
    }

    impl Vesting of IVesting {
        fn vest(amount: u256, start_timestamp: u64, duration: u64) {
            let beneficiary = get_caller_address();
            let vesting_info = VestingInfo {
                beneficiary,
                total_amount: amount,
                start_timestamp,
                duration,
                claimed_amount: u256::zero(),
            };
            Storage::vesting_info[beneficiary] = vesting_info;
        }

        fn claim() {
            let beneficiary = get_caller_address();
            let mut vesting_info = Storage::vesting_info[beneficiary];
            let current_timestamp = get_block_timestamp();

            if current_timestamp < vesting_info.start_timestamp {
                // Vesting period has not started
                return;
            }

            let elapsed_time = current_timestamp - vesting_info.start_timestamp;
            let vesting_progress = min(elapsed_time / VESTING_INTERVAL, vesting_info.duration);

            let claimable_amount =
                (vesting_info.total_amount * vesting_progress) / vesting_info.duration;

            let claimed_amount =
                min(claimable_amount, vesting_info.total_amount - vesting_info.claimed_amount);

            if claimed_amount > u256::zero() {
                vesting_info.claimed_amount += claimed_amount;
                // Transfer the claimed amount to the beneficiary
                // (You need to implement your token transfer logic here)
            }

            Storage::vesting_info[beneficiary] = vesting_info;
        }
    }
}
