.globl write_matrix

.text
# ==============================================================================
# FUNCTION: Write a matrix of integers to a binary file
# FILE FORMAT:
#   - The first 8 bytes store two 4-byte integers representing the number of 
#     rows and columns, respectively.
#   - Each subsequent 4-byte segment represents a matrix element, stored in 
#     row-major order.
#
# Arguments:
#   a0 (char *) - Pointer to a string representing the filename.
#   a1 (int *)  - Pointer to the matrix's starting location in memory.
#   a2 (int)    - Number of rows in the matrix.
#   a3 (int)    - Number of columns in the matrix.
#
# Returns:
#   None
#
# Exceptions:
#   - Terminates with error code 27 on `fopen` error or end-of-file (EOF).
#   - Terminates with error code 28 on `fclose` error or EOF.
#   - Terminates with error code 30 on `fwrite` error or EOF.
# ==============================================================================
write_matrix:
    # Prologue
    addi sp, sp, -44
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)

    # Save arguments
    mv s1, a1        # s1 = matrix pointer
    mv s2, a2        # s2 = number of rows
    mv s3, a3        # s3 = number of columns

    li a1, 1         # Mode "w" for write

    jal fopen

    li t0, -1
    beq a0, t0, fopen_error   # fopen failed

    mv s0, a0        # s0 = file descriptor

    # Write number of rows and columns to file
    sw s2, 24(sp)    # Store number of rows
    sw s3, 28(sp)    # Store number of columns

    mv a0, s0
    addi a1, sp, 24  # Buffer with rows and columns
    li a2, 2         # Number of elements
    li a3, 4         # Size of each element

    jal fwrite

    li t0, 2
    bne a0, t0, fwrite_error

    # Compute total number of elements s4 = s2 * s3
    li s4, 0         # s4 = total elements
    mv t0, s2        # multiplicand (rows)
    mv t1, s3        # multiplier (columns)

mul_loop3:
    beq t1, zero, mul_done3
    andi t2, t1, 1
    beq t2, zero, skip_add3
    add s4, s4, t0
skip_add3:
    slli t0, t0, 1
    srli t1, t1, 1
    j mul_loop3
mul_done3:

    # Write matrix data to file
    mv a0, s0
    mv a1, s1        # Matrix data pointer
    mv a2, s4        # Number of elements to write
    li a3, 4         # Size of each element

    jal fwrite

    bne a0, s4, fwrite_error

    # Close file
    mv a0, s0

    jal fclose

    li t0, -1
    beq a0, t0, fclose_error

    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    addi sp, sp, 44

    jr ra

fopen_error:
    li a0, 27
    j error_exit

fwrite_error:
    li a0, 30
    j error_exit

fclose_error:
    li a0, 28
    j error_exit

error_exit:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    addi sp, sp, 44
    j exit
