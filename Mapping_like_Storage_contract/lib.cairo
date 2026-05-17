// ===========================================================
//  TOPIC  : Mappings (LegacyMap) in Cairo / StarkNet
//  FILE   : lib.cairo  (place this inside  src/lib.cairo)
//  CONTRACT: GradeBook — A Student Grade Management System
//
// ─────────────────────────────────────────────────────────
//  HOW TO RUN THIS FILE  (Step-by-Step)
// ─────────────────────────────────────────────────────────
//
//  STEP 1 — Install Scarb (Cairo's official build tool)
//  ─────────────────────────────────────────────────────
//  Scarb is like "npm" for Cairo. You need it to build
//  and test Cairo/StarkNet contracts.
//
//  Linux / macOS — open Terminal and paste:
//    curl --proto '=https' --tlsv1.2 -sSf \
//      https://docs.swmansion.com/scarb/install.sh | sh
//
//  Windows — download installer from:
//    https://docs.swmansion.com/scarb/download
//
//  Verify it installed correctly:
//    scarb --version
//    (you should see something like: scarb 2.6.x)
//
// ─────────────────────────────────────────────────────────
//
//  STEP 2 — Create a new Scarb project
//  ─────────────────────────────────────
//  In your terminal run:
//
//    scarb new gradebook
//    cd gradebook
//
//  This creates a folder called "gradebook" with:
//    gradebook/
//    ├── Scarb.toml      ← project config file
//    └── src/
//        └── lib.cairo   ← your Cairo code goes here
//
// ─────────────────────────────────────────────────────────
//
//  STEP 3 — Replace src/lib.cairo with this file
//  ───────────────────────────────────────────────
//  Open  gradebook/src/lib.cairo  in any text editor.
//  Delete everything inside it.
//  Copy and paste ALL the code below into it.
//  Save the file.
//
// ─────────────────────────────────────────────────────────
//
//  STEP 4 — Update Scarb.toml
//  ───────────────────────────
//  Open  gradebook/Scarb.toml  and replace its full
//  contents with exactly this:
//
//    [package]
//    name = "gradebook"
//    version = "0.1.0"
//    edition = "2023_11"
//
//    [dependencies]
//    starknet = ">=2.6.0"
//
//    [[target.starknet-contract]]
//
//  Save the file.
//
// ─────────────────────────────────────────────────────────
//
//  STEP 5 — Build the project
//  ───────────────────────────
//  In your terminal (inside the gradebook folder) run:
//
//    scarb build
//
//  Expected output on success:
//    Compiling gradebook v0.1.0
//    Finished release target(s) in 3s
//
//  The compiled contract appears in:  target/dev/
//
// ─────────────────────────────────────────────────────────
//
//  STEP 6 — Run the tests
//  ───────────────────────
//    scarb test
//
//  Expected output:
//    running 4 tests
//    test gradebook::GradeBook::tests::test_unregistered_returns_false ... ok
//    test gradebook::GradeBook::tests::test_default_grade_is_zero ... ok
//    test gradebook::GradeBook::tests::test_register_student_writes_name_mapping ... ok
//    test gradebook::GradeBook::tests::test_two_students_separate_mapping_entries ... ok
//    test result: ok. 4 passed; 0 failed;
//
// ─────────────────────────────────────────────────────────
//
//  GOOGLE COLAB ALTERNATIVE
//  ─────────────────────────
//  If you prefer to run in browser without local install:
//
//  1) Open https://colab.research.google.com
//  2) New notebook. In a code cell run:
//
//       !curl --proto '=https' --tlsv1.2 -sSf \
//         https://docs.swmansion.com/scarb/install.sh | sh
//       !~/.local/bin/scarb --version
//
//  3) Create the Scarb.toml file:
//
//       %%writefile /content/Scarb.toml
//       [package]
//       name = "gradebook"
//       version = "0.1.0"
//       edition = "2023_11"
//       [dependencies]
//       starknet = ">=2.6.0"
//       [[target.starknet-contract]]
//
//  4) Create the Cairo source file:
//
//       import os
//       os.makedirs("/content/src", exist_ok=True)
//
//       %%writefile /content/src/lib.cairo
//       <paste this entire file here>
//
//  5) Build:
//       !cd /content && ~/.local/bin/scarb build
//
//  6) Test:
//       !cd /content && ~/.local/bin/scarb test
//
// ===========================================================


// ----------------------------------------------------------
// INTERFACE
// Declares all the public functions that callers can use.
// Must be placed BEFORE the contract module in Cairo.
// ----------------------------------------------------------
#[starknet::interface]
trait IGradeBook<TContractState> {
    fn register_student(ref self: TContractState, name: felt252);

    fn assign_grade(
        ref self: TContractState,
        student: starknet::ContractAddress,
        grade: u8
    );

    fn assign_subject_grade(
        ref self: TContractState,
        student: starknet::ContractAddress,
        subject_id: u8,
        grade: u8
    );

    fn get_grade(
        self: @TContractState,
        student: starknet::ContractAddress
    ) -> u8;

    fn get_subject_grade(
        self: @TContractState,
        student: starknet::ContractAddress,
        subject_id: u8
    ) -> u8;

    fn get_student_name(
        self: @TContractState,
        student: starknet::ContractAddress
    ) -> felt252;

    fn is_student_registered(
        self: @TContractState,
        student: starknet::ContractAddress
    ) -> bool;

    fn get_total_students(self: @TContractState) -> u32;
}


// ----------------------------------------------------------
// CONTRACT MODULE
// ----------------------------------------------------------
#[starknet::contract]
mod GradeBook {

    use starknet::ContractAddress;
    use starknet::get_caller_address;

    // ======================================================
    //  STORAGE
    //  All data stored permanently on-chain lives here.
    //
    //  KEY CONCEPT:  LegacyMap::<KeyType, ValueType>
    //  ──────────────────────────────────────────────
    //  This is Cairo's mapping type.
    //  Think of it as a giant dictionary stored on-chain:
    //
    //    Key     →    Value
    //    ──────────────────
    //    0xABC   →    85      (Ali's grade)
    //    0xDEF   →    72      (Sara's grade)
    //    0x999   →    0       (unknown → default zero)
    //
    //  Any key never written returns ZERO by default.
    //  You can READ with .read(key)
    //  You can WRITE with .write(key, value)
    // ======================================================
    #[storage]
    struct Storage {

        // ── MAPPING 1 ──────────────────────────────────────
        // grades
        // Key:   ContractAddress  (student's wallet address)
        // Value: u8               (grade from 0 to 100)
        //
        // grades[0xABC...] = 85  means Ali scored 85 overall
        grades: LegacyMap::<ContractAddress, u8>,

        // ── MAPPING 2 ──────────────────────────────────────
        // student_names
        // Key:   ContractAddress  (student's wallet address)
        // Value: felt252          (student's name as short string)
        //
        // felt252 can store short text like 'Ali', 'Sara', etc.
        // student_names[0xABC...] = 'Ali'
        student_names: LegacyMap::<ContractAddress, felt252>,

        // ── MAPPING 3 ──────────────────────────────────────
        // is_registered
        // Key:   ContractAddress  (any wallet address)
        // Value: bool             (true = registered, false = not)
        //
        // is_registered[0xABC...] = true
        // is_registered[0x999...] = false  (never written → default)
        is_registered: LegacyMap::<ContractAddress, bool>,

        // ── MAPPING 4 — NESTED (Tuple Key) ─────────────────
        // subject_grades
        // Key:   (ContractAddress, u8)  ← TUPLE of two values
        // Value: u8                     (grade for that subject)
        //
        // Cairo uses tuple keys instead of nested mappings.
        // (0xABC..., 1) = 90  →  Ali scored 90 in subject 1
        // (0xABC..., 2) = 78  →  Ali scored 78 in subject 2
        // (0xDEF..., 1) = 65  →  Sara scored 65 in subject 1
        subject_grades: LegacyMap::<(ContractAddress, u8), u8>,

        // ── SINGLE VARIABLES (not mappings) ────────────────
        teacher: ContractAddress,  // address of the teacher/admin
        student_count: u32,        // total number of registered students
    }


    // ======================================================
    //  EVENTS — notify the outside world about state changes
    // ======================================================
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StudentRegistered: StudentRegistered,
        GradeAssigned: GradeAssigned,
        SubjectGradeAssigned: SubjectGradeAssigned,
    }

    #[derive(Drop, starknet::Event)]
    struct StudentRegistered {
        student: ContractAddress,
        name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct GradeAssigned {
        student: ContractAddress,
        grade: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct SubjectGradeAssigned {
        student: ContractAddress,
        subject_id: u8,
        grade: u8,
    }


    // ======================================================
    //  CONSTRUCTOR — runs once when the contract is deployed
    // ======================================================
    #[constructor]
    fn constructor(ref self: ContractState) {
        // get_caller_address() = the address that is deploying
        let deployer = get_caller_address();
        self.teacher.write(deployer);
        self.student_count.write(0_u32);
    }


    // ======================================================
    //  PUBLIC FUNCTIONS (External/ABI)
    // ======================================================
    #[abi(embed_v0)]
    impl GradeBookImpl of super::IGradeBook<ContractState> {

        // ──────────────────────────────────────────────────
        //  register_student
        //  Called by any student address to register.
        //
        //  MAPPING WRITES:
        //    student_names[caller] = name   ← stores name
        //    is_registered[caller] = true   ← marks registered
        // ──────────────────────────────────────────────────
        fn register_student(ref self: ContractState, name: felt252) {
            let caller = get_caller_address();

            // READ is_registered mapping to check if already registered
            let already = self.is_registered.read(caller);
            assert(!already, 'Already registered');

            // WRITE to student_names mapping
            // Syntax: self.mapping_name.write(key, value)
            self.student_names.write(caller, name);

            // WRITE to is_registered mapping
            self.is_registered.write(caller, true);

            // Increment student count
            let count = self.student_count.read();
            self.student_count.write(count + 1_u32);

            self.emit(StudentRegistered { student: caller, name });
        }


        // ──────────────────────────────────────────────────
        //  assign_grade
        //  Teacher assigns an overall grade to a student.
        //  Only the teacher (deployer) can call this function.
        //
        //  MAPPING WRITE:
        //    grades[student] = grade
        // ──────────────────────────────────────────────────
        fn assign_grade(ref self: ContractState, student: ContractAddress, grade: u8) {
            // Access control — only teacher can assign grades
            let caller = get_caller_address();
            let teacher = self.teacher.read();
            assert(caller == teacher, 'Only teacher allowed');

            // Grade must be valid
            assert(grade <= 100_u8, 'Grade must be 0 to 100');

            // READ is_registered mapping to verify student exists
            let registered = self.is_registered.read(student);
            assert(registered, 'Student not registered');

            // WRITE to grades mapping
            // stores the grade value under the student's address key
            self.grades.write(student, grade);

            self.emit(GradeAssigned { student, grade });
        }


        // ──────────────────────────────────────────────────
        //  assign_subject_grade
        //  Teacher assigns a grade for a specific subject.
        //
        //  NESTED MAPPING WRITE (tuple key):
        //    subject_grades[(student, subject_id)] = grade
        // ──────────────────────────────────────────────────
        fn assign_subject_grade(
            ref self: ContractState,
            student: ContractAddress,
            subject_id: u8,
            grade: u8
        ) {
            let caller = get_caller_address();
            let teacher = self.teacher.read();
            assert(caller == teacher, 'Only teacher allowed');
            assert(grade <= 100_u8, 'Grade must be 0 to 100');

            let registered = self.is_registered.read(student);
            assert(registered, 'Student not registered');

            // WRITE to nested mapping using TUPLE KEY
            // (student, subject_id) together form the unique key
            self.subject_grades.write((student, subject_id), grade);

            self.emit(SubjectGradeAssigned { student, subject_id, grade });
        }


        // ──────────────────────────────────────────────────
        //  get_grade
        //  Returns the overall grade of a student.
        //  Returns 0 if grade was never assigned (default).
        //
        //  MAPPING READ:
        //    return grades[student]
        // ──────────────────────────────────────────────────
        fn get_grade(self: @ContractState, student: ContractAddress) -> u8 {
            // READ from mapping
            // Syntax: self.mapping_name.read(key)
            self.grades.read(student)
        }


        // ──────────────────────────────────────────────────
        //  get_subject_grade
        //  Returns the grade for a student in one subject.
        //  Returns 0 if never assigned (default value).
        //
        //  NESTED MAPPING READ (tuple key):
        //    return subject_grades[(student, subject_id)]
        // ──────────────────────────────────────────────────
        fn get_subject_grade(
            self: @ContractState,
            student: ContractAddress,
            subject_id: u8
        ) -> u8 {
            // READ from nested mapping using tuple key
            self.subject_grades.read((student, subject_id))
        }


        // ──────────────────────────────────────────────────
        //  get_student_name
        //  Returns the stored name for a student's address.
        //
        //  MAPPING READ:
        //    return student_names[student]
        // ──────────────────────────────────────────────────
        fn get_student_name(self: @ContractState, student: ContractAddress) -> felt252 {
            self.student_names.read(student)
        }


        // ──────────────────────────────────────────────────
        //  is_student_registered
        //  Returns true if the address has registered.
        //  Returns false (default) for unknown addresses.
        //
        //  MAPPING READ:
        //    return is_registered[student]
        // ──────────────────────────────────────────────────
        fn is_student_registered(self: @ContractState, student: ContractAddress) -> bool {
            self.is_registered.read(student)
        }


        // ──────────────────────────────────────────────────
        //  get_total_students
        //  Returns total number of students who registered.
        // ──────────────────────────────────────────────────
        fn get_total_students(self: @ContractState) -> u32 {
            self.student_count.read()
        }
    }


    // ======================================================
    //  TESTS
    //  ────────────────────────────────────────────────────
    //  Run with:   scarb test
    //
    //  These tests verify mapping read/write behavior
    //  without deploying to a real blockchain.
    // ======================================================
    #[cfg(test)]
    mod tests {
        use super::GradeBook;
        use starknet::testing::set_caller_address;
        use starknet::contract_address_const;

        // Fake addresses for testing
        fn student_ali() -> starknet::ContractAddress {
            contract_address_const::<0x2>()
        }
        fn student_sara() -> starknet::ContractAddress {
            contract_address_const::<0x3>()
        }
        fn unknown() -> starknet::ContractAddress {
            contract_address_const::<0x99>()
        }

        // ── TEST 1 ─────────────────────────────────────────
        // An address that NEVER registered should return
        // false from is_registered mapping (default = false)
        #[test]
        fn test_unregistered_returns_false() {
            let state = GradeBook::contract_state_for_testing();
            let result = GradeBook::GradeBookImpl::is_student_registered(
                @state, unknown()
            );
            // Mapping was never written for unknown() → returns false
            assert(result == false, 'Should be false by default');
        }

        // ── TEST 2 ─────────────────────────────────────────
        // An address that NEVER received a grade should
        // return 0 from grades mapping (default = 0)
        #[test]
        fn test_default_grade_is_zero() {
            let state = GradeBook::contract_state_for_testing();
            let grade = GradeBook::GradeBookImpl::get_grade(@state, unknown());
            // Mapping was never written for unknown() → returns 0
            assert(grade == 0_u8, 'Default grade should be 0');
        }

        // ── TEST 3 ─────────────────────────────────────────
        // Registering a student correctly writes to BOTH
        // the student_names AND is_registered mappings
        #[test]
        fn test_register_writes_to_mappings() {
            set_caller_address(student_ali());
            let mut state = GradeBook::contract_state_for_testing();

            // ACTION: Ali registers with name 'Ali'
            GradeBook::GradeBookImpl::register_student(ref state, 'Ali');

            // VERIFY: student_names[ali_address] == 'Ali'
            let name = GradeBook::GradeBookImpl::get_student_name(
                @state, student_ali()
            );
            assert(name == 'Ali', 'Name mapping incorrect');

            // VERIFY: is_registered[ali_address] == true
            let registered = GradeBook::GradeBookImpl::is_student_registered(
                @state, student_ali()
            );
            assert(registered == true, 'Registration mapping incorrect');
        }

        // ── TEST 4 ─────────────────────────────────────────
        // Two students store SEPARATE entries in the mapping.
        // Keys do not interfere with each other.
        #[test]
        fn test_two_students_have_separate_mapping_entries() {
            // Register Ali
            set_caller_address(student_ali());
            let mut state = GradeBook::contract_state_for_testing();
            GradeBook::GradeBookImpl::register_student(ref state, 'Ali');

            // Register Sara
            set_caller_address(student_sara());
            GradeBook::GradeBookImpl::register_student(ref state, 'Sara');

            // VERIFY: each address has its own value in the mapping
            let ali_name  = GradeBook::GradeBookImpl::get_student_name(
                @state, student_ali()
            );
            let sara_name = GradeBook::GradeBookImpl::get_student_name(
                @state, student_sara()
            );
            assert(ali_name  == 'Ali',  'Ali name wrong');
            assert(sara_name == 'Sara', 'Sara name wrong');

            // VERIFY: student count is 2
            let count = GradeBook::GradeBookImpl::get_total_students(@state);
            assert(count == 2_u32, 'Count should be 2');
        }
    }
}
