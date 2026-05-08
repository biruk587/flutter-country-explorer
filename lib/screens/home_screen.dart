// lib/screens/home_screen.dart
// Home screen — displays a scrollable list of ALL countries.
// Uses FutureBuilder<List<Country>> and handles all 4 states:
//   ConnectionState.waiting → loading spinner
//   snapshot.hasError      → error message + Retry button
//   snapshot.data == null  → empty/no data message
//   snapshot.hasData       → ListView of countries
//
// NOTE: No http imports here — all networking is in CountryApiService.

import 'dart:async'; // TimeoutException
import 'dart:io';   // SocketException

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../services/api_exception.dart';
import 'search_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The single service instance used for all HTTP calls.
  final CountryApiService _apiService = CountryApiService();

  // The Future that drives the FutureBuilder. Stored so we can replace it
  // on Retry without rebuilding the widget tree unnecessarily.
  late Future<List<Country>> _countriesFuture;

  @override
  void initState() {
    super.initState();
    // Assign the future in initState — never call async functions in build().
    _countriesFuture = _apiService.fetchAllCountries();
  }

  /// Retriggers the network request by replacing the stored Future.
  void _retry() {
    setState(() {
      _countriesFuture = _apiService.fetchAllCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Country Explorer'),
        centerTitle: true,
        actions: [
          // Navigate to the Search screen.
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search countries',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Country>>(
        future: _countriesFuture,
        builder: (context, snapshot) {
          // ── State 1: Loading ──────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading countries…'),
                ],
              ),
            );
          }

          // ── State 2: Error ────────────────────────────────────────────────
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error!);
          }

          // ── State 3: No data ──────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No countries found.'),
            );
          }

          // ── State 4: Data ─────────────────────────────────────────────────
          final countries = snapshot.data!;
          return ListView.builder(
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              return _CountryListTile(
                country: country,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        alpha3Code: country.alpha3Code,
                        countryName: country.commonName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds an error widget with a user-friendly message and a Retry button.
  /// Handles all 5 error types required by the assignment (Section 4.5).
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

// ── Private list tile widget ──────────────────────────────────────────────────

class _CountryListTile extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const _CountryListTile({
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        country.flagEmoji,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        country.commonName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(country.region.isNotEmpty ? country.region : 'Unknown region'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
