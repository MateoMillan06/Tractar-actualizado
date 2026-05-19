-- ============================================================
--  TRACTAR — Base de Datos PostgreSQL
--  Sistema de gestión de vehículos, conductores y viajes
-- ============================================================

-- Eliminar tablas si ya existen (útil para reimportar)
DROP TABLE IF EXISTS trips          CASCADE;
DROP TABLE IF EXISTS driver_vehicles CASCADE;
DROP TABLE IF EXISTS vehicles       CASCADE;
DROP TABLE IF EXISTS users          CASCADE;


-- ============================================================
--  TABLA: users
--  role   -> 'propietario' | 'conductor'
--  status -> 'Activo' | 'Inactivo' | 'Disponible'
-- ============================================================
CREATE TABLE users (
    id         SERIAL PRIMARY KEY,
    username   VARCHAR(100) UNIQUE NOT NULL,
    password   VARCHAR(255) NOT NULL,
    role       VARCHAR(20)  NOT NULL
                   CHECK (role IN ('propietario', 'conductor')),
    status     VARCHAR(20)  NOT NULL DEFAULT 'Activo'
                   CHECK (status IN ('Activo', 'Inactivo', 'Disponible')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
--  TABLA: vehicles
--  Cada vehículo pertenece a un propietario (user_id)
--  placa formato: ABC123
-- ============================================================
CREATE TABLE vehicles (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    placa      VARCHAR(10) UNIQUE NOT NULL,
    marca      VARCHAR(100) NOT NULL,
    modelo     VARCHAR(100) NOT NULL,
    color      VARCHAR(20)  NOT NULL
                   CHECK (color IN ('Rojo', 'Azul', 'Blanco', 'Negro')),
    apodo      VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
--  TABLA: driver_vehicles  (afiliaciones)
--  Relación muchos-a-muchos: conductor <-> vehículo
-- ============================================================
CREATE TABLE driver_vehicles (
    id         SERIAL PRIMARY KEY,
    driver_id  INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (driver_id, vehicle_id)
);


-- ============================================================
--  TABLA: trips
--  status -> 'Pendiente' | 'Asignado' | 'En ruta' | 'Finalizado' | 'Cancelado'
--  flete  -> valor en pesos colombianos
-- ============================================================
CREATE TABLE trips (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    vehicle_id INTEGER     REFERENCES vehicles(id)      ON DELETE SET NULL,
    driver_id  INTEGER     REFERENCES users(id)         ON DELETE SET NULL,
    origen     VARCHAR(200) NOT NULL,
    destino    VARCHAR(200) NOT NULL,
    flete      NUMERIC(14, 2) DEFAULT 0,
    status     VARCHAR(20)  NOT NULL DEFAULT 'Pendiente'
                   CHECK (status IN ('Pendiente','Asignado','En ruta','Finalizado','Cancelado')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
--  ÍNDICES para consultas frecuentes
-- ============================================================
CREATE INDEX idx_vehicles_user        ON vehicles(user_id);
CREATE INDEX idx_driver_vehicles_drv  ON driver_vehicles(driver_id);
CREATE INDEX idx_driver_vehicles_veh  ON driver_vehicles(vehicle_id);
CREATE INDEX idx_trips_user           ON trips(user_id);
CREATE INDEX idx_trips_driver         ON trips(driver_id);
CREATE INDEX idx_trips_vehicle        ON trips(vehicle_id);
CREATE INDEX idx_trips_status         ON trips(status);
CREATE INDEX idx_trips_created        ON trips(created_at);


-- ============================================================
--  VISTAS útiles para el backend
-- ============================================================

-- Facturación total por vehículo (para /billing)
CREATE OR REPLACE VIEW v_billing_by_vehicle AS
SELECT
    v.id         AS vehicle_id,
    v.placa      AS vehiculo,
    v.user_id    AS owner_id,
    COUNT(t.id)  AS trips,
    COALESCE(SUM(t.flete), 0) AS total
FROM vehicles v
LEFT JOIN trips t ON t.vehicle_id = v.id AND t.status = 'Finalizado'
GROUP BY v.id, v.placa, v.user_id;

-- Facturación total por conductor (para /billing)
CREATE OR REPLACE VIEW v_billing_by_driver AS
SELECT
    u.id         AS driver_id,
    u.username,
    t.user_id    AS owner_id,
    COUNT(t.id)  AS trips,
    COALESCE(SUM(t.flete), 0) AS total
FROM users u
JOIN trips t ON t.driver_id = u.id AND t.status = 'Finalizado'
WHERE u.role = 'conductor'
GROUP BY u.id, u.username, t.user_id;

-- KPIs por conductor (para /driver/kpis/:id)
CREATE OR REPLACE VIEW v_driver_kpis AS
SELECT
    driver_id,
    COUNT(*)                                          AS total,
    COUNT(*) FILTER (WHERE status = 'Finalizado')     AS completed,
    COUNT(*) FILTER (WHERE status = 'Cancelado')      AS cancelled
FROM trips
GROUP BY driver_id;

-- Detalle de viajes con info de vehículo y conductor (para /reports)
CREATE OR REPLACE VIEW v_trips_detail AS
SELECT
    t.id,
    t.user_id,
    t.origen,
    t.destino,
    t.flete,
    t.status       AS trip_status,
    t.created_at,
    v.placa,
    v.marca,
    v.apodo,
    u.username     AS driver_username,
    t.driver_id,
    t.vehicle_id
FROM trips t
LEFT JOIN vehicles v ON v.id = t.vehicle_id
LEFT JOIN users    u ON u.id = t.driver_id;


-- ============================================================
--  DATOS DE PRUEBA
--  NOTA: en producción la contraseña debe ser un hash bcrypt.
--  Aquí se usa texto plano solo para desarrollo local.
-- ============================================================

-- Propietarios
INSERT INTO users (username, password, role, status) VALUES
  ('admin',   '1234', 'propietario', 'Activo'),
  ('carlos',  '1234', 'propietario', 'Activo');

-- Conductores
INSERT INTO users (username, password, role, status) VALUES
  ('pedro',   '1234', 'conductor', 'Disponible'),
  ('luis',    '1234', 'conductor', 'Activo'),
  ('maria',   '1234', 'conductor', 'Inactivo');

-- Vehículos de 'admin' (id = 1)
INSERT INTO vehicles (user_id, placa, marca, modelo, color, apodo) VALUES
  (1, 'ABC123', 'Chevrolet', 'NHR',    'Blanco', 'El Blanco'),
  (1, 'DEF456', 'Ford',      'F-350',  'Negro',  'La Bestia'),
  (1, 'GHI789', 'Toyota',    'Hilux',  'Azul',   NULL);

-- Vehículos de 'carlos' (id = 2)
INSERT INTO vehicles (user_id, placa, marca, modelo, color, apodo) VALUES
  (2, 'JKL012', 'Mazda', 'BT-50', 'Rojo', 'El Rojo');

-- Afiliaciones conductor <-> vehículo
INSERT INTO driver_vehicles (driver_id, vehicle_id) VALUES
  (3, 1),   -- pedro  <-> ABC123
  (3, 2),   -- pedro  <-> DEF456
  (4, 3),   -- luis   <-> GHI789
  (5, 4);   -- maria  <-> JKL012

-- Viajes de prueba
INSERT INTO trips (user_id, vehicle_id, driver_id, origen, destino, flete, status, created_at) VALUES
  (1, 1, 3, 'Cartagena',   'Barranquilla', 850000,  'Finalizado', NOW() - INTERVAL '10 days'),
  (1, 1, 3, 'Barranquilla','Medellín',    1200000,  'Finalizado', NOW() - INTERVAL '8 days'),
  (1, 2, 4, 'Cartagena',   'Bogotá',      2500000,  'En ruta',    NOW() - INTERVAL '1 day'),
  (1, 3, NULL,'Cartagena', 'Santa Marta',  600000,  'Pendiente',  NOW()),
  (2, 4, 5, 'Bogotá',      'Cali',        1800000,  'Cancelado',  NOW() - INTERVAL '5 days'),
  (1, 2, 4, 'Medellín',    'Cali',         950000,  'Finalizado', NOW() - INTERVAL '15 days');
