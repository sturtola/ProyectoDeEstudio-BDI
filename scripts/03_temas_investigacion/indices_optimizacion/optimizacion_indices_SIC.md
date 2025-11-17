# 1. Introducción a la Optimización por Índices

En los sistemas de gestión de bases de datos, la eficiencia de las consultas (**SELECT**) es un factor decisivo para el rendimiento general. A medida que las tablas crecen a miles o millones de registros, la búsqueda secuencial se vuelve extremadamente costosa: es el equivalente a buscar una palabra en un libro de 1.000 páginas **sin un índice**.

Los **índices** permiten acelerar consultas haciendo que el motor pueda ubicar filas sin recorrer la tabla completa. Son el equivalente a los índices de un libro: un atajo directo.

---

# 2. ¿Qué es un Table Scan?

Un **Table Scan** (o Full Table Scan) ocurre cuando el motor **lee fila por fila toda la tabla**, buscando los registros que cumplen la condición.

Ejemplo:

```sql
SELECT *
FROM Lista_Espera
WHERE dni = '40111222';
```

Si `dni` **no tiene índice**, el motor debe examinar los 20.000 registros.

Esto es extremadamente costoso en tablas grandes, consumiendo CPU, memoria y tiempo innecesario.

---

# 3. ¿Qué problema ocurre en el SIC-UNNE?

En el sistema `SIC-UNNE`, tablas como:

- `Lista_Espera`
- `Inscripciones`
- `Estudiantes`
- `Comisiones`

podrían crecer rápidamente durante periodos de inscripción.

Consultas críticas como:

```sql
SELECT *
FROM Lista_Espera
WHERE legajo = 12345;
```

o

```sql
SELECT *
FROM Lista_Espera
WHERE estado = 'En espera';
```

pueden provocar:

- lentitud excesiva  
- bloqueos  
- timeouts  
- saturación del servidor

Todo debido al **Table Scan** cuando no existen índices adecuados.

---

# 4. Escenario sin Índices: La Pesadilla

Supongamos que la tabla `Lista_Espera` tiene **20.000 estudiantes** en estado `"En espera"` (muy probable en época de inscripción).

Cuando un estudiante nuevo se anota, el sistema ejecuta:

```sql
SELECT COUNT(*)
FROM Lista_Espera
WHERE estado = 'En espera'
  AND comision_id = 15;
```

Sin índices, el motor debe:

1. Leer las **20.000 filas**  
2. Comparar una por una  
3. Filtrar  
4. Recién después devolver el resultado

Esto es un **Full Table Scan**, donde el motor hace:

```
20.000 comparaciones por consulta
x 1.000 estudiantes inscribiéndose
= 20 MILLONES de comparaciones en horas pico
```

Resultado:

- La API se vuelve lenta  
- La app del usuario queda "cargando..."  
- La base de datos se congestiona  
- Riesgo de caídas por saturación  

---

# 5. Escenario con Índice: La Solución Óptima

Creamos un índice por las columnas más consultadas:

```sql
CREATE INDEX idx_lista_espera_estado_comision
ON Lista_Espera (estado, comision_id);
```

¿Qué cambia?

- El motor **no recorre la tabla**
- Usa el índice como un **mapa ordenado**
- Encuentra los registros en **milisegundos**
- Baja el costo de O(n) → a O(log n)

La misma consulta ahora accede solo a las filas relevantes:

```sql
SELECT COUNT(*)
FROM Lista_Espera
WHERE estado = 'En espera'
  AND comision_id = 15;
```

De 20.000 filas → pasa a leer solo ~300 (si esa comisión tiene 300 en espera).

---

# 6. ¿Qué columnas conviene indexar en el SIC-UNNE?

### Candidatos principales:

### 1. `dni` o `legajo`  
Usado para buscar un estudiante.

```sql
CREATE INDEX idx_estudiantes_dni
ON Estudiantes (dni);
```

### 2. `estado` + `comision_id`  
Para filtrar en la lista de espera.

```sql
CREATE INDEX idx_lista_espera_estado_comision
ON Lista_Espera (estado, comision_id);
```

### 3. `estudiante_id`  
Frecuentemente usado en joins.

```sql
CREATE INDEX idx_lista_espera_estudiante
ON Lista_Espera (estudiante_id);
```

### 4. `materia_id` + `turno` en Comisiones  
Para búsquedas de cupos.

```sql
CREATE INDEX idx_comisiones_materia_turno
ON Comisiones (materia_id, turno);
```

---

# 7. Ventajas Tangibles

## Velocidad ×10  
Consultas que tardaban 200–600 ms → bajan a 5–15 ms.

## Menos carga del servidor  
Se reduce drásticamente el uso de:

- CPU  
- I/O  
- memoria  

## El sistema soporta más tráfico  
Ideal para periodos pico (inscripción, cambios masivos).

## Más estabilidad  
Menos riesgo de caídas por saturación.

---

# 8. Posibles Desventajas de Usar Índices (y cómo evitarlas)

Los índices no son gratis. Tienen costos en:

- espacio en disco  
- tiempo extra al insertar o actualizar filas  
- mala elección de índices → fragmentación

### Reglas para no equivocarse:

- Indexar columnas **altamente consultadas**  
- Evitar indexar columnas con **pocos valores** (ej.: booleanos)  
- Evitar índices innecesarios  
- Mantener los índices ordenados (`REINDEX`, `VACUUM`)  

---

# 9. Conclusión

Sin índices, el sistema `SIC-UNNE` escala muy mal y sufre **Table Scans** constantes.  
Con índices bien diseñados, el rendimiento mejora exponencialmente, la plataforma se vuelve estable y responde rápido incluso con miles de usuarios simultáneos.

La optimización por índices **no es opcional** en aplicaciones de este tipo:  
es un requisito fundamental para garantizar **escalabilidad, velocidad y confiabilidad**.
