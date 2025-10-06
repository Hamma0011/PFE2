import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/controllers/product/horaire_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../../shop/models/horaire_model.dart';
import '../../../shop/models/jour_semaine.dart';
import '../../../shop/models/statut_etablissement_model.dart';
import '../etablisment/gestion_horaires_screen.dart';

class EditEtablissementScreen extends StatefulWidget {
  final Etablissement etablissement;

  const EditEtablissementScreen({super.key, required this.etablissement});

  @override
  State<EditEtablissementScreen> createState() =>
      _EditEtablissementScreenState();
}

class _EditEtablissementScreenState extends State<EditEtablissementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final EtablissementController _etablissementController =
      Get.find<EtablissementController>();
  late final HoraireController _horaireController;

  bool _isLoading = false;
  bool _horairesLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeHoraireController();
    _initializeForm();
    _loadHoraires();
  }

  void _initializeHoraireController() {
    try {
      _horaireController = Get.find<HoraireController>();
      print('✅ Contrôleur horaire existant récupéré dans EditEtablissement');
    } catch (e) {
      _horaireController = Get.put(HoraireController(HoraireRepository()));
      print('🆕 Nouveau contrôleur horaire créé dans EditEtablissement');
    }
  }

  void _initializeForm() {
    _nameController.text = widget.etablissement.name;
    _addressController.text = widget.etablissement.address;
    _latitudeController.text = widget.etablissement.latitude?.toString() ?? '';
    _longitudeController.text =
        widget.etablissement.longitude?.toString() ?? '';
  }

  Future<void> _loadHoraires() async {
    try {
      print('🔄 Chargement des horaires pour ${widget.etablissement.id}...');

      setState(() {
        _horairesLoaded = false;
      });

      await _horaireController.fetchHoraires(widget.etablissement.id!);

      print('📊 Horaires chargés: ${_horaireController.horaires.length}');
      for (var horaire in _horaireController.horaires) {
        print(
            '  - ${horaire.jour.valeur}: ${horaire.estOuvert ? "${horaire.ouverture}-${horaire.fermeture}" : "FERMÉ"}');
      }
      print('🎯 Jours ouverts: ${_horaireController.nombreJoursOuverts}');
      print('🔍 HasHoraires: ${_horaireController.hasHoraires.value}');

      setState(() {
        _horairesLoaded = true;
      });

      print('✅ Chargement des horaires terminé');
    } catch (e) {
      print('❌ Erreur chargement horaires: $e');
      setState(() {
        _horairesLoaded = true;
      });
    }
  }

  void _gererHoraires() async {
    try {
      print('🎯 Navigation vers GestionHoraires...');

      final result = await Get.to(() => GestionHorairesEtablissement(
            etablissementId: widget.etablissement.id!,
            nomEtablissement: widget.etablissement.name,
            isCreation: false,
          ));

      print('🔙 Retour de GestionHoraires avec result: $result');

      if (result == true) {
        print('🔄 Rechargement des horaires après modification...');
        await _loadHoraires();

        // ✅ REMPLACÉ: Utilisation de la méthode du contrôleur
        _etablissementController
            .showSuccessSnackbar('Horaires mis à jour avec succès');

        print('✅ Horaires rafraîchis dans l\'interface');
      } else {
        print('↩️ Retour sans sauvegarde (result: $result)');
      }
    } catch (e) {
      print('❌ Erreur lors de la gestion des horaires: $e');
      // ✅ REMPLACÉ: Utilisation de la méthode du contrôleur
      _etablissementController
          .showErrorSnackbar('Impossible de modifier les horaires: $e');
    }
  }

  void _updateEtablissement() async {
    print('🔄 Début de _updateEtablissement');

    if (!_formKey.currentState!.validate()) {
      print('❌ Validation du formulaire échouée');
      return;
    }

    setState(() => _isLoading = true);
    print('⏳ Chargement activé');

    try {
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (_latitudeController.text.isNotEmpty) {
        updateData['latitude'] = double.tryParse(_latitudeController.text);
      }
      if (_longitudeController.text.isNotEmpty) {
        updateData['longitude'] = double.tryParse(_longitudeController.text);
      }

      print('📤 Envoi des données: $updateData');

      final success = await _etablissementController.updateEtablissement(
        widget.etablissement.id!,
        updateData,
      );
      Get.back(result: true);

      print('✅ Réponse reçue: $success');

      if (success) {
        print('🎉 Succès - Affichage snackbar');

        // ✅ REMPLACÉ: Utilisation de la méthode du contrôleur
        _etablissementController
            .showSuccessSnackbar('Établissement mis à jour avec succès');

        print('⏳ Attente avant fermeture...');
        await Future.delayed(const Duration(milliseconds: 1500));

        print('🚪 Fermeture de l écran');
        //Get.back(result: true);
      } else {
        print('❌ Échec - Affichage erreur');
        // ✅ REMPLACÉ: Utilisation de la méthode du contrôleur
        _etablissementController.showErrorSnackbar('Échec de la mise à jour');
      }
    } catch (e) {
      print('💥 Erreur catch: $e');
      // ✅ REMPLACÉ: Utilisation de la méthode du contrôleur
      _etablissementController.showErrorSnackbar('Erreur: $e');
    } finally {
      print('🏁 Fin du processus');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthodes helper pour les horaires
  Widget _buildAucunHoraire() {
    return const Column(
      children: [
        Icon(Icons.access_time, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Aucun horaire configuré',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          'Configurez les horaires d\'ouverture de votre établissement',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHorairePreview(Horaire horaire) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getJourAbrege(horaire.jour),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horaire.jour.valeur,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${horaire.ouverture} - ${horaire.fermeture}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHorairesSection() {
    if (!_horairesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasHoraires = _horaireController.hasHoraires.value;
    final nbJoursOuverts = _horaireController.nombreJoursOuverts;
    final horairesOuverts = _horaireController.horaires
        .where((h) => h.estOuvert && h.isValid)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHoraires && horairesOuverts.isNotEmpty) ...[
          Text(
            '$nbJoursOuverts jours ouverts',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...horairesOuverts.take(3).map(_buildHorairePreview).toList(),
          if (horairesOuverts.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... et ${horairesOuverts.length - 3} autres jours',
                style: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
        ] else ...[
          _buildAucunHoraire(),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _gererHoraires,
          icon: const Icon(Icons.schedule),
          label: Text(hasHoraires
              ? 'Modifier les horaires'
              : 'Configurer les horaires'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[50],
            foregroundColor: Colors.orange[800],
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  String _getStatutText(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return 'Approuvé';
      case StatutEtablissement.rejete:
        return 'Rejeté';
      case StatutEtablissement.enAttente:
        return 'En attente';
    }
  }

  Color _getStatutColor(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return Colors.green;
      case StatutEtablissement.rejete:
        return Colors.red;
      case StatutEtablissement.enAttente:
        return Colors.orange;
    }
  }

  String _getJourAbrege(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
        return 'LUN';
      case JourSemaine.mardi:
        return 'MAR';
      case JourSemaine.mercredi:
        return 'MER';
      case JourSemaine.jeudi:
        return 'JEU';
      case JourSemaine.vendredi:
        return 'VEN';
      case JourSemaine.samedi:
        return 'SAM';
      case JourSemaine.dimanche:
        return 'DIM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'établissement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateEtablissement,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Carte statut
                    Card(
                      color: _getStatutColor(widget.etablissement.statut)
                          .withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color:
                                  _getStatutColor(widget.etablissement.statut),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statut',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    _getStatutText(widget.etablissement.statut),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatutColor(
                                              widget.etablissement.statut),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations de l'établissement
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'établissement',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Veuillez entrer le nom'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse complète',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Veuillez entrer l\'adresse'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Coordonnées GPS
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.gps_fixed),
                            ),
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.gps_fixed),
                            ),
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les coordonnées GPS sont optionnelles',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // Section Horaires
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.orange),
                                const SizedBox(width: 12),
                                Text(
                                  'Horaires d\'ouverture',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildHorairesSection(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons d'action
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _updateEtablissement,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
