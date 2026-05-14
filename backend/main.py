from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from io import BytesIO
from openpyxl import Workbook
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATABASE_URL = os.getenv("DATABASE_URL")

# Verificar que exista
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL no está configurada")

# IMPORTANTE PARA RAILWAY
if DATABASE_URL.startswith("mysql://"):
    DATABASE_URL = DATABASE_URL.replace(
        "mysql://",
        "mysql+pymysql://",
        1
    )

engine = create_engine(DATABASE_URL)
# =========================
# MODELOS
# =========================
class LoginRequest(BaseModel):
    username: str
    password: str


class RegisterRequest(BaseModel):
    username: str
    password: str


class VehicleRequest(BaseModel):
    user_id: int
    placa: str
    marca: str
    modelo: str
    color: str
    apodo: str | None = None


class TripRequest(BaseModel):
    user_id: int
    driver_id: int | None = None
    origen: str
    destino: str
    vehiculo: str
    flete: str | None = None


class AssignDriverRequest(BaseModel):
    driver_id: int
    vehicle_id: int


class AssignTripRequest(BaseModel):
    trip_id: int
    driver_id: int
    vehicle_id: int


# =========================
# AUTH
# =========================
@app.post("/register")
def register(data: RegisterRequest):
    with engine.begin() as conn:
        existing = conn.execute(
            text("SELECT id FROM users WHERE username = :username"),
            {"username": data.username}
        ).fetchone()

        if existing:
            return {"success": False, "message": "El usuario ya existe"}

        conn.execute(
            text("""
                INSERT INTO users (username, password, role, status)
                VALUES (:username, :password, 'propietario', 'Disponible')
            """),
            {
                "username": data.username,
                "password": data.password
            }
        )

    return {"success": True}


@app.post("/login")
def login(data: LoginRequest):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT id, username, role, status
                FROM users
                WHERE username = :username
                AND password = :password
            """),
            data.dict()
        ).fetchone()

        if result:
            user = dict(result._mapping)
            return {
                "success": True,
                "user_id": user["id"],
                "username": user["username"],
                "role": user["role"],
                "status": user["status"]
            }

    return {"success": False}


# =========================
# CONDUCTORES
# =========================

# Punto 1: endpoint para que el conductor actualice su estado laboral
@app.put("/driver/status/{driver_id}")
def update_driver_status(driver_id: int, status: str):
    allowed = ["Disponible", "En viaje", "Inactivo"]
    if status not in allowed:
        return {"success": False, "message": "Estado no válido"}

    with engine.begin() as conn:
        conn.execute(
            text("UPDATE users SET status = :status WHERE id = :id"),
            {"status": status, "id": driver_id}
        )

    return {"success": True, "message": f"Estado actualizado a {status}"}


# Punto 5: afiliaciones del conductor (propietarios y vehículos a los que está afiliado)
@app.get("/driver/affiliations/{driver_id}")
def get_driver_affiliations(driver_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT
                    v.id AS vehicle_id,
                    v.placa,
                    v.marca,
                    v.modelo,
                    v.color,
                    u.username AS propietario
                FROM vehicles v
                JOIN users u ON v.user_id = u.id
                WHERE v.driver_id = :driver_id
            """),
            {"driver_id": driver_id}
        )
        return {
            "success": True,
            "affiliations": [dict(r._mapping) for r in result]
        }


@app.get("/drivers")
def get_drivers():
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT id, username, status
                FROM users
                WHERE role = 'conductor'
                ORDER BY username
            """)
        )

        return {
            "success": True,
            "drivers": [dict(row._mapping) for row in result]
        }


# =========================
# AFILIAR CONDUCTOR
# =========================
@app.post("/assign-driver")
def assign_driver(data: AssignDriverRequest):
    with engine.begin() as conn:

        existing = conn.execute(
            text("""
                SELECT driver_id
                FROM vehicles
                WHERE id = :vehicle_id
            """),
            {"vehicle_id": data.vehicle_id}
        ).fetchone()

        if existing and existing._mapping["driver_id"] == data.driver_id:
            return {
                "success": False,
                "message": "Este conductor ya está afiliado a este vehículo"
            }

        conn.execute(
            text("""
                UPDATE vehicles
                SET driver_id = :driver_id
                WHERE id = :vehicle_id
            """),
            data.dict()
        )

    return {
        "success": True,
        "message": "Afiliado correctamente"
    }


# =========================
# ASIGNAR VIAJE
# =========================
@app.post("/assign-trip")
def assign_trip(data: AssignTripRequest):
    with engine.begin() as conn:

        # Punto 2: validar que el conductor no tenga viaje activo
        active = conn.execute(
            text("""
                SELECT COUNT(*) AS cnt FROM trips
                WHERE driver_id = :driver_id
                  AND trip_status IN ('Asignado', 'En ruta')
            """),
            {"driver_id": data.driver_id}
        ).fetchone()

        if active._mapping["cnt"] > 0:
            return {
                "success": False,
                "message": "Este conductor ya tiene un viaje activo"
            }

        vehicle = conn.execute(
            text("SELECT placa FROM vehicles WHERE id = :id"),
            {"id": data.vehicle_id}
        ).fetchone()

        conn.execute(
            text("""
                UPDATE trips
                SET driver_id = :driver_id,
                    vehiculo = :vehiculo,
                    trip_status = 'Asignado'
                WHERE id = :trip_id
            """),
            {
                "trip_id": data.trip_id,
                "driver_id": data.driver_id,
                "vehiculo": vehicle._mapping["placa"]
            }
        )

        # Punto 3: auto-actualizar status del conductor a "En viaje"
        conn.execute(
            text("UPDATE users SET status = 'En viaje' WHERE id = :id"),
            {"id": data.driver_id}
        )

    return {"success": True, "message": "Viaje asignado correctamente"}


# =========================
# DASHBOARD CONDUCTOR
# =========================
@app.get("/driver/dashboard/{driver_id}")
def driver_dashboard(driver_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT v.*, u.username AS propietario
                FROM vehicles v
                JOIN users u ON v.user_id = u.id
                WHERE v.driver_id = :driver_id
            """),
            {"driver_id": driver_id}
        )

        vehicles = [dict(r._mapping) for r in result]

        return {
            "success": True,
            "vehicles": vehicles
        }


# =========================
# KPI
# =========================
@app.get("/driver/kpis/{driver_id}")
def driver_kpis(driver_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT
                    SUM(trip_status='Asignado' OR trip_status='En ruta') AS active,
                    SUM(trip_status='Finalizado') AS completed,
                    SUM(trip_status='Cancelado') AS cancelled,
                    COALESCE(SUM(CAST(flete AS DECIMAL(10,2))),0) AS income
                FROM trips
                WHERE driver_id=:driver_id
            """),
            {"driver_id": driver_id}
        ).fetchone()

        return {"success": True, "kpis": dict(result._mapping)}


# =========================
# VIAJES CON FILTRO
# =========================
@app.get("/driver/trips/{driver_id}")
def driver_trips(driver_id: int, status: str = "Todos"):
    with engine.connect() as conn:

        query = """
            SELECT t.*
            FROM trips t
            JOIN vehicles v ON t.vehiculo = v.placa
            WHERE v.driver_id = :driver_id
        """

        params = {"driver_id": driver_id}

        if status != "Todos":
            query += " AND t.trip_status = :status"
            params["status"] = status

        query += " ORDER BY t.id DESC"

        trips = conn.execute(text(query), params)

        return {
            "success": True,
            "trips": [dict(t._mapping) for t in trips]
        }


# =========================
# UPDATE STATUS
# =========================
@app.put("/driver/trips/{trip_id}/status")
def update_trip_status(trip_id: int, status: str):
    with engine.begin() as conn:
        conn.execute(
            text("""
                UPDATE trips
                SET trip_status = :status
                WHERE id = :id
            """),
            {"status": status, "id": trip_id}
        )

        # Punto 3: auto-actualizar status del conductor al finalizar/cancelar
        if status in ("Finalizado", "Cancelado"):
            trip = conn.execute(
                text("SELECT driver_id FROM trips WHERE id = :id"),
                {"id": trip_id}
            ).fetchone()

            if trip and trip._mapping["driver_id"]:
                driver_id = trip._mapping["driver_id"]

                # Solo volver a Disponible si no tiene otros viajes activos
                other_active = conn.execute(
                    text("""
                        SELECT COUNT(*) AS cnt FROM trips
                        WHERE driver_id = :driver_id
                          AND trip_status IN ('Asignado', 'En ruta')
                          AND id != :trip_id
                    """),
                    {"driver_id": driver_id, "trip_id": trip_id}
                ).fetchone()

                if other_active._mapping["cnt"] == 0:
                    conn.execute(
                        text("UPDATE users SET status = 'Disponible' WHERE id = :id"),
                        {"id": driver_id}
                    )

    return {"success": True}


# =========================
# VEHÍCULOS
# =========================
@app.get("/vehicles/{user_id}")
def get_vehicles(user_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM vehicles WHERE user_id=:id"),
            {"id": user_id}
        )
        return [dict(r._mapping) for r in result]


@app.post("/vehicles")
def add_vehicle(v: VehicleRequest):
    with engine.begin() as conn:
        conn.execute(
            text("""
                INSERT INTO vehicles
                (user_id,placa,marca,modelo,color,apodo)
                VALUES (:user_id,:placa,:marca,:modelo,:color,:apodo)
            """),
            v.dict()
        )
    return {"success": True}


# =========================
# VIAJES
# =========================
@app.get("/trips/{user_id}")
def get_trips(user_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM trips WHERE user_id=:id ORDER BY id DESC"),
            {"id": user_id}
        )
        return [dict(r._mapping) for r in result]


@app.post("/trips")
def add_trip(t: TripRequest):
    with engine.begin() as conn:
        conn.execute(
            text("""
                INSERT INTO trips
                (user_id,driver_id,origen,destino,vehiculo,flete)
                VALUES (:user_id,:driver_id,:origen,:destino,:vehiculo,:flete)
            """),
            t.dict()
        )
    return {"success": True}


# =========================
# DETALLE VEHÍCULO
# =========================
@app.get("/vehicle/{vehicle_id}")
def get_vehicle_detail(vehicle_id: int):
    with engine.connect() as conn:

        result = conn.execute(
            text("""
                SELECT 
                    v.*,
                    u.username AS conductor,
                    u.status AS conductor_status
                FROM vehicles v
                LEFT JOIN users u ON v.driver_id = u.id
                WHERE v.id = :vehicle_id
            """),
            {"vehicle_id": vehicle_id}
        ).fetchone()

        if not result:
            return {"success": False}

        vehicle = dict(result._mapping)

        driver = None
        if vehicle["conductor"] is not None:
            driver = {
                "username": vehicle["conductor"],
                "status": vehicle["conductor_status"]
            }

        trips = conn.execute(
            text("""
                SELECT *
                FROM trips
                WHERE vehiculo = :placa
                ORDER BY id DESC
            """),
            {"placa": vehicle["placa"]}
        )

        return {
            "success": True,
            "vehicle": vehicle,
            "driver": driver,
            "trips": [dict(t._mapping) for t in trips]
        }


# =========================
# 🔥 FIX CRÍTICO
# SOPORTE PARA /vehicle/detail/{id}
# =========================
@app.get("/vehicle/detail/{vehicle_id}")
def get_vehicle_detail_alias(vehicle_id: int):
    return get_vehicle_detail(vehicle_id)

from fastapi import Body

# =========================
# REPORTES
# =========================
@app.get("/reports/{user_id}")
def get_reports(
    user_id: int,
    fecha_inicio: str = None,
    fecha_fin: str = None,
    estado: str = None
):
    with engine.connect() as conn:

        filters = "WHERE user_id = :user_id"
        params = {"user_id": user_id}

        if fecha_inicio:
            filters += " AND DATE(created_at) >= :fecha_inicio"
            params["fecha_inicio"] = fecha_inicio

        if fecha_fin:
            filters += " AND DATE(created_at) <= :fecha_fin"
            params["fecha_fin"] = fecha_fin

        if estado and estado != "Todos":
            filters += " AND trip_status = :estado"
            params["estado"] = estado

        summary = conn.execute(
            text(f"""
                SELECT
                    COUNT(*) AS total_trips,
                    SUM(trip_status = 'Finalizado') AS completed,
                    SUM(trip_status = 'Cancelado') AS cancelled,
                    COALESCE(SUM(CAST(flete AS DECIMAL(10,2))), 0) AS income
                FROM trips
                {filters}
            """),
            params
        ).fetchone()

        trips = conn.execute(
            text(f"""
                SELECT *
                FROM trips
                {filters}
                ORDER BY id DESC
            """),
            params
        )

        return {
            "success": True,
            "summary": dict(summary._mapping),
            "trips": [dict(t._mapping) for t in trips]
        }


@app.get("/reports/{user_id}/excel")
def download_excel(user_id: int):
    with engine.connect() as conn:

        trips = conn.execute(
            text("""
                SELECT origen, destino, vehiculo, flete, trip_status
                FROM trips
                WHERE user_id = :user_id
                ORDER BY id DESC
            """),
            {"user_id": user_id}
        )

        rows = [dict(t._mapping) for t in trips]

    wb = Workbook()
    ws = wb.active
    ws.title = "Viajes"

    headers = ["Origen", "Destino", "Vehículo", "Flete", "Estado"]
    ws.append(headers)

    for row in rows:
        ws.append([
            row.get("origen", ""),
            row.get("destino", ""),
            row.get("vehiculo", ""),
            row.get("flete", ""),
            row.get("trip_status", ""),
        ])

    buffer = BytesIO()
    wb.save(buffer)
    buffer.seek(0)

    return StreamingResponse(
        buffer,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=reporte.xlsx"}
    )


# =========================
# FACTURACIÓN
# =========================
@app.get("/billing/{user_id}")
def get_billing(user_id: int):
    with engine.connect() as conn:

        total = conn.execute(
            text("""
                SELECT COALESCE(SUM(CAST(flete AS DECIMAL(10,2))), 0) AS total
                FROM trips
                WHERE user_id = :user_id
                  AND trip_status = 'Finalizado'
            """),
            {"user_id": user_id}
        ).fetchone()

        monthly = conn.execute(
            text("""
                SELECT COALESCE(SUM(CAST(flete AS DECIMAL(10,2))), 0) AS total
                FROM trips
                WHERE user_id = :user_id
                  AND trip_status = 'Finalizado'
                  AND MONTH(created_at) = MONTH(CURDATE())
                  AND YEAR(created_at) = YEAR(CURDATE())
            """),
            {"user_id": user_id}
        ).fetchone()

        by_vehicle = conn.execute(
            text("""
                SELECT
                    vehiculo,
                    COUNT(*) AS trips,
                    COALESCE(SUM(CAST(flete AS DECIMAL(10,2))), 0) AS total
                FROM trips
                WHERE user_id = :user_id
                  AND trip_status = 'Finalizado'
                GROUP BY vehiculo
                ORDER BY total DESC
            """),
            {"user_id": user_id}
        )

        by_driver = conn.execute(
            text("""
                SELECT
                    u.username,
                    COUNT(*) AS trips,
                    COALESCE(SUM(CAST(t.flete AS DECIMAL(10,2))), 0) AS total
                FROM trips t
                JOIN users u ON t.driver_id = u.id
                WHERE t.user_id = :user_id
                  AND t.trip_status = 'Finalizado'
                GROUP BY u.username
                ORDER BY total DESC
            """),
            {"user_id": user_id}
        )

        return {
            "success": True,
            "billing": {
                "total": float(total._mapping["total"]),
                "monthly": {"total": float(monthly._mapping["total"])},
                "by_vehicle": [dict(r._mapping) for r in by_vehicle],
                "by_driver": [dict(r._mapping) for r in by_driver],
            }
        }


@app.put("/vehicle/{vehicle_id}")
def update_vehicle(vehicle_id: int, data: dict = Body(...)):
    with engine.begin() as conn:
        conn.execute(
            text("""
                UPDATE vehicles
                SET placa = :placa,
                    marca = :marca,
                    modelo = :modelo,
                    color = :color,
                    apodo = :apodo
                WHERE id = :id
            """),
            {
                "id": vehicle_id,
                "placa": data.get("placa"),
                "marca": data.get("marca"),
                "modelo": data.get("modelo"),
                "color": data.get("color"),
                "apodo": data.get("apodo"),
            }
        )

    return {"success": True, "message": "Vehículo actualizado"}