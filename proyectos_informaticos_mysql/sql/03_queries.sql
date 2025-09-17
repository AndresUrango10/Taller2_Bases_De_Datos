-- Este script contiene consultas para gestionar y probar la base de datos "proyectos_informaticos". 


-- Q0: Crear y usar la base de datos
CREATE DATABASE IF NOT EXISTS proyectos_informaticos;   -- Crea la base de datos solo si no existe
USE proyectos_informaticos;                             -- Selecciona la base de datos para trabajar

-- Q1: Proyectos y su docente jefe
SELECT p.proyecto_id,                                  -- Selecciona el ID del proyecto
       p.nombre AS proyecto,                           -- Selecciona el nombre del proyecto (con alias 'proyecto')
       d.nombres AS docente_jefe                       -- Selecciona el nombre del docente jefe del proyecto
FROM proyecto p                                        -- Desde la tabla proyecto (alias p)
JOIN docente d ON d.docente_id = p.docente_id_jefe;    -- Relaciona con la tabla docente para traer el jefe

-- Q2: Promedio de presupuesto por docente (UDF)
SELECT d.docente_id,                                   -- Selecciona el ID del docente
       d.nombres,                                      -- Selecciona el nombre del docente
       fn_promedio_presupuesto_por_docente(d.docente_id) AS promedio_presupuesto  -- Usa la función definida por el usuario para calcular el promedio de presupuesto de los proyectos de cada docente
FROM docente d;                                        -- Desde la tabla docente

-- Q3: Verificar trigger UPDATE (auditoría)
SELECT *                                               -- Trae todas las columnas
FROM copia_actualizados_docente                        -- De la tabla donde se guardan los cambios hechos a docentes (por trigger UPDATE)
ORDER BY auditoria_id DESC                             -- Ordena los registros de más reciente a más antiguo
LIMIT 10;                                              -- Muestra solo los últimos 10 registros

-- Q4: Verificar trigger DELETE (auditoría)
SELECT *                                               -- Trae todas las columnas
FROM copia_eliminados_docente                          -- De la tabla donde se guardan los docentes eliminados (por trigger DELETE)
ORDER BY auditoria_id DESC                             -- Ordena los registros de más reciente a más antiguo
LIMIT 10;                                              -- Muestra solo los últimos 10 registros

-- Q5: Validar CHECKs
SELECT proyecto_id,                                    -- ID del proyecto
       nombre,                                         -- Nombre del proyecto
       fecha_inicial,                                  -- Fecha en la que inicia el proyecto
       fecha_final,                                    -- Fecha en la que termina (puede ser NULL)
       presupuesto,                                    -- Presupuesto asignado
       horas                                           -- Horas estimadas
FROM proyecto                                          -- Desde la tabla proyecto
WHERE (fecha_final IS NULL OR fecha_final >= fecha_inicial)  -- Verifica que la fecha final sea nula o mayor/igual a la inicial
  AND presupuesto >= 0                                -- Verifica que el presupuesto no sea negativo
  AND horas >= 0;                                     -- Verifica que las horas no sean negativas

-- Q6: Docentes con sus proyectos
SELECT d.docente_id,                                   -- ID del docente
       d.nombres,                                      -- Nombre del docente
       p.proyecto_id,                                  -- ID del proyecto (si tiene)
       p.nombre                                        -- Nombre del proyecto (si tiene)
FROM docente d                                         -- Desde la tabla docente
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe  -- Une con la tabla proyecto (LEFT JOIN asegura que muestre al docente aunque no tenga proyectos)
ORDER BY d.docente_id;                                 -- Ordena por el ID del docente

-- Q7: Total de horas por docente
SELECT d.docente_id,                                   -- ID del docente
       d.nombres,                                      -- Nombre del docente
       SUM(p.horas) AS total_horas                     -- Suma de las horas de todos sus proyectos (alias total_horas)
FROM docente d                                         -- Desde la tabla docente
LEFT JOIN proyecto p ON d.docente_id = p.docente_id_jefe  -- Une con la tabla proyecto
GROUP BY d.docente_id, d.nombres;                      -- Agrupa por docente para calcular la suma

-- Q8: Inserciones vía procedimientos
CALL sp_docente_crear('CC1001', 'Ana Gómez', 'MSc. Ing. Sistemas', 6, 'Cra 10 # 5-55', 'Tiempo completo');  -- Inserta un docente usando el procedimiento almacenado
CALL sp_docente_crear('CC1002', 'Carlos Ruiz', 'Ing. Informático', 3, 'Cll 20 # 4-10', 'Cátedra');          -- Inserta otro docente

SET @id_ana    := (SELECT docente_id FROM docente WHERE numero_documento='CC1001');   -- Obtiene el ID del docente "Ana Gómez" y lo guarda en la variable @id_ana
SET @id_carlos := (SELECT docente_id FROM docente WHERE numero_documento='CC1002');   -- Obtiene el ID del docente "Carlos Ruiz" y lo guarda en @id_carlos

CALL sp_proyecto_crear('Plataforma Académica', 'Módulos de matrícula', '2025-01-01', NULL, 25000000, 800, @id_ana);   -- Crea un proyecto a nombre de Ana
CALL sp_proyecto_crear('Chat Soporte TI', 'Chat universitario', '2025-02-01', '2025-06-30', 12000000, 450, @id_carlos); -- Crea un proyecto a nombre de Carlos

-- Q9: Inserciones directas (opcional)
INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)   -- Inserta un docente directamente en la tabla
VALUES ('CC2001','María López','Esp. Gestión de Proyectos',7,'Av. Siempre Viva 742','Cátedra');

INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)  -- Inserta un proyecto directamente en la tabla
VALUES ('App Biblioteca','App móvil de préstamos','2025-03-01',NULL, 9000000, 320,
        (SELECT docente_id FROM docente WHERE numero_documento='CC2001'));   -- Usa un subquery para asignar como jefe a "María López"
