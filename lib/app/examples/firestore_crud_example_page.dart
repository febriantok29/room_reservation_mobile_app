// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';

/// Contoh penggunaan FirestoreClient
///
/// Contoh ini menunjukkan bagaimana menggunakan FirestoreClient untuk:
/// 1. Membuat dokumen baru
/// 2. Membaca dokumen (get dan query)
/// 3. Mengubah dokumen
/// 4. Menghapus dokumen
/// 5. Batch operation
/// 6. Transaction
class FirestoreCrudExamplePage extends StatefulWidget {
  const FirestoreCrudExamplePage({Key? key}) : super(key: key);

  @override
  State<FirestoreCrudExamplePage> createState() =>
      _FirestoreCrudExamplePageState();
}

class _FirestoreCrudExamplePageState extends State<FirestoreCrudExamplePage> {
  // Client untuk collection 'examples'
  late final Future<FirestoreClient> _firestoreClient = FirestoreClient.create(
    'examples',
  );

  // Status dan hasil operasi
  bool _isLoading = false;
  String _statusMessage = '';
  String _operationResult = '';

  // Text controllers
  final _documentIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Document IDs dari create operation untuk contoh
  final List<String> _createdDocumentIds = [];

  @override
  void initState() {
    super.initState();
    _initFirestore();
  }

  /// Inisialisasi Firestore
  Future<void> _initFirestore() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Menginisialisasi Firestore...';
    });

    try {
      await _firestoreClient;
      setState(() {
        _statusMessage = 'Firestore berhasil diinisialisasi';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Create
  /// Membuat dokumen baru di collection 'examples'
  Future<void> _createDocument() async {
    if (!mounted) return;

    // Validasi input
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Title dan description harus diisi';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Membuat dokumen baru...';
      });
    }

    try {
      final client = await _firestoreClient;

      // Data untuk dokumen baru
      final data = {
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'tags': ['example', 'crud'],
        'status': 'active',
      };

      // Tambahkan dokumen dengan ID otomatis
      final docRef = await client.add(data);
      final documentId = docRef.id;

      // Simpan ID untuk contoh selanjutnya
      _createdDocumentIds.add(documentId);

      if (mounted) {
        setState(() {
          _statusMessage = 'Dokumen berhasil dibuat';
          _operationResult = 'Created document with ID: $documentId';
          _documentIdController.text = documentId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error creating document: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// CRUD: Create with specific ID
  /// Membuat dokumen dengan ID spesifik
  Future<void> _createDocumentWithId() async {
    // Validasi input
    final documentId = _documentIdController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (documentId.isEmpty || title.isEmpty || description.isEmpty) {
      setState(() {
        _statusMessage = 'Document ID, title, dan description harus diisi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Membuat dokumen dengan ID $documentId...';
    });

    try {
      final client = await _firestoreClient;

      // Data untuk dokumen baru
      final data = {
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'tags': ['example', 'custom-id'],
        'status': 'active',
      };

      // Set dokumen dengan ID spesifik
      await client.set(documentId, data);

      // Simpan ID untuk contoh selanjutnya
      if (!_createdDocumentIds.contains(documentId)) {
        _createdDocumentIds.add(documentId);
      }

      setState(() {
        _statusMessage = 'Dokumen berhasil dibuat dengan ID $documentId';
        _operationResult = 'Created document with custom ID: $documentId';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Read
  /// Membaca dokumen dengan ID spesifik
  Future<void> _getDocument() async {
    // Validasi input
    final documentId = _documentIdController.text.trim();

    if (documentId.isEmpty) {
      setState(() {
        _statusMessage = 'Document ID harus diisi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengambil dokumen dengan ID $documentId...';
    });

    try {
      final client = await _firestoreClient;

      // Get dokumen
      final docSnapshot = await client.get(documentId);

      if (!docSnapshot.exists) {
        setState(() {
          _statusMessage = 'Dokumen dengan ID $documentId tidak ditemukan';
          _operationResult = 'Document not found';
        });
        return;
      }

      // Data dokumen
      final data = docSnapshot.data() as Map<String, dynamic>;

      setState(() {
        _statusMessage = 'Dokumen berhasil diambil';
        _operationResult = 'Document data: $data';

        // Update form fields
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Read All
  /// Membaca semua dokumen di collection
  Future<void> _getAllDocuments() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengambil semua dokumen...';
    });

    try {
      final client = await _firestoreClient;

      // Get semua dokumen
      final querySnapshot = await client.getAll();

      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      setState(() {
        _statusMessage = 'Berhasil mengambil ${documents.length} dokumen';
        _operationResult = 'All documents: $documents';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting documents: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Query
  /// Query dokumen dengan status 'active'
  Future<void> _queryDocuments() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Querying documents with status=active...';
    });

    try {
      final client = await _firestoreClient;

      // Query dokumen
      final querySnapshot = await client.query(
        field: 'status',
        isEqualTo: 'active',
      );

      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      setState(() {
        _statusMessage = 'Berhasil query ${documents.length} dokumen';
        _operationResult = 'Query results: $documents';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error querying documents: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Advanced Query
  /// Advanced query dengan multiple conditions
  Future<void> _advancedQuery() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running advanced query...';
    });

    try {
      final client = await _firestoreClient;

      // Advanced query dengan multiple conditions
      final querySnapshot = await client.advancedQuery(
        conditions: [
          QueryCondition(field: 'status', isEqualTo: 'active'),
          QueryCondition(field: 'tags', arrayContains: 'example'),
        ],
        orderBy: 'createdAt',
        descending: true,
        limit: 5,
      );

      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      setState(() {
        _statusMessage = 'Advanced query berhasil: ${documents.length} dokumen';
        _operationResult = 'Advanced query results: $documents';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in advanced query: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Update
  /// Update dokumen dengan ID spesifik
  Future<void> _updateDocument() async {
    // Validasi input
    final documentId = _documentIdController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (documentId.isEmpty || title.isEmpty || description.isEmpty) {
      setState(() {
        _statusMessage = 'Document ID, title, dan description harus diisi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating document $documentId...';
    });

    try {
      final client = await _firestoreClient;

      // Data untuk update
      final data = {
        'title': title,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update dokumen
      await client.update(documentId, data);

      setState(() {
        _statusMessage = 'Dokumen berhasil diupdate';
        _operationResult = 'Updated document: $documentId';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRUD: Delete
  /// Delete dokumen dengan ID spesifik
  Future<void> _deleteDocument() async {
    // Validasi input
    final documentId = _documentIdController.text.trim();

    if (documentId.isEmpty) {
      setState(() {
        _statusMessage = 'Document ID harus diisi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting document $documentId...';
    });

    try {
      final client = await _firestoreClient;

      // Delete dokumen
      await client.delete(documentId);

      // Remove from created documents list
      _createdDocumentIds.remove(documentId);

      setState(() {
        _statusMessage = 'Dokumen berhasil dihapus';
        _operationResult = 'Deleted document: $documentId';
        _documentIdController.clear();
        _titleController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error deleting document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Batch Operation Example
  /// Menunjukkan cara melakukan batch operation
  Future<void> _batchOperation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running batch operation...';
    });

    try {
      final client = await _firestoreClient;

      // Generate random IDs for batch
      final batchId1 = 'batch-${DateTime.now().millisecondsSinceEpoch}-1';
      final batchId2 = 'batch-${DateTime.now().millisecondsSinceEpoch}-2';

      // Batch operations
      await client.batch(
        operations: [
          // Create first document
          BatchOperation.set(batchId1, {
            'title': 'Batch Create 1',
            'description': 'Created in batch',
            'createdAt': FieldValue.serverTimestamp(),
          }),

          // Create second document
          BatchOperation.set(batchId2, {
            'title': 'Batch Create 2',
            'description': 'Created in batch',
            'createdAt': FieldValue.serverTimestamp(),
          }),

          // If we have any created documents, update the first one
          if (_createdDocumentIds.isNotEmpty)
            BatchOperation.update(_createdDocumentIds.first, {
              'updatedInBatch': true,
              'batchUpdateTime': FieldValue.serverTimestamp(),
            }),
        ],
      );

      // Add batch IDs to created docs list
      _createdDocumentIds.add(batchId1);
      _createdDocumentIds.add(batchId2);

      setState(() {
        _statusMessage = 'Batch operation berhasil';
        _operationResult = 'Created documents with IDs: $batchId1, $batchId2';

        // Update document ID field to show one of the created docs
        _documentIdController.text = batchId1;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in batch operation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Transaction Example
  /// Menunjukkan cara melakukan transaction
  Future<void> _transactionExample() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running transaction...';
    });

    try {
      final client = await _firestoreClient;

      // Transaction needs at least one document to work with
      if (_createdDocumentIds.isEmpty) {
        setState(() {
          _statusMessage = 'Tidak ada dokumen yang tersedia untuk transaction';
          _operationResult = 'Create at least one document first';
        });
        return;
      }

      final documentId = _createdDocumentIds.first;
      final transactionId = 'trans-${DateTime.now().millisecondsSinceEpoch}';

      // Run transaction
      final result = await client.transaction<String>((transaction) async {
        // Read the document first
        final docRef = client.document(documentId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Document does not exist');
        }

        // Read current data
        final data = snapshot.data() as Map<String, dynamic>;
        final currentTitle = data['title'] as String? ?? 'No title';

        // Create a new document in the transaction
        final newDocRef = client.document(transactionId);
        transaction.set(newDocRef, {
          'title': 'Transaction Example',
          'description': 'Created in transaction',
          'sourceDocument': documentId,
          'sourceName': currentTitle,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update the original document
        transaction.update(docRef, {
          'transactionUpdated': true,
          'transactionTime': FieldValue.serverTimestamp(),
          'relatedTransactionDoc': transactionId,
        });

        return 'Transaction completed: Created $transactionId and updated $documentId';
      });

      // Add transaction ID to created docs list
      _createdDocumentIds.add(transactionId);

      setState(() {
        _statusMessage = 'Transaction berhasil';
        _operationResult = result;
        _documentIdController.text = transactionId;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in transaction: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clear form dan status
  void _clearForm() {
    setState(() {
      _documentIdController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _operationResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore CRUD Example')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status message
                  if (_statusMessage.isNotEmpty)
                    Container(
                      color: Colors.blue.shade50,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Form
                  Text(
                    'Document Form',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _documentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Document ID (otomatis untuk create)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CRUD Buttons
                  Text(
                    'CRUD Operations',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _createDocument,
                        child: const Text('Create'),
                      ),
                      ElevatedButton(
                        onPressed: _createDocumentWithId,
                        child: const Text('Create with ID'),
                      ),
                      ElevatedButton(
                        onPressed: _getDocument,
                        child: const Text('Get'),
                      ),
                      ElevatedButton(
                        onPressed: _updateDocument,
                        child: const Text('Update'),
                      ),
                      ElevatedButton(
                        onPressed: _deleteDocument,
                        child: const Text('Delete'),
                      ),
                      ElevatedButton(
                        onPressed: _clearForm,
                        child: const Text('Clear Form'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Query Buttons
                  Text(
                    'Query Operations',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _getAllDocuments,
                        child: const Text('Get All'),
                      ),
                      ElevatedButton(
                        onPressed: _queryDocuments,
                        child: const Text('Simple Query'),
                      ),
                      ElevatedButton(
                        onPressed: _advancedQuery,
                        child: const Text('Advanced Query'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Batch and Transaction Buttons
                  Text(
                    'Advanced Operations',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _batchOperation,
                        child: const Text('Batch Operation'),
                      ),
                      ElevatedButton(
                        onPressed: _transactionExample,
                        child: const Text('Transaction'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Created Document IDs
                  if (_createdDocumentIds.isNotEmpty) ...[
                    Text(
                      'Created Document IDs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _createdDocumentIds
                            .map((id) => Text(id))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Operation Result
                  if (_operationResult.isNotEmpty) ...[
                    Text(
                      'Operation Result',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.green.shade50,
                      child: Text(_operationResult),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _documentIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
