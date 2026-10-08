	.file	""
	.data
	.globl	camlNative_references.data_begin
camlNative_references.data_begin:
	.text
	.globl	camlNative_references.code_begin
camlNative_references.code_begin:
	.data
	.align	3
	.data
	.align	3
	.quad	3063
	.globl	camlNative_references.1
camlNative_references.1:
	.quad	camlNative_references.run_276
	.quad	72057594037927941
	.data
	.align	3
	.quad	2816
	.globl	camlNative_references
	.globl	camlNative_references
camlNative_references:
	.quad	1
	.quad	1
	.data
	.align	3
	.globl	camlNative_references.gc_roots
	.globl	camlNative_references.gc_roots
camlNative_references.gc_roots:
	.quad	camlNative_references
	.quad	0
	.text
	.align	3
	.globl	camlNative_references.run_276
camlNative_references.run_276:
.L101:
.L102:
	str	x30, [sp, #-8]
	sub	sp, sp, #16
	.ifgt (. - .L102) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L103:
.L100:
	.ifgt (. - .L103) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L104:
	adrp	x1, camlNative_references
	add	x1, x1, #:lo12:camlNative_references
	.ifgt (. - .L104) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L105:
	ldr	x2, [x1, #0]
	.ifgt (. - .L105) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L106:
	ldr	x3, [x2, #0]
	.ifgt (. - .L106) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L107:
	str	x3, [sp, #0]
	.ifgt (. - .L107) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L108:
	adrp	x8, host_function
	add	x8, x8, #:lo12:host_function
	bl	caml_c_call
.L109:
	.ifgt (. - .L108) - 12
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L110:
	ldr	x7, [sp, #0]
	.ifgt (. - .L110) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L111:
	add	x5, x0, x7
	.ifgt (. - .L111) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L112:
	sub	x0, x5, #1
	.ifgt (. - .L112) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L113:
	.ifgt (. - .L113) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L114:
	add	sp, sp, #16
	ldr	x30, [sp, #-8]
	and	x30, x30, #0x00FFFFFFFFFFFFFF
	ret
	.ifgt (. - .L114) - 16
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.ifgt (. - .L101) - 68
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.text
	.align	3
	.globl	camlNative_references.entry
camlNative_references.entry:
.L116:
.L117:
	str	x30, [sp, #-8]
	sub	sp, sp, #16
	.ifgt (. - .L117) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L118:
.L115:
	.ifgt (. - .L118) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L119:
	bl	caml_alloc1
.L120:	add	x1, x27, #8
	.ifgt (. - .L119) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L121:
	orr	x2, xzr, #1024
	.ifgt (. - .L121) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L122:
	str	x2, [x1, #-8]
	.ifgt (. - .L122) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L123:
	movz	x2, #85, lsl #0
	.ifgt (. - .L123) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L124:
	str	x2, [x1, #0]
	.ifgt (. - .L124) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L125:
	adrp	x0, camlNative_references
	add	x0, x0, #:lo12:camlNative_references
	.ifgt (. - .L125) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L126:
	mov	x19, sp
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	caml_initialize
	mov	sp, x19
	.ifgt (. - .L126) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L127:
	adrp	x1, camlNative_references.1
	add	x1, x1, #:lo12:camlNative_references.1
	.ifgt (. - .L127) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L128:
	adrp	x5, camlNative_references
	add	x5, x5, #:lo12:camlNative_references
	.ifgt (. - .L128) - 8
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L129:
	add	x0, x5, #8
	.ifgt (. - .L129) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L130:
	mov	x19, sp
	ldr	x16, [x28, 64]
	mov	sp, x16
	bl	caml_initialize
	mov	sp, x19
	.ifgt (. - .L130) - 20
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L131:
	orr	x0, xzr, #1
	.ifgt (. - .L131) - 4
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L132:
	.ifgt (. - .L132) - 0
	.error "Emit.instr_size: instruction length mismatch"
	.endif
.L133:
	add	sp, sp, #16
	ldr	x30, [sp, #-8]
	and	x30, x30, #0x00FFFFFFFFFFFFFF
	ret
	.ifgt (. - .L133) - 16
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.ifgt (. - .L116) - 120
	.error "Emit.instr_size: instruction length mismatch"
	.endif
	.data
	.align	3
	.quad	host_function
	.text
	.globl	camlNative_references.code_end
camlNative_references.code_end:
	.data
	.quad	0
	.globl	camlNative_references.data_end
camlNative_references.data_end:
	.quad	0
	.align	3
	.globl	camlNative_references.frametable
camlNative_references.frametable:
	.quad	2
	.quad	.L120
	.short	18
	.short	0
	.byte	1
	.byte	0
	.align	3
	.quad	.L109
	.short	17
	.short	0
	.align	2
	.long	.L134 - . + 0x0
	.align	3
	.align	2
.L134:
	.long	.L136 - . + 0x0
	.long	0x1830d8
.L135:
	.asciz	"native_references.ml"
	.align	2
.L136:
	.long	.L135 - . + 0x0
	.asciz	"Native_references.run"
	.align	3
