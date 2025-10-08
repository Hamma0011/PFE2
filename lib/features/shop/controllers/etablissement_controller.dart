import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/etablissement_model.dart';
import '../models/horaire_model.dart';
import '../models/statut_etablissement_model.dart';

class EtablissementController extends GetxController {
  final EtablissementRepository repo;
  final UserController userController = Get.find<UserController>();
  final etablissements = <Etablissement>[].obs;

  EtablissementController(this.repo);

  // Méthode pour créer un établissement SANS horaires
  Future<String?> createEtablissement(Etablissement e) async {
    try {
      if (!_isUserGerant()) {
        _logError('création',
            'Permission refusée : seul un Gérant peut créer un établissement');
        return null;
      }

      final id = await repo.createEtablissement(e);

      // ✅ Si la création réussit, on recharge la liste automatiquement
      if (id != null && id.isNotEmpty) {
        await fetchEtablissementsByOwner(e.idOwner!);
        print('✅ Liste des établissements rechargée après création.');
      }

      return id;
    } catch (err, stack) {
      _logError('création', err, stack);
      return null;
    }
  }

  // Mettre à jour un établissement
  Future<bool> updateEtablissement(String? id, Map<String, dynamic> data) async {
    try {
      if (!_isUserGerant()) {
        _logError('mise à jour',
            'Permission refusée : seul un Gérant peut modifier un établissement');
        return false;
      }

      final success = await repo.updateEtablissement(id, data);
      return success;
    } catch (e, stack) {
      _logError('mise à jour', e, stack);
      return false;
    }
  }
/*
  // Dans EtablissementController
Future<bool> updateEtablissementWithData(
  String id, {
  required String name,
  required String address,
  double? latitude,
  double? longitude,
}) async {
  try {
    if (!_isUserGerant()) {
      _logError('mise à jour', 'Permission refusée');
      return false;
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'address': address.trim(),
    };

    // Ajouter les coordonnées si renseignées
    if (latitude != null) {
      updateData['latitude'] = latitude;
    }
    if (longitude != null) {
      updateData['longitude'] = longitude;
    }

    final success = await repo.updateEtablissement(id, updateData);
    
    if (success) {
      await fetchUserEtablissements(); // Rafraîchir les données
    }
    
    return success;
  } catch (e, stack) {
    _logError('mise à jour', e, stack);
    return false;
  }
}
// Dans EtablissementController
Future<void> fetchUserEtablissements() async {
  try {
    final user = userController.user.value;
    if (user.id.isNotEmpty) {
      // Cette méthode va rafraîchir les données en cache
      await getMonEtablissement();
    }
  } catch (e) {
    _logError('rafraîchissement établissements', e);
  }
}*/
  // Méthode pour changer le statut d'un établissement (pour Admin)
  Future<bool> changeStatutEtablissement(String id, StatutEtablissement newStatut) async {
    try {
      if (!_isUserAdmin()) {
        _logError('changement statut', 'Permission refusée : Admin requis');
        return false;
      }

      final success = await repo.changeStatut(id, newStatut);

      if (success) {
        // Rafraîchir la liste des établissements
        await getTousEtablissements();
        showSuccessSnackbar('Statut mis à jour avec succès');
      } else {
        showErrorSnackbar('Échec de la mise à jour du statut');
      }

      return success;
    } catch (e, stack) {
      _logError('changement statut', e, stack);
      showErrorSnackbar('Erreur lors du changement de statut: $e');
      return false;
    }
  }
  // Ajouter des horaires à un établissement existant
  Future<bool> addHorairesToEtablissement(
      String etablissementId, List<Horaire> horaires) async {
    try {
      if (!_isUserGerant()) {
        _logError('ajout horaires', 'Permission refusée');
        return false;
      }
      await repo.addHorairesToEtablissement(etablissementId, horaires);
      return true;
    } catch (e, stack) {
      _logError('ajout horaires', e, stack);
      return false;
    }
  }

  // Récupérer les établissements d'un propriétaire
  Future<List<Etablissement>?> fetchEtablissementsByOwner(
      String ownerId) async {
    try {
      final data = await repo.getEtablissementsByOwner(ownerId);
      etablissements.assignAll(data); //  mise à jour automatique de la liste
      return data;
    } catch (e, stack) {
      _logError('récupération', e, stack);
      return null;
    }
  }

  // Récupérer l'établissement du gérant connecté
  Future<Etablissement?> getMonEtablissement() async {
    try {
      final userRole = userController.userRole;
      if (userRole.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      final user = userController.user.value;
      if (user.id.isEmpty) {
        _logError('récupération établissement', 'Utilisateur non connecté');
        return null;
      }

      final etablissements = await repo.getEtablissementsByOwner(user.id);
      return etablissements.isNotEmpty ? etablissements.first : null;
    } catch (e, stack) {
      _logError('récupération établissement', e, stack);
      return null;
    }
  }

  /// 2. Pour Admin - tous les établissements (liste complète)
  Future<List<Etablissement>> getTousEtablissements() async {
    try {
      final userRole = userController.userRole;
      if (userRole.isEmpty || userRole != 'Admin') {
        return [];
      }

      return await repo.getAllEtablissements();
    } catch (e, stack) {
      _logError('récupération établissements', e, stack);
      return [];
    }
  }

  Future<bool> deleteEtablissement(String id) async {
    try {
      if (!_isUserGerant()) {
        _logError('suppression',
            'Permission refusée : seul un Gérant peut supprimer un établissement');
        return false;
      }
      await repo.deleteEtablissement(id);
      return true;
    } catch (e, stack) {
      _logError('suppression', e, stack);
      return false;
    }
  }
// Méthode pour récupérer un établissement par son ID
  Future<Etablissement?> getEtablissementById(String id) async {
    try {
      final tousEtablissements = await getTousEtablissements();
      return tousEtablissements.firstWhereOrNull((etab) => etab.id == id);
    } catch (e) {
      _logError('récupération par ID', e);
      return null;
    }
  }

  bool _isUserGerant() {
    final userRole = userController.userRole;
    if (userRole.isEmpty) {
      _logError('vérification rôle', 'Utilisateur non connecté');
      return false;
    }
    if (userRole != 'Gérant') {
      _logError(
          'vérification rôle', 'Rôle insuffisant. Rôle actuel: $userRole');
      return false;
    }
    return true;
  }

  // Méthode utilitaire pour vérifier si l'utilisateur est admin
  bool _isUserAdmin() {
    final userRole = userController.userRole; //  Utilise le getter userRole
    print('Rôle utilisateur détecté: $userRole');

    if (userRole.isEmpty) {
      _logError('vérification admin', 'Utilisateur non connecté');
      return false;
    }

    // Vérifie si le rôle est "Admin" (avec majuscule comme dans votre UserModel)
    final isAdmin = userRole == 'Admin';
    print('Est admin: $isAdmin');

    return isAdmin;
  }



  void showSuccessSnackbar(String message) {
    Get.snackbar(
      "Succès",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  void showErrorSnackbar(String error) {
    Get.snackbar(
      "Erreur",
      error,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void _logError(String action, Object error, [StackTrace? stack]) {
    print('Erreur lors de la $action de l\'établissement : $error');
    if (stack != null) {
      print(stack);
    }
  }
}
