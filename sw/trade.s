# Generated RV32E from sw/v24/reference_port.c; shifts lowered to additions.
.text
.globl _start
_start:
    li sp, 0x10000400
    j firmware
	.text
	.globl	reset                           # -- Begin function reset
	.p2align	2
	.type	reset,@function
reset:                                  # @reset
# %bb.0:
	li	a1, 115
	mv	a2, a0
	beqz	a1, .LBB0_2
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
	sw	zero, 0(a2)
	addi	a1, a1, -1
	addi	a2, a2, 4
	bnez	a1, .LBB0_1
.LBB0_2:
	lui	a1, 2
	addi	a1, a1, 1808
	sw	a1, 424(a0)
	li	a1, 255
	sw	a1, 416(a0)
	sw	a1, 348(a0)
	ret
.Lfunc_end0:
	.size	reset, .Lfunc_end0-reset
                                        # -- End function
	.globl	step                            # -- Begin function step
	.p2align	2
	.type	step,@function
step:                                   # @step
# %bb.0:
	addi	sp, sp, -40
	sw	ra, 36(sp)                      # 4-byte Folded Spill
	sw	s0, 32(sp)                      # 4-byte Folded Spill
	sw	s1, 28(sp)                      # 4-byte Folded Spill
	mv	s0, a0
	lw	s1, 0(a0)
	mv	ra, a1
	li	a1, 8
	andi	a0, s1, 63
	blt	s1, a1, .LBB1_3
# %bb.1:
	addi	a1, s0, 4
	addi	a2, s1, 56
	andi	a2, a2, 63
    add a2, a2, a2
    add a2, a2, a2
	add	a2, a1, a2
	lw	a2, 0(a2)
	li	a3, 64
	sub	a2, ra, a2
	sw	a2, 24(sp)                      # 4-byte Folded Spill
	bltu	s1, a3, .LBB1_4
# %bb.2:
    add a2, a0, a0
    add a2, a2, a2
	add	a1, a1, a2
	lw	a1, 0(a1)
	sub	a1, ra, a1
	sw	a1, 20(sp)                      # 4-byte Folded Spill
	j	.LBB1_5
.LBB1_3:
	sw	zero, 24(sp)                    # 4-byte Folded Spill
.LBB1_4:
	sw	zero, 20(sp)                    # 4-byte Folded Spill
.LBB1_5:
	lw	a1, 436(s0)
    add a0, a0, a0
    add a0, a0, a0
	add	a0, s0, a0
	li	a2, 191
	sw	ra, 4(a0)
	beq	a1, a2, .LBB1_10
# %bb.6:
	li	a0, 127
	bne	a1, a0, .LBB1_20
# %bb.7:
	lw	a0, 424(s0)
	addi	a2, a0, -5
    add a3, ra, ra
    add a3, a3, a3
    add a3, a3, a3
    add a3, a3, a3
    add a3, a3, a3
	slt	a4, a2, a3
	xori	a5, a4, 1
    add a0, ra, ra
    add a1, ra, ra
    add a1, a1, a1
    add t0, ra, ra
    add t0, t0, t0
    add t0, t0, t0
    add t1, ra, ra
    add t1, t1, t1
    add t1, t1, t1
    add t1, t1, t1
    add a5, a5, a5
    add a5, a5, a5
    add a5, a5, a5
    add a5, a5, a5
    add a5, a5, a5
	addi	a4, a4, -1
	and	a3, a4, a3
	sub	a2, a2, a3
	slt	a3, a2, t1
	xori	a4, a3, 1
    add a4, a4, a4
    add a4, a4, a4
    add a4, a4, a4
    add a4, a4, a4
	or	a4, a5, a4
	addi	a3, a3, -1
	and	a3, a3, t1
	sub	a2, a2, a3
	slt	a3, a2, t0
	xori	a5, a3, 1
    add a5, a5, a5
    add a5, a5, a5
    add a5, a5, a5
	or	a4, a4, a5
	addi	a3, a3, -1
	and	a3, a3, t0
	sub	a2, a2, a3
	slt	a3, a2, a1
	xori	a5, a3, 1
    add a5, a5, a5
    add a5, a5, a5
	or	a4, a4, a5
	addi	a3, a3, -1
	and	a1, a3, a1
	sub	a2, a2, a1
	slt	a1, a2, a0
	xori	a3, a1, 1
    add a3, a3, a3
	or	a3, a4, a3
	addi	a1, a1, -1
	and	a0, a1, a0
	sub	a0, a2, a0
	slt	a2, a0, ra
	xori	a1, a2, 1
	or	a1, a3, a1
	beqz	a1, .LBB1_17
# %bb.8:
	addi	a2, a2, -1
	lw	a3, 428(s0)
	and	a2, a2, ra
	sub	a0, a0, a2
	sw	a0, 424(s0)
	add	a1, a3, a1
	sw	a1, 428(s0)
	beqz	a1, .LBB1_18
.LBB1_9:
	sw	ra, 456(s0)
	li	a1, 452
	mv	a0, ra
	j	.LBB1_19
.LBB1_10:
	sw	s1, 12(sp)                      # 4-byte Folded Spill
	lw	s1, 428(s0)
	li	a1, 63
	mv	a0, s1
	blt	s1, a1, .LBB1_12
# %bb.11:
	li	a0, 63
.LBB1_12:
	sw	a0, 8(sp)                       # 4-byte Folded Spill
	sw	ra, 16(sp)                      # 4-byte Folded Spill
	mv	a1, ra
    jal ra, times
	beqz	s1, .LBB1_15
# %bb.13:
	lw	a1, 424(s0)
	add	a0, a1, a0
	li	a1, 5
	blt	a0, a1, .LBB1_15
# %bb.14:
	addi	a0, a0, -5
	sw	a0, 424(s0)
	lw	a0, 8(sp)                       # 4-byte Folded Reload
	sub	a0, s1, a0
	sw	a0, 428(s0)
.LBB1_15:
	lw	a1, 440(s0)
	li	a0, 1
	lw	ra, 16(sp)                      # 4-byte Folded Reload
	lw	s1, 12(sp)                      # 4-byte Folded Reload
	bne	a1, a0, .LBB1_20
# %bb.16:
	lw	a1, 424(s0)
	lw	a2, 444(s0)
	lw	a3, 448(s0)
	sub	a1, a1, a2
	add	a3, a3, a1
	sw	a3, 448(s0)
	li	a2, -750
	li	a1, 320
	bge	a2, a3, .LBB1_19
	j	.LBB1_20
.LBB1_17:
	lw	a1, 428(s0)
	bnez	a1, .LBB1_9
.LBB1_18:
	li	a0, 0
	li	a1, 432
.LBB1_19:
	add	a1, s0, a1
	sw	a0, 0(a1)
.LBB1_20:
	lw	a0, 288(s0)
	li	a2, 1
	beq	a0, a2, .LBB1_23
# %bb.21:
	li	a1, 2
	bne	a0, a1, .LBB1_24
# %bb.22:
	lw	a0, 268(s0)
	lw	a1, 292(s0)
	li	a2, 0
	sub	a0, ra, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
	add	a0, a1, a0
	addi	a0, a0, -10
	sw	a0, 292(s0)
	j	.LBB1_25
.LBB1_23:
	sw	ra, 268(s0)
	j	.LBB1_25
.LBB1_24:
	li	a2, 0
.LBB1_25:
	lw	a5, 264(s0)
	lw	a3, 292(s0)
	beqz	a5, .LBB1_27
# %bb.26:
	lw	a0, 268(s0)
	sub	a0, ra, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
    add a0, a0, a0
	addi	a0, a0, -5
	j	.LBB1_28
.LBB1_27:
	li	a0, 0
.LBB1_28:
	snez	a1, s1
	andi	a4, s1, 127
	seqz	a4, a4
	and	a4, a1, a4
	add	t2, a0, a3
	beqz	a4, .LBB1_30
# %bb.29:
	lw	a0, 304(s0)
	lw	t0, 308(s0)
	lw	a1, 300(s0)
	lw	t1, 312(s0)
	sw	a0, 300(s0)
	sw	t0, 304(s0)
	sw	a1, 12(sp)                      # 4-byte Folded Spill
	sw	a1, 296(s0)
	sw	t1, 308(s0)
	sw	t2, 312(s0)
	j	.LBB1_31
.LBB1_30:
	lw	a0, 296(s0)
	sw	a0, 12(sp)                      # 4-byte Folded Spill
.LBB1_31:
	li	a0, 128
	blt	a3, a0, .LBB1_33
# %bb.32:
	li	a0, 1
	sw	a0, 316(s0)
.LBB1_33:
	beqz	a2, .LBB1_35
# %bb.34:
	sw	ra, 272(s0)
	sw	ra, 268(s0)
	sw	s1, 276(s0)
	sw	zero, 284(s0)
.LBB1_35:
	li	a1, 1
	li	a0, 8
	addi	t1, s1, 16
	bge	s1, a0, .LBB1_37
.LBB1_36:
	li	a3, 0
	li	a0, 0
	j	.LBB1_58
.LBB1_37:
	beqz	a5, .LBB1_46
# %bb.38:
	lw	a0, 268(s0)
	addi	a2, a0, -16
	bge	a2, ra, .LBB1_49
# %bb.39:
	lw	a2, 284(s0)
	beqz	a2, .LBB1_50
# %bb.40:
	lw	a2, 272(s0)
	blt	ra, a2, .LBB1_42
# %bb.41:
	mv	a2, ra
.LBB1_42:
	addi	a5, a2, -12
	sw	a2, 272(s0)
	blt	a5, a0, .LBB1_44
# %bb.43:
	mv	a0, a5
.LBB1_44:
	blt	a0, ra, .LBB1_36
# %bb.45:
	li	a1, 0
	li	a3, 0
	sw	zero, 284(s0)
	j	.LBB1_56
.LBB1_46:
	li	a0, -4
	li	a3, 0
	lw	a2, 24(sp)                      # 4-byte Folded Reload
	blt	a0, a2, .LBB1_138
# %bb.47:
	lw	a5, 280(s0)
	mv	a0, a3
	blt	s1, a5, .LBB1_58
# %bb.48:
	li	a1, 1
	sw	a1, 264(s0)
	li	a3, 1
	li	a0, 1
	j	.LBB1_58
.LBB1_49:
	li	a1, 0
	li	a3, 0
	sw	zero, 284(s0)
	sw	zero, 264(s0)
	sw	t1, 280(s0)
	j	.LBB1_57
.LBB1_50:
	li	a5, 4
	lw	a2, 24(sp)                      # 4-byte Folded Reload
	blt	a2, a5, .LBB1_53
# %bb.51:
	addi	a0, a0, 2
	blt	ra, a0, .LBB1_53
# %bb.52:
	li	a3, 0
	li	a0, 0
	li	a1, 1
	sw	a1, 284(s0)
	sw	ra, 272(s0)
	j	.LBB1_58
.LBB1_53:
	li	a3, 0
	lw	a0, 24(sp)                      # 4-byte Folded Reload
	blt	a0, a5, .LBB1_138
# %bb.54:
	lw	a0, 276(s0)
	sub	a5, s1, a0
	li	t0, 31
	mv	a0, a3
	blt	a5, t0, .LBB1_58
# %bb.55:
	li	a1, 0
	li	a3, 0
.LBB1_56:
	sw	zero, 264(s0)
.LBB1_57:
	li	a0, 2
.LBB1_58:
	sw	a0, 288(s0)
	sw	t1, 0(sp)                       # 4-byte Folded Spill
	beqz	a4, .LBB1_60
# %bb.59:
	li	a5, 0
	lw	a0, 388(s0)
	lw	a4, 384(s0)
	lw	t0, 380(s0)
	lw	t1, 392(s0)
	sw	a0, 376(s0)
	sw	a4, 372(s0)
	sw	t0, 368(s0)
	sw	t1, 380(s0)
	lw	a0, 396(s0)
	lw	a4, 400(s0)
	lw	t0, 404(s0)
	lw	t1, 408(s0)
	sw	a0, 384(s0)
	sw	a4, 388(s0)
	sw	t0, 392(s0)
	sw	t1, 396(s0)
	lw	a0, 412(s0)
	lw	a4, 416(s0)
	lw	t0, 420(s0)
	lw	t1, 260(s0)
	sw	a0, 400(s0)
	sw	a4, 404(s0)
	sw	t0, 408(s0)
	sw	t1, 412(s0)
	li	a4, 255
	bge	a4, ra, .LBB1_61
	j	.LBB1_62
.LBB1_60:
	lw	a4, 416(s0)
	lw	a5, 420(s0)
	blt	a4, ra, .LBB1_62
.LBB1_61:
	mv	a4, ra
.LBB1_62:
	sw	a4, 416(s0)
	blt	ra, a5, .LBB1_64
# %bb.63:
	mv	a5, ra
.LBB1_64:
	lw	t0, 356(s0)
	sw	a5, 420(s0)
	beqz	t0, .LBB1_72
# %bb.65:
	li	a5, 2
	li	a0, 360
	beq	t0, a5, .LBB1_69
# %bb.66:
	li	a5, 1
	bne	t0, a5, .LBB1_68
# %bb.67:
	lw	a5, 328(s0)
	blt	a5, ra, .LBB1_70
.LBB1_68:
	li	a5, 0
	j	.LBB1_71
.LBB1_69:
	lw	a5, 328(s0)
	addi	a5, a5, 2
	blt	ra, a5, .LBB1_68
.LBB1_70:
	lw	a0, 332(s0)
	sw	a0, 360(s0)
	addi	a5, s1, 512
	li	a0, 364
.LBB1_71:
	add	a0, s0, a0
	sw	a5, 0(a0)
	sw	zero, 356(s0)
.LBB1_72:
	lw	a0, 352(s0)
	li	a5, 1
	bne	a0, a5, .LBB1_74
# %bb.73:
	sw	ra, 332(s0)
	sw	ra, 328(s0)
	sw	s1, 336(s0)
.LBB1_74:
	li	a0, 64
	sw	a1, 8(sp)                       # 4-byte Folded Spill
	sw	a3, 16(sp)                      # 4-byte Folded Spill
	bge	s1, a0, .LBB1_76
.LBB1_75:
	li	t0, 0
	j	.LBB1_174
.LBB1_76:
	sw	t2, 4(sp)                       # 4-byte Folded Spill
	li	a0, 512
	bltu	s1, a0, .LBB1_97
# %bb.77:
	mv	a2, ra
	lw	t2, 368(s0)
	lw	a0, 380(s0)
	blt	t2, a0, .LBB1_79
# %bb.78:
	mv	t2, a0
.LBB1_79:
	lw	ra, 392(s0)
	lw	a0, 404(s0)
	blt	ra, a0, .LBB1_81
# %bb.80:
	mv	ra, a0
.LBB1_81:
	lw	t0, 372(s0)
	lw	a0, 384(s0)
	blt	a0, t0, .LBB1_83
# %bb.82:
	mv	t0, a0
.LBB1_83:
	mv	a3, s1
	lw	t1, 396(s0)
	lw	a0, 408(s0)
	blt	a0, t1, .LBB1_85
# %bb.84:
	mv	t1, a0
.LBB1_85:
	mv	s1, t2
	blt	t2, ra, .LBB1_87
# %bb.86:
	mv	s1, ra
.LBB1_87:
	addi	a0, s1, -2
	li	a5, 2
	bge	a0, a2, .LBB1_99
# %bb.88:
	lw	a0, 412(s0)
	lw	a5, 376(s0)
	addi	a1, t2, 2
	sub	a0, a0, a5
	bge	ra, a1, .LBB1_136
.LBB1_89:
	addi	a1, t2, -2
	bge	a1, ra, .LBB1_141
.LBB1_90:
	sub	a1, ra, t2
	addi	a1, a1, 3
	li	a5, 6
	bltu	a5, a1, .LBB1_98
# %bb.91:
	sub	t2, t1, t0
	li	a1, 3
	blt	a1, t2, .LBB1_98
# %bb.92:
	li	a1, -3
	li	a5, 0
	blt	t2, a1, .LBB1_99
# %bb.93:
	addi	a0, a0, 4
	li	a1, 8
	bltu	a1, a0, .LBB1_99
# %bb.94:
	blt	t1, t0, .LBB1_96
# %bb.95:
	mv	t0, t1
.LBB1_96:
	sub	a0, t0, s1
	slti	a0, a0, 10
	addi	a0, a0, -1
	andi	a5, a0, 3
	j	.LBB1_99
.LBB1_97:
	mv	a3, s1
	mv	a2, ra
.LBB1_98:
	li	a5, 0
.LBB1_99:
	lw	a0, 344(s0)
	li	a1, -5
	lw	t0, 24(sp)                      # 4-byte Folded Reload
	blt	t0, a1, .LBB1_116
# %bb.100:
	li	a1, -8
	lw	t0, 20(sp)                      # 4-byte Folded Reload
	bge	a1, t0, .LBB1_116
# %bb.101:
	mv	ra, a2
	mv	s1, a3
	beqz	a0, .LBB1_109
# %bb.102:
	lw	a0, 348(s0)
	blt	a0, ra, .LBB1_104
# %bb.103:
	mv	a0, ra
.LBB1_104:
	li	a1, 2
	sw	a0, 348(s0)
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	beq	a5, a1, .LBB1_122
# %bb.105:
	lw	a1, 20(sp)                      # 4-byte Folded Reload
	blez	a1, .LBB1_122
# %bb.106:
	li	a1, 2
	lw	a2, 24(sp)                      # 4-byte Folded Reload
	blt	a2, a1, .LBB1_122
# %bb.107:
	sub	a0, ra, a0
	li	a1, 8
	blt	a0, a1, .LBB1_122
# %bb.108:
	sw	zero, 344(s0)
.LBB1_109:
	lw	a0, 324(s0)
	beqz	a0, .LBB1_124
# %bb.110:
	lw	t2, 332(s0)
	blt	ra, t2, .LBB1_112
# %bb.111:
	mv	t2, ra
.LBB1_112:
	lw	a4, 328(s0)
	addi	t1, a4, -8
	sw	t2, 332(s0)
	bge	t1, ra, .LBB1_139
# %bb.113:
	li	a0, -2
	lw	a1, 20(sp)                      # 4-byte Folded Reload
	blt	a0, a1, .LBB1_143
# %bb.114:
	li	t0, 2
	bne	a5, t0, .LBB1_143
# %bb.115:
	sw	zero, 324(s0)
	li	a0, 3
	sw	a0, 356(s0)
	addi	a0, s1, 64
	sw	a0, 340(s0)
	li	a0, 1
	sw	a0, 344(s0)
	j	.LBB1_140
.LBB1_116:
	mv	ra, a2
	beqz	a0, .LBB1_118
# %bb.117:
	lw	a0, 348(s0)
	j	.LBB1_119
.LBB1_118:
	li	a0, 1
	sw	a0, 344(s0)
	mv	a0, ra
.LBB1_119:
	mv	s1, a3
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	blt	a0, ra, .LBB1_121
# %bb.120:
	mv	a0, ra
.LBB1_121:
	sw	a0, 348(s0)
.LBB1_122:
	lw	a0, 324(s0)
	beqz	a0, .LBB1_75
# %bb.123:
	sw	zero, 324(s0)
	li	t0, 2
	sw	t0, 356(s0)
	addi	a0, s1, 64
	sw	a0, 340(s0)
	li	a0, 1
	sw	a0, 344(s0)
	li	a0, 348
	mv	a1, ra
	j	.LBB1_173
.LBB1_124:
	li	a0, 512
	li	t0, 0
	bltu	s1, a0, .LBB1_145
# %bb.125:
	lw	a0, 340(s0)
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	blt	s1, a0, .LBB1_174
# %bb.126:
	lw	a3, 404(s0)
	mv	t0, a3
	blt	a3, a4, .LBB1_128
# %bb.127:
	mv	t0, a4
.LBB1_128:
	lw	a0, 396(s0)
	lw	a4, 408(s0)
	blt	a4, a0, .LBB1_130
# %bb.129:
	mv	a0, a4
.LBB1_130:
	li	a1, 2
	li	a4, 0
	lw	a2, 24(sp)                      # 4-byte Folded Reload
	blt	a2, a1, .LBB1_134
# %bb.131:
	lw	a1, 20(sp)                      # 4-byte Folded Reload
	blez	a1, .LBB1_134
# %bb.132:
	sub	a1, ra, t0
	addi	a1, a1, -3
	li	t0, 7
	bltu	t0, a1, .LBB1_134
# %bb.133:
	lw	a1, 412(s0)
	addi	a1, a1, -2
	slt	a1, ra, a1
	xori	a4, a1, 1
.LBB1_134:
	bge	a0, ra, .LBB1_146
# %bb.135:
	lw	a1, 260(s0)
	lw	a2, 24(sp)                      # 4-byte Folded Reload
	slti	t0, a2, 2
	not	t0, t0
	slt	a0, a0, a1
	xori	a0, a0, 1
	lw	a1, 20(sp)                      # 4-byte Folded Reload
	slti	a1, a1, 2
	not	a1, a1
	and	a1, a1, t0
	and	a0, a1, a0
	j	.LBB1_147
.LBB1_136:
	addi	a1, t0, 2
	blt	t1, a1, .LBB1_89
# %bb.137:
	li	a1, 2
	li	a5, 1
	blt	a1, a0, .LBB1_99
	j	.LBB1_89
.LBB1_138:
	mv	a0, a3
	j	.LBB1_58
.LBB1_139:
	sw	zero, 324(s0)
	li	a0, 3
	sw	a0, 356(s0)
	addi	a0, s1, 64
	sw	a0, 340(s0)
	li	a0, 1
	sw	a0, 344(s0)
	li	t0, 2
.LBB1_140:
	li	a0, 348
	mv	a1, ra
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	j	.LBB1_173
.LBB1_141:
	addi	a1, t0, -2
	blt	a1, t1, .LBB1_90
# %bb.142:
	li	a1, -2
	li	a5, 2
	blt	a0, a1, .LBB1_99
	j	.LBB1_90
.LBB1_143:
	sub	a0, t2, a4
	li	a1, 24
	blt	a0, a1, .LBB1_160
# %bb.144:
	addi	t2, t2, -5
	j	.LBB1_164
.LBB1_145:
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	j	.LBB1_174
.LBB1_146:
	li	a0, 0
.LBB1_147:
	li	a1, 1
	bne	a5, a1, .LBB1_150
# %bb.148:
	or	a4, a4, a0
	beqz	a4, .LBB1_150
.LBB1_149:
	li	a1, 0
	li	t0, 1
	sw	t0, 324(s0)
	li	a0, 360
	j	.LBB1_173
.LBB1_150:
	bnez	a5, .LBB1_152
# %bb.151:
	lw	a1, 392(s0)
	slt	a1, a1, a3
	lw	a2, 20(sp)                      # 4-byte Folded Reload
	slti	a4, a2, 4
	not	a4, a4
	and	a1, a4, a1
	and	a0, a0, a1
	bnez	a0, .LBB1_149
.LBB1_152:
	lw	a0, 360(s0)
	beqz	a0, .LBB1_75
# %bb.153:
	li	a1, 1
	li	t0, 0
	bltu	a1, a5, .LBB1_174
# %bb.154:
	lw	a1, 364(s0)
	blt	a1, s1, .LBB1_174
# %bb.155:
	li	t0, 0
	bge	a0, ra, .LBB1_174
# %bb.156:
	lw	a1, 392(s0)
	blt	a3, a1, .LBB1_174
# %bb.157:
	li	a3, 2
	li	t0, 0
	lw	a1, 24(sp)                      # 4-byte Folded Reload
	blt	a1, a3, .LBB1_174
# %bb.158:
	lw	a1, 20(sp)                      # 4-byte Folded Reload
	blt	a1, a3, .LBB1_174
# %bb.159:
	lw	a1, 260(s0)
	bge	a0, a1, .LBB1_149
	j	.LBB1_174
.LBB1_160:
	li	a1, 12
	blt	a0, a1, .LBB1_162
# %bb.161:
	addi	t2, t2, -8
	j	.LBB1_164
.LBB1_162:
	li	a1, 8
	blt	a0, a1, .LBB1_193
# %bb.163:
	addi	t2, t2, -12
.LBB1_164:
	mv	t1, a4
	blt	t2, a4, .LBB1_166
.LBB1_165:
	mv	t1, t2
.LBB1_166:
	bge	t1, ra, .LBB1_171
# %bb.167:
	lw	a0, 336(s0)
	sub	a0, s1, a0
	li	a1, 256
	lw	t2, 4(sp)                       # 4-byte Folded Reload
	blt	a0, a1, .LBB1_75
# %bb.168:
	li	t0, 0
	lw	a0, 20(sp)                      # 4-byte Folded Reload
	bgtz	a0, .LBB1_174
# %bb.169:
	blt	a4, ra, .LBB1_174
# %bb.170:
	sw	zero, 324(s0)
	li	a0, 4
	sw	a0, 356(s0)
	li	t0, 2
	li	a0, 340
	j	.LBB1_172
.LBB1_171:
	sw	zero, 324(s0)
	li	a0, 1
	sw	a0, 356(s0)
	li	t0, 2
	li	a0, 340
	lw	t2, 4(sp)                       # 4-byte Folded Reload
.LBB1_172:
	lw	a1, 0(sp)                       # 4-byte Folded Reload
.LBB1_173:
	add	a0, s0, a0
	sw	a1, 0(a0)
.LBB1_174:
	lw	a4, 432(s0)
	sw	t0, 352(s0)
	sw	ra, 260(s0)
	addi	a0, s1, 1
	sw	a0, 0(s0)
	beqz	a4, .LBB1_184
# %bb.175:
	lw	s1, 456(s0)
	blt	ra, s1, .LBB1_177
# %bb.176:
	mv	s1, ra
.LBB1_177:
	li	a0, 1
	sw	s1, 456(s0)
	bne	a4, a0, .LBB1_189
# %bb.178:
	sw	a4, 24(sp)                      # 4-byte Folded Spill
	lw	a2, 448(s0)
	lw	a1, 424(s0)
	lw	a0, 428(s0)
	sw	a0, 20(sp)                      # 4-byte Folded Spill
	add	a1, a1, a2
	sw	a1, 12(sp)                      # 4-byte Folded Spill
	sw	ra, 16(sp)                      # 4-byte Folded Spill
	mv	a1, ra
    jal ra, times
	lw	a1, 12(sp)                      # 4-byte Folded Reload
	add	a0, a1, a0
	lw	a1, 444(s0)
	lw	a2, 20(sp)                      # 4-byte Folded Reload
	seqz	a2, a2
	addi	a2, a2, -1
	andi	a2, a2, -5
	sub	a0, a0, a1
	add	a0, a0, a2
	li	a1, -750
	blt	a1, a0, .LBB1_180
# %bb.179:
	li	a1, 1
	sw	a1, 320(s0)
.LBB1_180:
	lw	a1, 452(s0)
	sub	a1, s1, a1
	li	a2, 24
	lw	a3, 16(sp)                      # 4-byte Folded Reload
	lw	a4, 24(sp)                      # 4-byte Folded Reload
	blt	a1, a2, .LBB1_182
# %bb.181:
	addi	a2, s1, -5
	bge	a2, a3, .LBB1_190
.LBB1_182:
	li	a2, -749
	blt	a0, a2, .LBB1_190
# %bb.183:
	addi	a1, a1, -24
	sltiu	a0, a1, -12
	addi	s1, s1, -8
	slt	a1, s1, a3
	or	a0, a0, a1
	lw	a1, 8(sp)                       # 4-byte Folded Reload
	and	a0, a1, a0
	bnez	a0, .LBB1_191
	j	.LBB1_190
.LBB1_184:
	lw	a0, 316(s0)
	beqz	a0, .LBB1_187
# %bb.185:
	lw	a0, 320(s0)
	seqz	a0, a0
	lw	a1, 16(sp)                      # 4-byte Folded Reload
	and	a0, a0, a1
	beqz	a0, .LBB1_187
# %bb.186:
	lw	a0, 12(sp)                      # 4-byte Folded Reload
	sub	a1, t2, a0
	li	a2, -129
	li	a0, 1
	blt	a2, a1, .LBB1_188
.LBB1_187:
	li	a1, 1
	li	a0, 2
	bne	t0, a1, .LBB1_191
.LBB1_188:
	lw	a1, 424(s0)
	sw	a0, 432(s0)
	sw	a1, 444(s0)
	li	a0, 127
	j	.LBB1_192
.LBB1_189:
	li	a0, 2
	bne	t0, a0, .LBB1_191
.LBB1_190:
	sw	a4, 440(s0)
	sw	zero, 432(s0)
	li	a0, 191
	j	.LBB1_192
.LBB1_191:
	li	a0, 0
.LBB1_192:
	sw	a0, 436(s0)
	lw	ra, 36(sp)                      # 4-byte Folded Reload
	lw	s0, 32(sp)                      # 4-byte Folded Reload
	lw	s1, 28(sp)                      # 4-byte Folded Reload
	addi	sp, sp, 40
	ret
.LBB1_193:
	li	a1, 4
	blt	a0, a1, .LBB1_166
# %bb.194:
	addi	t1, a4, -2
	addi	t2, t2, -12
	bge	t2, t1, .LBB1_165
	j	.LBB1_166
.Lfunc_end1:
	.size	step, .Lfunc_end1-step
                                        # -- End function
	.p2align	2                               # -- Begin function times
	.type	times,@function
times:                                  # @times
# %bb.0:
	li	a2, 0
	li	a3, 1
	blt	a0, a3, .LBB2_2
.LBB2_1:                                # =>This Inner Loop Header: Depth=1
	and	a4, a3, a0
	seqz	a4, a4
	addi	a4, a4, -1
	and	a4, a4, a1
	add	a2, a4, a2
    add a3, a3, a3
    add a1, a1, a1
	bge	a0, a3, .LBB2_1
.LBB2_2:
	mv	a0, a2
	ret
.Lfunc_end2:
	.size	times, .Lfunc_end2-times
                                        # -- End function
	.globl	firmware                        # -- Begin function firmware
	.p2align	2
	.type	firmware,@function
firmware:                               # @firmware
# %bb.0:
	addi	sp, sp, -8
	sw	ra, 4(sp)                       # 4-byte Folded Spill
	sw	s0, 0(sp)                       # 4-byte Folded Spill
	lui	s0, 524304
	lui	a0, 65536
    jal ra, reset
	li	a0, 0
.LBB3_1:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB3_2 Depth 2
	sw	a0, 8(s0)
.LBB3_2:                                #   Parent Loop BB3_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lw	a0, 0(s0)
	andi	a0, a0, 1
	beqz	a0, .LBB3_2
# %bb.3:                                #   in Loop: Header=BB3_1 Depth=1
	lw	a1, 4(s0)
	lui	a0, 65536
    jal ra, step
	j	.LBB3_1
.Lfunc_end3:
	.size	firmware, .Lfunc_end3-firmware
                                        # -- End function
