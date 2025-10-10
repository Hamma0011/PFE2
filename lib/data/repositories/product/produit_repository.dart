import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/produit_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class ProduitRepository extends GetxController {
  static ProduitRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'produits';

  /// Charger tous les produits
  Future<List<ProduitModel>> getAllProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits : $e';
    }
  }

  /// Récupérer un produit par son ID
  Future<ProduitModel?> getProductById(String productId) async {
    try {
      final response =
          await _db.from(_table).select('*').eq('id', productId).single();

      return ProduitModel.fromMap(response);
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération du produit : $e';
    }
  }

  /// Récupérer les produits d'un établissement
  Future<List<ProduitModel>> getProductsByEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .eq('etablissement_id', etablissementId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de l\'établissement : $e';
    }
  }

  /// Récupérer les produits d'une catégorie
  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .eq('categorie_id', categoryId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de la catégorie : $e';
    }
  }

  /// Ajouter un nouveau produit
  Future<void> addProduct(ProduitModel produit) async {
    try {
      await _db.from(_table).insert(produit.toJson());
      // Pas besoin de vérifier error → si ça échoue, une exception sera levée
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      print(e);
      throw 'Erreur lors de l\'ajout du produit : $e';
    }
  }

  /// Modifier un produit
  Future<void> updateProduct(ProduitModel produit) async {
    try {
      await _db.from(_table).update(produit.toJson()).eq('id', produit.id);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la mise à jour du produit : $e';
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.from(_table).delete().eq('id', productId);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la suppression du produit : $e';
    }
  }

  /// Uploader une image de produit
  Future<String> uploadProductImage(File imageFile) async {
    try {
      final fileName = 'produit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = 'produits';

      // Upload vers le bucket "produits"
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(fileName, imageFile);

      // Récupérer l'URL publique
      final publicUrl =
          Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload de l\'image : $e';
    }
  }
}
