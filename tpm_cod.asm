global main
extern printf

BYTES_POR_GRUPO         equ 3
CARACTERES_POR_GRUPO    equ 4


MASCARA_INDICE          equ 0x3F  ;63
DESPL_INDICE_1          equ 18
DESPL_INDICE_2          equ 12
DESPL_INDICE_3          equ 6

BITS_POR_INDICE         equ 6
DESPL_BYTE_1            equ 16
DESPL_BYTE_2            equ 8
CANT_SIMBOLOS           equ 64

section .data
    secuenciaBinariaA	db	0xC4, 0x94, 0x37, 0x95, 0x63, 0xA2, 0x1D, 0x3C
			db	0x86, 0xFC, 0x22, 0xA9, 0x3D, 0x7C, 0xA4, 0x51
			db	0x63, 0x7C, 0x29, 0x04, 0x93, 0xBB, 0x65, 0x18

    largoSecuenciaA     db  0x18   ;24
    
    secuenciaImprmibleB db	"vhyAHZucgTUuznwTDciGQ8m4TuvUIyjU"
    largoSecuenciaB	db  0x20  ;32d
    
    TablaConversion	db  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    
    
    ;VARIABLES DE SALIDA POR PANTALLA USANDO PRINTF
    grupoCodificado     db "Secuencia de 3 bytes actual: %02X %02X %02X -> caracteres imprimibles generados: %.4s", 10,0
    
    secuenciaTotalBinaria db 10,"Secuencia de %d bytes completa: ", 0
    
    byteSecuencia       db  "%02X ",0
    
    secuenciaTotalCodificada db    "-> caracteres imprimibles generados: %.*s",10,10,0 
    
    
section .bss
    secuenciaImprimibleA    resb    32
    secuenciaBinariaB       resb    24
    
 
section .text

main:
    sub     rsp, 8
    
    mov     rsi, secuenciaBinariaA
    mov     rdi, secuenciaImprimibleA
    movzx   rcx, byte[largoSecuenciaA]
    call    CODIFICAR
    mov     rsi, secuenciaBinariaA
    mov     rdi, secuenciaImprimibleA
    movzx   rcx, byte[largoSecuenciaA]
    call    MOSTRAR_CODIFICACION
    

finPrograma:
    add     rsp, 8
    xor     eax, eax
    ret
    

CODIFICAR:
    xor     r9, r9      ;escribí 0 caracteres hasta el momento
    
.ciclo:
    cmp     rcx, 0    
    je      .fin
    
    ;ARMAR LOS 24 BITS DEL GRUPO ACTUAL EN EAX
    movzx   eax, byte[rsi]
    shl     eax, DESPL_BYTE_1
    movzx   r8d, byte[rsi+1]
    shl     r8d, DESPL_BYTE_2
    or      eax, r8d
    movzx   r8d, byte[rsi+2]
    or      eax, r8d
    
    ;OBTENER LOS 4 INDICES Y CODIFICAR CADA CARACTER EN BASE A ESTOS
    ;1° caracter
    mov     edx, eax
    shr     edx, DESPL_INDICE_1
    and     edx, MASCARA_INDICE
    mov     dl, [TablaConversion + rdx]
    mov     [rdi], dl
    ;2°
    mov     edx, eax
    shr     edx, DESPL_INDICE_2
    and     edx, MASCARA_INDICE
    mov     dl, [TablaConversion + rdx]
    mov     [rdi+1], dl
    ;3°
    mov     edx, eax
    shr     edx, DESPL_INDICE_3
    and     edx, MASCARA_INDICE
    mov     dl, [TablaConversion + rdx]
    mov     [rdi+2], dl
    ;4°
    mov     edx, eax
    and     edx, MASCARA_INDICE
    mov     dl, [TablaConversion + rdx]
    mov     [rdi+3], dl
    
    ;avanzo los registros
    add    rsi, BYTES_POR_GRUPO
    add    rdi, CARACTERES_POR_GRUPO
    add    r9, CARACTERES_POR_GRUPO
    sub    rcx, BYTES_POR_GRUPO
    jmp    .ciclo
 
.fin:
    mov rax, r9
    ret
      
   
MOSTRAR_CODIFICACION:
    push   rbx
    push   r12
    push   r13
    push   r14
    sub     rsp, 8
    mov     rbx, rsi
    mov     r12, rdi
    mov     r13, rcx
    xor     r14, r14    ;grupo actual = 0
    
.grupo:
    ;1) CONDICION DE SALIDA, YA SE CODIFICARON TODOS LOS GRUPOS DE 3 BYTES
    mov     rax, r14
    imul    rax, BYTES_POR_GRUPO    
    cmp     rax, r13
    jae     .totalBinario                  

    ;2) CARGO LOS ARGUMENTOS DE PRINTF
    mov     rdi, grupoCodificado
    movzx   esi, byte[rbx + rax]
    movzx   edx, byte[rbx + rax + 1]
    movzx   ecx, byte[rbx + rax + 2]
    mov     r8, r14
    imul    r8, CARACTERES_POR_GRUPO
    add     r8, r12                 
    xor     eax, eax               
    call    printf
    inc     r14
    jmp     .grupo

.totalBinario:
    mov     rdi, secuenciaTotalBinaria
    mov     esi, r13d
    xor     eax, eax
    call    printf
 
.byte:
    cmp     r13, 0
    je      .totalImprimible
    mov     rdi, byteSecuencia
    movzx   esi, byte[rbx]
    xor     eax, eax
    call    printf
    inc     rbx
    dec     r13
    jmp     .byte
    
.totalImprimible:
    mov     rdi, secuenciaTotalCodificada
    imul    r14, CARACTERES_POR_GRUPO
    mov     esi, r14d
    mov     rdx, r12
    xor     eax, eax
    call    printf
    
.fin:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
 

    
    
    
    
    
    