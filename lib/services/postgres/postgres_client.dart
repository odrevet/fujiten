import 'package:dio/dio.dart';

/// Thin client for the Supabase PostgREST API.
///
/// Queries the REST endpoint exposed by Supabase using the publishable
/// (anon) key and an `Accept-Profile` header to select the schema
/// (`expression` or `kanji`).
class PostgresClient {
  final String url;
  final String anonKey;
  final String schema;

  late final Dio _dio;

  PostgresClient({
    required this.url,
    required this.anonKey,
    required this.schema,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$url/rest/v1',
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Accept-Profile': schema,
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Runs a GET query against [table] with the given PostgREST parameters
  /// (e.g. `select`, `limit`, `offset`, `order`, column filters).
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> params,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/$table',
      queryParameters: params,
    );
    return response.data?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Returns the total number of rows matching [params] using the
  /// `Prefer: count=exact` header.
  Future<int> count(String table, Map<String, dynamic> params) async {
    final response = await _dio.get<List<dynamic>>(
      '/$table',
      queryParameters: params,
      options: Options(
        headers: {'Prefer': 'count=exact'},
        responseType: ResponseType.plain,
      ),
    );
    final contentRange = response.headers.value('content-range') ?? '';
    final match = RegExp(r'/(\d+)$').firstMatch(contentRange);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  /// Tests the connection by querying a single row from [table].
  Future<bool> testConnection(String table) async {
    try {
      await query(table, {'select': '*', 'limit': 1});
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _dio.close(force: true);
  }
}
