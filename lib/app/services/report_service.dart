import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';

class ReportService {
  Future<Map<String, dynamic>> fetchReport(
    String routeKey,
    Map<String, dynamic> filters,
  ) async {
    final response = await RouteBuilder(
      routeKey,
      queries: {..._cleanFilters(filters), 'format': 'json'},
    ).get();

    if (response is! Map<String, dynamic> || response['success'] != true) {
      final message = response is Map ? response['message'] : null;
      throw message?.toString() ?? 'Gagal memuat laporan';
    }

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw 'Format data laporan tidak valid';
    }

    return data;
  }

  Future<File> downloadReport({
    required String routeKey,
    required Map<String, dynamic> filters,
    required String format,
  }) async {
    final dir = await getTemporaryDirectory();
    final ext = format == 'excel' ? 'xlsx' : 'pdf';
    final reportSlug = routeKey.split('.').last;
    final fileName = 'laporan-$reportSlug-${_todayCompact()}.$ext';
    final savePath = '${dir.path}/$fileName';

    return RouteBuilder(
      routeKey,
      queries: {..._cleanFilters(filters), 'format': format},
    ).downloadFileToPath(savePath: savePath);
  }

  Map<String, dynamic> _cleanFilters(Map<String, dynamic> filters) {
    final cleaned = <String, dynamic>{};
    filters.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) cleaned[key] = value;
    });
    return cleaned;
  }

  String _todayCompact() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
}
