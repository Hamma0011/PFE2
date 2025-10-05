import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import 'add_brand_screen.dart';
import 'edit_brand_screen.dart';

class MonEtablissementScreen extends StatefulWidget {
  const MonEtablissementScreen({super.key});

  @override
  State<MonEtablissementScreen> createState() => _MonEtablissementScreenState();
}

class _MonEtablissementScreenState extends State<MonEtablissementScreen> {
  // SOLUTION : Utiliser Get.put() au lieu de Get.find()
  late final EtablissementController _controller;
  Etablissement? _monEtablissement;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur
    _controller = Get.put(EtablissementController(EtablissementRepository()));
    _chargerEtablissement();
  }

  void _chargerEtablissement() async {
    final etab = await _controller.getMonEtablissement();
    setState(() {
      _monEtablissement = etab;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Établissement')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _monEtablissement == null
          ? _afficherAucunEtablissement()
          : _afficherMonEtablissement(),
    );
  }

  Widget _afficherAucunEtablissement() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Vous n\'avez pas d\'établissement'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.to(() => AddEtablissementScreen()),
            child: const Text('Créer mon établissement'),
          ),
        ],
      ),
    );
  }

  Widget _afficherMonEtablissement() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Affichage de l'établissement
          Card(
            child: ListTile(
              leading: const Icon(Icons.business, color: Colors.blue),
              title: Text(_monEtablissement!.name),
              subtitle: Text(_monEtablissement!.address),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Get.to(() => EditEtablissementScreen(etablissement: _monEtablissement!));
              },
            ),
          ),
        ],
      ),
    );
  }
}