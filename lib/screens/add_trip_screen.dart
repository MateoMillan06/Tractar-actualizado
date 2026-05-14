import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/vehicle_trip_scaffold.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});
  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final origen = TextEditingController();
  final destino = TextEditingController();
  final flete = TextEditingController();

  bool _loadingMap = false;
  String? _selectingFor; // 'origen' o 'destino'

  // ── Búsqueda de dirección con Nominatim ──────────────────────
  Future<void> _abrirBuscadorMapa(String campo) async {
    setState(() => _selectingFor = campo);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapSearchSheet(
        campo: campo,
        onSelected: (address) {
          setState(() {
            if (campo == 'origen') {
              origen.text = address;
            } else {
              destino.text = address;
            }
            _selectingFor = null;
          });
        },
      ),
    );
    setState(() => _selectingFor = null);
  }

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ApiService.addTrip({
      "origen": origen.text.trim(),
      "destino": destino.text.trim(),
      "vehiculo": "",
      "flete": flete.text.trim().isEmpty ? null : flete.text.trim(),
    });

    if (ok && mounted) {
      Navigator.pop(context);
    }
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
              // ── Origen ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: origen,
                      decoration: const InputDecoration(
                        labelText: "Origen",
                        hintText: "Ciudad o dirección de partida",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "El origen es obligatorio" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: "Seleccionar en mapa",
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _abrirBuscadorMapa('origen'),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // ── Destino ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: destino,
                      decoration: const InputDecoration(
                        labelText: "Destino",
                        hintText: "Ciudad o dirección de llegada",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "El destino es obligatorio" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: "Seleccionar en mapa",
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _abrirBuscadorMapa('destino'),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // ── Flete ──────────────────────────────────────────
              TextFormField(
                controller: flete,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Flete (opcional)",
                  prefixText: "\$",
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: guardar,
                child: const Text("Guardar viaje"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bottom sheet con buscador de dirección (Nominatim) ─────────
class _MapSearchSheet extends StatefulWidget {
  final String campo;
  final void Function(String address) onSelected;

  const _MapSearchSheet({required this.campo, required this.onSelected});

  @override
  State<_MapSearchSheet> createState() => _MapSearchSheetState();
}

class _MapSearchSheetState extends State<_MapSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _buscar(String query) async {
    if (query.trim().length < 3) return;
    setState(() { _loading = true; _error = null; _results = []; });
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(query)}&format=json&limit=8&addressdetails=1",
      );
      final r = await http.get(uri, headers: {
        "User-Agent": "TracktarApp/1.0",
        "Accept-Language": "es",
      });
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List;
        setState(() {
          _results = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() { _error = "Error al buscar"; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = "Sin conexión"; _loading = false; });
    }
  }

  String _formatDisplay(Map<String, dynamic> item) {
    final addr = item["address"] as Map? ?? {};
    final parts = <String>[];
    for (final k in ["road", "suburb", "city", "town", "village", "state", "country"]) {
      final v = addr[k]?.toString();
      if (v != null && v.isNotEmpty) parts.add(v);
    }
    return parts.isNotEmpty ? parts.join(", ") : item["display_name"].toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                "Seleccionar ${widget.campo == 'origen' ? 'Origen' : 'Destino'} en el mapa",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: "Buscar ciudad o dirección...",
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _results = []);
                      },
                    ),
                ],
                onChanged: (v) {
                  setState(() {});
                  if (v.trim().length >= 3) _buscar(v);
                },
                onSubmitted: _buscar,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else if (_results.isEmpty && _searchCtrl.text.length >= 3)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text("No se encontraron resultados"),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = _results[i];
                    final display = _formatDisplay(item);
                    final icon = _iconForType(item["type"]?.toString() ?? "");
                    return ListTile(
                      leading: Icon(icon, color: const Color(0xFF4B2E83)),
                      title: Text(display, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        item["display_name"].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelected(display);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "city": case "town": case "village": return Icons.location_city;
      case "road": case "street": return Icons.edit_road;
      case "administrative": return Icons.map;
      default: return Icons.place;
    }
  }
}
