$ErrorActionPreference = "Stop"
$base = "https://tractar-actualizado-production.up.railway.app"
$pwd  = "demo1234"

function Post($path, $body) {
    return Invoke-RestMethod -Uri "$base$path" -Method Post -ContentType "application/json" -Body ($body | ConvertTo-Json)
}
function Put($path) {
    return Invoke-RestMethod -Uri "$base$path" -Method Put
}

# ──────────────────────────────────────────────────────────────
# 1) Crear propietarios + login para obtener su user_id
# ──────────────────────────────────────────────────────────────
$owners = @(
    @{ user = "TransportesABC"; },
    @{ user = "FletesNorte";    },
    @{ user = "LogisticaSur";   }
)

foreach ($o in $owners) {
    try {
        $reg = Post "/register" @{ username = $o.user; password = $pwd }
        Write-Host "[REGISTER] $($o.user) -> $($reg | ConvertTo-Json -Compress)"
    } catch {
        Write-Host "[REGISTER] $($o.user) ya existía o falló (continuamos)"
    }
    $log = Post "/login" @{ username = $o.user; password = $pwd }
    $o.id = $log.user_id
    Write-Host "[LOGIN]    $($o.user) -> id=$($o.id)"
}

# ──────────────────────────────────────────────────────────────
# 2) Vehículos por propietario
# ──────────────────────────────────────────────────────────────
$vehicleSpecs = @{
    "TransportesABC" = @(
        @{ placa="ABC123"; marca="Kenworth";    modelo="T800";  color="Rojo";    apodo="El Rojo"      },
        @{ placa="ABC234"; marca="Freightliner"; modelo="Cascadia"; color="Azul";   apodo="Azulito"     },
        @{ placa="ABC345"; marca="Volvo";       modelo="FH16";  color="Blanco";  apodo="Blanca Nieves" }
    )
    "FletesNorte" = @(
        @{ placa="FLN100"; marca="Mack";        modelo="Anthem";   color="Negro";  apodo="Negrura"  },
        @{ placa="FLN200"; marca="International"; modelo="LT";     color="Gris";   apodo="Plomo"    },
        @{ placa="FLN300"; marca="Peterbilt";   modelo="389";       color="Verde";  apodo="El Verde" }
    )
    "LogisticaSur" = @(
        @{ placa="LSR111"; marca="Scania";      modelo="R500";    color="Amarillo"; apodo="Solecito" },
        @{ placa="LSR222"; marca="MAN";         modelo="TGX";     color="Rojo";     apodo="Pasión"   }
    )
}

$createdVehicles = @{}  # user -> array of vehicle objects with id, placa
foreach ($o in $owners) {
    $createdVehicles[$o.user] = @()
    foreach ($v in $vehicleSpecs[$o.user]) {
        $v.user_id = $o.id
        try {
            $r = Post "/vehicles" $v
            $createdVehicles[$o.user] += @{ placa = $v.placa; id = $r.vehicle_id; data = $r }
            Write-Host "[VEHICLE]  $($o.user) <- $($v.placa) ($($v.marca) $($v.modelo)) -> $($r | ConvertTo-Json -Compress)"
        } catch {
            Write-Host "[VEHICLE]  Falló $($v.placa): $($_.Exception.Message)"
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 3) Listar vehículos de cada propietario para obtener IDs reales
#    (el endpoint /vehicles puede no devolver id en la creación)
# ──────────────────────────────────────────────────────────────
foreach ($o in $owners) {
    $list = Invoke-RestMethod -Uri "$base/vehicles/$($o.id)" -Method Get
    Write-Host "[FLEET $($o.user)] $((($list | ConvertTo-Json -Compress)))"
    $o.vehicles = $list
}

# ──────────────────────────────────────────────────────────────
# 4) Afiliar conductores existentes a vehículos
#    Conductores actuales (de /drivers): Ana=2, Juan=4, Mateo=7, PEPITO=8
# ──────────────────────────────────────────────────────────────
$driversList = (Invoke-RestMethod -Uri "$base/drivers" -Method Get).drivers
$driverIds = $driversList | ForEach-Object { $_.id }
Write-Host "[DRIVERS] disponibles: $($driverIds -join ',')"

$i = 0
foreach ($o in $owners) {
    foreach ($veh in $o.vehicles) {
        if ($i -ge $driverIds.Count) { break }
        $vid = $veh.id
        if (-not $vid) { $vid = $veh.vehicle_id }
        if (-not $vid) { continue }
        $did = $driverIds[$i]
        try {
            $r = Post "/assign-driver" @{ driver_id = $did; vehicle_id = $vid }
            Write-Host "[ASSIGN]   driver=$did vehicle=$vid -> $($r | ConvertTo-Json -Compress)"
            $i++
        } catch {
            Write-Host "[ASSIGN]   Falló driver=$did vehicle=$vid"
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 5) Crear viajes (varios por propietario)
# ──────────────────────────────────────────────────────────────
$tripSpecs = @{
    "TransportesABC" = @(
        @{ origen="Cartagena, Bolívar";  destino="Barranquilla, Atlántico"; flete="850000" },
        @{ origen="Bogotá, Cundinamarca"; destino="Medellín, Antioquia";    flete="2400000" },
        @{ origen="Cali, Valle";          destino="Buenaventura, Valle";    flete="600000" }
    )
    "FletesNorte" = @(
        @{ origen="Santa Marta, Magdalena"; destino="Riohacha, La Guajira"; flete="700000" },
        @{ origen="Sincelejo, Sucre";       destino="Montería, Córdoba";    flete="450000" }
    )
    "LogisticaSur" = @(
        @{ origen="Neiva, Huila";    destino="Popayán, Cauca";  flete="1100000" },
        @{ origen="Pasto, Nariño";   destino="Ipiales, Nariño"; flete="350000"  }
    )
}

$createdTrips = @{}
foreach ($o in $owners) {
    $createdTrips[$o.user] = @()
    foreach ($t in $tripSpecs[$o.user]) {
        $t.user_id  = $o.id
        $t.vehiculo = ""
        try {
            $r = Post "/trips" $t
            Write-Host "[TRIP]     $($o.user) $($t.origen) -> $($t.destino) -> $($r | ConvertTo-Json -Compress)"
            $createdTrips[$o.user] += $r
        } catch {
            Write-Host "[TRIP]     Falló: $($_.Exception.Message)"
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 6) Asignar algunos viajes a conductor+vehículo
#    y marcar algunos como "Completado" o "Cancelado"
# ──────────────────────────────────────────────────────────────
foreach ($o in $owners) {
    $tripsList = (Invoke-RestMethod -Uri "$base/trips/$($o.id)" -Method Get)
    Write-Host "[TRIPS $($o.user)] $(($tripsList | ConvertTo-Json -Compress))"
    $o.trips = $tripsList
}

# Asignar primer viaje de cada owner a primer vehículo+conductor disponible
$j = 0
foreach ($o in $owners) {
    if ($o.trips.Count -eq 0 -or $o.vehicles.Count -eq 0) { continue }
    $trip = $o.trips[0]
    $veh  = $o.vehicles[0]
    $tid = $trip.id; if (-not $tid) { $tid = $trip.trip_id }
    $vid = $veh.id;  if (-not $vid) { $vid = $veh.vehicle_id }
    if ($j -ge $driverIds.Count) { $j = 0 }
    $did = $driverIds[$j]; $j++
    try {
        $r = Post "/assign-trip" @{ trip_id = $tid; driver_id = $did; vehicle_id = $vid }
        Write-Host "[ASSIGN-TRIP] trip=$tid driver=$did vehicle=$vid -> $($r | ConvertTo-Json -Compress)"
    } catch {
        Write-Host "[ASSIGN-TRIP] Falló trip=${tid} - $($_.Exception.Message)"
    }
}

# Marcar segundo viaje de cada owner como Completado (vía /driver/trips/{id}/status)
foreach ($o in $owners) {
    if ($o.trips.Count -lt 2) { continue }
    $trip = $o.trips[1]
    $tid = $trip.id; if (-not $tid) { $tid = $trip.trip_id }
    try {
        $r = Put "/driver/trips/$tid/status?status=Completado"
        Write-Host "[STATUS]   trip=$tid -> Completado -> $($r | ConvertTo-Json -Compress)"
    } catch {
        Write-Host "[STATUS]   Falló trip=${tid} - $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "  DATOS DEMO CREADOS"
Write-Host "════════════════════════════════════════════════════════════"
Write-Host "Propietarios (todos con contraseña: $pwd):"
foreach ($o in $owners) {
    Write-Host "  - $($o.user) (id=$($o.id))"
}
Write-Host ""
Write-Host "Conductores existentes (reutilizados):"
foreach ($d in $driversList) {
    Write-Host "  - $($d.username) (id=$($d.id))"
}
