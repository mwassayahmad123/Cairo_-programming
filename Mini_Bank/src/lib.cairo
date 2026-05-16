// ============================================================
// Mini Bank Smart Contract - Cairo Language
// Student: Sana Hashim
// Topic: Mini Bank (Deposit, Withdraw, Balance Check)
// ============================================================

use starknet::ContractAddress;

#[starknet::interface]
trait IMiniBank<TContractState> {
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
    fn get_balance(self: @TContractState, user: ContractAddress) -> u256;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256);
}

#[starknet::contract]
mod MiniBank {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        Map,
    };

    #[storage]
    struct Storage {
        balances: Map::<ContractAddress, u256>,
        owner: ContractAddress,
        total_deposits: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposited: Deposited,
        Withdrawn: Withdrawn,
        Transferred: Transferred,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposited {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawn {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Transferred {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.total_deposits.write(0);
    }

    #[abi(embed_v0)]
    impl MiniBankImpl of super::IMiniBank<ContractState> {

        // DEPOSIT: Add money to your account
        fn deposit(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Deposit must be > 0');
            let caller = get_caller_address();
            let current_balance = self.balances.read(caller);
            self.balances.write(caller, current_balance + amount);
            let total = self.total_deposits.read();
            self.total_deposits.write(total + amount);
            self.emit(Deposited { user: caller, amount: amount });
        }

        // WITHDRAW: Take money out of your account
        fn withdraw(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Withdraw must be > 0');
            let caller = get_caller_address();
            let current_balance = self.balances.read(caller);
            assert(current_balance >= amount, 'Insufficient balance');
            self.balances.write(caller, current_balance - amount);
            let total = self.total_deposits.read();
            self.total_deposits.write(total - amount);
            self.emit(Withdrawn { user: caller, amount: amount });
        }

        // GET BALANCE: Check how much money a user has
        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.balances.read(user)
        }

        // GET OWNER: Returns who owns this bank contract
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        // TRANSFER: Send money to another user
        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(amount > 0, 'Transfer must be > 0');
            let caller = get_caller_address();
            assert(caller != to, 'Cannot transfer to yourself');
            let sender_balance = self.balances.read(caller);
            assert(sender_balance >= amount, 'Insufficient balance');
            let receiver_balance = self.balances.read(to);
            self.balances.write(caller, sender_balance - amount);
            self.balances.write(to, receiver_balance + amount);
            self.emit(Transferred { from: caller, to: to, amount: amount });
        }
    }
}
