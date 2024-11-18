.globl relu

.text
# ==============================================================================
# FUNCTION: Array ReLU Activation
#
# Applies ReLU (Rectified Linear Unit) operation in-place:
# For each element x in array: x = max(0, x)
#
# Arguments:
#   a0: Pointer to integer array to be modified
#   a1: Number of elements in array
#
# Returns:
#   None - Original array is modified directly
#
# Validation:
#   Requires non-empty array (length ≥ 1)
#   Terminates (code 36) if validation fails
#
# Example:
#   Input:  [-2, 0, 3, -1, 5]
#   Result: [ 0, 0, 3,  0, 5]
# ============================================================================
relu:
    li t0, 1             # Minimum valid length
    blt a1, t0, error    # Check array length >= 1
    li t1, 0             # Index i = 0

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


error:
    li a0, 36            # Error code for invalid array length
    j exit