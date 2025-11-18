**[Procedimientos y Funciones Almacenadas]{.underline}**

1.  **Procedimientos Almacenados**

Un **procedimiento almacenado** (Stored Procedure) es un conjunto de
instrucciones SQL predefinidas y almacenadas en la base de datos, que
puede ejecutarse cuando se necesite. Actúa como una especie de programa
interno de la base de datos que permite agrupar consultas, operaciones
de manipulación de datos, validaciones, cálculos o incluso lógica de
negocio.

Es decir, un procedimiento almacenado es un objeto del servidor que
contiene código SQL compilado y guardado para ser reutilizado.

En SQL Server, un procedimiento almacenado puede incluir:

-   Sentencias **SELECT**, **INSERT**, **UPDATE**, **DELETE**

-   Declaración y uso de **variables**

-   Uso de **transacciones**

-   Validaciones lógicas mediante **IF**, **WHILE**, **CASE**, etc.

-   Ejecución de otros procedimientos almacenados

-   Parámetros de entrada, de salida y valores retornados

Su principal propósito es simplificar tareas frecuentes, automatizar
procesos y centralizar la lógica de negocio dentro de la base de datos.

**Características**

-   **Reutilizables:** El código se escribe una sola vez y puede
    > ejecutarse múltiples veces.

-   **Compilados previamente:** SQL Server compila el procedimiento la
    > primera vez que se ejecuta y almacena el plan de ejecución, lo que
    > mejora considerablemente el rendimiento.

-   **Admiten parámetros:** Pueden recibir datos externos en forma de
    > parámetros, lo que los hace dinámicos. Ejemplo: \@id, \@nombre,
    > \@PageSize, etc.

-   **Permiten manejar lógica compleja:** Incluyen estructuras de
    > control como ciclos, condiciones, bloque TRY/CATCH, etc.

-   **Pueden devolver valores y conjuntos de datos:** Pueden retornar
    > tanto un valor escalar como conjuntos completos de resultados
    > (como un SELECT).

-   **Seguridad y control de permisos:** Permiten restringir el acceso a
    > tablas y vistas mediante permisos específicos otorgados al
    > procedimiento.

-   **Ejecutan transacciones:** Permiten garantizar la integridad de los
    > datos aplicando COMMIT o ROLLBACK.

+-----------------------------------+-----------------------------------+
| **Ventajas**                      | **Desventajas**                   |
+===================================+===================================+
| #### Mejoran el rendimiento       | Dependencia del motor de base de  |
|                                   | datos                             |
+-----------------------------------+-----------------------------------+
| Centralizan la lógica             | Sobrecarga en el servidor         |
+-----------------------------------+-----------------------------------+
| Incrementan la seguridad          | Dificultad en el versionado       |
+-----------------------------------+-----------------------------------+
| Reducen el tráfico entre la       | Mayor complejidad                 |
| aplicación y la base              |                                   |
+-----------------------------------+-----------------------------------+
| Facilitan el mantenimiento        |                                   |
+-----------------------------------+-----------------------------------+

Un procedimiento almacenado suele tener la siguiente estructura:

CREATE PROCEDURE nombre_del_procedimiento

\@Parametro1 INT,

\@Parametro2 VARCHAR(50)

AS

BEGIN

SELECT \* FROM Tabla WHERE Campo = \@Parametro1;

END

GO

Los procedimientos se aplican generalmente para:

-   Paginación de datos

-   Insertar o actualizar registros

-   Procesos automáticos

-   Validaciones antes de modificar datos

-   Cálculo de totales, estadísticas e informes

-   Lógica de negocio centralizada

Dentro del proyecto **SIC-UNNE**, la utilización de procedimientos
almacenados adquiere un rol central debido a la necesidad de gestionar
correctamente entidades como **Usuarios**, **Profesores**, **Carreras**,
**Comisiones**, entre otras. La gestión eficiente de estas tablas,
particularmente en operaciones de inserción, actualización, eliminación
y listados, constituye una parte esencial del funcionamiento del
sistema, que apunta a administrar intercambios de comisiones, perfiles
de usuarios, asignación de profesores y más.

Para ejemplificar la aplicación práctica de los conceptos previamente
expuestos, a continuación se detallan **tres procedimientos
almacenados** correspondientes a una de las tablas del proyecto, junto
con la inserción de datos mediante **sentencias directas** y mediante la
**invocación de dichos procedimientos**. Finalmente, se incluyen
ejemplos de operaciones *UPDATE* y *DELETE* utilizando dichos
procedimientos de forma controlada.

a.  **Insertar Usuario**

Dentro del contexto del proyecto **SIC-UNNE**, la gestión de usuarios
requiere un tratamiento diferencial según el tipo de persona que ingresa
al sistema. Por este motivo, el proceso de inserción de usuarios no se
resolvió mediante un único procedimiento genérico, sino a través de
**dos procedimientos almacenados independientes**, cada uno ajustado a
las reglas de negocio específicas de su categoría. Estos procedimientos
son:

-   [**sp_insertar_estudiante**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L15)

-   [**sp_insertar_personal**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L100)

La separación no es arbitraria: responde a diferencias funcionales,
lógicas y de integridad entre ambos tipos de usuarios. Esto se debe a
que ambos tipos de usuarios poseen atributos obligatorios diferentes

Un **estudiante** al momento del registro requiere información adicional
que no corresponde al personal administrativo, como ser: Carrera
(id_carrera, la cual puede ser NULL para el personal), Estado
(0/inactivo), Rol ('Estudiante'), además la tabla Constancia está
asociada al Usuario que se registra como estudiante. En cambio, un
**personal administrativo** no tiene una carrera asociada, no requiere
una constancia y su rol se asigna como 'Indefinido' hasta que un
administrador verifique sus datos.

Juntar ambos tipos de inserciones en un solo SP habría obligado a
manejar demasiadas validaciones condicionales, lo cual, complejiza el
código, facilita errores lógicos, hace difícil el mantenimiento y genera
ambigüedades al validar los campos.

Separar ambos procedimientos simplifica el diseño y asegura que cada uno
valide solo lo que le corresponde.

b.  **Modificar/Actualizar Usuario**

En el proyecto SIC-UNNE, cualquier tipo de usuario comparte los mismos
atributos básicos (nombre, apellido, correo, documento, contraseña), por
lo cual es correcta la creación de un solo procedimiento que acapare la
idea de modificación/actualización de los datos del usuario. Cabe
aclarar que con respecto al Estudiante no es posible la modificación de
la constancia, razón por la cual no es necesaria la división de
procedimientos como en el ítem anterior.

El procedimiento de almacenado asegura que si no se realiza ningún
cambio, los datos se mantienen. Dicho procedimiento lleva el nombre de

-   [**sp_actualizar_usuario**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L172)


Otra modificación que se puede realizar es la del cambio de rol, y va
dirigida principalmente para el Administrador, que es el encargado de
verificar que sus usuarios delegados sean realmente 'Verificadores' por
lo cual tiene la responsabilidad de asignarles dicho rol. En este
procedimiento se verifica que el usuario registrado no tenga una carrera
relacionada ni una constancia:

-   [**sp_actualizar_rol**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L451)


Por ultimo tambien se creo un procedimiento que permite al Administrador
realizar conjuntamente un cambio de rol y una activación para aquel
usuario que se presenta como Verificador, llamada:

-   [**sp_activar_verificador**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L577)


c.  **Eliminar/Inactivar Usuario**

En el sistema SIC-UNNE no se permite borrar físicamente registros de la
tabla Usuario. En lugar de eso, cada usuario posee un campo estado (tipo
BIT), que funciona como:

-   1 → usuario activo

-   0 → usuario inactivo

Esto significa que, en vez de eliminar un registro, simplemente se lo
deshabilita en el sistema.

Las razones principales que llevaron a esta decisión se basan en que el
usuario está relacionado con múltiples entidades en el sistema, y si
este se eliminara físicamente, rompería la integridad de los datos. Es
importante saber que solo los Estudiantes pueden desactivarse a sí
mismos, los roles superiores solo están habilitados para activar o
desactivar roles inferiores (Por ejemplo: Administrador -\> Verificador,
Verificador -\> Estudiante). Además, la eliminación de un registro es
irreversible, contrario a lo que ejecuta el procedimiento:

-   [**sp_actualizar_estado**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L324)


d.  **Carga de datos**

La carga de datos en una base de datos puede realizarse de dos maneras
principales: [**mediante sentencias SQL directas**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L635) 
o [**mediante procedimientos almacenados (Stored Procedures)**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L663).

Por un lado, las **sentencias insert directas** permiten poblar la base
de datos rápidamente y sin lógica adicional, siendo ideales para cargas
iniciales, pruebas tempranas o inserción masiva de registros sin reglas
específicas. Este tipo de carga es útil para realizar pruebas
funcionales y verificar la estructura de las tablas antes de aplicar
validaciones más complejas.

Por otro lado, la carga de datos **a través de procedimientos almacenados** 
representa la manera recomendada y controlada de insertar información 
durante la operación normal del sistema. Los SP encapsulan reglas de 
negocio, validaciones (como evitar duplicados o garantizar integridad), 
y aseguran que todos los registros ingresen respetando las restricciones 
del proyecto SIC-UNNE. Además, permiten registrar bitácoras, realizar 
acciones adicionales en cascada y garantizar que la lógica de acceso 
a datos esté centralizada y mantenible.

e.  **Update y Delete mediante procedimientos**

En el marco del sistema SIC-UNNE, las sentencias UPDATE y DELETE cumplen
un rol fundamental para la gestión dinámica de los datos. Los siguientes
[**ejemplos**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L685) muestran cómo se aplican estas operaciones en situaciones
reales del sistema, tales como actualizar estados, activar usuarios,
modificar información de usuarios e inactivar un registro. Cada ejemplo
se acompaña de su respectiva explicación para mostrar claramente su
propósito dentro del funcionamiento del SIC-UNNE y cómo contribuye a
mantener la base de datos ordenada, coherente y actualizada.

> **2. Funciones Almacenadas**

Una **función almacenada** es un objeto de la base de datos que
encapsula una operación o cálculo y devuelve un valor (o una tabla). Se
define una vez en la base de datos y puede reutilizarse desde consultas
(SELECT), procedimientos, vistas, o desde la aplicación. A diferencia de
un procedimiento almacenado, una función está pensada para calcular y
devolver información y no para realizar efectos secundarios (es decir,
normalmente no modifica datos).

# **Características** 

-   **Devuelve un valor:** puede ser un valor escalar o una tabla.

-   **Reutilizable:** se define en la base de datos y se invoca desde
    > múltiples lugares, evitando duplicación de lógica.

-   **Puede ser determinística o no determinística:** una función
    > determinística siempre devuelve el mismo resultado con los mismos
    > parámetros; una no determinística depende de factores externos, lo
    > que afecta su uso en optimizaciones.

-   **Encapsula lógica compleja:** permite ocultar detalles de cálculo y
    > exponer una interfaz simple.

-   **Puede usarse dentro de consultas:** las funciones se pueden usar
    > dentro de SELECT, JOIN, WHERE, etc.

-   **Limitaciones de side-effects:** en sistemas como SQL Server las
    > funciones T-SQL **no pueden** realizar operaciones que modifiquen
    > datos de la base (INSERT, UPDATE, DELETE sobre tablas
    > persistentes) ni ejecutar procedimientos almacenados o SQL
    > dinámico.

-   **Tipos:** **Scalar UDF** (devuelve un solo valor escalar).
    > **Table-valued function (TVF)** ( devuelve una tabla; puede ser
    > INLINE o MULTI-STATEMENT).

  -----------------------------------------------------------------------
  **Ventajas**                        **Desventajas**
  ----------------------------------- -----------------------------------
  Reutilización y mantenimiento       No deben tener efectos secundarios

  Legibilidad y abstracción           Problemas de rendimiento si se usan
                                      mal

  Integridad lógica                   Restricciones sintácticas

  Posible optimización por el motor   Depuración y manejo de errores

  Seguridad                           Posible complejidad en permisos
  -----------------------------------------------------------------------

**Diferencias entre Procedimiento y Función**

  ------------------------------------------------------------------------
  **Aspecto**              **Función (UDF)**       **Procedimiento (SP)**
  ------------------------ ----------------------- -----------------------
  **Devuelve**             Valor escalar o tabla   Códigos, mensajes o
                                                   result sets múltiples

  **Uso en consultas**     Sí                      No

  **Efectos secundarios    No permiten DML en      Sí permiten DML,
  (DML)**                  tablas persistentes     transacciones, llamadas
                           (dependiendo del motor) a otros SP, SQL
                                                   dinámico

  **Parámetros de salida** Devuelven resultado por Soportan OUTPUT
                           RETURN o tabla; no      parameters y mecanismos
                           tienen OUTPUT           de retorno variados

  **Uso recomendado**      Cálculos reutilizables, Flujos transaccionales,
                           lógica sin efectos      lógica que modifica
                           secundarios,            datos, tareas
                           encapsulación de        administrativas
                           expresiones             

  **Optimización**         Inline TVF puede ser    Muy optimizables para
                           optimizada; scalar UDF  tareas transaccionales;
                           tradicionales pueden    control total de
                           penalizar               transacciones

  **Manejo de errores /    Limitado                Completo (TRY/CATCH,
  control transaccional**                          THROW, control de
                                                   transacciones)

  **Seguridad/Permisos**   Ejecutan con contexto   Similar, pero más
                           de invocador a menos    flexibilidad en
                           que se configure        esquemas de ejecución
  ------------------------------------------------------------------------

Una vez comprendidos los fundamentos teóricos de las funciones
almacenadas resulta fundamental observar cómo se aplican en un escenario
real. En esta sección se presentan ejemplos concretos desarrollados para
el proyecto **SIC-UNNE**, donde las funciones permiten encapsular
cálculos recurrentes, simplificar consultas y asegurar coherencia en las
reglas del sistema.

Los [**ejemplos**](https://github.com/sturtola/ProyectoDeEstudio-BDI/scripts/03_temas_investigacion/procedimientos_funciones/sp_funciones.sql#L717) seleccionados tienen como objetivo ilustrar distintos
tipos de funciones almacenadas, desde funciones escalares simples (como
el cálculo de edad) hasta funciones orientadas a validaciones o
consultas específicas del sistema. Además, se analiza la eficiencia
comparando el uso de funciones y procedimientos frente a operaciones
directas, evidenciando cómo el motor de base de datos optimiza cada
enfoque y en qué situaciones conviene utilizar uno u otro.

A través de estos casos prácticos se muestra no solo la implementación
técnica, sino también el impacto que tienen en la mantenibilidad,
reutilización y rendimiento del sistema. Esto permite comprender el rol
que cumplen las funciones dentro de la arquitectura del SIC-UNNE y
justificar su uso dentro del proyecto.

Para concluir con la investigación, se da a conocer una breve
comparación de eficiencia entre las operaciones directas, los
procedimientos almacenados y las funciones almacenadas:

  -----------------------------------------------------------------------
  **Criterio**      **Operación       **Procedimiento   **Función
                    Directa**         almacenado**      almacenada**
  ----------------- ----------------- ----------------- -----------------
  **Plan de         Se recompila      Se reutiliza (más Se reutiliza
  ejecución**       siempre           rápido)           

  **Rendimiento**   Medio--bajo       Alto              Alto para
                                                        cálculos

  **Seguridad**     Baja si no se     Muy alta          Alta
                    parametriza                         

  **Consistencia de Depende del       Garantizada       Garantizada
  reglas**          programador                         

  **Tráfico entre   Alto              Bajo              Bajo
  capas**                                               

  **Facilidad de    Baja              Alta              Alta
  mantenimiento**                                       

  **Lógica          Difícil           Ideal             Solo cálculos
  compleja**                                            
  -----------------------------------------------------------------------

En conclusión, las **operaciones directas** son útiles para prototipos,
pero **no son recomendables** en un sistema con reglas complejas como
SIC-UNNE. Los **procedimientos almacenados** brindan **mayor eficiencia,
seguridad y gobernanza**, especialmente para reglas estrictas de
usuarios, roles y estados. Y las **funciones almacenadas** mejoran
modularidad, rendimiento en cálculos y evitan duplicación de lógica.
