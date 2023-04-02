STACK_KERNEL_MODE equ 0x7c00
STACK_USER_MODE   equ 0x8000

EFLAGS_RES1_BIT   equ 1
EFLAGS_IF_BIT     equ 9
EFLAGS_DF_BIT     equ 10
EFLAGS_IOPL_BITS  equ 12

IOPL3             equ 3
IOPL0             equ 0
RPL3              equ 3
RPL0              equ 0

section kernel vstart=0x7e00

; 16-bit real mode here
bits 16
    ; Demo code/data resides < 0x100000, A20 is not enabled
    cli                        ; Disable interrupts
    lgdt [gdtr]                ; load GDT register with our GDT record
    mov eax, cr0
    or al, 1                   ; Enable PE (Protected Mode) bit in CR0
    mov cr0, eax
    jmp CODE32_SEL_DPL0 | RPL0:setcs
                               ; Enter 32-bit protected mode

; 32-bit protected mode here
bits 32
setcs:
    ; Set the kernel mode stack
    mov eax, DATA32_SEL_DPL0 | RPL0
    mov ss, eax
    mov esp, STACK_KERNEL_MODE

    ; Prior to switching to user mode set the selector registers
    ; to a user mode data selector. Stack Segment (SS) will be done
    ; with the IRETD instruction.
    mov eax, DATA32_SEL_DPL3 | RPL3
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    ; Push SS:ESP (stack) for user mode
    push DATA32_SEL_DPL3 | RPL3
    push STACK_USER_MODE

    ; Push EFLAGS with direction set forward, IOPL=0,
    ; Interrupts off, Reserved bit to 1
    push IOPL0 << EFLAGS_IOPL_BITS \
         | 0 << EFLAGS_IF_BIT \
         | 0 << EFLAGS_DF_BIT \
         | 1 << EFLAGS_RES1_BIT

    ; Push CS:EIP for user mode address to jump to
    push CODE32_SEL_DPL3 | RPL3
    push usermode_entry

    ; Transfer control to user mode (ring 3)
    iretd

gdt_start:
; NULL selector
    dq 0x0             ; 8 bytes

; Kernel code selector (DPL=0), 1-byte gran, base=0x0000, limit=0x8000
kernel_code:
    dw 0x8000          ; segment length, bits 0-15
    dw 0x0             ; segment base, bits 0-15
    db 0x0             ; segment base, bits 16-23
    db 10011010b       ; access flags (8 bits)
    db 01000000b       ; flags (4 bits) + segment length, bits 16-19
    db 0x0             ; segment base, bits 24-31

; Kernel data selector (DPL=0), 1-byte gran, base=0x0000, limit=0x8000
kernel_data:
    dw 0x8000          ; segment length, bits 0-15
    dw 0x0             ; segment base, bits 0-15
    db 0x0             ; segment base, bits 16-23
    db 10010010b       ; access flags (8 bits)
    db 01000000b       ; flags (4 bits) + segment length, bits 16-19
    db 0x0             ; segment base, bits 24-31

; User code selector (DPL=3), 1-byte gran, base=0x8000, limit=0x8000
U_code:
    dw 0x8000          ; segment length, bits 0-15
    dw 0x8000          ; segment base, bits 0-15
    db 0x0             ; segment base, bits 16-23
    db 11111010b       ; access flags (8 bits)
    db 01000000b       ; flags (4 bits) + segment length, bits 16-19
    db 0x00            ; segment base, bits 24-31

; User data selector (DPL=3), 1-byte gran, base=0x8000, limit=0x8000
U_data:
    dw 0x8000          ; segment length, bits 0-15
    dw 0x8000          ; segment base, bits 0-15
    db 0x0             ; segment base, bits 16-23
    db 11110010b       ; access flags (8 bits)
    db 01000000b       ; flags (4 bits) + segment length, bits 16-19
    db 0x00            ; segment base, bits 24-31

; Video memory selector (DPL=3), 1-byte gran, base=0xb8000, limit=0x8000
V_text:
    dw 0x8000          ; segment length, bits 0-15
    dw 0x8000          ; segment base, bits 0-15
    db 0x0b            ; segment base, bits 16-23
    db 11110010b       ; access flags (8 bits)
    db 01000000b       ; flags (4 bits) + segment length, bits 16-19
    db 0x00            ; segment base, bits 24-31
gdt_end:

; GDT record
gdtr:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE32_SEL_DPL0 equ kernel_code - gdt_start
DATA32_SEL_DPL0 equ kernel_data - gdt_start
CODE32_SEL_DPL3 equ U_code - gdt_start
DATA32_SEL_DPL3 equ U_data - gdt_start
VIDMEM_SEL_DPL3 equ V_text - gdt_start

; Pad out kernel mode code/data to offset 0x8000
TIMES 512-($-$$) db 0x00

bits 32
; User mode has a vstart (ORG) of 0 since this code will be running
; in a segment with base=0x8000. This code is loaded into memory
; at physical address 0x8000.
section user vstart=0
usermode_entry:
    ; Print USER in upper left corner of console
    mov eax, VIDMEM_SEL_DPL3 | RPL3
    mov fs, eax
    mov WORD fs:[0], 0x57 << 8 | 'U'
    mov WORD fs:[2], 0x57 << 8 | 'S'
    mov WORD fs:[4], 0x57 << 8 | 'E'
    mov WORD fs:[6], 0x57 << 8 | 'R'

    jmp $
