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
    
    secuenciaTotalBinaria db "Secuencia de %d bytes completa: ", 0
    
    byteSecuencia       db  "%02X ",0
    
    secuenciaTotalCodificada db    " -> caracteres imprimibles generados: %.*s",10,10,0 
    
    
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
    
    mov     rsi, secuenciaImprmibleB
    mov     rdi, secuenciaBinariaB
    movzx   rcx, byte[largoSecuenciaB]
    call    DECODIFICAR
    mov     rsi, secuenciaImprmibleB
    mov     rdi, secuenciaBinariaB
    movzx   rcx, byte[largoSecuenciaB]
    call    MOSTRAR_DECODIFICACION

finPrograma:
    add     rsp, 8
    xor     eax, eax
    ret
    
    
;RUTINAS INTERNAS

CODIFICAR:
    xor     r9, r9      ;escribí 0 caracteres hasta el momento
    
.ciclo:
    cmp     rcx, 0    
    je      .fin
    
    ;armar los 24 bits del grupo actual en EAX
    movzx   eax, byte[rsi]
    shl     eax, DESPL_BYTE_1
    movzx   r8d, byte[rsi+1]
    shl     r8d, DESPL_BYTE_2
    or      eax, r8d
    movzx   r8d, byte[rsi+2]
    or      eax, r8d
    
    ;obtener los 4 indices y escribir los 4 caracteres
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
    sub    rcx, 
      
    
.fin:
    mov rax, r9
    ret
    
    
    
    
    
    