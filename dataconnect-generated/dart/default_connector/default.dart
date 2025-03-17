library default_connector;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultConnector {
  DefaultConnector();

  static DefaultConnector get instance {
    return DefaultConnector();
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Methods to query/write data
  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await firestore.collection(collection).add(data);
  }

  Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    final snapshot = await firestore.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Add more methods as needed
}

