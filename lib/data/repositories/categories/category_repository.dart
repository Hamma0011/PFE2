import 'dart:io';

import 'package:caferesto/utils/exceptions/supabase_exception.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/category_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../upload/upload_categories.dart';

class CategoryRepository extends GetxController {
  static CategoryRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'categories';

  /// Charger toutes les categories
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response =
          await _db.from(_table).select().order('name', ascending: true);
      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des catégories : $e';
    }
  }

  /// Charger sous-categories
  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .eq('parentId', categoryId)
          .order('name', ascending: true);
      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des catégories : ${e.toString()}';
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _db.from(_table).insert(category.toJson());
      // Pas besoin de vérifier error → si ça échoue, une exception sera levée
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      print(e);
      throw 'Erreur lors ajout categorie : $e';
    }
  }
  Future<void> uploadDummyCategories() async {
    try {
      final categories = UploadCategories.dummyCategories;
      final insertData =
      categories.map((category) => category.toJson()).toList();

      await _db.from(_table).insert(insertData);
      // Idem : pas besoin de response.error
    } on PostgrestException catch (e) {
      throw 'DB Error: ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Quelque chose s\'est mal passé ! Veuillez réessayer.';
    }
  }
  Future<String> uploadCategoryImage(File imageFile) async {
    try {
      final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = 'categories';

      // Upload vers le bucket "categories"
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(fileName, imageFile);

      // Récupérer l’URL publique
      final publicUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw 'Erreur lors de l’upload de l’image : $e';
    }
  }
  /// Modifier une catégorie
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _db
          .from(_table)
          .update(category.toJson())
          .eq('id', category.id);

    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Erreur lors de la mise à jour de la catégorie : $e';
    }
  }

  /// Supprimer une catégorie
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _db.from(_table).delete().eq('id', categoryId);

    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Erreur lors de la suppression de la catégorie : $e';
    }
  }



}
