use starknet::test::*;

#[test]
fn test_transfer() {
    let mut contract = deploy_contract!();
    let alice = Account::new([1; 32]);
    let bob = Account::new([2; 32]);

    // View contract name and check if it matches the expected value.
    contract
        .view(Token::name)
        .as(alice)
        .commit()
        .assert_success()
        .assert_result("Token");

    // Get initial balances of Alice and Bob.
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

    // Transfer 100 tokens from Alice to Bob.
    contract
        .external(Token::transfer)
        .as(alice)
        .with_args(bob.contract_address(), 100.into())
        .commit()
        .assert_success();

    // Get final balances of Alice and Bob.
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

    // Check if balances are updated correctly.
    assert_eq!(initial_balance_alice - 100, final_balance_alice);
    assert_eq!(initial_balance_bob + 100, final_balance_bob);
}

#[test]
fn test_approval_and_transfer_from() {
    let mut contract = deploy_contract!();
    let alice = Account::new([1; 32]);
    let bob = Account::new([2; 32]);
    let charlie = Account::new([3; 32]);

    // Approve Bob to spend 50 tokens on behalf of Alice.
    contract
        .external(Token::approve)
        .as(alice)
        .with_args(bob.contract_address(), 50.into())
        .commit()
        .assert_success();

    // Get allowance and check if it matches the expected value.
    let allowance: u256 = contract
        .view(Token::allowance)
        .with_args(alice.contract_address(), bob.contract_address())
        .commit()
        .assert_success()
        .get_result();

    assert_eq!(50, allowance);

    // Bob transfers 30 tokens from Alice to Charlie using the allowance.
    contract
        .external(Token::transferFrom)
        .as(bob)
        .with_args(alice.contract_address(), charlie.contract_address(), 30.into())
        .commit()
        .assert_success();

    // Get final balances of Alice and Charlie.
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

    // Check if balances are updated correctly.
    assert_eq!(70, final_balance_alice);
    assert_eq!(30, final_balance_charlie);
}
