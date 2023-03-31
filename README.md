# EnterUserModeSegmentation
Code to demonstrate entering user mode (ring 3) with IRETD from
kernel mode (ring 0). This code uses segmentation to separate
user mode and kernel mode. All the code is intended to fit in
the first 64KiB of memory. The kernel mode code/data are in a
segment that has a base of 0x0000 and a limit of 0x8000-1.
User mode is in a segment with a base of 0x8000 and a limit
of 0x8000-1.

The bootloader simply loads a stage2 binary at memory location
0x7e00. The stage2 binary contains the code to enter protected
mode and then transfers control to the user mode code that
will be loaded into memory at physical address 0x8000.

This code was in response to a user asking for sample code
in this [Stackoverflow question](https://stackoverflow.com/questions/75862100/switching-segments-in-the-gdt-x86-32bit-protected-mode)
