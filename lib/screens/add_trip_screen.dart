import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? selectedVehicle;

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ApiService.addTrip({
      "origen": origen.text.trim(),
      "destino": destino.text.trim(),
      "vehiculo": selectedVehicle,
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
              TextFormField(
                controller: origen,
                decoration: const InputDecoration(labelText: "Origen"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "El origen es obligatorio";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: destino,
                decoration: const InputDecoration(labelText: "Destino"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "El destino es obligatorio";
                  }
                  return null;
                },
              ),
              FutureBuilder<List<dynamic>>(
                future: ApiService.getVehicles(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? [];

                  return DropdownButtonFormField<String>(
                    items: data
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v["placa"].toString(),
                            child: Text(v["placa"]),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedVehicle = v,
                    decoration: const InputDecoration(labelText: "Vehículo"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Selecciona un vehículo";
                      }
                      return null;
                    },
                  );
                },
              ),
              TextFormField(
                controller: flete,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(labelText: "Flete"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: guardar,
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}