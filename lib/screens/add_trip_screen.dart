import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../widgets/vehicle_trip_scaffold.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});
  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final origen  = TextEditingController();
  final destino = TextEditingController();
  final flete   = TextEditingController();

  Future<void> _abrirMapa(String campo) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(
          titulo: campo == 'origen' ? 'Seleccionar Origen' : 'Seleccionar Destino',
          initialAddress: campo == 'origen' ? origen.text : destino.text,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (campo == 'origen') {
          origen.text = result;
        } else {
          destino.text = result;
        }
      });
    }
  }

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ApiService.addTrip({
      "origen":  origen.text.trim(),
      "destino": destino.text.trim(),
      "vehiculo": "",
      "flete": flete.text.trim().isEmpty ? null : flete.text.trim(),
    });

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return vehicleTripScaffold(
      context,
      "Agregar Viaje",
      [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Origen ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: origen,
                      decoration: const InputDecoration(
                        labelText: "Origen",
                        hintText: "Ciudad o dirección de partida",
                        prefixIcon: Icon(Icons.trip_origin),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "El origen es obligatorio"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: "Seleccionar en mapa",
                    child: IconButton.filled(
                      icon: const Icon(Icons.map),
                      onPressed: () => _abrirMapa('origen'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2E83),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Destino ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: destino,
                      decoration: const InputDecoration(
                        labelText: "Destino",
                        hintText: "Ciudad o dirección de llegada",
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "El destino es obligatorio"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: "Seleccionar en mapa",
                    child: IconButton.filled(
                      icon: const Icon(Icons.map),
                      onPressed: () => _abrirMapa('destino'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2E83),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Flete ────────────────────────────────────
              TextFormField(
                controller: flete,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Flete (opcional)",
                  prefixText: "\$",
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: guardar,
                icon: const Icon(Icons.save),
                label: const Text("Guardar viaje"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PANTALLA MAPA — pin arrastrable tipo Uber + buscador
// ══════════════════════════════════════════════════════════════
class _MapPickerScreen extends StatefulWidget {
  final String titulo;
  final String initialAddress;

  const _MapPickerScreen({
    required this.titulo,
    required this.initialAddress,
  });

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  static const _colombiaCenter = LatLng(4.5709, -74.2973);

  final _mapCtrl   = MapController();
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  LatLng _pinPosition = _colombiaCenter;
  String _addressDisplay = "Mueve el mapa para ajustar la ubicación";
  bool _loadingAddress = false;
  bool _searchOpen = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress.isNotEmpty) {
      _searchCtrl.text = widget.initialAddress;
      _geocodeAddress(widget.initialAddress);
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Geocodifica texto → coordenadas y mueve el mapa
  Future<void> _geocodeAddress(String query) async {
    if (query.trim().length < 3) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(query)}&format=json&limit=6&addressdetails=1",
      );
      final r = await http.get(uri, headers: {
        "User-Agent": "TracktarApp/1.0",
        "Accept-Language": "es",
      });
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List;
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
          _searching = false;
          _searchOpen = true;
        });
      }
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  // Geocodificación inversa: coordenadas → dirección
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() {
      _loadingAddress = true;
      _addressDisplay = "Obteniendo dirección...";
    });
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=es",
      );
      final r = await http.get(uri, headers: {
        "User-Agent": "TracktarApp/1.0",
      });
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map;
        final addr = data["address"] as Map? ?? {};
        final parts = <String>[];
        for (final k in ["road", "suburb", "city", "town", "village", "state", "country"]) {
          final v = addr[k]?.toString();
          if (v != null && v.isNotEmpty) parts.add(v);
        }
        setState(() {
          _addressDisplay = parts.isNotEmpty
              ? parts.take(4).join(", ")
              : data["display_name"]?.toString() ?? "Ubicación seleccionada";
          _loadingAddress = false;
        });
      }
    } catch (_) {
      setState(() {
        _addressDisplay = "Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}";
        _loadingAddress = false;
      });
    }
  }

  void _onSearchResultTap(Map<String, dynamic> item) {
    final lat = double.tryParse(item["lat"].toString()) ?? 4.57;
    final lon = double.tryParse(item["lon"].toString()) ?? -74.29;
    final pos = LatLng(lat, lon);

    final addr = item["address"] as Map? ?? {};
    final parts = <String>[];
    for (final k in ["road", "suburb", "city", "town", "village", "state", "country"]) {
      final v = addr[k]?.toString();
      if (v != null && v.isNotEmpty) parts.add(v);
    }
    final display = parts.isNotEmpty ? parts.take(4).join(", ") : item["display_name"].toString();

    _searchCtrl.text = display;
    setState(() {
      _pinPosition = pos;
      _addressDisplay = display;
      _searchResults = [];
      _searchOpen = false;
    });
    _mapCtrl.move(pos, 14);
    _focusNode.unfocus();
  }

  void _confirmar() {
    Navigator.pop(context, _addressDisplay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Mapa ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinPosition,
              initialZoom: 6,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  setState(() => _pinPosition = pos.center!);
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
                  _reverseGeocode(_pinPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.tractar.app",
              ),
            ],
          ),

          // ── Pin central fijo ───────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B2E83),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                ),
                // Sombra del pin
                Container(
                  width: 12,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          // ── AppBar custom ──────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Buscar dirección o ciudad...",
                            hintStyle: const TextStyle(color: Colors.black45),
                            prefixIcon: const Icon(Icons.search, color: Colors.black54),
                            suffixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.black45),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _searchOpen = false;
                                          });
                                        },
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (v) {
                            setState(() {});
                            if (v.trim().length >= 3) {
                              _geocodeAddress(v);
                            } else {
                              setState(() { _searchResults = []; _searchOpen = false; });
                            }
                          },
                          onSubmitted: _geocodeAddress,
                        ),
                      ),

                      // Resultados de búsqueda
                      if (_searchOpen && _searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final item = _searchResults[i];
                              final display = item["display_name"].toString();
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place, color: Color(0xFF4B2E83), size: 20),
                                title: Text(
                                  display,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                onTap: () => _onSearchResultTap(item),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Panel inferior — dirección + confirmar ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF4B2E83), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Ubicación seleccionada",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _loadingAddress
                      ? const SizedBox(
                          height: 20,
                          child: LinearProgressIndicator(backgroundColor: Colors.white12),
                        )
                      : Text(
                          _addressDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Icons.check),
                      label: Text(
                        "Confirmar ${widget.titulo.contains('Origen') ? 'origen' : 'destino'}",
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2E83),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}