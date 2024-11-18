# Part A: Mathematical Functions

## Matrix Representation

All two-dimensional matrices in this project will be stored as 1D vectors in row-major order.  
This means the rows of the matrix are concatenated to form a single continuous array.  
Alternatively, matrices could be stored in column-major order, but in this project, we stick to row-major order.

---

## Vector/Array Strides

The stride of a vector refers to the number of memory locations between consecutive elements, measured in the size of the vector's elements. For example:

- **Stride = 1**: Elements are stored contiguously (e.g., `[a[0], a[1], a[2]]`).
- **Stride = 4**: Elements are spaced apart in memory (e.g., `[a[0], a[4], a[8]]`).

In RISC-V, accessing the `i`-th element of a vector with stride `s` is expressed as:
``` c
a[i * s] or *(a + i * s)
```
---
## How to do multiplication:
Since we are working with the `RV32I` machine, the mul instruction is not available for use in our code. Instead, we implement multiplication by using repeated addition. For example, calculating 5 * 10 would be equivalent to adding 5 to itself 10 times. This approach ensures compatibility with the `RV32I` instruction set, which is designed for simplicity and does not include hardware multiplication support.
### Example
``` s
li s1, 0         # set s1 = 0,s1 = result
mv t3, t1        # t3=t1 (rows) as counter
	
multiply:
    beqz t3, multiply_done  #if t3=0 ,done
    add s1, s1, t2          #s1 = s1 +t2
    addi t3, t3, -1         #t3 = t3 - 1
    j multiply              #repeat until t3=0
```
## Task 1: ReLU

In `relu.s`, implement the ReLU function, which applies the transformation:
``` c
ReLU(a) = max(a, 0)
```
Each element of the input array will be individually processed by setting negative values to 0. Since the matrix is stored as a **1D row-major vector**, this function operates directly on the flattened array.
``` s
loop_start:
    bge t1, a1, loop_end        # If index t1 >= array length (a1), exit the loop

    # Compute the address of array[i]: t2 = a0 + t1 * 4
    slli t2, t1, 2              # t2 = t1 * 4 (convert index to byte offset)
    add t2, a0, t2              # t2 = base address (a0) + offset

    # Load the value from array[i]
    lw t3, 0(t2)                # t3 = value at array[i]

    # Apply ReLU operation: if value < 0, set to 0
    blt t3, zero, set_zero      # If t3 < 0, jump to set_zero
    j store_value               # Otherwise, skip to store_value
set_zero:
    li t3, 0                    # Set t3 to 0
store_value:
    # Store the modified value back to array[i]
    sw t3, 0(t2)                # Write t3 back to memory at array[i]

    # Increment the index to process the next element
    addi t1, t1, 1              # t1 = t1 + 1

    j loop_start                # Repeat the loop

loop_end:
    jr ra                       # Return to the caller
```

---

## Task 2: ArgMax

In `argmax.s`, implement the argmax function, which returns the **index of the largest element** in a given vector. If multiple elements share the largest value, return the smallest index. This function operates on **1D vectors**.
``` s
loop_start:
    # Check if t2 >= a1
    bge t2, a1, done_loop        # If index t2 >= array length (a1), exit the loop

    # Compute the address of a0[t2]: t4 = a0 + t2 * 4
    slli t3, t2, 2               # t3 = t2 * 4 (convert index to byte offset)
    add t4, a0, t3               # t4 = base address (a0) + offset

    # Load the value from a0[t2]
    lw t5, 0(t4)                 # t5 = value at a0[t2]

    # Compare the value t5 with the current maximum value t0
    blt t5, t0, nextiter         # If t5 < t0, skip to the next iteration

    # If t5 >= t0
    mv t0, t5                    # Update t0 with the new maximum value (t5)
    mv t1, t2                    # Update t1 with the index of the new maximum value

nextiter:
    # Increment the index t2
    addi t2, t2, 1               # t2 = t2 + 1 (move to the next element)

    # Jump back to loop_start
    j loop_start                 # Repeat the loop

done_loop:
    # Return the index of the maximum value in a0
    mv a0, t1                    # Set a0 to the index of the maximum value (t1)
    jr ra                        # Return to the caller

```

---

## Task 3.1: Dot Product

In `dot.s`, implement the dot product function, defined as:
``` 
dot(a, b) = Σ (a_i * b_i) for i = 0 to n-1
```
### Example:

- **Vectors**: 
```
v0 = [1, 2, 3] v1 = [1, 3, 5]
```

- **Result**:
``` 
dot(v0, v1) = 1 * 1 + 2 * 3 + 3 * 5 = 22
```
### Code :
``` s
loop_start:
    bge t1, a2, loop_end        # If counter >= element_count, exit the loop

    # Calculate addresses and load values
    slli t4, t2, 2              # t4 = index0 * 4 (byte offset for arr0)
    add t5, a0, t4              # t5 = base address of arr0 + offset
    lw t4, 0(t5)                # t4 = value from arr0[index0]

    slli t5, t3, 2              # t5 = index1 * 4 (byte offset for arr1)
    add t6, a1, t5              # t6 = base address of arr1 + offset
    lw t5, 0(t6)                # t5 = value from arr1[index1]

    # Save the current loop counter onto the stack
    addi sp, sp, -4             # Decrement stack pointer to allocate space
    sw t1, 0(sp)                # Store t1 (loop counter) onto the stack

    # Prepare for multiplication
    li t6, 0                    # t6 = 0 (initialize multiplication result)
    beq t5, zero, skip_mult     # If t5 is 0, skip the multiplication step

    # Handle negative multiplication
    bgez t5, mult_pos           # If t5 >= 0, jump to mult_pos
    neg t5, t5                  # Make t5 positive
    neg t4, t4                  # Negate t4 to preserve the correct sign

mult_pos:
    beqz t5, skip_mult          # If multiplier t5 is 0, multiplication is done
    add t6, t6, t4              # Add multiplicand t4 to result t6
    addi t5, t5, -1             # Decrement multiplier t5
    j mult_pos                  # Repeat the multiplication loop

skip_mult:
    lw t1, 0(sp)                # Restore t1 (loop counter) from the stack
    addi sp, sp, 4              # Increment stack pointer to reclaim space

    # Accumulate the product into the sum
    add t0, t0, t6              # Add multiplication result t6 to the total sum t0

    # Update indices using strides
    add t2, t2, a3              # index0 += stride0
    add t3, t3, a4              # index1 += stride1
    addi t1, t1, 1              # Increment loop counter t1

    j loop_start                # Jump back to loop_start to continue the loop
```

## Task 3.2: Matrix Multiplication
In `matmul.s`, implement matrix multiplication, where:

![image](https://hackmd.io/_uploads/H1R9f0ufkl.png)


Given matrices  A  (size  n * m ) and  B  (size  m *k ), the output matrix C  will have dimensions (n * k ).

- **Rows of matrix \( A \)** will have **stride = 1**.
- **Columns of matrix \( B \)** will require calculating the correct starting index and stride.

If the dimensions of the matrices are incompatible, the program should exit with **code 4**.

---

## Example

* Input Matrices:
```
m0 = [1, 2, 3
      4, 5, 6
      7, 8, 9]

m1 = [1, 2, 3
      4, 5, 6
      7, 8, 9]
```
* Output Matrix:
``` 
matmul(m0, m1) =
[30, 36, 42
 66, 81, 96
 102, 126, 150]
```
```
inner_loop_end:
    # Move to the next row of M0
    mv t0, a2          # t0 = number of columns in M0
    slli t2, t0, 2     # t2 = number of columns * 4 (convert to byte offset)
    add s3, s3, t2     # Update the M0 pointer to the base address of the next row

    # Increment the outer loop counter
    addi s0, s0, 1     # s0 = s0 + 1 (move to the next row in M0)

    # Jump back to the start of the outer loop
    j outer_loop_start  

```

---
# Part B: File Operations and Main

This section focuses on reading and writing matrices to files and building the `main` function to perform digit classification using the pretrained MNIST weights.

---

## Matrix File Format

- **Plaintext**: Begins with two integers (rows, columns), followed by matrix rows.
- **Binary**: Stores matrix dimensions in the first 8 bytes (two 4-byte integers), followed by matrix elements in row-major order.

---

## Tasks

### Task 1: Read Matrix

In `read_matrix.s`, implement the function to **read a binary matrix** from a file and load it into memory. If any file operation fails, will exit with the following codes:

- **48**: Malloc error  
- **50**: fopen error  
- **51**: fread error  
- **52**: fclose error  

In this part, we replaced the mul instruction with the multiplication method described above.
This code is a custom implementation of multiplication that replaces the `mul` instruction. It calculates the product of `t1` and `t2` by repeatedly adding `t2` to itself `t1` times, simulating multiplication using a loop.

``` s
# mul s1, t1, t2   # s1 is number of elements
# FIXME: Replace 'mul' with your own implementation

li s1, 0         # set s1 = 0
mv t3, t1        # t3=t1 (rows) as counter
	
multiply:                    #t1*t2 = t2 plus t1 times 
    beqz t3, multiply_done
    add s1, s1, t2   
    addi t3, t3, -1
    j multiply
```
---

### Task 2: Write Matrix

In `write_matrix.s`, implement the function to **write a matrix** to a binary file. will Use the following exit codes for errors:

- **53**: fopen error  
- **54**: fwrite error  
- **55**: fclose error  

In this part, we do the same thing just like **Read Matrix**
``` s
# FIXME: Replace 'mul' with your own implementation
# Calculate total elements (s2 * s3) without using mul
li s4, 0         # s4=0
mv t0, s2        # t0=s2 (rows) as counter
	
#s2*s3 = s3 plus s2 times 
multiply:
    beqz t0, multiply_done
    add s4, s4, s3   
    addi t0, t0, -1
    j multiply
```

---

### Task 3: Classification

In `classify.s`, bring everything together to classify an input using two weight matrices and the ReLU and ArgMax functions. Use the following sequence:

1. **Matrix Multiplication**:  
    `hidden_layer = matmul(m0, input)`


2. **ReLU Activation**:  
    `relu(hidden_layer)`

3. **Second Matrix Multiplication**:  
    `scores = matmul(m1, hidden_layer)`
    
4. **Classification**:  
Call `argmax` to find the index of the highest score.

# PartC : Challenges

### Register Overwriting Issue
When I initially tried to replace the mul instruction, I encountered problems with register management. Often, I would overwrite register values without saving the original data, which caused subsequent computations to fail repeatedly. This made me realize the importance of properly managing and preserving register values.

### Efficiency of Repeated Addition
Using repeated addition to replace the mul instruction becomes very slow when the multiplier is large. This significantly impacts the program's performance, especially when working with large datasets or performing matrix operations.

### Oversight in Stack Operations
When dealing with nested loops (e.g., matrix multiplication), frequent saving and restoring of register values is required. However, forgetting to properly manage the stack—such as failing to restore the stack pointer or accidentally overwriting data—can lead to incorrect results or program crashes.

### Memory Address Calculation Errors
While working on matrix row-column transformations, precise offset calculations were necessary. Initially, I often confused row-major and column-major memory access methods, resulting in incorrect data being read and subsequent computation errors.

### Complex Debugging Process
When working with the RV32I instruction set, the lack of high-level instructions or hardware support (such as a multiplication instruction) made the code more verbose and prone to subtle mistakes. Debugging each failure required painstakingly checking the code line by line, especially for stack and register management, which was time-consuming and error-prone.