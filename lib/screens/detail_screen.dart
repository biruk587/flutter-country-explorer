// lib/screens/detail_screen.dart
// Detail screen — shows full details of a selected country.
// Fetches data by ISO alpha-3 code via GET /alpha/{code}.
//
// Fields displayed: capital, population, currencies, languages,
//                   area, timezones (all required by Track A spec).
//
// Uses FutureBuilder<Country> with all 4 states + mounted check.
// NOTE: No http imports here — all networking is in CountryApiService.

import 'dart:async'; // TimeoutException
import 'dart:io';   // SocketException

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../services/api_exception.dart';

class DetailScreen extends StatefulWidget {
  /// ISO alpha-3 code of the country to load.
  final String alpha3Code;

  /// Display name shown in the AppBar while loading.
  final String countryName;

  const DetailScreen({
    super.key,
    required this.alpha3Code,
    required this.countryName,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final CountryApiService _apiService = CountryApiService();
  late Future<Country> _countryFuture;

  @override
  void initState() {
    super.initState();
    // Kick off the network call in initState — never in build().
    _countryFuture = _apiService.fetchByCode(widget.alpha3Code);
  }

  /// Retries the fetch by replacing the stored Future.
  void _retry() {
    // mounted check — we are still in initState/setState flow so widget is
    // guaranteed mounted here, but we guard explicitly as best practice.
    if (!mounted) return;
    setState(() {
      _countryFuture = _apiService.fetchByCode(widget.alpha3Code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.countryName),
        centerTitle: true,
      ),
      body: FutureBuilder<Country>(
        future: _countryFuture,
        builder: (context, snapshot) {
          // ── State 1: Loading ────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading details…'),
                ],
              ),
            );
          }

          // ── State 2: Error ──────────────────────────────────────────────
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error!);
          }

          // ── State 3: No data ────────────────────────────────────────────
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No data available for this country.'),
            );
          }

          // ── State 4: Data ───────────────────────────────────────────────
          final country = snapshot.data!;
          return _buildCountryDetail(country);
        },
      ),
    );
  }

  /// Renders the full country detail layout.
  Widget _buildCountryDetail(Country country) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Flag + Name header ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 8),
                Text(
                  country.commonName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (country.officialName != country.commonName) ...[
                  const SizedBox(height: 4),
                  Text(
                    country.officialName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // ── Detail rows ─────────────────────────────────────────────────
          _DetailRow(
            icon: Icons.location_city,
            label: 'Capital',
            value: country.capital,
          ),
          _DetailRow(
            icon: Icons.people,
            label: 'Population',
            value: _formatNumber(country.population),
          ),
          _DetailRow(
            icon: Icons.map,
            label: 'Region',
            value: country.region.isNotEmpty
                ? '${country.region}${country.subregion.isNotEmpty ? ' — ${country.subregion}' : ''}'
                : 'N/A',
          ),
          _DetailRow(
            icon: Icons.square_foot,
            label: 'Area',
            value: country.area > 0
                ? '${_formatNumber(country.area.round())} km²'
                : 'N/A',
          ),
          _DetailRow(
            icon: Icons.attach_money,
            label: 'Currencies',
            value: country.currencies.isNotEmpty
                ? country.currencies.join(', ')
                : 'N/A',
          ),
          _DetailRow(
            icon: Icons.language,
            label: 'Languages',
            value: country.languages.isNotEmpty
                ? country.languages.join(', ')
                : 'N/A',
          ),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Timezones',
            value: country.timezones.isNotEmpty
                ? country.timezones.join(', ')
                : 'N/A',
          ),
          _DetailRow(
            icon: Icons.tag,
            label: 'ISO Code (alpha-3)',
            value: country.alpha3Code.isNotEmpty ? country.alpha3Code : 'N/A',
          ),
        ],
      ),
    );
  }

  /// Formats a large integer with comma separators.
  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  /// Builds a user-friendly error widget with Retry for all 5 error types.
  Widget _buildErrorWidget(Object error) {
    final String message = _errorMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps exception types to user-friendly messages (assignment Section 4.5).
  String _errorMessage(Object error) {
    if (error is SocketException) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is ApiException) {
      return 'Server error (HTTP ${error.statusCode}):\n${error.message}';
    }
    if (error is FormatException) {
      return 'Unexpected data format received.';
    }
    return 'An unexpected error occurred:\n${error.toString()}';
  }
}

// ── Private reusable detail row ───────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
