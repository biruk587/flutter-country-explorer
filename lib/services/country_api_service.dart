import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/country.dart';
import 'api_exception.dart';

class CountryApiService {
  final String _baseUrl = 'restcountries.com';
  final String _basePath = '/v3.1';
  final Duration _timeout = const Duration(seconds: 10);
  final Map<String, String> _headers = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _statusMessage(response.statusCode),
      );
    }
  }

  String _statusMessage(int code) {
    switch (code) {
      case 400:
        return 'Bad request.';
      case 404:
        return 'Country not found (404).';
      case 429:
        return 'Too many requests. Please wait.';
      case 500:
        return 'Server error (500). Try again later.';
      default:
        return 'Unexpected server response (HTTP $code).';
    }
  }

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

  Future<List<Country>> searchByName(String name) async {
    final uri = Uri.https(_baseUrl, '$_basePath/name/$name');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    _checkResponse(response);

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Country> fetchByCode(String code) async {
    final uri = Uri.https(_baseUrl, '$_basePath/alpha/$code');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    _checkResponse(response);

    // /alpha returns an array with one element
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) {
      throw ApiException(statusCode: 404, message: 'Country not found.');
    }
    return Country.fromJson(data.first as Map<String, dynamic>);
  }
}
