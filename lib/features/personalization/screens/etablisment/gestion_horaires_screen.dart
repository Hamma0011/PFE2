import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../shop/controllers/product/horaire_controller.dart';
import '../../../shop/models/horaire_model.dart';
import '../../../shop/models/jour_semaine.dart';
import 'horaire_tile.dart';

class GestionHorairesEtablissement extends StatefulWidget {
  final String etablissementId;
  final String nomEtablissement;
  final bool isCreation;

  const GestionHorairesEtablissement({
    super.key,
    required this.etablissementId,
    required this.nomEtablissement,
    this.isCreation = false,
  });

  @override
  State<GestionHorairesEtablissement> createState() => _GestionHorairesEtablissementState();
}

class _GestionHorairesEtablissementState extends State<GestionHorairesEtablissement> {
  late final HoraireController _horaireController;
  bool _initialisationEnCours = true;
  bool _sauvegardeEnCours = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeHoraires();
  }

  void _initializeController() {
    try {
      // Essayer de récupérer le contrôleur existant
      _horaireController = Get.find<HoraireController>();
      print('✅ Contrôleur horaire existant récupéré dans GestionHoraires');
    } catch (e) {
      // Si non trouvé, en créer un nouveau
      _horaireController = Get.put(HoraireController(HoraireRepository()));
      print('🆕 Nouveau contrôleur horaire créé dans GestionHoraires');
    }
  }

  Future<void> _initializeHoraires() async {
    try {
      print('🔄 Initialisation des horaires pour ${widget.etablissementId}');

      if (widget.isCreation) {
        _horaireController.initializeHoraires(widget.etablissementId);
        print('📝 Horaires initialisés pour création');
      } else {
        await _horaireController.fetchHoraires(widget.etablissementId);
        print('📥 Horaires chargés depuis la base: ${_horaireController.horaires.length}');
      }
    } catch (e) {
      print('❌ Erreur initialisation horaires: $e');
      _showErrorSnackbar('Impossible de charger les horaires: $e');
    } finally {
      if (mounted) {
        setState(() => _initialisationEnCours = false);
      }
    }
  }

  void _onHoraireChanged(Horaire horaire) {
    _horaireController.updateHoraire(horaire);
  }

  Future<void> _sauvegarderHoraires() async {
    if (_sauvegardeEnCours) return;

    print('💾 Début sauvegarde des horaires...');
    setState(() => _sauvegardeEnCours = true);

    try {
      final success = widget.isCreation
          ? await _horaireController.createHoraires(
        widget.etablissementId,
        _horaireController.horaires,
      )
          : await _horaireController.updateAllHoraires(
        widget.etablissementId,
        _horaireController.horaires,
      );

      if (success) {
        print('Sauvegarde réussie');


        // Attendre un peu pour que l'utilisateur voie le message
        await Future.delayed(const Duration(milliseconds: 1500));

        // Retourner à l'écran précédent avec un résultat positif
        if (mounted) {
          print('Retour à EditEtablissementScreen avec result: true');
          Get.back(result: true);
          //_showSuccessSnackbar('Horaires sauvegardés avec succès');
        }
      } else {
        print('Échec de la sauvegarde');
        _showErrorSnackbar('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      _showErrorSnackbar('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() => _sauvegardeEnCours = false);
      }
    }
  }

  void _appliquerHoraireStandard() {
    _showConfirmationDialog(
      title: 'Horaire standard',
      content: 'Appliquer l\'horaire standard (7h-22h tous les jours) ?',
      onConfirm: _appliquerHoraireStandardConfirm,
    );
  }

  void _appliquerHoraireStandardConfirm() {
    final nouveauxHoraires = _horaireController.horaires.map((horaire) {
      return horaire.copyWith(
        estOuvert: true,
        ouverture: '07:00',
        fermeture: '22:00',
      );
    }).toList();

    _updateHoraires(nouveauxHoraires, 'Horaire standard appliqué');
  }

  void _toutFermer() {
    _showConfirmationDialog(
      title: 'Tout fermer',
      content: 'Fermer l\'établissement tous les jours ?',
      onConfirm: _toutFermerConfirm,
    );
  }

  void _toutFermerConfirm() {
    final nouveauxHoraires = _horaireController.horaires.map((horaire) {
      return horaire.copyWith(
        estOuvert: false,
        ouverture: null,
        fermeture: null,
      );
    }).toList();

    _updateHoraires(nouveauxHoraires, 'Tous les jours sont maintenant fermés');
  }

  void _updateHoraires(List<Horaire> nouveauxHoraires, String message) {
    _horaireController.horaires.assignAll(nouveauxHoraires);
    _horaireController.horaires.refresh();
    _showSuccessSnackbar(message, backgroundColor: Colors.orange);
  }

  // Méthodes utilitaires pour les dialogues et snackbars
  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message, {Color backgroundColor = Colors.green}) {
    Get.snackbar(
      'Succès',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildHoraireSummary() {
    return Obx(() {
      final nbJoursOuverts = _horaireController.nombreJoursOuverts;
      final isOpenNow = _horaireController.isOpenNow;

      return Card(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statut actuel:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpenNow ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpenNow ? 'OUVERT' : 'FERMÉ',
                      style: TextStyle(
                        color: isOpenNow ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jours ouverts:'),
                  Text(
                    '$nbJoursOuverts/7',
                    style: TextStyle(
                      color: nbJoursOuverts > 0 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun horaire configuré',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Utilisez les boutons ci-dessous pour configurer les horaires',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHorairesList() {
    return Obx(() {
      final horaires = _horaireController.horaires;

      print('📋 Construction liste horaires: ${horaires.length} éléments');

      if (horaires.isEmpty) return _buildEmptyState();

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: horaires.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final horaire = horaires[index];
          return HoraireTileAmeliore(
            horaire: horaire,
            onChanged: _onHoraireChanged,
          );
        },
      );
    });
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _sauvegardeEnCours ? null : () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _sauvegardeEnCours ? null : _sauvegarderHoraires,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _sauvegardeEnCours
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Sauvegarder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horaires d\'ouverture',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nomEtablissement,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'standard',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Horaire standard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fermer',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Tout fermer'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'standard':
                  _appliquerHoraireStandard();
                  break;
                case 'fermer':
                  _toutFermer();
                  break;
              }
            },
          ),
        ],
      ),
      body: _initialisationEnCours
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des horaires...'),
          ],
        ),
      )
          : Column(
        children: [
          // Bannière d'information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Configuration des horaires',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isCreation
                      ? 'Définissez les horaires d\'ouverture de votre établissement'
                      : 'Modifiez les horaires existants de votre établissement',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Résumé
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildHoraireSummary(),
          ),

          // En-tête de la liste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jours de la semaine',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Obx(() {
                  final nbJoursOuverts = _horaireController.nombreJoursOuverts;
                  return Text(
                    '$nbJoursOuverts/7 jours ouverts',
                    style: TextStyle(
                      color: nbJoursOuverts > 0 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste des horaires
          Expanded(child: _buildHorairesList()),

          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }
}