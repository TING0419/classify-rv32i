.globl argmax

.text
# =================================================================
# FUNCTION: Maximum Element First Index Finder
#
# Scans an integer array to find its maximum value and returns the
# position of its first occurrence. In cases where multiple elements
# share the maximum value, returns the smallest index.
#
# Arguments:
#   a0 (int *): Pointer to the first element of the array
#   a1 (int):  Number of elements in the array
#
# Returns:
#   a0 (int):  Position of the first maximum element (0-based index)
#
# Preconditions:
#   - Array must contain at least one element
#
# Error Cases:
#   - Terminates program with exit code 36 if array length < 1
# ================================================================
argmax:
    li t6, 1
    blt a1, t6, handle_error

    lw t0, 0(a0)

    li t1, 0
    li t2, 1
loop_start:
    # Check if t2 >= a1
    bge t2, a1, done_loop

    # Compute address of a0[t2] = a0 + t2 * 4
    slli t3, t2, 2      # t3 = t2 * 4

    add t4, a0, t3      # t4 = address of a0[t2]

    lw t5, 0(t4)        # t5 = a0[t2]

    # Compare t5 with t0 (current maximum value)
    blt t5, t0, nextiter    # if t5 < t0, go to next iteration

    # If t5 >= t0
    # Update t0 to t5
    mv t0, t5           # t0 = t5

    # Update t1 to t2 (index of current maximum)
    mv t1, t2

nextiter:
    # Increment t2
    addi t2, t2, 1

    # Jump back to loop_start
    j loop_start

done_loop:
    # Return t1 in a0
    mv a0, t1
    jr ra

handle_error:
    li a0, 36
    j exit
