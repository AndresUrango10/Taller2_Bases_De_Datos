
-- estos drop eliminan triggers y tablas si existen para seguir ejecutando varias veces sin errores
DROP TRIGGER IF EXISTS tr_docente_after_update;
DROP TRIGGER IF EXISTS tr_docente_after_delete;

DROP TABLE IF EXISTS copia_eliminados_docente;
DROP TABLE IF EXISTS copia_actualizados_docente;
DROP TABLE IF EXISTS proyecto;
DROP TABLE IF EXISTS docente;

-- Tablas DOCENTE Contiene los datos básicos de los docentes responsables de proyectos
CREATE TABLE docente (
  docente_id        INT AUTO_INCREMENT PRIMARY KEY,          -- Identificador único (clave primaria)
  numero_documento  VARCHAR(20)  NOT NULL,                   -- Número de identificación personal
  nombres           VARCHAR(120) NOT NULL,                   -- Nombre completo del docente
  titulo            VARCHAR(120),                            -- Título académico
  anios_experiencia INT          NOT NULL DEFAULT 0,         -- Años de experiencia (valor por defecto 0)
  direccion         VARCHAR(180),                            -- Dirección física 
  tipo_docente      VARCHAR(40),                             -- Tipo de contrato (planta, cátedra, etc.)
  CONSTRAINT uq_docente_documento UNIQUE (numero_documento), -- Garantiza que no haya documentos duplicados
  CONSTRAINT ck_docente_anios CHECK (anios_experiencia >= 0) -- Valida que los años de experiencia sean positivos
) ENGINE=InnoDB;

-- Contiene la información de los proyectos asociados a docentes
CREATE TABLE proyecto (
  proyecto_id      INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(120) NOT NULL,   -- Nombre del proyecto
  descripcion      VARCHAR(400),            -- Breve descripción
  fecha_inicial    DATE NOT NULL,           -- Fecha de inicio
  fecha_final      DATE,                    -- Fecha de finalización (puede ser NULL si sigue activo)
  presupuesto      DECIMAL(12,2) NOT NULL DEFAULT 0, -- Recursos asignados
  horas            INT NOT NULL DEFAULT 0,           -- Horas estimadas
  docente_id_jefe  INT NOT NULL,                     -- Relación con el docente responsable
  -- Restricciones para garantizar datos válidos
  CONSTRAINT ck_proyecto_horas CHECK (horas >= 0),
  CONSTRAINT ck_proyecto_pres CHECK (presupuesto >= 0),
  CONSTRAINT ck_proyecto_fechas CHECK (fecha_final IS NULL OR fecha_final >= fecha_inicial),
  -- Clave foránea con relación al docente jefe
  CONSTRAINT fk_proyecto_docente FOREIGN KEY (docente_id_jefe) REFERENCES docente(docente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Auditoría Registrar todos los cambios realizados en la tabla docente
CREATE TABLE copia_actualizados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,         -- Identificador único de registro de auditoría
  docente_id         INT NOT NULL,                           -- ID original del docente modificado
  numero_documento   VARCHAR(20)  NOT NULL,                  -- Documento de identidad (post-modificación)
  nombres            VARCHAR(120) NOT NULL,                  -- Nombres (post-modificación)
  titulo             VARCHAR(120),                           -- Título (post-modificación)
  anios_experiencia  INT          NOT NULL,                  -- Años de experiencia (post-modificación)
  direccion          VARCHAR(180),                           -- Dirección (post-modificación)
  tipo_docente       VARCHAR(40),                            -- Tipo de docente (post-modificación)
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()), -- Marca temporal UTC del cambio
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())   -- Usuario que realizó el cambio
) ENGINE=InnoDB;

-- Registrar backups de docentes eliminados
CREATE TABLE copia_eliminados_docente (
  auditoria_id       INT AUTO_INCREMENT PRIMARY KEY,         -- ID único del registro de auditoría
  docente_id         INT NOT NULL,                           -- ID del docente eliminado (referencia original)
  numero_documento   VARCHAR(20)  NOT NULL,                  -- Documento del docente eliminado
  nombres            VARCHAR(120) NOT NULL,                  -- Nombres del docente eliminado
  titulo             VARCHAR(120),                           -- Título del docente eliminado
  anios_experiencia  INT          NOT NULL,                  -- Años de experiencia del docente eliminado
  direccion          VARCHAR(180),                           -- Dirección del docente eliminado
  tipo_docente       VARCHAR(40),                            -- Tipo de docente del eliminado
  accion_fecha       DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()), -- Marca temporal UTC de la eliminación
  usuario_sql        VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())   -- Usuario SQL que realizó la eliminación
) ENGINE=InnoDB;

-- Procedimientos DOCENTE elimina procedimientos si existen para evitar errores
DROP PROCEDURE IF EXISTS sp_docente_crear;
DROP PROCEDURE IF EXISTS sp_docente_leer;
DROP PROCEDURE IF EXISTS sp_docente_actualizar;
DROP PROCEDURE IF EXISTS sp_docente_eliminar;

DELIMITER $$ -- Cambia el delimitador para definir procedimientos almacenados
CREATE PROCEDURE sp_docente_crear(
  IN p_numero_documento VARCHAR(20), -- Número de documento
  IN p_nombres          VARCHAR(120), -- Nombres completos
  IN p_titulo           VARCHAR(120), -- Título académico
  IN p_anios_experiencia INT,-- Años de experiencia
  IN p_direccion        VARCHAR(180), -- Dirección física
  IN p_tipo_docente     VARCHAR(40) -- Tipo de docente (planta, cátedra, etc.
)
BEGIN
  INSERT INTO docente (numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES (p_numero_documento, p_nombres, p_titulo, IFNULL(p_anios_experiencia,0), p_direccion, p_tipo_docente);
  SELECT LAST_INSERT_ID() AS docente_id_creado; -- Retorna el ID del docente creado
END$$

-- Leer datos de un docente por su ID
CREATE PROCEDURE sp_docente_leer(IN p_docente_id INT)
BEGIN
  SELECT * FROM docente WHERE docente_id = p_docente_id; 
END$$

-- Actualizar datos de un docente existente
CREATE PROCEDURE sp_docente_actualizar(
  IN p_docente_id       INT, -- ID del docente a actualizar
  IN p_numero_documento VARCHAR(20), -- Nuevo número de documento
  IN p_nombres          VARCHAR(120), -- Nuevos nombres completos
  IN p_titulo           VARCHAR(120),-- Nuevo título académico
  IN p_anios_experiencia INT,-- Nuevos años de experiencia
  IN p_direccion        VARCHAR(180), -- Nueva dirección física
  IN p_tipo_docente     VARCHAR(40)-- Nuevo tipo de docente (planta, cátedra, etc.
)
-- Actualiza los datos del docente y retorna el registro actualizado
BEGIN
  UPDATE docente -- Actualiza el registro del docente
     SET numero_documento = p_numero_documento, 
         nombres = p_nombres, -- Cambia los nombres
         titulo = p_titulo, -- Cambia el título
         anios_experiencia = IFNULL(p_anios_experiencia,0), -- Cambia los años de experiencia
         direccion = p_direccion, -- Cambia la dirección
         tipo_docente = p_tipo_docente -- Cambia el tipo de docente
   WHERE docente_id = p_docente_id; -- Filtra por el ID del docente
  SELECT * FROM docente WHERE docente_id = p_docente_id; -- Retorna el registro actualizado
END$$

-- Eliminar un docente por su ID
CREATE PROCEDURE sp_docente_eliminar(IN p_docente_id INT)
BEGIN
  DELETE FROM docente WHERE docente_id = p_docente_id;
END$$

-- Procedimientos PROYECTO elimina procedimientos si existen para evitar errores
DROP PROCEDURE IF EXISTS sp_proyecto_crear;
DROP PROCEDURE IF EXISTS sp_proyecto_leer;
DROP PROCEDURE IF EXISTS sp_proyecto_actualizar;
DROP PROCEDURE IF EXISTS sp_proyecto_eliminar;
-- Procedimientos almacenados para crear proyectos
CREATE PROCEDURE sp_proyecto_crear(
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicial    DATE,
  IN p_fecha_final      DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_docente_id_jefe  INT
)
BEGIN
  INSERT INTO proyecto (nombre, descripcion, fecha_inicial, fecha_final, presupuesto, horas, docente_id_jefe)
  VALUES (p_nombre, p_descripcion, p_fecha_inicial, p_fecha_final, IFNULL(p_presupuesto,0), IFNULL(p_horas,0), p_docente_id_jefe);
  SELECT LAST_INSERT_ID() AS proyecto_id_creado; -- Retorna el ID del proyecto creado
END$$
-- Leer datos de un proyecto por su ID, incluyendo el nombre del docente jefe

CREATE PROCEDURE sp_proyecto_leer(
  IN p_proyecto_id INT -- Parámetro: ID del proyecto a consultar
)
BEGIN
  SELECT p.*, d.nombres AS nombre_docente_jefe -- Selecciona datos del proyecto y nombre del docente jefe
  FROM proyecto p
  JOIN docente d ON d.docente_id = p.docente_id_jefe -- Relaciona con tabla docente para obtener nombre
  WHERE p.proyecto_id = p_proyecto_id; -- Filtra por el proyecto solicitado
END$$

CREATE PROCEDURE sp_proyecto_actualizar(
  IN p_proyecto_id      INT,           -- ID del proyecto a actualizar
  IN p_nombre           VARCHAR(120),  -- nuevo nombre del proyecto
  IN p_descripcion      VARCHAR(400),  -- nueva descripción
  IN p_fecha_inicial    DATE,          -- nueva fecha inicial
  IN p_fecha_final      DATE,          -- nueva fecha final
  IN p_presupuesto      DECIMAL(12,2), -- nuevo presupuesto
  IN p_horas            INT,           -- nuevas horas estimadas
  IN p_docente_id_jefe  INT            -- nuevo docente jefe responsable
)

BEGIN
  UPDATE proyecto
     SET nombre = p_nombre,                     -- Actualiza nombre
         descripcion = p_descripcion,           -- Actualiza descripción
         fecha_inicial = p_fecha_inicial,       -- Actualiza fecha inicial
         fecha_final = p_fecha_final,           -- Actualiza fecha final
         presupuesto = IFNULL(p_presupuesto,0),-- Actualiza presupuesto (0 si NULL)
         horas = IFNULL(p_horas,0),             -- Actualiza horas (0 si NULL)
         docente_id_jefe = p_docente_id_jefe   -- Actualiza docente jefe
   WHERE proyecto_id = p_proyecto_id;           -- Condición: solo el proyecto indicado
  CALL sp_proyecto_leer(p_proyecto_id);         -- Devuelve el proyecto actualizado (llama al SP de lectura)
END$$

-- Eliminar un proyecto por su ID
CREATE PROCEDURE sp_proyecto_eliminar(IN p_proyecto_id INT)
BEGIN
  DELETE FROM proyecto WHERE proyecto_id = p_proyecto_id;
END$$

-- funcion Calcular el promedio de presupuesto de proyectos por docente
DROP FUNCTION IF EXISTS fn_promedio_presupuesto_por_docente; -- Elimina la función si existe
CREATE FUNCTION fn_promedio_presupuesto_por_docente(p_docente_id INT) -- Función que calcula promedio de presupuesto
RETURNS DECIMAL(12,2)                                              -- Tipo de retorno: decimal con 2 decimales
DETERMINISTIC                                                      -- Determinística (mismo resultado con mismos datos)
READS SQL DATA                                                      -- Lee datos de la base
BEGIN
  DECLARE v_prom DECIMAL(12,2);                                     -- Variable local para el promedio
  SELECT IFNULL(AVG(presupuesto),0) INTO v_prom                    -- Calcula promedio de presupuesto por docente
  FROM proyecto
  WHERE docente_id_jefe = p_docente_id;                            -- Filtra proyectos por docente jefe
  RETURN IFNULL(v_prom,0);                                         -- Devuelve promedio (0 si NULL)
END$$


-- Triggers
CREATE TRIGGER tr_docente_after_update
AFTER UPDATE ON docente                                             -- Trigger ejecutado después de UPDATE en docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_actualizados_docente                              -- Inserta copia en tabla de actualizados
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (NEW.docente_id, NEW.numero_documento, NEW.nombres, NEW.titulo, NEW.anios_experiencia, NEW.direccion, NEW.tipo_docente); -- Usa valores nuevos
END$$

CREATE TRIGGER tr_docente_after_delete
AFTER DELETE ON docente                                             -- Trigger ejecutado después de DELETE en docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_eliminados_docente                                -- Inserta copia en tabla de eliminados
    (docente_id, numero_documento, nombres, titulo, anios_experiencia, direccion, tipo_docente)
  VALUES
    (OLD.docente_id, OLD.numero_documento, OLD.nombres, OLD.titulo, OLD.anios_experiencia, OLD.direccion, OLD.tipo_docente); -- Usa valores antiguos
END$$

DELIMITER ;     

-- Índices para mejorar rendimiento en búsquedas
CREATE INDEX ix_proyecto_docente ON proyecto(docente_id_jefe);
CREATE INDEX ix_docente_documento ON docente(numero_documento);
