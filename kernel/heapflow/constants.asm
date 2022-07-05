HEAPFLOW_EQU db 'equ', 0
HEAPFLOW_PT db 'pt', 0
HEAPFLOW_PTF db 'ptf', 0
HEAPFLOW_LPT db 'lpt', 0
HEAPFLOW_LPTF db 'lptf', 0
HEAPFLOW_END db 'end', 0
HEAPFLOW_IF db 'if', 0
HEAPFLOW_JMP db 'jmp', 0
HEAPFLOW_WHILE db 'while', 0
HEAPFLOW_RETURN db 'return', 0
HEAPFLOW_INT db 'int', 0
HEAPFLOW_DEL db 'del', 0
HEAPFLOW_DELF db 'delf', 0
HEAPFLOW_BREAK db 'break', 0
HEAPFLOW_CONTINUE db 'continue', 0
HEAPFLOW_IN db 'in', 0
HEAPFLOW_OUT db 'out', 0
HEAPFLOW_ARGS db 'args', 0
HEAPFLOW_SET db 'set', 0

HEAPFLOW_RETURN_FLAG equ 0x1
HEAPFLOW_BREAK_FLAG equ 0x2
HEAPFLOW_CONTINUE_FLAG equ 0x4
HEAPFLOW_ERROR_FLAG equ 0x8