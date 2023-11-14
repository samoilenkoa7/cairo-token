use starknet::test::*;
use starknet::ContractAddress;

fn main() -> felt252 {
    fib(16)
}

fn fib(mut n: felt252) -> felt252 {
    let mut a: felt252 = 0;
    let mut b: felt252 = 1;
    loop {
        if n == 0 {
            break a;
        }
        n = n - 1;
        let temp = b;
        b = a + b;
        a = temp;
    }
}

#[cfg(test)]
mod tests {
    use super::fib;

    #[test]
    #[available_gas(100000)]
    fn it_works() {
        assert_eq!(fib(16), 987, "it works!");
    }

    #[test]
    fn test_transfer() {
        let mut contract = deploy_contract!();
        let alice = Account::new([1; 32]);
        let bob = Account::new([2; 32]);

        contract
            .view(Token::name)
            .as(alice)
            .commit()
            .assert_success()
            .assert_result("Token");

        let initial_balance_alice: u256 = contract
            .view(Token::balanceOf)
            .with_args(alice.contract_address())
            .commit()
            .assert_success()
            .get_result();

        let initial_balance_bob: u256 = contract
            .view(Token::balanceOf)
            .with_args(bob.contract_address())
            .commit()
            .assert_success()
            .get_result();

        // Transfer 100 tokens from Alice to Bob
        contract
            .external(Token::transfer)
            .as(alice)
            .with_args(bob.contract_address(), 100.into())
            .commit()
            .assert_success();

        let final_balance_alice: u256 = contract
            .view(Token::balanceOf)
            .with_args(alice.contract_address())
            .commit()
            .assert_success()
            .get_result();

        let final_balance_bob: u256 = contract
            .view(Token::balanceOf)
            .with_args(bob.contract_address())
            .commit()
            .assert_success()
            .get_result();

        // Check if balances are updated correctly
        assert_eq!(initial_balance_alice - 100.into(), final_balance_alice);
        assert_eq!(initial_balance_bob + 100.into(), final_balance_bob);
    }

    #[test]
    fn test_approval_and_transfer_from() {
        let mut contract = deploy_contract!();
        let alice = Account::new([1; 32]);
        let bob = Account::new([2; 32]);
        let charlie = Account::new([3; 32]);

        // Approve Bob to spend 50 tokens on behalf of Alice
        contract
            .external(Token::approve)
            .as(alice)
            .with_args(bob.contract_address(), 50.into())
            .commit()
            .assert_success();

        let allowance: u256 = contract
            .view(Token::allowance)
            .with_args(alice.contract_address(), bob.contract_address())
            .commit()
            .assert_success()
            .get_result();

        assert_eq!(50.into(), allowance);

        // Bob transfers 30 tokens from Alice to Charlie using the allowance
        contract
            .external(Token::transferFrom)
            .as(bob)
            .with_args(alice.contract_address(), charlie.contract_address(), 30.into())
            .commit()
            .assert_success();

        let final_balance_alice: u256 = contract
            .view(Token::balanceOf)
            .with_args(alice.contract_address())
            .commit()
            .assert_success()
            .get_result();

        let final_balance_charlie: u256 = contract
            .view(Token::balanceOf)
            .with_args(charlie.contract_address())
            .commit()
            .assert_success()
            .get_result();

        // Check if balances are updated correctly
        assert_eq!(70.into(), final_balance_alice);
        assert_eq!(30.into(), final_balance_charlie);
    }
}
