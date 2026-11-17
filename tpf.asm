global	main
extern	printf

BYTES_POR_GRUPO			equ	3
CARACTERES_POR_GRUPO	equ	4
BITS_POR_INDICE			equ	6
DESPL_BYTE_1			equ	16
DESPL_BYTE_2			equ	8
CANT_SIMBOLOS			equ	64

section	.data
	secuenciaBinariaA	db	0xC4, 0x94, 0x37, 0x95, 0x63, 0xA2, 0x1D, 0x3C 
						db	0x86, 0xFC, 0x22, 0xA9, 0x3D, 0x7C, 0xA4, 0x51 
						db	0x63, 0x7C, 0x29, 0x04, 0x93, 0xBB, 0x65, 0x18 
	largoSecuenciaA		db	0x18 ; 24d

	secuenciaImprimibleB db	"vhyAHZucgTUuznwTDciGQ8m4TuvUIyjU"
	largoSecuenciaB		db	0x20 ; 32d

	TablaConversion		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	decFormatoGrupo		db	"Secuencia de 4 caracteres inicial: %.4s -> bytes generados: %02X %02X %02X",10,0

; Casos de prueba:
; SecuenciaBinariaDePrueba db	0x73, 0x38, 0xE7, 0xF7, 0x34, 0x2C, 0x4F, 0x92
;						   db	0x49, 0x55, 0xE5, 0x9F, 0x8E, 0xF2, 0x75, 0x5A 
;						   db	0xD3, 0xC5, 0x53, 0x65, 0x68, 0x52, 0x78, 0x3F
; SecuenciaImprimibleCodificada	db	"czjn9zQsT5JJVeWfjvJ1WtPFU2VoUng/"

; SecuenciaImprimibleDePrueba db "Qy2A2dhEivizBySXb/09gX+tk/2ExnYb"
; SecuenciaBinariaDecodificada	db	0x43, 0x2D, 0x80, 0xD9, 0xD8, 0x44, 0x8A, 0xF8 
;								db	0xB3, 0x07, 0x24, 0x97, 0x6F, 0xFD, 0x3D, 0x81 
;								db	0x7F, 0xAD, 0x93, 0xFD, 0x84, 0xC6, 0x76, 0x1B
 
; Un codificador/decodificador online se puede encontrar en https://www.rapidtables.com/web/tools/base64-encode.html
	
section	.bss
	secuenciaImprimibleA	resb	32
	secuenciaBinariaB		resb	24
	
section	.text

main:
        sub     rsp, 8
        
        mov     rsi, secuenciaImprimibleB
        mov     rdi, secuenciaBinariaB
        movzx	rcx, byte [largoSecuenciaB]
        call	DECODIFICAR

        mov     rsi, secuenciaImprimibleB
        mov     rdi, secuenciaBinariaB
        movzx   rcx, byte [largoSecuenciaB]
        call    MOSTRAR_DECODIFICACION
        
finPrograma:
	add		rsp, 8
	xor		eax, eax
	ret


DECODIFICAR:
        xor     r9d, r9d
.ciclo:
        cmp     rcx, 0
        jle     .fin
        
        xor     eax, eax
        mov     r10, CARACTERES_POR_GRUPO
        
.caracter:
        mov     dl, [rsi]
        call    .buscarIndice
        shl     eax, BITS_POR_INDICE
        or      eax, r8d
        
        inc     rsi
        dec     r10
        jnz     .caracter
        
        mov     edx, eax
        shr     edx, DESPL_BYTE_1
        mov     [rdi], dl

        mov     edx, eax
        shr     edx, DESPL_BYTE_2
        mov     [rdi + 1], dl
        
        mov     [rdi + 2], al
        
        add     rdi, BYTES_POR_GRUPO
        add     r9, BYTES_POR_GRUPO
        sub     rcx, CARACTERES_POR_GRUPO
        jmp     .ciclo

.fin:
        mov     rax, r9
        ret
        
        
.buscarIndice:
        xor     r8d, r8d
       
.compara:
        cmp     dl, [TablaConversion + r8]
        je      .encontrado
        inc     r8
        cmp     r8, CANT_SIMBOLOS
        jb      .compara
        xor     r8d, r8d
       

        
.encontrado: 
        ret
        
        
MOSTRAR_DECODIFICACION:
        push    rbx
        push    r12
        push    r13 
        
        mov         rbx,rsi
        mov         r12, rdi
        mov         r13, rcx
        
.ciclo:
        cmp     r13, 0
        jle     .fin
        
        mov     rdi, decFormatoGrupo
        mov     rsi, rbx
        movzx   edx, byte[r12]
        movzx   ecx, byte[r12 + 1]
        movzx   r8d, byte[r12 + 2]
        xor         eax, eax
        call printf
        
               
        add     rbx, CARACTERES_POR_GRUPO
        add     r12, BYTES_POR_GRUPO
        sub     r13, CARACTERES_POR_GRUPO
        jmp     .ciclo       
        
.fin: 
        pop     r13
        pop     r12
        pop     rbx
        
        ret  