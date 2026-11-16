INCLUDE Irvine32.inc

; =================================================================
; 1. DEFINICIÓN DE MACROS
; =================================================================
ImprimirTexto MACRO variableTexto
    push edx                        ;; Protege el valor actual de EDX
    mov edx, OFFSET variableTexto   ;; Carga la dirección del texto
    call WriteString                ;; Imprime en consola
    pop edx                         ;; Restaura EDX a su valor original
ENDM

; =================================================================
; 2. ESTRUCTURAS Y CONSTANTES
; =================================================================
MAX_PRODUCTOS = 10

Producto STRUCT
    codigo BYTE 8 DUP(0)
    nombre BYTE 26 DUP(0)
    precio DWORD 0
    existencia DWORD 0
Producto ENDS

TAM_PRODUCTO = SIZEOF Producto

.data
; --- Variables del Sistema ---
inventario Producto MAX_PRODUCTOS DUP(<>)
numProductos DWORD 0
ingresosSesion DWORD 0
archivoNombre BYTE "inventario.dat", 0
handleArchivo HANDLE ?
bytesLeidos DWORD ?

; --- Búferes de Entrada ---
bufferCodigo BYTE 8 DUP(0)
bufferNombre BYTE 26 DUP(0)
bufferEntrada BYTE 20 DUP(0)

; --- Textos del Menú ---
menuTitulo BYTE "=== TIENDA DE ELECTRONICA ===", 13, 10, 0
menu1 BYTE "1. Registrar producto", 13, 10, 0
menu2 BYTE "2. Buscar producto", 13, 10, 0
menu3 BYTE "3. Mostrar inventario", 13, 10, 0
menu4 BYTE "4. Recibir mercancia", 13, 10, 0
menu5 BYTE "5. Vender", 13, 10, 0
menu6 BYTE "6. Mostrar resumen", 13, 10, 0
menu7 BYTE "7. Salir y Guardar", 13, 10, 0
promptOpc BYTE "Elige una opcion: ", 0

; --- Textos de Prompts ---
pCodigo BYTE "Ingrese codigo (ABC-123): ", 0
pNombre BYTE "Ingrese nombre: ", 0
pPrecio BYTE "Ingrese precio (ej. 250.50): ", 0
pCant BYTE "Cantidad inicial: ", 0
pCantRec BYTE "Cantidad a recibir: ", 0
pCantVen BYTE "Cantidad a vender: ", 0

; --- Textos de Salida y Errores ---
msgMx BYTE " MXN", 0
msgSep BYTE " | ", 0
msgStock BYTE " uds.", 0
msgInvVacio BYTE "El inventario esta vacio.", 13, 10, 0
msgTotal BYTE "Total a pagar: $", 0
msgDesc BYTE "!Descuento 10% aplicado por mayoreo (>=3)!", 13, 10, 0
msgVentaExitosa BYTE "Venta exitosa. ", 0
msgInvTotal BYTE "---------------------------", 13, 10, "Total inventario: $", 0
msgIngresos BYTE "Ingresos de sesion: $", 0
msgGuardado BYTE "Archivo guardado. Bytes escritos: ", 0
msgCargado BYTE "Inventario cargado. Productos recuperados: ", 0

errLleno BYTE "Error: Inventario lleno.", 13, 10, 0
errDup BYTE "Error: Codigo ya existe.", 13, 10, 0
errNoF BYTE "Error: Producto no encontrado.", 13, 10, 0
errMax BYTE "Error: La existencia superaria las 100 unidades.", 13, 10, 0
errInsuf BYTE "Error: Existencias insuficientes.", 13, 10, 0
errArchivo BYTE "ERROR: No se pudo crear/abrir inventario.dat", 13, 10, 0

.code
; =================================================================
; MAIN: Carga de archivo y Menú Principal
; =================================================================
main PROC
    ; Intentar cargar inventario.dat
    mov edx, OFFSET archivoNombre
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je IniciarMenu
    mov handleArchivo, eax
    
    mov edx, OFFSET inventario
    mov ecx, SIZEOF inventario
    mov eax, handleArchivo
    call ReadFromFile
    mov bytesLeidos, eax
    
    mov eax, handleArchivo
    call CloseFile
    
    ; Calcular numProductos
    mov eax, bytesLeidos
    mov ecx, SIZEOF Producto
    xor edx, edx
    div ecx
    mov numProductos, eax

    ; Avisar cuántos productos cargó
    ImprimirTexto msgCargado
    mov eax, numProductos
    call ImprimirEntero
    call Crlf

IniciarMenu:
    call Crlf
    ImprimirTexto menuTitulo
    ImprimirTexto menu1
    ImprimirTexto menu2
    ImprimirTexto menu3
    ImprimirTexto menu4
    ImprimirTexto menu5
    ImprimirTexto menu6
    ImprimirTexto menu7
    ImprimirTexto promptOpc

    ; Leer opción
    mov edx, OFFSET bufferEntrada
    mov ecx, SIZEOF bufferEntrada
    call ReadString
    mov al, bufferEntrada[0]

    cmp al, '1'
    je OpcRegistrar
    cmp al, '2'
    je OpcBuscar
    cmp al, '3'
    je OpcMostrar
    cmp al, '4'
    je OpcRecibir
    cmp al, '5'
    je OpcVender
    cmp al, '6'
    je OpcResumen
    cmp al, '7'
    je OpcSalir
    jmp IniciarMenu

OpcRegistrar: call RegistrarProducto
    jmp IniciarMenu
OpcBuscar:    call BuscarProducto
    jmp IniciarMenu
OpcMostrar:   call MostrarInventario
    jmp IniciarMenu
OpcRecibir:   call RecibirMercancia
    jmp IniciarMenu
OpcVender:    call VenderProducto
    jmp IniciarMenu
OpcResumen:   call MostrarResumen
    jmp IniciarMenu

OpcSalir:
    ; Guardar archivo y salir
    mov edx, OFFSET archivoNombre
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorAlGuardar
    mov handleArchivo, eax

    mov eax, numProductos
    mov ecx, SIZEOF Producto
    mul ecx
    mov ecx, eax                ; ECX = bytes totales a escribir

    mov edx, OFFSET inventario  ; EDX = puntero a los datos
    mov eax, handleArchivo      ; EAX = handle del archivo
    call WriteToFile

    push eax                    ; Guardar bytes escritos para imprimirlos
    mov eax, handleArchivo
    call CloseFile

    ImprimirTexto msgGuardado
    pop eax
    call ImprimirEntero
    call Crlf
    call WaitMsg                ; Pausa para que alcances a leer el mensaje
    exit

ErrorAlGuardar:
    ImprimirTexto errArchivo
    call WaitMsg
    exit
main ENDP

; =================================================================
; 1. REGISTRAR PRODUCTO
; =================================================================
RegistrarProducto PROC
    mov eax, numProductos
    cmp eax, MAX_PRODUCTOS
    jb SeguirRegistro
    ImprimirTexto errLleno
    ret

SeguirRegistro:
    ImprimirTexto pCodigo
    mov edx, OFFSET bufferCodigo
    mov ecx, 8
    call ReadString

    call BuscarPorCodigo
    jz CodigoDuplicado

    ; Calcular ESI para el nuevo producto
    mov eax, numProductos
    mov ecx, TAM_PRODUCTO
    mul ecx
    mov esi, OFFSET inventario
    add esi, eax

    ; Copiar código
    INVOKE Str_copy, ADDR bufferCodigo, ADDR (Producto PTR [esi]).codigo

    ImprimirTexto pNombre
    mov edx, OFFSET bufferNombre
    mov ecx, 26
    call ReadString
    INVOKE Str_copy, ADDR bufferNombre, ADDR (Producto PTR [esi]).nombre

    ImprimirTexto pPrecio
    mov edx, OFFSET bufferEntrada
    mov ecx, 20
    call ReadString
    call CadenaACentavos
    mov (Producto PTR [esi]).precio, eax

    ImprimirTexto pCant
    mov edx, OFFSET bufferEntrada
    mov ecx, 20
    call ReadString
    call CadenaAEntero
    cmp eax, 100
    jbe GuardarExistencia
    ImprimirTexto errMax
    ret

GuardarExistencia:
    mov (Producto PTR [esi]).existencia, eax
    inc numProductos
    ret

CodigoDuplicado:
    ImprimirTexto errDup
    ret
RegistrarProducto ENDP

; =================================================================
; 2. BUSCAR PRODUCTO POR CÓDIGO
; =================================================================
BuscarProducto PROC
    ImprimirTexto pCodigo
    mov edx, OFFSET bufferCodigo
    mov ecx, 8
    call ReadString

    call BuscarPorCodigo
    jnz NoEncontradoBuscar

    ; Si lo encuentra, ESI ya apunta al producto encontrado
    call ImprimirDetalleProducto
    ret

NoEncontradoBuscar:
    ImprimirTexto errNoF
    ret
BuscarProducto ENDP

; =================================================================
; 3. MOSTRAR INVENTARIO COMPLETO
; =================================================================
MostrarInventario PROC
    mov esi, OFFSET inventario
    mov ecx, numProductos
    test ecx, ecx
    jz InvVacio

CicloMostrar:
    push ecx
    call ImprimirDetalleProducto
    add esi, TAM_PRODUCTO
    pop ecx
    loop CicloMostrar
    ret

InvVacio:
    ImprimirTexto msgInvVacio
    ret
MostrarInventario ENDP

; =================================================================
; 4. RECIBIR MERCANCÍA
; =================================================================
RecibirMercancia PROC
    ImprimirTexto pCodigo
    mov edx, OFFSET bufferCodigo
    mov ecx, 8
    call ReadString

    call BuscarPorCodigo
    jnz NoEncontrado

    ImprimirTexto pCantRec
    mov edx, OFFSET bufferEntrada
    mov ecx, 20
    call ReadString
    call CadenaAEntero
    
    mov ebx, (Producto PTR [esi]).existencia
    add ebx, eax
    cmp ebx, 100
    ja SuperaLimite
    mov (Producto PTR [esi]).existencia, ebx
    ret

SuperaLimite:
    ImprimirTexto errMax
    ret
NoEncontrado:
    ImprimirTexto errNoF
    ret
RecibirMercancia ENDP

; =================================================================
; 5. VENDER PRODUCTO (REGLA DEL 10%)
; =================================================================
VenderProducto PROC
    ImprimirTexto pCodigo
    mov edx, OFFSET bufferCodigo
    mov ecx, 8
    call ReadString

    call BuscarPorCodigo
    jnz NoEncontrado2

    ImprimirTexto pCantVen
    mov edx, OFFSET bufferEntrada
    mov ecx, 20
    call ReadString
    call CadenaAEntero
    mov ecx, eax            ; ECX = Cantidad a vender

    cmp ecx, (Producto PTR [esi]).existencia
    ja SinExistencia

    ; Actualizar inventario
    mov ebx, (Producto PTR [esi]).existencia
    sub ebx, ecx
    mov (Producto PTR [esi]).existencia, ebx

    ; Calcular total: Precio * Cantidad
    mov eax, (Producto PTR [esi]).precio
    mul ecx                 ; EAX = Total sin descuento
    mov ebx, eax            ; Guardamos el total en EBX

    ; Aplicar regla de negocio (>= 3 unidades)
    cmp ecx, 3
    jb VentaSinDescuento

    ImprimirTexto msgDesc
    mov eax, ebx
    mov ecx, 10
    xor edx, edx
    div ecx                 ; EAX = 10% del total
    sub ebx, eax            ; EBX = Total final con descuento

VentaSinDescuento:
    ; Sumar a ingresos
    mov eax, ingresosSesion
    add eax, ebx
    mov ingresosSesion, eax

    ImprimirTexto msgVentaExitosa
    ImprimirTexto msgTotal
    mov eax, ebx
    call CentavosACadena
    call Crlf
    ret

SinExistencia:
    ImprimirTexto errInsuf
    ret
NoEncontrado2:
    ImprimirTexto errNoF
    ret
VenderProducto ENDP

; =================================================================
; 6. MOSTRAR RESUMEN (INGRESOS E INVENTARIO)
; =================================================================
MostrarResumen PROC
    ImprimirTexto msgInvTotal
    
    mov esi, OFFSET inventario
    mov ecx, numProductos
    xor ebx, ebx            ; Acumulador de valor de inventario

    test ecx, ecx
    jz ImprimirResumen

CicloSumaInv:
    mov eax, (Producto PTR [esi]).precio
    push ebx
    mov ebx, (Producto PTR [esi]).existencia
    mul ebx                 ; EAX = precio * existencia
    pop ebx
    add ebx, eax            ; Sumar al acumulador total
    add esi, TAM_PRODUCTO
    dec ecx
    jnz CicloSumaInv

ImprimirResumen:
    mov eax, ebx
    call CentavosACadena
    call Crlf
    
    ImprimirTexto msgIngresos
    mov eax, ingresosSesion
    call CentavosACadena
    call Crlf
    ret
MostrarResumen ENDP

; =================================================================
; RUTINAS AUXILIARES Y CONVERSIONES
; =================================================================
ImprimirDetalleProducto PROC
    ; Asume que ESI apunta al producto actual
    mov edx, esi
    call WriteString
    ImprimirTexto msgSep

    mov edx, esi
    add edx, 8
    call WriteString
    ImprimirTexto msgSep

    mov al, '$'
    call WriteChar
    mov eax, (Producto PTR [esi]).precio
    call CentavosACadena
    ImprimirTexto msgSep

    mov eax, (Producto PTR [esi]).existencia
    call ImprimirEntero
    ImprimirTexto msgStock
    call Crlf
    ret
ImprimirDetalleProducto ENDP

BuscarPorCodigo PROC
    mov esi, OFFSET inventario
    mov ecx, numProductos
    test ecx, ecx
    jz B_NoEncontrado
B_Ciclo:
    push ecx
    INVOKE Str_compare, ADDR (Producto PTR [esi]).codigo, ADDR bufferCodigo
    pop ecx
    jz B_Encontrado
    add esi, TAM_PRODUCTO
    dec ecx
    jnz B_Ciclo
B_NoEncontrado:
    or eax, 1       ; Asegura ZF=0 (No encontrado)
    ret
B_Encontrado:
    cmp eax, eax    ; Enciende flag Z (ZF=1)
    ret
BuscarPorCodigo ENDP

CadenaAEntero PROC
    push ebx
    push ecx
    push esi
    xor eax, eax
    xor ecx, ecx
    mov esi, OFFSET bufferEntrada
C_Ciclo:
    mov cl, [esi]
    cmp cl, 13
    je C_Fin
    cmp cl, 0
    je C_Fin
    sub cl, 30h
    mov ebx, 10
    mul ebx
    add eax, ecx
    inc esi
    jmp C_Ciclo
C_Fin:
    pop esi
    pop ecx
    pop ebx
    ret
CadenaAEntero ENDP

CadenaACentavos PROC
    push ebx
    push ecx
    push esi
    xor eax, eax
    xor ecx, ecx
    xor ebx, ebx      ; EBX = contador de decimales
    mov esi, OFFSET bufferEntrada
CC_Ciclo:
    mov cl, [esi]
    cmp cl, 13
    je CC_RevisarCeros
    cmp cl, 0
    je CC_RevisarCeros
    cmp cl, '.'
    je CC_EsPunto
    
    sub cl, 30h
    push ebx
    mov ebx, 10
    mul ebx
    pop ebx
    add eax, ecx
    
    cmp ebx, 0
    je CC_Siguiente
    inc ebx           ; Contar cuántos decimales llevamos
    cmp ebx, 3
    je CC_Fin         ; Limitar a 2 decimales (ignoramos el tercero)
    jmp CC_Siguiente
    
CC_EsPunto:
    mov ebx, 1        ; Activar bandera de decimales
CC_Siguiente:
    inc esi
    jmp CC_Ciclo
    
CC_RevisarCeros:
    cmp ebx, 0
    je CC_SinDecimales
    cmp ebx, 1
    je CC_UnDecimal
    jmp CC_Fin
CC_SinDecimales:
    mov ebx, 100
    mul ebx
    jmp CC_Fin
CC_UnDecimal:
    mov ebx, 10
    mul ebx
CC_Fin:
    pop esi
    pop ecx
    pop ebx
    ret
CadenaACentavos ENDP

CentavosACadena PROC
    pushad
    mov ecx, 100
    xor edx, edx
    div ecx
    push edx             ; Guardar centavos

    mov ebx, 10
    xor ecx, ecx
CicloPesos:
    xor edx, edx
    div ebx
    add dl, 30h
    push edx
    inc ecx
    test eax, eax
    jnz CicloPesos
ImprimePesos:
    pop eax
    call WriteChar
    loop ImprimePesos

    mov al, '.'
    call WriteChar

    pop eax              ; Recuperar centavos
    cmp eax, 10
    jae ImprimeCents2D

    push eax
    mov al, '0'
    call WriteChar       ; Imprimir 0 a la izquierda
    pop eax
    add al, 30h
    call WriteChar
    jmp FinCents

ImprimeCents2D:
    mov ebx, 10
    xor edx, edx
    div ebx
    add al, 30h
    add dl, 30h
    call WriteChar
    mov al, dl
    call WriteChar

FinCents:
    ImprimirTexto msgMx
    popad
    ret
CentavosACadena ENDP

ImprimirEntero PROC
    pushad
    mov ecx, 10
    xor edi, edi
CicloDivE:
    xor edx, edx
    div ecx
    add dl, 30h
    push edx
    inc edi
    test eax, eax
    jnz CicloDivE
ImprimeDig:
    pop eax
    call WriteChar
    dec edi
    jnz ImprimeDig
    popad
    ret
ImprimirEntero ENDP

END main