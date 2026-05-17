// Attendance Tracker Smart Contract
// I built this to track student attendance on the blockchain
// instead of using a paper register that can be lost or faked
// Author: Maheen Fatima

// These imports are needed so we can read and write to blockchain storage
// without them Cairo literally has no idea what .read() and .write() mean
use starknet::storage::StorageMapReadAccess;
use starknet::storage::StorageMapWriteAccess;
use starknet::storage::StoragePointerReadAccess;
use starknet::storage::StoragePointerWriteAccess;

// This is the interface — basically a list of functions our contract promises to have
// think of it like a menu of what the contract can do
#[starknet::interface]
trait IAttendance<TContractState> {
    fn mark_attendance(ref self: TContractState);
    fn get_attendance(self: @TContractState, student: starknet::ContractAddress) -> u32;
    fn get_total_classes(self: @TContractState) -> u32;
    fn add_class(ref self: TContractState);
}

// The actual contract starts here
#[starknet::contract]
mod AttendanceTracker {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::Map;
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StorageMapWriteAccess;
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;

    // Storage is where all the data lives permanently on the blockchain
    // once something is written here it stays forever
    #[storage]
    struct Storage {
        // each student address points to how many classes they attended
        // works like a dictionary — student address is the key, count is the value
        attendance: Map<ContractAddress, u32>,
        // keeps track of how many total classes have been held so far
        total_classes: u32,
    }

    // Here we actually write out what each function does
    #[abi(embed_v0)]
    impl AttendanceImpl of super::IAttendance<ContractState> {

        // student calls this themselves to mark that they showed up today
        // get_caller_address() figures out who is calling the function automatically
        fn mark_attendance(ref self: ContractState) {
            let student = get_caller_address();
            let current = self.attendance.read(student);
            self.attendance.write(student, current + 1);
        }

        // anyone can call this to see how many classes a student attended
        // it just reads from storage and returns the number
        fn get_attendance(self: @ContractState, student: ContractAddress) -> u32 {
            self.attendance.read(student)
        }

        // returns how many classes have happened in total
        // useful to calculate attendance percentage later
        fn get_total_classes(self: @ContractState) -> u32 {
            self.total_classes.read()
        }

        // teacher calls this whenever a new class is held
        // it just adds 1 to the total class count
        fn add_class(ref self: ContractState) {
            let current = self.total_classes.read();
            self.total_classes.write(current + 1);
        }
    }
}