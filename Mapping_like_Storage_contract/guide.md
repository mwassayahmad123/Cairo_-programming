# Mappings in Cairo Programming Language
### A Complete Research Document

---

## 1. Introduction to Cairo

Cairo is a programming language developed by **StarkWare Industries** for writing provable programs. It is the native language of **StarkNet** — a decentralized, permissionless Layer 2 (L2) validity rollup built on top of Ethereum.

Unlike traditional smart contract languages like Solidity, Cairo is designed around **ZK-STARKs** (Zero-Knowledge Scalable Transparent ARguments of Knowledge), which means every program execution can be mathematically proven correct without revealing private data.

Cairo 1.0 (the modern version) has a syntax heavily inspired by **Rust**, making it safer and more developer-friendly than the original Cairo 0.

### Why Cairo Matters
- Enables cheap and fast transactions on StarkNet
- Provides mathematical proof of computation correctness
- Powers DeFi, NFT, and gaming applications on Ethereum's L2
- Every StarkNet smart contract is written in Cairo

---

## 2. What is a Mapping?

A **mapping** is a fundamental data structure in smart contract development. It stores data as **key → value** pairs, similar to:

| Language | Name |
|----------|------|
| Python | Dictionary (`dict`) |
| Rust | `HashMap` |
| Solidity | `mapping` |
| Java | `HashMap` |
| Cairo | `LegacyMap` |

### Simple Mental Model

Think of a mapping like a **locker system** at a gym:
- Every locker has a **unique number** (the key)
- Inside each locker is **your stuff** (the value)
- You can only open a locker if you know its exact number
- You cannot see all lockers at once — only one at a time

```
Key          →     Value
---------          -------
Locker #5    →     Ali's bag
Locker #12   →     Sara's bag
Locker #99   →     Ahmed's bag
```

In a smart contract:
```
Key             →     Value
-----------           -------
Wallet Address  →     Token Balance
Student ID      →     Grade
User Address    →     Has Voted (true/false)
Token ID        →     Owner Address
```

---

## 3. Mappings in Cairo — The LegacyMap Type

In Cairo 1.x (StarkNet contracts), the mapping type is called **`LegacyMap`**.

It is declared inside the `#[storage]` struct — a special block that holds all persistent (on-chain) data of the contract.

### Basic Syntax

```cairo
#[storage]
struct Storage {
    mapping_name: LegacyMap::<KeyType, ValueType>,
}
```

### Real Examples

```cairo
use starknet::ContractAddress;

#[storage]
struct Storage {
    // Address → Balance (for tokens)
    balances: LegacyMap::<ContractAddress, u256>,

    // Address → Has voted? (for voting systems)
    has_voted: LegacyMap::<ContractAddress, bool>,

    // Student ID → Score (for grade systems)
    scores: LegacyMap::<u32, u8>,

    // ID → Name (for registries)
    names: LegacyMap::<u32, felt252>,
}
```

---

## 4. How Mappings Work Internally

### 4.1 Storage Slots on StarkNet

StarkNet's storage is a giant table of `(address, key) → value` pairs. Every storage variable in your contract maps to a unique **storage slot**.

For a mapping, the slot is calculated using a **Pedersen Hash** of:
1. The variable name (e.g., `"balances"`)
2. The key (e.g., a wallet address)

```
storage_slot = pedersen_hash("balances", wallet_address)
```

This guarantees every `(mapping_name, key)` combination has a unique slot on-chain.

### 4.2 Default Values

If you read a key that was **never written to**, Cairo returns the **zero/default value** for that type:

| Type | Default Value |
|------|--------------|
| `u8, u16, u32, u64, u128, u256` | `0` |
| `bool` | `false` |
| `felt252` | `0` |
| `ContractAddress` | Zero address |

This means mappings in Cairo are **implicitly infinite** — every possible key exists with a zero default.

### 4.3 No Iteration

Mappings in Cairo (like in Solidity) **cannot be iterated**. You cannot loop through all keys. The blockchain only stores individual slots — there is no internal list of which keys were written.

**Workaround:** Maintain a separate array of keys if you need iteration.

---

## 5. Reading and Writing to Mappings

### 5.1 Writing a Value (`.write`)

```cairo
// Syntax: self.mapping_name.write(key, value);

self.balances.write(user_address, 1000_u256);
self.has_voted.write(voter_address, true);
self.scores.write(1_u32, 95_u8);
```

### 5.2 Reading a Value (`.read`)

```cairo
// Syntax: let variable = self.mapping_name.read(key);

let balance = self.balances.read(user_address);     // returns u256
let voted   = self.has_voted.read(voter_address);   // returns bool
let score   = self.scores.read(1_u32);              // returns u8
```

### 5.3 Full Example Function

```cairo
fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) {
    let caller = get_caller_address();

    // READ: get sender's current balance
    let sender_balance = self.balances.read(caller);

    // Check sender has enough
    assert(sender_balance >= amount, 'Insufficient balance');

    // READ: get receiver's current balance
    let receiver_balance = self.balances.read(to);

    // WRITE: update both balances
    self.balances.write(caller, sender_balance - amount);
    self.balances.write(to, receiver_balance + amount);
}
```

---

## 6. Supported Key and Value Types

### Key Types

| Type | Description | Example Use |
|------|-------------|-------------|
| `ContractAddress` | Wallet or contract address | Token balances |
| `felt252` | Cairo's native 252-bit field element | General purpose keys |
| `u8` | 8-bit unsigned integer (0–255) | Subject IDs, small indices |
| `u16` | 16-bit unsigned integer | Medium indices |
| `u32` | 32-bit unsigned integer | Student IDs, item IDs |
| `u64` | 64-bit unsigned integer | Timestamps, large IDs |
| `u128` | 128-bit unsigned integer | Large numerical keys |
| `u256` | 256-bit unsigned integer | Token IDs in NFTs |
| `bool` | Boolean | Rarely used as key |
| `(T1, T2)` | Tuple of types | Nested mappings |

### Value Types

Value can be any type that implements the **`Store`** trait, including:
- All integer types (`u8`, `u16`, `u32`, `u64`, `u128`, `u256`)
- `bool`
- `felt252`
- `ContractAddress`
- Structs (if they implement `Store`)

---

## 7. Nested Mappings

Cairo does not have true nested mapping syntax like `mapping(address => mapping(uint => uint))` in Solidity. Instead, it uses **tuple keys** to achieve the same result.

### Solidity Nested Mapping (for comparison):
```solidity
mapping(address => mapping(uint256 => uint256)) public subjectGrades;
// Access: subjectGrades[student][subjectId]
```

### Cairo Equivalent — Tuple Key:
```cairo
#[storage]
struct Storage {
    // (student_address, subject_id) → grade
    subject_grades: LegacyMap::<(ContractAddress, u8), u8>,
}

// Write:
self.subject_grades.write((student_addr, 1_u8), 90_u8);

// Read:
let grade = self.subject_grades.read((student_addr, 1_u8));
```

The tuple `(ContractAddress, u8)` acts as a **composite key**. Internally, Cairo hashes both parts together to form a unique storage slot.

### Triple Nested (Three-part tuple):
```cairo
permissions: LegacyMap::<(ContractAddress, ContractAddress, u8), bool>,
// (owner, operator, token_type) → is_approved
```

---

## 8. Multiple Mappings in One Contract

A real contract often uses **several mappings together**. Here is how a token contract might look:

```cairo
#[storage]
struct Storage {
    // ERC-20 style: address → token balance
    balances: LegacyMap::<ContractAddress, u256>,

    // ERC-20 style: (owner, spender) → how much spender can use
    allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,

    // NFT style: token_id → owner address
    owners: LegacyMap::<u256, ContractAddress>,

    // Access control: address → is admin?
    is_admin: LegacyMap::<ContractAddress, bool>,

    // Total supply (not a mapping, just a single value)
    total_supply: u256,
}
```

---

## 9. Mappings vs Arrays vs Single Variables

| Feature | Mapping (`LegacyMap`) | Array (`Array<T>`) | Single Variable |
|---------|----------------------|-------------------|-----------------|
| Access pattern | By any key | By integer index | Direct |
| Iterable | ❌ No | ✅ Yes | N/A |
| Default value | Zero for any key | Must push elements | Must initialize |
| Storage cost | Per key written | Per element | Fixed |
| Best for | Lookups (balance, ownership) | Ordered lists | Counters, flags |
| Key type | Any supported type | Only `u32` index | N/A |
| Can check "exists" | ❌ No (returns 0) | ✅ Yes (check length) | N/A |

---

## 10. Common Real-World Use Cases

### 10.1 Token Balances (ERC-20)
```cairo
balances: LegacyMap::<ContractAddress, u256>
// Every wallet address maps to how many tokens it holds
```

### 10.2 NFT Ownership (ERC-721)
```cairo
owners: LegacyMap::<u256, ContractAddress>
// Every token ID maps to the address that owns it
```

### 10.3 Voting System
```cairo
has_voted: LegacyMap::<ContractAddress, bool>
votes_for_candidate: LegacyMap::<felt252, u32>
// Track who voted, and how many votes each candidate has
```

### 10.4 Access Control / Whitelist
```cairo
is_whitelisted: LegacyMap::<ContractAddress, bool>
role: LegacyMap::<ContractAddress, u8>
// 0 = no role, 1 = admin, 2 = moderator
```

### 10.5 Allowance System (like ERC-20 approve)
```cairo
allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>
// (owner, spender) → how much the spender is allowed to use
```

### 10.6 Student Grade Book
```cairo
grades:         LegacyMap::<ContractAddress, u8>
subject_grades: LegacyMap::<(ContractAddress, u8), u8>
is_registered:  LegacyMap::<ContractAddress, bool>
```

---

## 11. Limitations of Mappings

| Limitation | Explanation |
|------------|-------------|
| **Not iterable** | You cannot loop through all stored keys |
| **No length/count** | No built-in way to count how many keys were written |
| **No deletion** | You can only overwrite with `0` or default — there is no `delete` |
| **No existence check** | Reading an unwritten key returns `0`, not an error |
| **Key must be known** | You must know the exact key to retrieve a value |

### How to Work Around These Limitations

```cairo
#[storage]
struct Storage {
    // The mapping itself
    grades: LegacyMap::<ContractAddress, u8>,

    // Companion array to track all keys (for iteration)
    student_list: LegacyMap::<u32, ContractAddress>,

    // Manual count of how many keys exist
    student_count: u32,
}

// When writing to the mapping, also record the key:
fn add_student(ref self: ContractState, student: ContractAddress, grade: u8) {
    self.grades.write(student, grade);

    let count = self.student_count.read();
    self.student_list.write(count, student);  // record the key
    self.student_count.write(count + 1);       // increment counter
}
```

---

## 12. Mappings and Gas / Fees

On StarkNet, every storage write costs a fee (paid in ETH or STRK). Here are best practices:

- **Minimize writes** — only write when value actually changes
- **Batch operations** — combine multiple changes in one transaction
- **Avoid redundant reads** — cache the value in a local variable if reading multiple times

```cairo
// BAD — reads the same value twice from storage (costs more)
if self.balances.read(addr) > 0 {
    let b = self.balances.read(addr);
    self.balances.write(addr, b - 1);
}

// GOOD — read once, reuse
let balance = self.balances.read(addr);
if balance > 0 {
    self.balances.write(addr, balance - 1);
}
```

---

## 13. Summary

| Concept | Detail |
|---------|--------|
| **Type name** | `LegacyMap::<KeyType, ValueType>` |
| **Declared in** | `#[storage]` struct |
| **Write** | `self.mapping.write(key, value)` |
| **Read** | `self.mapping.read(key)` |
| **Default** | Zero/false for unwritten keys |
| **Nested** | Use tuple keys `(T1, T2)` |
| **Iterable** | No |
| **Storage** | Pedersen hash of (variable name + key) |
| **Used for** | Balances, ownership, access control, voting |

---

## 14. References

- [Cairo Book — Contract Storage](https://book.cairo-lang.org/ch14-01-contract-storage.html)
- [StarkNet Documentation](https://docs.starknet.io)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
- [Scarb Package Manager](https://docs.swmansion.com/scarb/)
- [StarkNet Foundry (Testing)](https://foundry-rs.github.io/starknet-foundry/)

---

*Research compiled for the Cairo Programming Assignments — Mappings Topic*
