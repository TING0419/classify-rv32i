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
    # Error checking
    li t0, 1
    blt a2, t0, error_terminate    # If element_count < 1, error
    blt a3, t0, error_terminate    # If stride0 < 1, error
    blt a4, t0, error_terminate    # If stride1 < 1, error

    # Initialize sum and loop counter
    li t0, 0       # t0 = sum = 0
    li t1, 0       # t1 = i = 0

loop_start:
    bge t1, a2, loop_end    # Check if done (i >= element_count)

    # Calculate both offsets in one loop
    mv t2, t1       # t2 = t1 (copy of loop counter)
    li t3, 0        # t3 = offset1 = 0
    li t4, 0        # t4 = offset2 = 0

offset_loop:
    beqz t2, offset_done
    add t3, t3, a3    # t3 += stride0
    add t4, t4, a4    # t4 += stride1
    addi t2, t2, -1   # t2 -= 1
    j offset_loop

offset_done:
    # Convert offsets to bytes and load values
    slli t3, t3, 2     # t3 *= 4 (convert to byte offset for arr0)
    add t3, a0, t3     # t3 = address of arr0[i * stride0]
    lw t5, 0(t3)       # t5 = arr0[i * stride0]

    slli t4, t4, 2     # t4 *= 4 (convert to byte offset for arr1)
    add t4, a1, t4     # t4 = address of arr1[i * stride1]
    lw t6, 0(t4)       # t6 = arr1[i * stride1]

    # Multiply elements using repeated addition
    li t3, 0           # t3 = product = 0

    # Handle negative multiplier
    bltz t5, handle_neg   # If t5 < 0, handle negative

    mv t4, t5          # t4 = multiplier = t5
    j mult_loop

handle_neg:
    neg t4, t5         # t4 = -t5 (make multiplier positive)
    neg t6, t6         # t6 = -t6 (negate multiplicand)

mult_loop:
    beqz t4, mult_done    # If multiplier == 0, done
    add t3, t3, t6        # t3 += t6 (product += multiplicand)
    addi t4, t4, -1       # t4 -= 1 (decrement multiplier)
    j mult_loop

mult_done:
    # Accumulate product into sum
    add t0, t0, t3        # t0 += t3 (sum += product)

    # Increment loop counter
    addi t1, t1, 1        # t1 += 1 (i += 1)
    j loop_start

loop_end:
    # Move result into return register and return
    mv a0, t0
    jr ra

error_terminate:
    blt a2, t0, set_error_36   # If element_count < 1, set error 36
    li a0, 37                  # Error code 37 (stride error)
    j exit

set_error_36:
    li a0, 36                  # Error code 36 (element count error)
    j exit
