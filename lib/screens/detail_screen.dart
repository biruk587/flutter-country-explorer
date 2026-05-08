import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/api_exception.dart';
import '../services/country_api_service.dart';

class DetailScreen extends StatefulWidget {
  final String alpha3Code;
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
    _countryFuture = _apiService.fetchByCode(widget.alpha3Code);
  }

  void _retry() {
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
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error!);
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }
          return _buildCountryDetail(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildCountryDetail(Country country) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(country.flagEmoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 8),
                Text(
                  country.commonName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (country.officialName != country.commonName) ...[
                  const SizedBox(height: 4),
                  Text(
                    country.officialName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
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
            value: country.subregion.isNotEmpty
                ? '${country.region} — ${country.subregion}'
                : country.region,
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

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage(error),
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
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
