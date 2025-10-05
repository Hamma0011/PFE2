import 'package:get/get.dart';
import '../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/etablissement_model.dart';
import '../models/horaire_model.dart';
import '../models/statut_etablissement_model.dart';

class EtablissementController extends GetxController {
  final EtablissementRepository repo;
  final UserController userController = Get.find<UserController>();

  EtablissementController(this.repo);

  // Méthode pour créer un établissement SANS horaires
  Future<String?> createEtablissement(Etablissement e) async {
    try {
      if (!_isUserGerant()) {
        _logError('création', 'Permission refusée : seul un Gérant peut créer un établissement');
        return null;
      }
      return await repo.createEtablissement(e);
    } catch (e, stack) {
      _logError('création', e, stack);
      return null;
    }
  }

  // Mettre à jour un établissement
  Future<bool> updateEtablissement(String id, Map<String, dynamic> data) async {
    try {
      if (!_isUserGerant()) {
        _logError('mise à jour', 'Permission refusée : seul un Gérant peut modifier un établissement');
        return false;
      }

      final success = await repo.updateEtablissement(id, data);
      return success;
    } catch (e, stack) {
      _logError('mise à jour', e, stack);
      return false;
    }
  }

  // Ajouter des horaires à un établissement existant
  Future<bool> addHorairesToEtablissement(String etablissementId, List<Horaire> horaires) async {
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
  Future<List<Etablissement>?> fetchEtablissementsByOwner(String ownerId) async {
    try {
      return await repo.getEtablissementsByOwner(ownerId);
    } catch (e, stack) {
      _logError('récupération', e, stack);
      return null;
    }
  }

  // Récupérer l'établissement du gérant connecté
  Future<Etablissement?> getMonEtablissement() async {
    try {
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

  Future<bool> deleteEtablissement(String id) async {
    try {
      if (!_isUserGerant()) {
        _logError('suppression', 'Permission refusée : seul un Gérant peut supprimer un établissement');
        return false;
      }
      await repo.deleteEtablissement(id);
      return true;
    } catch (e, stack) {
      _logError('suppression', e, stack);
      return false;
    }
  }

  Future<bool> approveEtablissement(String id) async {
    return _changeStatut(id, StatutEtablissement.approuve);
  }

  Future<bool> rejectEtablissement(String id) async {
    return _changeStatut(id, StatutEtablissement.rejete);
  }

  // Méthode privée pour éviter la duplication
  Future<bool> _changeStatut(String id, StatutEtablissement statut) async {
    try {
      if (!_isUserGerant()) {
        final action = statut == StatutEtablissement.approuve ? 'approbation' : 'rejet';
        _logError(action, 'Permission refusée : rôle insuffisant');
        return false;
      }
      await repo.changeStatut(id, statut);
      return true;
    } catch (e, stack) {
      final action = statut == StatutEtablissement.approuve ? 'approbation' : 'rejet';
      _logError(action, e, stack);
      return false;
    }
  }

  bool _isUserGerant() {
    final user = userController.user.value;
    if (user.id.isEmpty) {
      _logError('vérification rôle', 'Utilisateur non connecté');
      return false;
    }
    if (user.role != 'Gérant') {
      _logError('vérification rôle', 'Rôle insuffisant. Rôle actuel: ${user.role}');
      return false;
    }
    return true;
  }

  void _logError(String action, Object error, [StackTrace? stack]) {
    print('Erreur lors de la $action de l\'établissement : $error');
    if (stack != null) {
      print(stack);
    }
  }
}