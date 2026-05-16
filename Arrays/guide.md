# Arrays in Cairo

This is my guide for the arrays assignment. I'll go through what I learned about Cairo arrays, how they're different from arrays in other languages I've used, and how my program works.

## What is an Array in Cairo?

An array in Cairo, written as `Array<T>`, is a list of values where every value is the same type `T`. For example, `Array<u32>` is a list of 32-bit unsigned integers.

The interesting part is that Cairo arrays are not like the arrays I'm used to in C++ or Python. Cairo's memory is immutable — once a value is written into a memory cell, it cannot be changed. This is because Cairo is designed for generating STARK proofs, and immutable memory makes the execution trace easier to verify.

What this means in practice:
- You can only add new elements at the end of the array (`append`).
- You can only remove elements from the front (`pop_front`).
- You cannot overwrite an existing element at some index.

So Cairo arrays are kind of like a one-way queue you can grow.

## Two Ways to Create an Array

### Way 1 — Manual append
```cairo
let mut arr: Array<u32> = ArrayTrait::new();
arr.append(1);
arr.append(2);
arr.append(3);
```
This creates an empty array and adds elements one at a time. You need `mut` because you're modifying the array.

### Way 2 — The `array!` macro (what I used)
```cairo
let arr: Array<u32> = array![1, 2, 3, 4, 5];
```
This is shorter and does the same thing — the macro just expands into multiple `append` calls behind the scenes. I picked this way because the assignment needed 5 fixed values.

## Accessing Elements

There are a few ways to read from an array:
- `arr.at(i)` — gets the element at index `i`. Panics if `i` is out of range.
- `arr[i]` — same as `.at(i)`, just shorter syntax.
- `arr.get(i)` — returns `Option<Box<@T>>`. Safer when you're not sure if the index exists.
- `arr.len()` — returns how many elements are in the array.
- `arr.is_empty()` — returns `true` if there are no elements.

## Iterating Over an Array (the tricky part)

Since you can't modify the array in place, you can't really do a normal `for` loop over it like in other languages. Instead, the common pattern is:

1. Convert the array to a **`Span`**, which is a read-only view of the array.
2. Use `pop_front()` in a loop to consume elements one by one.

```cairo
let mut span = arr.span();
loop {
    match span.pop_front() {
        Option::Some(value) => {
            // *value gives us the actual number (desnap)
        },
        Option::None => { break; },
    }
}
```

A few things tripped me up here:
- `pop_front()` returns an `Option<@T>` — so it's either `Some(snapshot of value)` or `None` when the span is empty.
- The value is a **snapshot** (written as `@u32`), not the value itself. To get the actual number, you put `*` in front of it. This is called "desnapping."
- The span has to be `mut` because `pop_front` updates an internal pointer inside it.

## How My Program Works

Here's what happens step by step in my `main` function:

1. I create the array `[1, 2, 3, 4, 5]` using the `array!` macro.
2. I print it using `println!("Array: {:?}", arr)`. The `{:?}` is the debug formatter — it works for complex types like arrays.
3. I declare `let mut sum: u32 = 0` to hold the running total. It has to be `mut` because I'll be adding to it.
4. I call `arr.span()` to get a span I can iterate over.
5. I run a `loop` that matches on `pop_front()`. Every time I get `Some(value)`, I add `*value` to `sum`. When I get `None`, the array is empty and I `break`.
6. I print the result with `println!("Sum = {}", sum)`.

## Sample Output
Array: [1, 2, 3, 4, 5]
Sum = 15

## How to Run

From inside the project folder (where `Scarb.toml` is):scarb execute

This compiles the Cairo code and runs the `main` function marked with `#[executable]`.

## Things I Learned

- Cairo's memory model is very different from regular languages — no in-place mutation.
- Spans are how you "look at" an array without owning it.
- The `Option` type and `match` are everywhere in Cairo, similar to Rust.
- The `#[executable]` attribute is what makes a function runnable by `scarb execute`. Without it, the function is just a normal function that can't be run directly.
- `Scarb.toml` needs `[[target.executable]]` and the `cairo_execute` dependency for executable programs (different from smart contracts).

## References

- The Cairo Book — Chapter 3.1 (Arrays) and Chapter 2.5 (Control Flow)
- Scarb documentation — Creating executable packages