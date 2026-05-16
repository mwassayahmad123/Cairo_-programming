# Mini Bank Smart Contract — Complete Guide
**Student:** Sana Hashim  
**Topic:** Mini Bank  
**Language:** Cairo  
**Platform:** StarkNet Blockchain  

---

## Table of Contents
1. [What is Cairo?](#what-is-cairo)
2. [What is StarkNet?](#what-is-starknet)
3. [What is a Smart Contract?](#what-is-a-smart-contract)
4. [What is Scarb?](#what-is-scarb)
5. [Project Structure](#project-structure)
6. [Contract Explanation](#contract-explanation)
7. [Every Function Explained](#every-function-explained)
8. [Key Concepts Used](#key-concepts-used)
9. [How to Run This Project](#how-to-run-this-project)
10. [What I Learned](#what-i-learned)

---

## What is Cairo?

Cairo is a **programming language** created by StarkWare. It is specifically designed for writing **provable programs** — programs whose execution can be mathematically proven to be correct.

### Key Features of Cairo:
- **Safety first:** Cairo forces you to write code that can be verified mathematically
- **Smart contract language:** Used to write programs that run on the StarkNet blockchain
- **Strongly typed:** Every variable must have a defined type (like `u256`, `bool`, `felt252`)
- **No garbage collection:** Memory is managed automatically and safely
- **Inspired by Rust:** Cairo's syntax looks very similar to the Rust programming language

### Cairo vs Other Languages:

| Feature | Cairo | Solidity | Python |
|---|---|---|---|
| Purpose | StarkNet contracts | Ethereum contracts | General purpose |
| Speed | Very fast (STARK proofs) | Moderate | Moderate |
| Safety | Very high | Moderate | Low |
| Learning curve | Medium | Medium | Easy |

---

## What is StarkNet?

StarkNet is a **Layer 2 blockchain** built on top of Ethereum. Think of it like this:

- **Ethereum** = A very secure but slow and expensive highway
- **StarkNet** = A fast lane built on top of that highway

### Why StarkNet?
- **Cheaper:** Transactions cost much less than on Ethereum
- **Faster:** Can process thousands of transactions per second
- **Secure:** Uses advanced math called "STARK proofs" to guarantee correctness
- **Decentralized:** No single person controls it

### How STARK Proofs Work (Simple Version):
1. Many transactions happen on StarkNet
2. A mathematical "proof" is created that says "all these transactions were done correctly"
3. This tiny proof is sent to Ethereum for verification
4. Ethereum verifies the proof — much cheaper than running every transaction

---

## What is a Smart Contract?

A **smart contract** is a program that:
- Lives on the blockchain permanently
- Runs automatically when someone calls its functions
- Cannot be changed once deployed (unless designed to be upgradeable)
- Executes without needing a third party (like a bank or lawyer)

### Real World Analogy:
> A vending machine is like a smart contract. You put money in (input), press a button (call a function), and it automatically gives you a snack (output) — no human needed.

### Our Mini Bank Contract:
Our contract acts like a simple digital bank where:
- Anyone can **deposit** virtual money
- Anyone can **withdraw** their own money
- Anyone can **check** any account's balance
- Users can **transfer** money to each other

---

## What is Scarb?

**Scarb** is the package manager and build tool for Cairo. It is similar to:
- `npm` for JavaScript
- `pip` for Python
- `cargo` for Rust

### What Scarb Does:
- Compiles your Cairo code into machine-readable format
- Manages dependencies (libraries your code needs)
- Runs tests
- Organizes your project structure

---

## Project Structure

```
mini_bank/
│
├── Scarb.toml          ← Project configuration file (like package.json)
│
├── src/
│   └── lib.cairo       ← Main smart contract code
│
└── guide.md            ← This file! Explains everything
```

### File Explanations:

**`Scarb.toml`** — The configuration file:
- Defines the project name and version
- Lists dependencies (we depend on `starknet` library)
- Tells Scarb this is a StarkNet contract

**`src/lib.cairo`** — The main contract:
- Contains all the bank logic
- Defines storage, events, and functions

---

## Contract Explanation

### 1. The Interface (`IMiniBank`)
```cairo
#[starknet::interface]
trait IMiniBank<TContractState> {
    fn deposit(...);
    fn withdraw(...);
    fn get_balance(...);
    fn get_owner(...);
    fn transfer(...);
}
```
An **interface** is like a menu at a restaurant — it lists what functions are available without explaining how they work. This is important because other contracts can interact with our bank using just the interface.

---

### 2. Storage
```cairo
#[storage]
struct Storage {
    balances: starknet::storage::Map::<ContractAddress, u256>,
    owner: ContractAddress,
    total_deposits: u256,
}
```
**Storage** is where data is saved permanently on the blockchain.

- `balances` — A mapping (like a dictionary/hashmap) that stores each user's balance
- `owner` — The address of whoever deployed the contract
- `total_deposits` — Running total of all money in the bank

A `ContractAddress` is a unique 32-byte identifier for every user/contract on StarkNet — like a bank account number.

`u256` means an **unsigned 256-bit integer** — a very large number (0 to 2^256 - 1). This is used for token amounts to avoid overflow errors.

---

### 3. Events
```cairo
#[event]
enum Event {
    Deposited: Deposited,
    Withdrawn: Withdrawn,
    Transferred: Transferred,
}
```
**Events** are like receipts — they are logged permanently on the blockchain whenever something important happens. Anyone can read these logs later to see the history of the contract.

---

### 4. Constructor
```cairo
#[constructor]
fn constructor(ref self: ContractState, owner: ContractAddress) {
    self.owner.write(owner);
    self.total_deposits.write(0);
}
```
The **constructor** runs exactly once — when the contract is first deployed. It sets the initial owner and starts total deposits at zero.

---

## Every Function Explained

### `deposit(amount: u256)`
**Purpose:** Add money to your account  
**How it works:**
1. Checks that amount > 0 (can't deposit nothing)
2. Gets the caller's address using `get_caller_address()`
3. Reads their current balance from storage
4. Adds the new amount to their balance
5. Updates the total bank deposits
6. Emits a `Deposited` event as a log/receipt

```
User calls deposit(500)
  → Check: 500 > 0 ✓
  → Read balance: 0
  → Write balance: 0 + 500 = 500
  → Emit: Deposited(user=0xABC, amount=500)
```

---

### `withdraw(amount: u256)`
**Purpose:** Take money out of your account  
**How it works:**
1. Checks amount > 0
2. Gets the caller's address
3. Reads their balance
4. Checks they have enough (`balance >= amount`)
5. Subtracts the amount from their balance
6. Updates total bank deposits
7. Emits a `Withdrawn` event

```
User calls withdraw(200) [has 500]
  → Check: 200 > 0 ✓
  → Read balance: 500
  → Check: 500 >= 200 ✓
  → Write balance: 500 - 200 = 300
  → Emit: Withdrawn(user=0xABC, amount=200)
```

---

### `get_balance(user: ContractAddress) → u256`
**Purpose:** Check how much money any address has  
**How it works:**
1. Takes a user's address as input
2. Reads their balance from storage
3. Returns the value

This is a **view function** (uses `@ContractState` not `ref self`) — it reads data but never changes anything.

---

### `get_owner() → ContractAddress`
**Purpose:** Returns the owner's address  
**How it works:** Simply reads and returns the stored owner address.

---

### `transfer(to: ContractAddress, amount: u256)`
**Purpose:** Send money from your account to another user  
**How it works:**
1. Checks amount > 0
2. Gets caller's address (the sender)
3. Checks sender is not sending to themselves
4. Reads sender's balance
5. Checks sender has enough money
6. Reads receiver's balance
7. Subtracts from sender, adds to receiver
8. Emits a `Transferred` event

```
Alice (0xAAA, balance=500) transfers 100 to Bob (0xBBB, balance=50)
  → Check: 100 > 0 ✓
  → Check: 0xAAA != 0xBBB ✓
  → Alice balance: 500 - 100 = 400
  → Bob balance: 50 + 100 = 150
  → Emit: Transferred(from=0xAAA, to=0xBBB, amount=100)
```

---

## Key Concepts Used

### `ref self` vs `@self`
- `ref self: ContractState` — The function **can modify** storage (used in deposit, withdraw, transfer)
- `@self: ContractState` — The function **cannot modify** storage, read-only (used in get_balance, get_owner)

### `assert(condition, 'error message')`
This is Cairo's way of checking conditions. If the condition is false, the entire transaction **reverts** (cancels) and no changes are saved. This is critical for security.

### `Map::<Key, Value>`
A mapping is like a giant dictionary where:
- Key = user's address
- Value = their balance
Every key starts with a default value of 0 automatically.

### `u256`
A 256-bit unsigned integer. Used for token amounts because:
- It's large enough to hold any realistic amount
- It matches how Ethereum and StarkNet handle token values
- It prevents overflow (wrapping around to 0)

### `ContractAddress`
A special type representing a unique address on StarkNet. Every wallet and every contract has one.

---

## How to Run This Project

### Step 1: Install Scarb
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
source ~/.bashrc
scarb --version
```

### Step 2: Navigate to Project
```bash
cd mini_bank
```

### Step 3: Build the Contract
```bash
scarb build
```

### Step 4: Expected Output
```
Compiling mini_bank v0.1.0
Finished release target(s) in X seconds
```

If you see "Finished" — your contract compiled successfully!

### Step 5: Find the Output
Compiled files are in `target/dev/` folder:
- `mini_bank_MiniBank.contract_class.json` — The compiled contract

---

## What I Learned

1. **Cairo language basics** — Variables, types, functions, structs
2. **Smart contract structure** — Interface, storage, events, constructor, functions
3. **StarkNet concepts** — How Layer 2 blockchains work, STARK proofs
4. **Blockchain security** — Using `assert` to prevent invalid operations
5. **Event logging** — How to create permanent logs on the blockchain
6. **Scarb build tool** — How to compile and manage a Cairo project
7. **Storage mappings** — How to store and retrieve user data on-chain
8. **Access control** — Using `get_caller_address()` to know who is calling
9. **View vs State-changing functions** — The difference between reading and writing data
10. **u256 arithmetic** — Safe math for large blockchain values

---

*This guide was written as part of the Cairo Programming Assignment.*  
*Repository: Cairo_-programming / Sana_Hashim_Mini_Bank*
