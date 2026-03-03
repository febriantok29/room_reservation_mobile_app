import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';

/// Halaman untuk melihat data collection Firebase (Admin only)
/// Layout 1:2 - Kiri: List collection, Kanan: Detail data
class DatabaseViewerPage extends StatefulWidget {
  final Profile user;

  const DatabaseViewerPage({super.key, required this.user});

  @override
  State<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  final _firestore = FirebaseFirestore.instance;

  // Collections yang akan ditampilkan
  final List<CollectionInfo> _collections = [
    CollectionInfo(
      name: 's_users',
      displayName: 'Users',
      icon: Icons.people,
      color: Colors.blue,
    ),
    CollectionInfo(
      name: 'm_rooms',
      displayName: 'Rooms',
      icon: Icons.meeting_room,
      color: Colors.green,
    ),
    CollectionInfo(
      name: 't_reservations',
      displayName: 'Reservations',
      icon: Icons.event,
      color: Colors.orange,
    ),
  ];

  String? _selectedCollection;
  List<Map<String, dynamic>> _collectionData = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Database Viewer'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export All Collections',
            onSelected: _handleExportAll,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 8),
                    Text('Export All as JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export All as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mysql',
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 20),
                    SizedBox(width: 8),
                    Text('Export All as MySQL'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Collection List (1/3)
          Expanded(flex: 1, child: _buildCollectionList()),
          const VerticalDivider(width: 1),
          // Right side - Collection Data (2/3)
          Expanded(flex: 2, child: _buildCollectionData()),
        ],
      ),
    );
  }

  Widget _buildCollectionList() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Text(
              'Collections',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                final collection = _collections[index];
                final isSelected = _selectedCollection == collection.name;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: collection.color.withValues(alpha: 0.1),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: collection.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(collection.icon, color: collection.color),
                  ),
                  title: Text(
                    collection.displayName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(collection.name),
                  onTap: () => _loadCollectionData(collection.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionData() {
    if (_selectedCollection == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih collection untuk melihat data',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCollectionData(_selectedCollection!),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_collectionData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data di collection ini',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedCollection!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_collectionData.length} records',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _collectionData.length,
            itemBuilder: (context, index) {
              final data = _collectionData[index];
              return _buildDataCard(data, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        title: Text(
          'Document #${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ID: ${data['id'] ?? 'N/A'}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatValue(entry.value),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Timestamp) {
      return value.toDate().toString();
    }
    if (value is DocumentReference) {
      return 'Reference: ${value.path}';
    }
    if (value is List) {
      return value.toString();
    }
    if (value is Map) {
      return JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  Future<void> _loadCollectionData(String collectionName) async {
    setState(() {
      _selectedCollection = collectionName;
      _isLoading = true;
      _errorMessage = '';
      _collectionData = [];
    });

    try {
      final snapshot = await _firestore.collection(collectionName).get();

      final data = snapshot.docs.map((doc) {
        final map = doc.data();
        map['id'] = doc.id; // Add document ID
        return map;
      }).toList();

      setState(() {
        _collectionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExportAll(String format) async {
    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading all collections...'),
          ],
        ),
      ),
    );

    try {
      // Fetch all collections data
      final allData = <String, List<Map<String, dynamic>>>{};

      for (final collection in _collections) {
        final snapshot = await _firestore.collection(collection.name).get();
        final data = snapshot.docs.map((doc) {
          final map = doc.data();
          map['id'] = doc.id;
          return map;
        }).toList();
        allData[collection.name] = data;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Confirm export
      final totalRecords = allData.values.fold(
        0,
        (total, list) => total + list.length,
      );
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export All Data'),
          content: Text(
            'Export $totalRecords records from ${_collections.length} collections as ${format.toUpperCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      String exportedData;

      switch (format) {
        case 'json':
          exportedData = _exportAllAsJson(allData);
          break;
        case 'csv':
          exportedData = _exportAllAsCsv(allData);
          break;
        case 'mysql':
          exportedData = _exportAllAsMysql(allData);
          break;
        default:
          return;
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: exportedData));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported $totalRecords records from ${_collections.length} collections as $format!\nCopied to clipboard.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if still open

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _exportAllAsJson(Map<String, List<Map<String, dynamic>>> allData) {
    final export = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalCollections': allData.length,
      'totalRecords': allData.values.fold(
        0,
        (total, list) => total + list.length,
      ),
      'collections': allData.map(
        (collection, data) => MapEntry(collection, {
          'name': collection,
          'recordCount': data.length,
          'data': data,
        }),
      ),
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  String _exportAllAsCsv(Map<String, List<Map<String, dynamic>>> allData) {
    final lines = <String>[];

    lines.add('# Exported from Database Viewer');
    lines.add('# Exported at: ${DateTime.now()}');
    lines.add('# Total collections: ${allData.length}');
    lines.add(
      '# Total records: ${allData.values.fold(0, (total, list) => total + list.length)}',
    );
    lines.add('');

    for (final entry in allData.entries) {
      final collectionName = entry.key;
      final data = entry.value;

      if (data.isEmpty) continue;

      lines.add('');
      lines.add('# ========================================');
      lines.add('# Collection: $collectionName (${data.length} records)');
      lines.add('# ========================================');

      // Get all unique keys
      final keys = <String>{};
      for (final item in data) {
        keys.addAll(item.keys);
      }
      final keysList = keys.toList()..sort();

      // Header
      lines.add(keysList.map((k) => '"$k"').join(','));

      // Data rows
      for (final item in data) {
        final row = keysList
            .map((key) {
              final value = item[key];
              final formatted = _formatValueForCsv(value);
              return '"${formatted.replaceAll('"', '""')}"';
            })
            .join(',');
        lines.add(row);
      }
    }

    return lines.join('\n');
  }

  String _exportAllAsMysql(Map<String, List<Map<String, dynamic>>> allData) {
    final lines = <String>[];

    lines.add('-- =====================================================');
    lines.add('-- MySQL dump for all collections');
    lines.add('-- Total collections: ${allData.length}');
    lines.add(
      '-- Total records: ${allData.values.fold<int>(0, (total, list) => total + list.length)}',
    );
    lines.add('-- Generated: ${DateTime.now()}');
    lines.add('-- =====================================================');
    lines.add('');

    for (final entry in allData.entries) {
      final collectionName = entry.key;
      final data = entry.value;

      if (data.isEmpty) continue;

      final tableName = collectionName.replaceAll('-', '_');

      lines.add('');
      lines.add('-- =====================================================');
      lines.add('-- Collection: $collectionName');
      lines.add('-- Records: ${data.length}');
      lines.add('-- =====================================================');

      // Get all unique keys
      final keys = <String>{};
      for (final item in data) {
        keys.addAll(item.keys);
      }
      final keysList = keys.toList()..sort();

      lines.add('DROP TABLE IF EXISTS `$tableName`;');
      lines.add('');
      lines.add('CREATE TABLE `$tableName` (');

      final columns = keysList.map((key) => '  `$key` TEXT').join(',\n');
      lines.add(columns);
      lines.add(');');
      lines.add('');

      // Build INSERT statements
      for (final item in data) {
        final values = keysList
            .map((key) {
              final value = item[key];
              return _formatValueForMysql(value);
            })
            .join(', ');

        final columnsStr = keysList.map((k) => '`$k`').join(', ');
        lines.add('INSERT INTO `$tableName` ($columnsStr) VALUES ($values);');
      }
    }

    return lines.join('\n');
  }

  String _formatValueForCsv(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is List || value is Map) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  String _formatValueForMysql(dynamic value) {
    if (value == null) return 'NULL';
    if (value is Timestamp) {
      return "'${value.toDate().toIso8601String()}'";
    }
    if (value is DocumentReference) {
      return "'${value.path}'";
    }
    if (value is String) {
      final escaped = value.replaceAll("'", "''");
      return "'$escaped'";
    }
    if (value is num) {
      return value.toString();
    }
    if (value is bool) {
      return value ? '1' : '0';
    }
    if (value is List || value is Map) {
      final json = jsonEncode(value).replaceAll("'", "''");
      return "'$json'";
    }
    return "'${value.toString().replaceAll("'", "''")}'";
  }
}

class CollectionInfo {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;

  CollectionInfo({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}
