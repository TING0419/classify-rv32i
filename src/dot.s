.globl dot

.text
# =======================================================
# FUNCTION: Strided Dot Product Calculator
#
# Calculates sum(arr0[i * stride0] * arr1[i * stride1])
# where i ranges from 0 to (element_count - 1)
#
# Args:
#   a0 (int *): Pointer to first input array
#   a1 (int *): Pointer to second input array
#   a2 (int):   Number of elements to process
#   a3 (int):   Skip distance in first array
#   a4 (int):   Skip distance in second array
#
# Returns:
#   a0 (int):   Resulting dot product value
#
# Preconditions:
#   - Element count must be positive (>= 1)
#   - Both strides must be positive (>= 1)
#
# Error Handling:
#   - Exits with code 36 if element count < 1
#   - Exits with code 37 if any stride < 1
# =======================================================
dot:
    # Prologue
    addi sp, sp, -20          # Allocate stack space
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)

    li t0, 1
    blt a2, t0, error_terminate  # Check element count >= 1
    blt a3, t0, error_terminate  # Check stride0 >= 1
    blt a4, t0, error_terminate  # Check stride1 >= 1

    # Initialize sum and index
    li t0, 0           # t0 = sum
    li t1, 0           # t1 = index i

    # Initialize pointers
    mv t2, a0          # t2 = pointer to arr0
    mv t3, a1          # t3 = pointer to arr1

    # Compute increments in bytes
    slli t4, a3, 2     # t4 = stride0 * 4 (byte increment for arr0)
    slli t5, a4, 2     # t5 = stride1 * 4 (byte increment for arr1)

loop_start:
    bge t1, a2, loop_end

    # Load values
    lw s0, 0(t2)       # s0 = arr0[i * stride0]
    lw s1, 0(t3)       # s1 = arr1[i * stride1]

    # Multiply s0 and s1 without using 'mul'
    # We'll use s2 for product, s3 for multiplicand, and t6 for multiplier
    li s2, 0           # s2 = product
    mv s3, s0          # s3 = multiplicand
    mv t6, s1          # t6 = multiplier

    # Handle negative multiplier
    blt t6, zero, neg_multiplier
pos_multiplier:
    # Positive multiplier
    beq t6, zero, mul_done
mul_loop:
    andi t1, t6, 1
    beq t1, zero, skip_add
    add s2, s2, s3
skip_add:
    slli s3, s3, 1
    srli t6, t6, 1
    bne t6, zero, mul_loop
    j mul_done
neg_multiplier:
    # Negative multiplier
    neg t6, t6         # t6 = -t6
    neg s3, s3         # s3 = -s3
    j pos_multiplier
mul_done:
    # Accumulate sum
    add t0, t0, s2

    # Increment pointers
    add t2, t2, t4     # arr0 pointer increment
    add t3, t3, t5     # arr1 pointer increment

    # Increment index
    addi t1, t1, 1

    j loop_start

loop_end:
    mv a0, t0

    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    jr ra

error_terminate:
    blt a2, t0, set_error_36
    li a0, 37          # Error code for stride < 1
    j exit

set_error_36:
    li a0, 36          # Error code for element count < 1
    j exit
