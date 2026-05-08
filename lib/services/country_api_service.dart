// lib/services/country_api_service.dart
// Dedicated API service class — ALL HTTP logic lives here.
// No screen or widget file imports this package directly.
//
// Implements the requirements from Section 4.3:
//   • private _baseUrl, _timeout, _headers
//   • private _checkResponse() that throws ApiException for non-200
//   • one method per endpoint, all returning typed Futures

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/country.dart';
import 'api_exception.dart';

class CountryApiService {
  // ── Private configuration ──────────────────────────────────────────────────

  /// Base host for all RestCountries v3.1 requests.
  final String _baseUrl = 'restcountries.com';

  /// Base path prefix used on every request.
  final String _basePath = '/v3.1';

  /// 10-second timeout applied to every HTTP call (assignment requirement).
  final Duration _timeout = const Duration(seconds: 10);

  /// Shared headers sent with every request.
  final Map<String, String> _headers = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Throws [ApiException] when the server returns a non-200 status code.
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _statusMessage(response.statusCode),
      );
    }
  }

  /// Returns a human-readable message for a given HTTP status code.
  String _statusMessage(int code) {
    switch (code) {
      case 400:
        return 'Bad request. Please check your input.';
      case 404:
        return 'Country not found (404).';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error (500). Try again later.';
      default:
        return 'Unexpected server response (HTTP $code).';
    }
  }

  // ── Public API methods ─────────────────────────────────────────────────────

  /// Fetches ALL countries with only the fields needed for the home screen.
  ///
  /// Endpoint: GET /v3.1/all?fields=name,flag,region,population
  /// Returns: `Future<List<Country>>`
  Future<List<Country>> fetchAllCountries() async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/all',
      {'fields': 'name,flag,region,population,cca3'},
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Searches countries by name.
  ///
  /// Endpoint: GET /v3.1/name/{name}
  /// Returns: `Future<List<Country>>`
  Future<List<Country>> searchByName(String name) async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/name/$name',
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single country's full details by its ISO alpha-3 code.
  ///
  /// Endpoint: GET /v3.1/alpha/{code}
  /// Returns: `Future<Country>`
  Future<Country> fetchByCode(String code) async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/alpha/$code',
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    _checkResponse(response);

    // The /alpha endpoint returns a JSON array with one element.
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) {
      throw ApiException(
        statusCode: 404,
        message: 'Country not found (HTTP 404).',
      );
    }
    return Country.fromJson(data.first as Map<String, dynamic>);
  }
}
