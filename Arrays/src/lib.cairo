// Assignment: Arrays in Cairo
// Name: Meeram Khalid
// Roll No: BSCS22019
//
// Program: Creates an array of 5 numbers, calculates the sum,
//          and prints both the array and the sum.

#[executable]
fn main() {
    // Step 1: Create an array of 5 numbers using the array! macro.
    // Array<u32> means an array of 32-bit unsigned integers.
    let arr: Array<u32> = array![1, 2, 3, 4, 5];

    // Step 2: Print the array using debug formatting {:?}.
    println!("Array: {:?}", arr);

    // Step 3: Declare a mutable accumulator for the sum.
    let mut sum: u32 = 0;

    // Step 4: Convert the array into a Span (read-only view) to iterate.
    // `mut` is required because pop_front updates the span's internal pointer.
    let mut arr_span = arr.span();

    // Step 5: Loop and add each element to sum.
    // pop_front() returns Option::Some(@value) or Option::None when empty.
    loop {
        match arr_span.pop_front() {
            Option::Some(value) => {
                // *value desnaps the snapshot (@u32 -> u32).
                sum += *value;
            },
            Option::None => { break; },
        }
    };

    // Step 6: Print the final sum.
    println!("Sum = {}", sum);
}