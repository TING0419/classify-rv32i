.globl matmul

.text
# =======================================================
# FUNCTION: Matrix Multiplication Implementation
#
# Performs operation: D = M0 × M1
# Where:
#   - M0 is a (rows0 × cols0) matrix
#   - M1 is a (rows1 × cols1) matrix
#   - D is a (rows0 × cols1) result matrix
#
# Arguments:
#   First Matrix (M0):
#     a0: Memory address of first element
#     a1: Row count
#     a2: Column count
#
#   Second Matrix (M1):
#     a3: Memory address of first element
#     a4: Row count
#     a5: Column count
#
#   Output Matrix (D):
#     a6: Memory address for result storage
#
# Validation (in sequence):
#   1. Validates M0: Ensures positive dimensions
#   2. Validates M1: Ensures positive dimensions
#   3. Validates multiplication compatibility: M0_cols = M1_rows
#   All failures trigger program exit with code 38
#
# Output:
#   None explicit - Result matrix D populated in-place
# =======================================================
matmul:
    # Error checks
    li t0, 1
    blt a1, t0, error    # Check M0 rows >= 1
    blt a2, t0, error    # Check M0 cols >= 1
    blt a4, t0, error    # Check M1 rows >= 1
    blt a5, t0, error    # Check M1 cols >= 1
    bne a2, a4, error    # Check M0_cols == M1_rows

    # Prologue
    addi sp, sp, -32
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)

    li s0, 0         # s0 = row index for M0
    mv s2, a6        # s2 = pointer to result matrix D

outer_loop_start:
    blt s0, a1, inner_loop_init
    j outer_loop_end

inner_loop_init:
    li s1, 0         # s1 = column index for M1

    # Compute s5 = s0 * a2 * 4 (offset to row s0 in M0)
    mv t0, s0        # t0 = s0
    mv t1, a2        # t1 = a2 (M0 columns)
    li s5, 0         # s5 = 0 (product)
    mv t2, t0        # t2 = multiplicand
    mv t3, t1        # t3 = multiplier
mul_loop1:
    beq t3, zero, mul_done1
    andi t4, t3, 1
    beq t4, zero, skip_add1
    add s5, s5, t2
skip_add1:
    slli t2, t2, 1
    srli t3, t3, 1
    j mul_loop1
mul_done1:
    slli s5, s5, 2   # s5 = s5 * 4 (byte offset)
    add s3, a0, s5   # s3 = pointer to row s0 in M0

inner_loop_start:
    blt s1, a5, compute_element
    j inner_loop_end

compute_element:
    # Compute s6 = s1 * 4 (byte offset to column s1 in M1)
    slli s6, s1, 2
    add s4, a3, s6   # s4 = pointer to column s1 in M1

    # Call dot product
    addi sp, sp, -24
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw a2, 8(sp)
    sw a3, 12(sp)
    sw a4, 16(sp)
    sw a5, 20(sp)

    mv a0, s3        # Pointer to row s0 in M0
    mv a1, s4        # Pointer to column s1 in M1
    mv a2, a2        # Number of elements (M0 columns or M1 rows)
    li a3, 1         # Stride for M0
    mv a4, a5        # Stride for M1 (number of columns in M1)

    jal dot

    mv t0, a0        # Result of dot product

    lw a0, 0(sp)
    lw a1, 4(sp)
    lw a2, 8(sp)
    lw a3, 12(sp)
    lw a4, 16(sp)
    lw a5, 20(sp)
    addi sp, sp, 24

    # Store result in D
    sw t0, 0(s2)
    addi s2, s2, 4   # Increment D pointer

    # Increment column index
    addi s1, s1, 1
    j inner_loop_start

inner_loop_end:
    # Increment row index
    addi s0, s0, 1
    j outer_loop_start

outer_loop_end:
    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    addi sp, sp, 32
    jr ra

error:
    li a0, 38
    j exit
