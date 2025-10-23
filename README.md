# Sistema de Intercambio de Comisiones (SIC)

## Proyecto de Estudio - Bases de Datos I

**Asignatura:** Bases de Datos I  
**Institución:** FaCENA - UNNE  
**Grupo:** 9

---

### Descripción del Proyecto

Este repositorio contiene el desarrollo del proyecto de estudio para la asignatura Bases de Datos I. El proyecto consiste en el **diseño e implementación de la base de datos** para un "Sistema de Intercambio de Comisiones (SIC)".

El objetivo de la aplicación (SIC) es brindar una herramienta digital que permita a los estudiantes universitarios gestionar de manera eficiente el intercambio de comisiones de cursado, mediante un sistema de emparejamiento inteligente.

### Integrantes del Grupo

- Riveros, Lautaro Ezquiel.
- Riveros, Maximo Tomas.
- Scetti, Santiago.
- Turtola, Sabrina.

### Motor de Base de Datos

El motor de base de datos seleccionado para la implementación es: **SQL Server**

---

### Estructura del Repositorio

El proyecto se organiza en la siguiente estructura de carpetas:

```plaintext
/
|
+-- 📄 README.md (Este archivo)
|
+-- 📁 documento/
|   |
|   +-- 📄 BDI_Grupo09_Informe.docx (Documento principal del proyecto - Capítulos I al VI)
|   |
|   +-- 📁 img/
|       +-- 🖼️ erd_sic.png (Diagrama Entidad-Relación del sistema)
|
+-- 📁 scripts/
    |
    +-- 📜 01_schema_creacion.sql
    |   (Script para la creación de todas las tablas, vistas y restricciones)
    |
    +-- 📜 02_carga_datos.sql
    |   (Script con los INSERTs para la carga de datos de prueba representativos)
    |
    +-- 📁 03_temas_investigacion/
        |
        +-- 📁 permisos/
        |   |-- 📜 permisos.sql
        |   +-- 📄 permisos.md (Explicación conceptual y procedimental)
        |
        +-- 📁 procedimientos_funciones/
        |   |-- 📜 sp_funciones.sql
        |   +-- 📄 sp_funciones.md (Explicación conceptual y procedimental)
        |
        +-- 📁 indices_optimizacion/
        |   |-- 📜 indices.sql
        |   +-- 📄 indices.md (Explicación conceptual y procedimental)
        |
        +-- 📁 tema_extra/
            |-- 📜 tema_extra.sql
            +-- 📄 tema_extra.md (Explicación del tema asignado por la cátedra)