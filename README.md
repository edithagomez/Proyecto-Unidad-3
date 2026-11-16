# Sistema de Ventas e Inventario (MASM x86 - Unidad 3)

**Materia:** Lenguajes de Interfaz  

**Equipo:**
* Ángel David Quiñónez Figueroa
* Sahory Estrada Trejo
* Edith Alessandra Gomez Sanchez

---

## Documentación y Reporte

* [Reporte Actualizado U3.pdf](./Reporte%20Actualizado%20U3.pdf) — Incluye la comparativa de antes y después, fragmentos de código refactorizado, conteo de líneas y evidencias de ejecución.

---

## Descripción del Proyecto

Sistema de gestión de ventas e inventario para una **Tienda de Electrónica**, desarrollado en lenguaje ensamblador **x86 de 32 bits** utilizando **Microsoft Macro Assembler (MASM)** y la librería **Irvine32**.

En esta versión correspondiente a la **Unidad 3**, se refactorizó el código fuente (`codigo.asm`) para eliminar repeticiones y mejorar la modularidad mediante:

* **Macros parametrizadas:** `ImprimirTexto` (resguardo de `EDX`) y `ValidarMaximo` (uso de etiqueta interna con `LOCAL` para evitar colisiones de nombres).
* **Procedimientos extraídos:** `LeerCadena` (estandarización de captura), `ImprimirDetalleProducto` (reutilizado en búsqueda e inventario completo), `CadenaAEntero` y `CadenaACentavos`.
* **Directiva `USES`:** Resguardo automático de registros en subrutinas, excluyendo aquellos que devuelven resultados (`EAX` y `ESI`).

---

## Reglas de Negocio y Estructura

* **Estructura en memoria (`Producto`):** Arreglo continuo de hasta 10 productos (`STRUCT` de **42 bytes**: código de 8 bytes, nombre de 26 bytes, precio en centavos de 4 bytes y existencia de 4 bytes).
* **Límite de inventario:** Máximo **100 unidades** por producto y códigos únicos (`ABC-123`).
* **Descuento por mayoreo:** Aplicación automática del **10% de descuento** en ventas de **3 o más unidades** de un mismo artículo.
* **Persistencia binaria:** Almacenamiento y carga automática del catálogo desde el archivo `inventario.dat`.

---

## Requisitos Previos

* **Visual Studio 2022** con la carga de trabajo *Desarrollo para el escritorio con C++*.
* **Librería Irvine32** instalada en una ruta local (ej. `C:\Irvine32\Irvine`).

---

## Instrucciones de Compilación y Ejecución

1. **Clonar o descargar** este repositorio en tu equipo local.
2. **Abrir la solución** (`.sln`) en Visual Studio.
3. **Verificar la arquitectura:** Asegurar en la barra superior que esté configurada en **x86 (32 bits)**.
4. **Habilitar MASM:** Clic derecho en el proyecto > *Dependencias de compilación* > *Personalizaciones de compilación* > marcar `masm(.targets, .props)`.
5. **Configurar rutas de Irvine32** en *Propiedades del proyecto*:
   * **Microsoft Macro Assembler > General > Include Paths:** Agregar la ruta de la carpeta `Irvine` (donde se encuentran `Irvine32.inc` y `SmallWin.inc`).
   * **Vinculador > General > Directorios de bibliotecas adicionales:** Agregar la misma ruta de la carpeta `Irvine` (donde se encuentra `Irvine32.lib`).
   * **Vinculador > Entrada > Dependencias adicionales:** Verificar que incluya `Irvine32.lib;kernel32.lib;user32.lib;`.
   * **Vinculador > Sistema > Subsistema:** Configurar como **Consola (`/SUBSYSTEM:CONSOLE`)**.
6. **Preparar datos iniciales:** Colocar el archivo de prueba `inventario.dat` en el directorio de trabajo del proyecto si se desea cargar el catálogo inicial.
7. **Compilar y ejecutar:** Presionar `Ctrl + F5` (*Depurar > Iniciar sin depurar*).

---

## Estructura del Repositorio

* **`codigo.asm`** — Código fuente principal en ensamblador MASM x86 refactorizado.
* **`inventario.dat`** — Archivo binario de inventario de prueba.
* **`Reporte Actualizado U3.pdf`** — Documentación completa del proyecto y evidencias de pruebas.
* **`README.md`** — Información general e instrucciones de compilación.
