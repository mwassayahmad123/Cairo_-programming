# Attendance Tracker — Cairo Smart Contract

## What is this about?
So basically I built a smart contract that tracks student attendance.
Instead of a teacher marking a register by hand, this contract stores
attendance permanently on the blockchain — meaning no one can fake it,
delete it, or change it after the fact. Pretty cool honestly.

## First things first — what even is Cairo?
Cairo is a programming language specifically built for writing smart
contracts on StarkNet. StarkNet is a Layer 2 solution sitting on top
of Ethereum, which basically means it does everything Ethereum does
but faster and cheaper. Cairo uses something called ZK-STARKs under
the hood to prove computations are correct without revealing all the data.

## And what is a Smart Contract?
Think of it like a vending machine. You put in your input, it gives
you the output, no human needed in between. A smart contract is a
program that lives on the blockchain and runs automatically when certain
conditions are met. Nobody owns it, nobody can secretly edit it once
it is deployed. That is what makes it trustworthy.

## How my contract actually works
- Every student has a wallet address — like a digital ID
- A student calls `mark_attendance()` and their count goes up by 1
- Anyone can call `get_attendance()` to see how many classes someone attended
- The teacher uses `add_class()` to record that a class happened
- All of this data lives in `Storage` permanently on-chain

## Things I learned while doing this

### #[starknet::contract]
This is how you tell Cairo "hey this is a smart contract, treat it that way."

### #[storage]
This is where all the permanent data of the contract lives. Anything
written here survives forever on the blockchain.

### Map<ContractAddress, u32>
Works exactly like a dictionary. Each student address maps to a number
representing how many classes they attended.

### ContractAddress
Every wallet and every contract on StarkNet has one of these unique
addresses. It is how the blockchain identifies who is who.

### ref self vs @self
This tripped me up at first but basically:
- `ref self` means the function can change storage (write access)
- `@self` means the function can only look at storage (read only)

### StorageMapReadAccess and StorageMapWriteAccess
These are traits you have to import so Cairo knows you want to read
or write from a Map in storage. Without them the compiler complains.

## What I would add if I had more time
- A way for only the teacher (contract owner) to call `add_class()`
- Percentage calculator to show attendance percentage automatically
- Events that get emitted when someone marks attendance

## Resources that actually helped
- Cairo Book: https://book.cairo-lang.org/
- StarkNet Docs: https://docs.starknet.io/
- Scarb Docs: https://docs.swmansion.com/scarb/