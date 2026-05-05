import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/vehicle_trip_scaffold.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final placa = TextEditingController();
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final apodo = TextEditingController();
  String? color;

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ApiService.addVehicle({
      "placa": placa.text.trim().toUpperCase(),
      "marca": marca.text.trim(),
      "modelo": modelo.text.trim(),
      "color": color,
      "apodo": apodo.text.trim().isEmpty ? null : apodo.text.trim(),
    });

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return vehicleTripScaffold(
      context,
      "Agregar Vehículo",
      [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: placa,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: "Placa"),
                validator: (value) {
                  final v = value?.trim().toUpperCase() ?? '';
                  final regex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
                  if (v.isEmpty) return 'La placa es obligatoria';
                  if (!regex.hasMatch(v)) return 'Formato válido: ABC123';
                  return null;
                },
              ),
              TextFormField(
                controller: marca,
                decoration: const InputDecoration(labelText: "Marca"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marca es obligatoria';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: modelo,
                decoration: const InputDecoration(labelText: "Modelo"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El modelo es obligatorio';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                items: ["Rojo", "Azul", "Blanco", "Negro"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => color = v,
                decoration: const InputDecoration(labelText: "Color"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El color es obligatorio';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: apodo,
                decoration: const InputDecoration(labelText: "Apodo"),
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