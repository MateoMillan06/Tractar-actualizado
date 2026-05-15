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
  final placa  = TextEditingController();
  final marca  = TextEditingController();
  final modelo = TextEditingController();
  final apodo  = TextEditingController();
  String? color;
  bool _loading = false;

  Future<void> guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await ApiService.addVehicleDetailed({
      "placa":  placa.text.trim().toUpperCase(),
      "marca":  marca.text.trim(),
      "modelo": modelo.text.trim(),
      "color":  color,
      "apodo":  apodo.text.trim().isEmpty ? null : apodo.text.trim(),
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (result["success"] == true) {
      Navigator.pop(context, true); // retorna true para que el llamador sepa que fue exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]?.toString() ?? "Error al guardar el vehículo"),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
                  if (v.isEmpty) return 'La placa es obligatoria';
                  final regex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
                  if (!regex.hasMatch(v)) return 'Formato válido: ABC123';
                  return null;
                },
              ),
              TextFormField(
                controller: marca,
                decoration: const InputDecoration(labelText: "Marca"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'La marca es obligatoria' : null,
              ),
              TextFormField(
                controller: modelo,
                decoration: const InputDecoration(labelText: "Modelo"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El modelo es obligatorio' : null,
              ),
              DropdownButtonFormField<String>(
                items: ["Rojo", "Azul", "Blanco", "Negro", "Gris", "Verde", "Amarillo"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => color = v,
                decoration: const InputDecoration(labelText: "Color"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'El color es obligatorio' : null,
              ),
              TextFormField(
                controller: apodo,
                decoration: const InputDecoration(labelText: "Apodo / Nombre (opcional)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loading ? null : guardar,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Guardar"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}