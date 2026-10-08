/* Object-format probe only; not linked or executed. */
        .text
        .p2align 2
        .globl direct_references
 direct_references:
        stp x29, x30, [sp, #-16]!
        mov x29, sp
        adrp x0, host_value
        add x0, x0, :lo12:host_value
        adrp x1, host_value
        ldr w1, [x1, :lo12:host_value]
        bl host_function
        ldp x29, x30, [sp], #16
        ret

        .data
        .p2align 3
        .globl absolute_pointer
 absolute_pointer:
        .quad host_value
        .globl relative_pointer
 relative_pointer:
        .long host_value - .
        .globl image_relative_pointer
 image_relative_pointer:
        .rva host_value
