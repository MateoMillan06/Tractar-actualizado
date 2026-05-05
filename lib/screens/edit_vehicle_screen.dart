import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/liquid_background.dart';
import '../widgets/liquid_glass_card.dart';

class EditVehicleScreen extends StatefulWidget {
  final int vehicleId;

  const EditVehicleScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<EditVehicleScreen> createState() =>
      _EditVehicleScreenState();
}

class _EditVehicleScreenState
    extends State<EditVehicleScreen> {
  final placaCtrl = TextEditingController();
  final marcaCtrl = TextEditingController();
  final modeloCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final apodoCtrl = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadVehicle();
  }

  Future<void> loadVehicle() async {
    final data =
        await ApiService.getVehicleDetail(widget.vehicleId);

    final vehicle = data?["vehicle"];

    if (vehicle != null) {
      placaCtrl.text = vehicle["placa"] ?? "";
      marcaCtrl.text = vehicle["marca"] ?? "";
      modeloCtrl.text = vehicle["modelo"] ?? "";
      colorCtrl.text = vehicle["color"] ?? "";
      apodoCtrl.text = vehicle["apodo"] ?? "";
    }

    setState(() => loading = false);
  }

  Future<void> save() async {
    final result = await ApiService.updateVehicle(
      vehicleId: widget.vehicleId,
      placa: placaCtrl.text,
      marca: marcaCtrl.text,
      modelo: modeloCtrl.text,
      color: colorCtrl.text,
      apodo: apodoCtrl.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "Actualizado"),
      ),
    );

    if (result["success"] == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 600,
                    child: LiquidGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // =========================
                            // HEADER CON BOTÓN ATRÁS
                            // =========================
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Editar vehículo",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // =========================
                            // FORMULARIO
                            // =========================
                            TextField(
                              controller: placaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Placa",
                              ),
                            ),
                            TextField(
                              controller: marcaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Marca",
                              ),
                            ),
                            TextField(
                              controller: modeloCtrl,
                              decoration: const InputDecoration(
                                labelText: "Modelo",
                              ),
                            ),
                            TextField(
                              controller: colorCtrl,
                              decoration: const InputDecoration(
                                labelText: "Color",
                              ),
                            ),
                            TextField(
                              controller: apodoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Apodo",
                              ),
                            ),

                            const SizedBox(height: 20),

                            // =========================
                            // BOTÓN GUARDAR
                            // =========================
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: save,
                                child: const Text("Guardar cambios"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}