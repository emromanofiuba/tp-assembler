# tp-assembler — TP Integrador Base64 (Organización del Computador, FIUBA)

Emi y Juanma. Entrega: **25/11/2026**.

Este README tiene dos partes:

1. [Plan TP Integrador Base64](#1-plan-tp-integrador-base64): qué hace cada uno, cómo se integra, cómo se prueba y cuándo.
2. [Nombres, constantes e interfaz](#2-tp-base64-nombres-constantes-e-interfaz): cada nombre, constante y registro que usamos en `tpf.asm`, para que las dos rutinas se puedan juntar sin tocar nada.

Si cambia algo del contrato, se cambia primero acá (y en los Google Docs compartidos) y se avisa al otro antes de tocar código.

---

# 1. Plan TP Integrador Base64

## Alcance y roles

Entregamos un solo `tpf.asm` que, partiendo de la plantilla, codifica `secuenciaBinariaA` (24 bytes) a Base64 en `secuenciaImprimibleA` (32 caracteres) y decodifica `secuenciaImprmibleB` (32 caracteres) a binario en `secuenciaBinariaB` (24 bytes). Además muestra por pantalla cada grupo de origen con lo que generó, y la secuencia completa con su resultado completo (ver [Salida por pantalla](#salida-por-pantalla)).

El enunciado para grupos de 2 simplifica el problema: la secuencia binaria es múltiplo de 3 y la imprimible es múltiplo de 4, así que **no hay relleno ni símbolos "="** que manejar. Tampoco pide leer archivos ni ingresar datos por consola (eso es del grupo de 3).

| Quién | Es dueño de | También hace |
| --- | --- | --- |
| Emi | Rutinas `CODIFICAR` y `MOSTRAR_CODIFICACION` | `main`, integración final en `tpf.asm` |
| Juanma | Rutinas `DECODIFICAR` y `MOSTRAR_DECODIFICACION` | Ensayo final desde cero en su máquina |

Cada uno revisa el código del otro antes de integrar. El enunciado no pide informe: la entrega es solo el programa.

Dos detalles del enunciado a tener presentes. En la parte de decodificación dice "coloque la secuencia de caracteres imprimibles", pero se refiere a la secuencia **binaria** en `secuenciaBinariaB`. Y la plantilla escribe `secuenciaImprmibleB` (sin la "i"): se usa tal cual, no se corrige.

## Arquitectura y contrato de interfaz

`main` solo prepara parámetros y llama a rutinas internas independientes, una por integrante. Las rutinas reciben direcciones y largo por registro, no usan las etiquetas de la plantilla adentro: así cada uno puede probar la suya con los casos de prueba comentados en la plantilla cambiando solo lo que carga `main`, y la integración se reduce a pegar la rutina.

| Contrato | CODIFICAR (Emi) | DECODIFICAR (Juanma) |
| --- | --- | --- |
| Entrada RSI | Dirección del origen binario | Dirección del origen imprimible |
| Entrada RDI | Dirección del destino imprimible | Dirección del destino binario |
| Entrada RCX | Largo del origen en bytes (múltiplo de 3) | Largo del origen en caracteres (múltiplo de 4) |
| Lee | `TablaConversion` | `TablaConversion` |
| Escribe | 4 × RCX / 3 caracteres en `[RDI]` | 3 × RCX / 4 bytes en `[RDI]` |
| RAX al volver | Cantidad de caracteres escritos | Cantidad de bytes escritos |
| Puede modificar | RAX, RCX, RDX, RSI, RDI, R8 a R11 | RAX, RCX, RDX, RSI, RDI, R8 a R11 |
| No puede tocar | RBX, RBP, R12 a R15, RSP | RBX, RBP, R12 a R15, RSP |

La fila de registros sigue la *ABI System V* (la convención de Linux x86_64 que define qué registros puede pisar una función y cuáles tiene que devolver intactos). Si alguno necesita RBX o R12 a R15, hace `push` al entrar y `pop` al salir, en orden inverso. No es una formalidad: a `main` la llama el arranque de C, que espera encontrar RBX intacto cuando `main` vuelve. Pisarlo puede romper el programa justo al salir, aunque los resultados en memoria estén bien.

El `main` acordado, que no se cambia sin avisar al otro:

```nasm
main:
        sub     rsp, 8                      ; alinea la pila una sola vez

        mov     rsi, secuenciaBinariaA
        mov     rdi, secuenciaImprimibleA
        movzx   rcx, byte[largoSecuenciaA]   ; el largo es db: 1 byte
        call    CODIFICAR
        mov     rsi, secuenciaBinariaA       ; se recargan: CODIFICAR
        mov     rdi, secuenciaImprimibleA    ; dejo RSI, RDI y RCX
        movzx   rcx, byte[largoSecuenciaA]   ; en cualquier valor
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
        xor     eax, eax                    ; codigo de salida 0
        ret
```

Las rutinas `MOSTRAR_` reciben los mismos tres registros que la rutina que muestran, por eso `main` los vuelve a cargar antes de llamarlas. El `sub rsp, 8` del principio deja la pila como la espera cualquier función de C; el detalle está en [Salida por pantalla](#salida-por-pantalla).

## Estándares de código

La regla de fondo: el archivo final tiene que leerse como si lo hubiera escrito una sola persona.

**Plantilla intocable.** No se renombran, mueven ni redimensionan las etiquetas de `.data` y `.bss` de la plantilla, typo incluido. La cátedra puede corregir reemplazando los datos, y si cambia una etiqueta el programa deja de ensamblar. Los largos se leen siempre de `largoSecuenciaA` y `largoSecuenciaB`, nunca 24 o 32 fijos.

**Nombres.**

| Elemento | Convención | Ejemplo |
| --- | --- | --- |
| Rutinas internas | MAYÚSCULAS, como `VALSM` de la cátedra | `CODIFICAR`, `DECODIFICAR` |
| Rótulos dentro de una rutina | Locales de NASM: empiezan con punto | `.ciclo`, `.fin`, `.buscarIndice` |
| Variables propias nuevas | camelCase con prefijo de la rutina | `codFormatoGrupo`, `decFormatoGrupo` |
| Constantes | MAYÚSCULAS con `equ` | `MASCARA_INDICE equ 0x3F` |

NASM ata cada rótulo con punto a la última etiqueta sin punto: `.ciclo` escrito dentro de CODIFICAR es en realidad `CODIFICAR.ciclo`. Así los dos pueden usar `.ciclo` y `.fin` sin chocar al juntar las rutinas, sin inventar prefijos. Conviene no crear variables en memoria salvo que hagan falta: con los registros libres del contrato alcanza.

**Encabezado obligatorio en cada rutina.**

```nasm
;-----------------------------------------------------------------
; CODIFICAR: convierte bytes binarios a caracteres Base64
; Entrada : RSI = origen, RDI = destino, RCX = largo (bytes)
; Salida  : destino cargado, RAX = caracteres escritos
; Modifica: RAX, RCX, RDX, RSI, RDI, R8, R9
;-----------------------------------------------------------------
```

**Formato.** Indentación con tabs como la plantilla: rótulo en la columna 0, instrucción y operandos en columnas fijas. Comentarios en castellano sin tildes (los archivos de la cátedra no las usan y evita problemas de codificación), explicando el *por qué* del bloque, no repitiendo la instrucción. Nada de código comentado ni restos de pruebas en la entrega.

**Lecturas de memoria.** Todo byte que se carga en un registro más grande va con `movzx` (*extensión con ceros*: completa los bits altos con 0). Un `mov al, [x]` deja basura en los bits altos de EAX y rompe los desplazamientos.

**Ensamblado y enlace.** Ambos usan exactamente los comandos de la guía 00 de la cátedra, para que el binario se comporte igual en las dos máquinas:

```sh
nasm -f elf64 -g -F dwarf -l tpf.lst -o tpf.o tpf.asm
gcc -no-pie -z noexecstack -o tpf tpf.o
```

**Llamadas a `printf`.** Solo desde las rutinas `MOSTRAR_`, nunca desde `CODIFICAR` ni `DECODIFICAR`. Antes de cada `call printf` va `xor eax, eax`, porque `printf` es *variádica* (acepta cantidad variable de argumentos y lee en AL cuántos registros XMM se usaron). Las reglas de pila y registros están en [Salida por pantalla](#salida-por-pantalla).

## Parte de Emi: CODIFICAR

Cada vuelta del ciclo toma 3 bytes del origen y escribe 4 caracteres en el destino; el ciclo da RCX / 3 vueltas (8 con la plantilla).

1. Calcular la cantidad de grupos: RCX / 3 (con `div` o restando 3 por vuelta; si usan `div`, recordar que pisa RDX).
2. Armar los 24 bits en EAX: primer byte desplazado 16 a la izquierda, el segundo 8, el tercero sin desplazar, unidos con `or`. Se arma byte a byte y no con un `mov eax, [rsi]` porque Intel es little-endian (guarda en memoria primero el byte menos significativo): esa lectura dejaría los 3 bytes al revés. Cada byte se carga con `movzx`.
3. Sacar los 4 índices de 6 bits con desplazamiento a la derecha y máscara `0x3F`, usando una copia de EAX para cada uno:

| Índice | Bits de EAX | Operación |
| --- | --- | --- |
| 1º | 23 a 18 | `shr 18`, `and 0x3F` |
| 2º | 17 a 12 | `shr 12`, `and 0x3F` |
| 3º | 11 a 6 | `shr 6`, `and 0x3F` |
| 4º | 5 a 0 | `and 0x3F` |

4. Cada índice se convierte en carácter leyendo `TablaConversion` con ese desplazamiento, por ejemplo `mov dl, [TablaConversion + r8]` con el índice en R8, y se guarda en `[RDI]`.
5. Avanzar RSI en 3 y RDI en 4, contar el grupo y repetir hasta terminar. Al salir, RAX = 4 × grupos.

Prueba de escritorio antes de tocar el teclado: el ejemplo del enunciado `0xFA 0x17 0x6B` arma `EAX = 0x00FA176B` y da los índices 62, 33, 29, 43, o sea `+hdr`. Conviene verificar ese valor de EAX en GDB en la primera vuelta.

Errores típicos a evitar: cargar el byte con `mov` en lugar de `movzx`, desplazar EAX en el lugar y perder el valor para el índice siguiente, avanzar RSI de a 4 por confusión con el destino, y traer el carácter de la tabla a AL. AL es la parte baja de EAX, así que pisa los 24 bits que todavía hacen falta para los índices siguientes: usen DL u otro registro que no sea parte de EAX.

## Parte de Juanma: DECODIFICAR

Cada vuelta toma 4 caracteres del origen y escribe 3 bytes en el destino; el ciclo da RCX / 4 vueltas (8 con la plantilla).

1. Calcular la cantidad de grupos: RCX / 4. Como 4 es potencia de 2, alcanza con `shr rcx, 2`.
2. Para cada uno de los 4 caracteres, obtener su índice (0 a 63) **recorriendo `TablaConversion`** hasta encontrarlo: la posición donde coincide es el índice. Conviene hacerlo como una subrutina interna `.buscarIndice` (carácter en DL, índice en R8; no en AL, que es parte del acumulador EAX), que respete el mismo contrato de registros.
3. Acumular los 24 bits en EAX: arrancar en 0 y, por cada índice, `shl eax, 6` y `or` con el índice.
4. Sacar los 3 bytes: `shr 16` para el primero, `shr 8` para el segundo y el byte bajo para el tercero (en cada caso alcanza con quedarse con el registro de 8 bits, sin máscara). Guardarlos en `[RDI]`, `[RDI+1]`, `[RDI+2]`.
5. Avanzar RSI en 4 y RDI en 3, contar y repetir. Al salir, RAX = 3 × grupos.

Se usa búsqueda en la tabla y no una tabla inversa nueva para reutilizar la de la plantilla y que ambas rutinas dependan de los mismos datos. Si un carácter no aparece en la tabla (no debería pasar con estos datos), se toma índice 0 y se deja como supuesto en un comentario del código.

Prueba de escritorio: `+PrT` da índices 62, 15, 43, 19, acumula `EAX = 0x00F8FAD3` y escribe `0xF8 0xFA 0xD3`, como en el enunciado.

Errores típicos: hacer el `shl` después del `or` en el último índice (corre todo 6 bits de más), devolver la dirección en vez de la posición al buscar en la tabla, y escribir los bytes en orden inverso.

## Salida por pantalla

Cada parte muestra sus 8 grupos, uno por línea (el grupo de origen y lo que generó), y al final una línea con la secuencia completa y su resultado completo. Esta es la salida exacta que da una versión de prueba armada con este diseño, ensamblada con los comandos de la cátedra. El programa entregado tiene que mostrar lo mismo:

```
Secuencia de 3 bytes inicial: C4 94 37 -> caracteres imprimibles generados: xJQ3
Secuencia de 3 bytes inicial: 95 63 A2 -> caracteres imprimibles generados: lWOi
Secuencia de 3 bytes inicial: 1D 3C 86 -> caracteres imprimibles generados: HTyG
Secuencia de 3 bytes inicial: FC 22 A9 -> caracteres imprimibles generados: /CKp
Secuencia de 3 bytes inicial: 3D 7C A4 -> caracteres imprimibles generados: PXyk
Secuencia de 3 bytes inicial: 51 63 7C -> caracteres imprimibles generados: UWN8
Secuencia de 3 bytes inicial: 29 04 93 -> caracteres imprimibles generados: KQST
Secuencia de 3 bytes inicial: BB 65 18 -> caracteres imprimibles generados: u2UY

Secuencia de 24 bytes completa: C4 94 37 95 63 A2 1D 3C 86 FC 22 A9 3D 7C A4 51 63 7C 29 04 93 BB 65 18 -> caracteres imprimibles generados: xJQ3lWOiHTyG/CKpPXykUWN8KQSTu2UY

Secuencia de 4 caracteres inicial: vhyA -> bytes generados: BE 1C 80
Secuencia de 4 caracteres inicial: HZuc -> bytes generados: 1D 9B 9C
Secuencia de 4 caracteres inicial: gTUu -> bytes generados: 81 35 2E
Secuencia de 4 caracteres inicial: znwT -> bytes generados: CE 7C 13
Secuencia de 4 caracteres inicial: DciG -> bytes generados: 0D C8 86
Secuencia de 4 caracteres inicial: Q8m4 -> bytes generados: 43 C9 B8
Secuencia de 4 caracteres inicial: TuvU -> bytes generados: 4E EB D4
Secuencia de 4 caracteres inicial: IyjU -> bytes generados: 23 28 D4

Secuencia de 32 caracteres completa: vhyAHZucgTUuznwTDciGQ8m4TuvUIyjU -> bytes generados: BE 1C 80 1D 9B 9C 81 35 2E CE 7C 13 0D C8 86 43 C9 B8 4E EB D4 23 28 D4
```

**Por qué en rutinas aparte.** `printf` puede pisar RSI, RDI, RCX y R8 a R11, que son justo los registros que usan los ciclos de `CODIFICAR` y `DECODIFICAR`. Llamarlo en medio del ciclo obligaría a guardar todo antes de cada llamada. Por eso cada parte convierte primero y muestra después, recorriendo origen y destino en paralelo.

| Rutina | Dueño | Formato (en `.data`) | Argumentos de `printf` |
| --- | --- | --- | --- |
| `MOSTRAR_CODIFICACION` | Emi | `codFormatoGrupo` | RDI = formato, ESI, EDX, ECX = los 3 bytes (con `movzx`), R8 = dirección de los 4 caracteres |
| `MOSTRAR_DECODIFICACION` | Juanma | `decFormatoGrupo` | RDI = formato, RSI = dirección de los 4 caracteres, EDX, ECX, R8D = los 3 bytes (con `movzx`) |

Los formatos usan `%02X` (dos dígitos hexa, con 0 adelante si hace falta) para cada byte y `%.4s` para los caracteres. El `%.4s` imprime exactamente 4 caracteres desde la dirección que recibe; un `%s` común seguiría leyendo hasta encontrar un 0, y estos buffers no terminan en 0. Cada formato termina en `,10,0` (salto de línea y fin de cadena).

**La línea completa** se arma con varias llamadas a `printf`, porque la cantidad de bytes depende del largo: una con el comienzo de la línea, una con `%02X ` por cada byte y una de cierre. El largo se imprime con `%d` y los caracteres con `%.*s`, que recibe la cantidad como argumento, así nada queda fijo en 24 o 32. Los formatos exactos están en la [sección 2](#variables-nuevas-formatos-de-printf).

**Reglas para que `printf` no rompa nada:**

1. Las rutinas `MOSTRAR_` reciben RSI = origen, RDI = destino, RCX = largo del origen, igual que la rutina que muestran.
2. Al entrar copian esos tres valores a RBX, R12 y R13, y usan R14 como contador de grupos: son registros que `printf` está obligada a devolver intactos. Para eso hacen `push rbx`, `push r12`, `push r13`, `push r14` al entrar y los `pop` en orden inverso al salir.
3. Después de los 4 `push` va un `sub rsp, 8`, y antes de los `pop` el `add rsp, 8`. Los 4 `push` corren la pila 32 bytes, que la dejarían desalineada; el `sub rsp, 8` lo compensa. Junto con el `sub rsp, 8` de `main`, RSP queda en múltiplo de 16 en cada `call printf`, que es lo que exige la *ABI* (la convención de llamadas de Linux). Lo controlé en GDB llamada por llamada en una versión de prueba. Si alguno agrega o saca un `push`, tiene que revisar esta cuenta.
4. `extern printf` va una sola vez al principio de `tpf.asm`, y lo agrega Emi.

## Plan de pruebas

Cada rutina se da por terminada solo cuando pasa sus tres casos, y el programa integrado cuando pasa la prueba cruzada. Los resultados esperados de la plantilla los calculé con un codificador Base64 estándar y coinciden con los casos de prueba que trae comentados la cátedra.

| Rutina | Caso | Entrada | Resultado esperado | Fuente |
| --- | --- | --- | --- | --- |
| CODIFICAR | Ejemplo | `0xFA 0x17 0x6B` | `+hdr` | Enunciado |
| CODIFICAR | Prueba | `SecuenciaBinariaDePrueba` | `czjn9zQsT5JJVeWfjvJ1WtPFU2VoUng/` | Plantilla |
| CODIFICAR | Entrega | `secuenciaBinariaA` | `xJQ3lWOiHTyG/CKpPXykUWN8KQSTu2UY` | Calculado |
| DECODIFICAR | Ejemplo | `+PrT` | `0xF8 0xFA 0xD3` | Enunciado |
| DECODIFICAR | Prueba | `Qy2A2dhEivizBySXb/09gX+tk/2ExnYb` | `0x43 0x2D 0x80 ... 0x76 0x1B` (24 bytes) | Plantilla |
| DECODIFICAR | Entrega | `secuenciaImprmibleB` | `0xBE 0x1C 0x80 0x1D 0x9B 0x9C 0x81 0x35 0x2E 0xCE 0x7C 0x13 0x0D 0xC8 0x86 0x43 0xC9 0xB8 0x4E 0xEB 0xD4 0x23 0x28 0xD4` | Calculado |

**Prueba cruzada (integración).** Decodificar lo que produjo CODIFICAR tiene que devolver exactamente `secuenciaBinariaA`, y codificar lo que produjo DECODIFICAR tiene que devolver `secuenciaImprmibleB`. Es la prueba más fuerte que tenemos: si las dos rutinas se equivocan, es muy improbable que se equivoquen de forma inversa.

**Cómo verificar en GDB** (tutorial 02 de la cátedra):

```
gdb ./tpf
break finPrograma
run
x/32cb &secuenciaImprimibleA
x/24xb &secuenciaBinariaB
```

`x/32cb` muestra 32 bytes como caracteres y `x/24xb` 24 bytes en hexa. Para depurar un ciclo, `break CODIFICAR.ciclo` (o `DECODIFICAR.buscarIndice`) e `info registers eax` en cada vuelta. La salida por pantalla tiene que mostrar los mismos valores que esta tabla.

## Flujo de trabajo e integración

Cada uno desarrolla en su propio archivo y `tpf.asm` se toca una sola vez, el día de integración. Así nunca hay dos personas editando el mismo archivo.

1. Repositorio compartido: este repo (`tp-assembler`), con el `tpf.asm` original y este plan.
2. Emi trabaja en `tpf_cod.asm` y Juanma en `tpf_dec.asm`. Los dos son copias del esqueleto de la sección 2, completando solo su rutina.
3. Para probar con otros casos, cada uno descomenta en su copia los datos de prueba de la plantilla y cambia solo la dirección que carga `main` en RSI. La rutina no se toca.
4. Una rutina está lista cuando pasa sus tres casos de la tabla de pruebas. Se avisa al otro y se sube.
5. El otro la revisa con este plan al lado: encabezado completo, contrato de registros, prefijos, `movzx`, sin largos fijos.
6. Integración (Emi): copiar las dos rutinas en `tpf.asm`, ensamblar con los comandos acordados, correr los casos de entrega y la prueba cruzada.
7. Cualquier cambio al contrato se acuerda entre los dos y se anota primero acá, en la tabla de contrato, antes de tocar código.

## Acuerdos antes de escribir código

Son 10 puntos para cerrar entre Emi y Juanma en el kickoff. Si los primeros cinco quedan distintos, `tpf.asm` no ensambla o se cae al ejecutar, aunque cada rutina ande bien sola. El primero ya está en discusión: el esqueleto de Juanma y este plan lo resuelven distinto.

| Qué acordar | Propuesta del plan | Si no lo acuerdan | Estado |
| --- | --- | --- | --- |
| Cómo reciben los datos las rutinas | Por registros desde `main`: RSI, RDI, RCX. El esqueleto de Juanma carga las etiquetas adentro de cada rutina | `main` carga registros que nadie lee, o una rutina usa registros que `main` nunca cargó | Pendiente |
| Nombre exacto de cada rutina | `CODIFICAR` y `DECODIFICAR`. Juanma usó minúsculas y NASM las distingue | Error de símbolo no definido al ensamblar | Pendiente |
| Rótulos internos | Siempre locales con punto (`.ciclo`, `.fin`) | Un `ciclo` sin punto en las dos rutinas da rótulo redefinido | Pendiente |
| Constantes `equ` y variables nuevas | Constantes comunes en un solo bloque arriba, a cargo de Emi. Variables propias con prefijo `cod` o `dec` | Dos `MASCARA_INDICE equ` dan error de redefinición | Pendiente |
| Registros que no se pueden pisar | RBX, RBP y R12 a R15 solo con `push` y `pop` balanceados | El programa se cae al salir de `main` | Pendiente |
| Qué devuelve RAX | La cantidad de caracteres o bytes escritos | Las pruebas comparan contra basura | Pendiente |
| Datos de la plantilla | Nadie toca `TablaConversion` ni las etiquetas. Los datos de prueba se descomentan solo en la copia propia | Se entrega con datos de prueba activos o una etiqueta cambiada | Pendiente |
| Quién edita `tpf.asm` y `main` | Solo Emi, el día de integración. Juanma entrega su rutina y no edita el archivo final | Dos versiones de `tpf.asm` y cambios perdidos | Pendiente |
| Mostrar resultados por pantalla | Sí. Cada uno escribe la rutina que muestra su parte; `main` alinea la pila una sola vez | Uno agrega `printf` sin alinear la pila y el programa se cae | **Acordado** |
| Herramientas y comandos | Los de la guía 00, los dos en Linux x86_64 | Anda en una máquina y no en la otra | Pendiente |

Cuando un punto pasa a Acordado, la decisión queda escrita en la sección del plan que le corresponde. Si después alguno quiere cambiarla, avisa antes de tocar código.

## Cronograma

| Fecha | Qué | Quién |
| --- | --- | --- |
| Dom 16/11 | Kickoff: cerrar los 10 acuerdos | Emi y Juanma |
| Lun 17 a mié 19/11 | Escribir y probar cada rutina con sus tres casos | Cada uno la suya |
| Jue 20/11 | Integración en `tpf.asm` y prueba cruzada | Emi |
| Vie 21 y sáb 22/11 | Revisión cruzada del código | Emi y Juanma |
| Lun 23/11 | Ensayo desde cero | Juanma |
| Mar 24/11 | Margen | — |
| Mié 25/11 | Entrega | Emi y Juanma |

El jueves 19 cada rutina tiene que pasar sus tres casos; si no llega, se usa el margen del martes 24 y no se recorta la revisión cruzada. El ensayo del lunes 23 es clonar el repo en una carpeta vacía, ensamblar con los comandos acordados y correr todas las pruebas, como lo haría el corrector.

## Checklist de entrega

- [ ] Está confirmado con la cátedra el medio de entrega
- [ ] `tpf.asm` ensambla y enlaza sin warnings con los comandos de la guía 00
- [ ] Las etiquetas de la plantilla están intactas y no hay largos fijos
- [ ] CODIFICAR pasa sus tres casos
- [ ] DECODIFICAR pasa sus tres casos
- [ ] Pasa la prueba cruzada en ambos sentidos
- [ ] Cada rutina tiene su encabezado completo y respeta el contrato de registros
- [ ] No quedan código comentado, datos de prueba sueltos ni rótulos sin prefijo
- [ ] La salida por pantalla muestra los 8 grupos y la línea completa de cada parte, con los valores esperados
- [ ] El ensayo desde cero salió bien en la máquina del que no integró

**Qué se verificó al armar este plan.** Los comandos de ensamblado y enlace salen de la guía 00 de NASM y GCC de la cátedra. El `sub rsp, 8` antes de llamar a C sale del tutorial de GDB. Los resultados esperados de los casos de entrega los calculé con un codificador Base64 estándar, y ese mismo cálculo reproduce los dos casos de prueba de la plantilla. Lo que **no** está verificado: el medio de entrega, que el enunciado no indica.

---

# 2. TP Base64: nombres, constantes e interfaz

Esta sección fija cada nombre, constante y registro que usamos en `tpf.asm`, para que las dos rutinas se puedan juntar sin tocar nada. Si alguno necesita cambiar algo, lo cambia primero acá y le avisa al otro.

## Reglas de nombres

Cada tipo de nombre tiene una forma distinta, así se reconoce qué es con solo leerlo. NASM distingue mayúsculas de minúsculas: `CODIFICAR` y `codificar` son dos símbolos distintos.

| Qué es | Forma | Ejemplo |
| --- | --- | --- |
| Rutina principal | minúscula, la exige gcc | `main` |
| Rutinas del TP | MAYÚSCULAS, con guión bajo entre palabras | `CODIFICAR`, `MOSTRAR_CODIFICACION` |
| Rótulos dentro de una rutina | punto + camelCase | `.ciclo`, `.fin`, `.buscarIndice` |
| Constantes | MAYÚSCULAS con guión bajo, definidas con `equ` | `MASCARA_INDICE` |
| Etiquetas de la plantilla | tal cual vienen, sin corregir | `secuenciaImprmibleB` |
| Variables nuevas en memoria | camelCase con prefijo `cod` o `dec` según la parte | `codFormatoGrupo` |

Las únicas variables nuevas son los ocho formatos de `printf`. Todo lo demás entra en registros, lo que evita la fuente más común de choques entre las dos partes. Si alguno necesita otra variable, la anota primero acá.

## Datos de la plantilla

Estas siete etiquetas vienen en `tpf.asm` y no se renombran, mueven ni cambian de tamaño. Las rutinas no las nombran: `main` les pasa las direcciones por registro.

| Etiqueta | Sección | Tamaño | Contenido | Quién la usa |
| --- | --- | --- | --- | --- |
| `secuenciaBinariaA` | `.data` | 24 bytes | Binario a codificar | `main` la pasa en RSI a CODIFICAR |
| `largoSecuenciaA` | `.data` | 1 byte (`db`) | 0x18 = 24 | `main` la lee con `movzx` a RCX |
| `secuenciaImprimibleA` | `.bss` | 32 bytes (`resb`) | Resultado de codificar | CODIFICAR la escribe (RDI) |
| `secuenciaImprmibleB` | `.data` | 32 bytes | Texto a decodificar (sin la "i", así viene) | `main` la pasa en RSI a DECODIFICAR |
| `largoSecuenciaB` | `.data` | 1 byte (`db`) | 0x20 = 32 | `main` la lee con `movzx` a RCX |
| `secuenciaBinariaB` | `.bss` | 24 bytes (`resb`) | Resultado de decodificar | DECODIFICAR la escribe (RDI) |
| `TablaConversion` | `.data` | 64 bytes | `A` a `Z`, `a` a `z`, `0` a `9`, `+`, `/` | Las dos rutinas, solo lectura |

Los datos de prueba comentados en la plantilla se descomentan solo en la copia de trabajo de cada uno, nunca en el `tpf.asm` final.

### Variables nuevas: formatos de `printf`

Para la salida por pantalla se agregan ocho variables en `.data`, después de `TablaConversion`, y un `extern printf` debajo de `global main`. Los agrega Emi una sola vez.

| Variable | Contenido | Para qué |
| --- | --- | --- |
| `codFormatoGrupo` | `"Secuencia de 3 bytes inicial: %02X %02X %02X -> caracteres imprimibles generados: %.4s",10,0` | Línea de cada grupo (Emi) |
| `codFormatoTotalInicio` | `10,"Secuencia de %d bytes completa: ",0` | Comienzo de la línea completa (Emi) |
| `codFormatoByte` | `"%02X ",0` | Cada byte de la línea completa (Emi) |
| `codFormatoTotalFin` | `"-> caracteres imprimibles generados: %.*s",10,10,0` | Cierre de la línea completa (Emi) |
| `decFormatoGrupo` | `"Secuencia de 4 caracteres inicial: %.4s -> bytes generados: %02X %02X %02X",10,0` | Línea de cada grupo (Juanma) |
| `decFormatoTotalInicio` | `10,"Secuencia de %d caracteres completa: %.*s -> bytes generados: ",0` | Comienzo de la línea completa (Juanma) |
| `decFormatoByte` | `"%02X ",0` | Cada byte de la línea completa (Juanma) |
| `decFormatoTotalFin` | `10,0` | Fin de línea (Juanma) |

`%02X` imprime un byte como dos dígitos hexa. `%.4s` imprime exactamente 4 caracteres, necesario porque los buffers no terminan en 0. El `10,0` final es salto de línea y fin de cadena.

`%d` imprime el largo en decimal, así el 24 o el 32 no quedan escritos fijos. `%.*s` imprime tantos caracteres como diga el argumento anterior. El `10` al principio de los formatos de la línea completa deja una línea en blanco antes, y el `10,10` de `codFormatoTotalFin` deja otra antes de la parte de Juanma. `codFormatoByte` y `decFormatoByte` son iguales a propósito: cada parte usa la suya y nadie depende de una variable del otro.

## Constantes comunes

Las constantes van todas juntas en un solo bloque al principio de `tpf.asm`, antes de `section .data`, y las escribe Emi una sola vez. Juanma las usa pero no las vuelve a definir en su copia final: dos `equ` con el mismo nombre dan error al ensamblar. Una constante `equ` no ocupa memoria, NASM reemplaza el nombre por el número al ensamblar.

| Constante | Valor | Para qué | La usa |
| --- | --- | --- | --- |
| `BYTES_POR_GRUPO` | 3 | Bytes binarios por grupo | Las dos |
| `CARACTERES_POR_GRUPO` | 4 | Caracteres imprimibles por grupo | Las dos |
| `MASCARA_INDICE` | 0x3F | Deja solo los 6 bits de un índice (0 a 63) | CODIFICAR |
| `DESPL_INDICE_1` | 18 | Desplazamiento para el 1º índice (bits 23 a 18) | CODIFICAR |
| `DESPL_INDICE_2` | 12 | Desplazamiento para el 2º índice (bits 17 a 12) | CODIFICAR |
| `DESPL_INDICE_3` | 6 | Desplazamiento para el 3º índice (bits 11 a 6) | CODIFICAR |
| `BITS_POR_INDICE` | 6 | Lo que se corre el acumulador antes de sumar cada índice | DECODIFICAR |
| `DESPL_BYTE_1` | 16 | Desplazamiento para el 1º byte (bits 23 a 16) | DECODIFICAR |
| `DESPL_BYTE_2` | 8 | Desplazamiento para el 2º byte (bits 15 a 8) | DECODIFICAR |
| `CANT_SIMBOLOS` | 64 | Largo de `TablaConversion`, límite de la búsqueda | DECODIFICAR |

El 4º índice y el 3º byte no necesitan constante de desplazamiento: ya están en los bits más bajos.

## main y contrato de llamada

`main` es de Emi y alinea la pila, y por cada parte llama a la rutina que convierte y después a la que muestra. Las cuatro rutinas reciben los mismos tres registros, por eso `main` los recarga antes de cada `MOSTRAR_`. El código de `main` está en la [sección 1](#arquitectura-y-contrato-de-interfaz) y en el esqueleto de abajo.

| Registro | Al entrar a la rutina | Al salir de la rutina |
| --- | --- | --- |
| RSI | Dirección del origen | Cualquier valor |
| RDI | Dirección del destino | Cualquier valor |
| RCX | Largo del origen: bytes en CODIFICAR, caracteres en DECODIFICAR | Cualquier valor |
| RAX | Sin uso | Cantidad escrita en el destino |
| RDX, R8 a R11 | Sin uso | Cualquier valor |
| RBX, RBP, R12 a R15, RSP | No se tocan | Iguales que al entrar |

RCX se usa como lo que falta procesar: cada vuelta le resta el tamaño del grupo y el ciclo termina cuando llega a 0. Así no hace falta dividir.

El `xor eax, eax` antes del `ret` de `main` no es decorativo. Lo que queda en EAX al salir de `main` es el *código de salida* (el número que el programa le devuelve al sistema; 0 significa "terminó bien"). Sin esa línea el programa devuelve 24, lo que dejó DECODIFICAR en RAX, y parece que falló. El rótulo `finPrograma` sirve para poner ahí el punto de parada de GDB.

El `sub rsp, 8` al entrar y el `add rsp, 8` antes de salir dejan la pila como la espera cualquier función de C. Sin eso, `printf` arranca con la pila desalineada y puede romperse.

## CODIFICAR (Emi)

Convierte grupos de 3 bytes en grupos de 4 caracteres. Cada registro tiene un solo rol durante toda la rutina, para que quien lea el código sepa qué hay en cada uno sin seguirle el rastro.

| Registro | Rol |
| --- | --- |
| RSI | Byte actual del origen; avanza `BYTES_POR_GRUPO` por vuelta |
| RDI | Posición actual del destino; avanza `CARACTERES_POR_GRUPO` por vuelta |
| RCX | Bytes que faltan codificar |
| EAX | Los 24 bits del grupo actual; no se modifica mientras se sacan los 4 índices |
| EDX / DL | Copia de EAX para sacar cada índice; después, el carácter leído de la tabla |
| R8D | Byte leído del origen antes de unirlo a EAX |
| R9 | Caracteres escritos; pasa a RAX al salir |

| Rótulo | Nombre completo | Dónde va |
| --- | --- | --- |
| `.ciclo` | `CODIFICAR.ciclo` | Inicio de cada vuelta; ahí se pregunta si RCX llegó a 0 |
| `.fin` | `CODIFICAR.fin` | Copia R9 a RAX y hace `ret` |

El carácter se trae a DL y no a AL porque AL es parte de EAX y borraría los bits que faltan.

## DECODIFICAR (Juanma)

Convierte grupos de 4 caracteres en grupos de 3 bytes. Usa los mismos registros que CODIFICAR para las mismas funciones (RSI, RDI, RCX, R9), así las dos rutinas se leen igual.

| Registro | Rol |
| --- | --- |
| RSI | Carácter actual del origen; avanza de a 1 dentro del grupo |
| RDI | Posición actual del destino; avanza `BYTES_POR_GRUPO` por vuelta |
| RCX | Caracteres que faltan decodificar |
| EAX | Acumulador de los 24 bits del grupo; arranca en 0 en cada vuelta |
| DL | Carácter que se manda a buscar a la tabla; después, cada byte a guardar |
| R8D | Índice (0 a 63) que devuelve `.buscarIndice` |
| R9 | Bytes escritos; pasa a RAX al salir |
| R10 | Caracteres que faltan dentro del grupo actual (de 4 a 0) |

| Rótulo | Nombre completo | Dónde va |
| --- | --- | --- |
| `.ciclo` | `DECODIFICAR.ciclo` | Inicio de cada grupo; ahí se pregunta si RCX llegó a 0 |
| `.caracter` | `DECODIFICAR.caracter` | Ciclo interno que procesa los 4 caracteres del grupo |
| `.fin` | `DECODIFICAR.fin` | Copia R9 a RAX y hace `ret` |
| `.buscarIndice` | `DECODIFICAR.buscarIndice` | Subrutina interna, se llama con `call .buscarIndice` |
| `.compara` | `DECODIFICAR.compara` | Ciclo de la búsqueda |
| `.encontrado` | `DECODIFICAR.encontrado` | Salida de la búsqueda (`ret`) |

**Contrato de `.buscarIndice`.** Recibe el carácter en DL y devuelve en R8 su posición en `TablaConversion`, recorriéndola de 0 a `CANT_SIMBOLOS - 1`. Si no lo encuentra devuelve 0. Solo modifica R8 y los flags: no toca EAX ni R10, que DECODIFICAR sigue usando.

**Corrección respecto de una versión anterior del plan.** Una primera versión decía que la búsqueda devolvía el índice en AL. Está mal: AL es parte de EAX, que es el acumulador, y lo rompería en cada carácter. Por eso el índice vuelve en R8.

## Rutinas de salida: MOSTRAR_CODIFICACION (Emi) y MOSTRAR_DECODIFICACION (Juanma)

Cada una recorre su origen y su destino en paralelo y hace un `printf` por grupo; al final arma la línea completa con varias llamadas más. Van aparte de las rutinas que convierten porque `printf` pisa RSI, RDI, RCX y R8 a R11, que son los registros de los ciclos de conversión. Las dos tienen la misma forma; cambia qué va en cada argumento.

| Registro | MOSTRAR_CODIFICACION | MOSTRAR_DECODIFICACION |
| --- | --- | --- |
| RBX | Dirección del origen | Dirección del origen |
| R12 | Dirección del destino | Dirección del destino |
| R13 | Largo del origen | Largo del origen |
| R14 | Grupo actual: el grupo empieza en RBX + 3 × R14 y su resultado en R12 + 4 × R14 | Grupo actual: el grupo empieza en RBX + 4 × R14 y su resultado en R12 + 3 × R14 |
| RDI | El formato de cada `printf` | El formato de cada `printf` |
| RSI, RDX, RCX | Los 3 bytes del grupo (con `movzx`) | RSI = dirección de los 4 caracteres; EDX y ECX = 1º y 2º byte generado |
| R8 | Dirección de los 4 caracteres generados | 3º byte generado (con `movzx`) |
| EAX | 0 antes de cada `call printf` | 0 antes de cada `call printf` |

**Línea completa de MOSTRAR_CODIFICACION.** Un `printf` con `codFormatoTotalInicio` y el largo en ESI. Después uno con `codFormatoByte` por cada byte del origen: RBX avanza y R13 cuenta los que faltan, porque a esa altura ya no se necesitan. Al final uno con `codFormatoTotalFin`: ESI = 4 × R14 (la cantidad de caracteres) y RDX = R12.

**Línea completa de MOSTRAR_DECODIFICACION.** Un `printf` con `decFormatoTotalInicio`: ESI = EDX = largo y RCX = RBX. Después uno con `decFormatoByte` por cada byte generado: R13 pasa a 3 × R14 y R12 avanza. Al final uno con `decFormatoTotalFin`.

RBX, R12, R13 y R14 se usan porque `printf` está obligada a devolverlos intactos. Cada rutina hace `push rbx`, `push r12`, `push r13`, `push r14` y después `sub rsp, 8`; al salir, `add rsp, 8` y los `pop` en orden inverso. Los 4 `push` mueven la pila 32 bytes y la dejarían desalineada: el `sub rsp, 8` lo compensa y, junto con el de `main`, deja RSP en múltiplo de 16 en cada `call printf`. Si alguno agrega o saca un `push`, tiene que rehacer esa cuenta.

Rótulos de `MOSTRAR_CODIFICACION`: `.grupo`, `.total`, `.byte`, `.resultado` y `.fin`. De `MOSTRAR_DECODIFICACION`: `.grupo`, `.total`, `.byte`, `.salto` y `.fin`. Como son locales, quedan `MOSTRAR_CODIFICACION.grupo`, `MOSTRAR_DECODIFICACION.grupo`, etc., sin chocar.

## Esqueleto de tpf.asm

Este es el archivo final con todo lo de arriba en su lugar y las cuatro rutinas vacías. Lo ensamblé y enlacé con los comandos de la guía 00 de la cátedra (NASM 2.16): no da errores ni advertencias y termina con código de salida 0. Cada uno lo copia como `tpf_cod.asm` o `tpf_dec.asm` y completa solo los comentarios de su rutina, sin tocar el resto.

Como control, armé aparte una versión con las cuatro rutinas completas respetando exactamente estos nombres, constantes y registros. Ensambla, deja en memoria los resultados esperados para los dos casos de entrega y muestra por pantalla la salida esperada del plan. En GDB, RSP es múltiplo de 16 en cada llamada a printf. O sea, el diseño cierra: si cada uno respeta este documento, las rutinas se pueden juntar sin cambios.

```nasm
global	main
extern	printf

;=====================================================================
; CONSTANTES (bloque unico, lo mantiene Emi)
;=====================================================================
BYTES_POR_GRUPO			equ	3
CARACTERES_POR_GRUPO	equ	4
MASCARA_INDICE			equ	0x3F
DESPL_INDICE_1			equ	18
DESPL_INDICE_2			equ	12
DESPL_INDICE_3			equ	6
BITS_POR_INDICE			equ	6
DESPL_BYTE_1			equ	16
DESPL_BYTE_2			equ	8
CANT_SIMBOLOS			equ	64

section	.data
	secuenciaBinariaA	db	0xC4, 0x94, 0x37, 0x95, 0x63, 0xA2, 0x1D, 0x3C
						db	0x86, 0xFC, 0x22, 0xA9, 0x3D, 0x7C, 0xA4, 0x51
						db	0x63, 0x7C, 0x29, 0x04, 0x93, 0xBB, 0x65, 0x18
	largoSecuenciaA		db	0x18 ; 24d

	secuenciaImprmibleB db	"vhyAHZucgTUuznwTDciGQ8m4TuvUIyjU"
	largoSecuenciaB		db	0x20 ; 32d

	TablaConversion		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

	; Formatos de salida (variables nuevas)
	codFormatoGrupo		db	"Secuencia de 3 bytes inicial: %02X %02X %02X -> caracteres imprimibles generados: %.4s",10,0
	codFormatoTotalInicio	db	10,"Secuencia de %d bytes completa: ",0
	codFormatoByte			db	"%02X ",0
	codFormatoTotalFin		db	"-> caracteres imprimibles generados: %.*s",10,10,0
	decFormatoGrupo		db	"Secuencia de 4 caracteres inicial: %.4s -> bytes generados: %02X %02X %02X",10,0
	decFormatoTotalInicio	db	10,"Secuencia de %d caracteres completa: %.*s -> bytes generados: ",0
	decFormatoByte			db	"%02X ",0
	decFormatoTotalFin		db	10,0

section	.bss
	secuenciaImprimibleA	resb	32
	secuenciaBinariaB		resb	24

section	.text

;=====================================================================
; main (Emi): convierte, muestra y termina
;=====================================================================
main:
		sub		rsp, 8			; alinea la pila una sola vez

		mov		rsi, secuenciaBinariaA
		mov		rdi, secuenciaImprimibleA
		movzx	rcx, byte[largoSecuenciaA]
		call	CODIFICAR
		mov		rsi, secuenciaBinariaA
		mov		rdi, secuenciaImprimibleA
		movzx	rcx, byte[largoSecuenciaA]
		call	MOSTRAR_CODIFICACION

		mov		rsi, secuenciaImprmibleB
		mov		rdi, secuenciaBinariaB
		movzx	rcx, byte[largoSecuenciaB]
		call	DECODIFICAR
		mov		rsi, secuenciaImprmibleB
		mov		rdi, secuenciaBinariaB
		movzx	rcx, byte[largoSecuenciaB]
		call	MOSTRAR_DECODIFICACION
finPrograma:
		add		rsp, 8
		xor		eax, eax		; codigo de salida 0
		ret

;---------------------------------------------------------------------
; CODIFICAR (Emi): convierte bytes binarios a caracteres Base64
; Entrada : RSI = origen, RDI = destino, RCX = largo en bytes
; Salida  : destino cargado, RAX = caracteres escritos
; Modifica: RAX, RCX, RDX, RSI, RDI, R8, R9
;---------------------------------------------------------------------
CODIFICAR:
		xor		r9d, r9d		; caracteres escritos = 0
.ciclo:
		; si RCX = 0, terminar
		; armar los 24 bits del grupo en EAX
		; sacar los 4 indices y escribir los 4 caracteres
		; avanzar RSI, RDI, sumar a R9, restar a RCX
.fin:
		mov		rax, r9
		ret

;---------------------------------------------------------------------
; DECODIFICAR (Juanma): convierte caracteres Base64 a binario
; Entrada : RSI = origen, RDI = destino, RCX = largo en caracteres
; Salida  : destino cargado, RAX = bytes escritos
; Modifica: RAX, RCX, RDX, RSI, RDI, R8, R9, R10
;---------------------------------------------------------------------
DECODIFICAR:
		xor		r9d, r9d		; bytes escritos = 0
.ciclo:
		; si RCX = 0, terminar
		; EAX = 0, R10 = CARACTERES_POR_GRUPO
.caracter:
		; DL = caracter, call .buscarIndice, acumular R8 en EAX
		; avanzar RSI, repetir mientras R10 > 0
		; escribir los 3 bytes, avanzar RDI, sumar a R9, restar a RCX
.fin:
		mov		rax, r9
		ret

;---------------------------------------------------------------------
; .buscarIndice (Juanma, interna de DECODIFICAR)
; Entrada : DL = caracter
; Salida  : R8 = posicion en TablaConversion (0 si no esta)
; Modifica: R8, flags
;---------------------------------------------------------------------
.buscarIndice:
		xor		r8d, r8d
.compara:
		; comparar DL con TablaConversion[R8], avanzar hasta CANT_SIMBOLOS
.encontrado:
		ret

;---------------------------------------------------------------------
; MOSTRAR_CODIFICACION (Emi): imprime cada grupo y la secuencia completa
; Entrada : RSI = origen, RDI = destino, RCX = largo en bytes
; Salida  : una linea por grupo y una linea final con todo
; Modifica: RAX, RCX, RDX, RSI, RDI, R8 a R11 (los pisa printf)
; Preserva: RBX, R12, R13, R14 (push al entrar, pop al salir)
;---------------------------------------------------------------------
MOSTRAR_CODIFICACION:
		push	rbx
		push	r12
		push	r13
		push	r14
		sub		rsp, 8			; 4 push + 8 = pila alineada
		mov		rbx, rsi		; origen
		mov		r12, rdi		; destino
		mov		r13, rcx		; largo del origen
		xor		r14d, r14d		; grupo actual = 0
.grupo:
		; si 3 * R14 >= R13, ir a .total
		; printf con codFormatoGrupo: 3 bytes del grupo y sus 4 caracteres
		; inc R14
.total:
		; printf con codFormatoTotalInicio (largo en ESI)
.byte:
		; printf con codFormatoByte por cada byte del origen
.resultado:
		; printf con codFormatoTotalFin (4 * R14 caracteres desde R12)
.fin:
		add		rsp, 8
		pop		r14
		pop		r13
		pop		r12
		pop		rbx
		ret

;---------------------------------------------------------------------
; MOSTRAR_DECODIFICACION (Juanma): imprime cada grupo y la secuencia completa
; Entrada : RSI = origen, RDI = destino, RCX = largo en caracteres
; Salida  : una linea por grupo y una linea final con todo
; Modifica: RAX, RCX, RDX, RSI, RDI, R8 a R11 (los pisa printf)
; Preserva: RBX, R12, R13, R14 (push al entrar, pop al salir)
;---------------------------------------------------------------------
MOSTRAR_DECODIFICACION:
		push	rbx
		push	r12
		push	r13
		push	r14
		sub		rsp, 8			; 4 push + 8 = pila alineada
		mov		rbx, rsi		; origen
		mov		r12, rdi		; destino
		mov		r13, rcx		; largo del origen
		xor		r14d, r14d		; grupo actual = 0
.grupo:
		; si 4 * R14 >= R13, ir a .total
		; printf con decFormatoGrupo: 4 caracteres del grupo y sus 3 bytes
		; inc R14
.total:
		; printf con decFormatoTotalInicio (largo y origen completo)
.byte:
		; printf con decFormatoByte por cada byte del destino (3 * R14)
.salto:
		; printf con decFormatoTotalFin
.fin:
		add		rsp, 8
		pop		r14
		pop		r13
		pop		r12
		pop		rbx
		ret
```
