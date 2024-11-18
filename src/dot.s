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
# ======================================================
dot:
    li t0, 1
    blt a2, t0, error_terminate  
    blt a3, t0, error_terminate   
    blt a4, t0, error_terminate  

    li t0, 0            # product
    li t1, 0            # loop counter
    li t2, 0            # Initialize index0 = 0
    li t3, 0            # Initialize index1 = 0

###############################################################
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

##############################################################
loop_end:
    mv a0, t0
    jr ra

error_terminate:
    blt a2, t0, set_error_36
    li a0, 37
    j exit

set_error_36:
    li a0, 36
    j exit