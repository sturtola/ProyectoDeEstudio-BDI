Procedimientos y Funciones Almacenadas


Procedimientos Almacenados

Un procedimiento almacenado (Stored Procedure) es un conjunto de instrucciones SQL predefinidas y almacenadas en la base de datos, que puede ejecutarse cuando se necesite. Actúa como una especie de programa interno de la base de datos que permite agrupar consultas, operaciones de manipulación de datos, validaciones, cálculos o incluso lógica de negocio.
Es decir, un procedimiento almacenado es un objeto del servidor que contiene código SQL compilado y guardado para ser reutilizado.
En SQL Server, un procedimiento almacenado puede incluir:
Sentencias SELECT, INSERT, UPDATE, DELETE
Declaración y uso de variables
Uso de transacciones
Validaciones lógicas mediante IF, WHILE, CASE, etc.
Ejecución de otros procedimientos almacenados
Parámetros de entrada, de salida y valores retornados
Su principal propósito es simplificar tareas frecuentes, automatizar procesos y centralizar la lógica de negocio dentro de la base de datos.
Características 
Reutilizables: El código se escribe una sola vez y puede ejecutarse múltiples veces.
Compilados previamente: SQL Server compila el procedimiento la primera vez que se ejecuta y almacena el plan de ejecución, lo que mejora considerablemente el rendimiento.
Admiten parámetros: Pueden recibir datos externos en forma de parámetros, lo que los hace dinámicos. Ejemplo: @id, @nombre, @PageSize, etc.
Permiten manejar lógica compleja: Incluyen estructuras de control como ciclos, condiciones, bloque TRY/CATCH, etc.
Pueden devolver valores y conjuntos de datos: Pueden retornar tanto un valor escalar como conjuntos completos de resultados (como un SELECT).
Seguridad y control de permisos: Permiten restringir el acceso a tablas y vistas mediante permisos específicos otorgados al procedimiento.
Ejecutan transacciones: Permiten garantizar la integridad de los datos aplicando COMMIT o ROLLBACK.

Ventajas
Desventajas
Mejoran el rendimiento
Dependencia del motor de base de datos
Centralizan la lógica
Sobrecarga en el servidor
Incrementan la seguridad
Dificultad en el versionado
Reducen el tráfico entre la aplicación y la base
Mayor complejidad


Facilitan el mantenimiento







Un procedimiento almacenado suele tener la siguiente estructura:

CREATE PROCEDURE nombre_del_procedimiento
    @Parametro1 INT,
    @Parametro2 VARCHAR(50)
AS
BEGIN
    SELECT * FROM Tabla WHERE Campo = @Parametro1;
END
GO

Los procedimientos se aplican generalmente para:
Paginación de datos
Insertar o actualizar registros
Procesos automáticos
Validaciones antes de modificar datos
Cálculo de totales, estadísticas e informes
Lógica de negocio centralizada

Dentro del proyecto SIC-UNNE, la utilización de procedimientos almacenados adquiere un rol central debido a la necesidad de gestionar correctamente entidades como Usuarios, Profesores, Carreras, Comisiones, entre otras. La gestión eficiente de estas tablas, particularmente en operaciones de inserción, actualización, eliminación y listados, constituye una parte esencial del funcionamiento del sistema, que apunta a administrar intercambios de comisiones, perfiles de usuarios, asignación de profesores y más.
Para ejemplificar la aplicación práctica de los conceptos previamente expuestos, a continuación se detallan tres procedimientos almacenados correspondientes a una de las tablas del proyecto, junto con la inserción de datos mediante sentencias directas y mediante la invocación de dichos procedimientos. Finalmente, se incluyen ejemplos de operaciones UPDATE y DELETE utilizando dichos procedimientos de forma controlada.
Insertar Usuario
Dentro del contexto del proyecto SIC-UNNE, la gestión de usuarios requiere un tratamiento diferencial según el tipo de persona que ingresa al sistema. Por este motivo, el proceso de inserción de usuarios no se resolvió mediante un único procedimiento genérico, sino a través de dos procedimientos almacenados independientes, cada uno ajustado a las reglas de negocio específicas de su categoría. Estos procedimientos son:
sp_insertar_estudiante


sp_insertar_personal
La separación no es arbitraria: responde a diferencias funcionales, lógicas y de integridad entre ambos tipos de usuarios. Esto se debe a que ambos tipos de usuarios poseen atributos obligatorios diferentes
Un estudiante al momento del registro requiere información adicional que no corresponde al personal administrativo, como ser: Carrera (id_carrera, la cual puede ser NULL para el personal), Estado (0/inactivo), Rol (‘Estudiante’), además la tabla Constancia está asociada al Usuario que se registra como estudiante. En cambio, un personal administrativo no tiene una carrera asociada, no requiere una constancia y su rol se asigna como ‘Indefinido’ hasta que un administrador verifique sus datos.
Juntar ambos tipos de inserciones en un solo SP habría obligado a manejar demasiadas validaciones condicionales, lo cual, complejiza el código, facilita errores lógicos, hace difícil el mantenimiento y genera ambigüedades al validar los campos.
Separar ambos procedimientos simplifica el diseño y asegura que cada uno valide solo lo que le corresponde.
Modificar/Actualizar Usuario
En el proyecto SIC-UNNE, cualquier tipo de usuario comparte los mismos atributos básicos (nombre, apellido, correo, documento, contraseña), por lo cual es correcta la creación de un solo procedimiento que acapare la idea de modificación/actualización de dicho usuario. Cabe aclarar que con respecto al Estudiante no es posible la modificación de la constancia, razón por la cual no es necesaria la división de procedimientos como en el ítem anterior.
El procedimiento de almacenado asegura que si no se realiza ningun cambio, los datos se mantienen. Dicho procedimiento lleva el nombre de
sp_actualizar_usuario

Eliminar/Inactivar Usuario
En el sistema SIC-UNNE no se permite borrar físicamente registros de la tabla Usuario. En lugar de eso, cada usuario posee un campo estado (tipo BIT), que funciona como:
1 → usuario activo
0 → usuario inactivo
Esto significa que, en vez de eliminar un registro, simplemente se lo deshabilita en el sistema.
Las razones principales que llevaron a esta decisión se basan en que el usuario está relacionado con múltiples entidades en el sistema, y si este se eliminara físicamente, rompería la integridad de los datos. Además, la eliminación de un registro es irreversible, contrario a lo que ejecuta el procedimiento:
sp_cambiar_estado
Este procedimiento también incluye la activación de los usuarios.
Carga de datos
La carga de datos en una base de datos puede realizarse de dos maneras principales: mediante sentencias SQL directas o mediante procedimientos almacenados (Stored Procedures).
Por un lado, las sentencias insert directas permiten poblar la base de datos rápidamente y sin lógica adicional, siendo ideales para cargas iniciales, pruebas tempranas o inserción masiva de registros sin reglas específicas. Este tipo de carga es útil para realizar pruebas funcionales y verificar la estructura de las tablas antes de aplicar validaciones más complejas.
Por otro lado, la carga de datos a través de procedimientos almacenados representa la manera recomendada y controlada de insertar información durante la operación normal del sistema. Los SP encapsulan reglas de negocio, validaciones (como evitar duplicados o garantizar integridad), y aseguran que todos los registros ingresen respetando las restricciones del proyecto SIC-UNNE. Además, permiten registrar bitácoras, realizar acciones adicionales en cascada y garantizar que la lógica de acceso a datos esté centralizada y mantenible.




