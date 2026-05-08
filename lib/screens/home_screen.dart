import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/api_exception.dart';
import '../services/cache_service.dart';
import '../services/country_api_service.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CountryApiService _apiService = CountryApiService();
  final CacheService _cache = CacheService();
  static const String _cacheKey = 'all_countries';
  static const int _pageSize = 20;

  List<Country> _allCountries = [];
  int _displayedCount = _pageSize;
  bool _isLoading = true;
  bool _isFromCache = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Bonus: check cache first
    final cached = _cache.get<List<Country>>(_cacheKey);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _allCountries = cached;
        _displayedCount = _pageSize;
        _isFromCache = true;
        _isLoading = false;
      });
      // Refresh in background even if cache is valid
      _refreshInBackground();
      return;
    }

    try {
      final countries = await _apiService.fetchAllCountries();
      if (!mounted) return;
      _cache.put(_cacheKey, countries);
      setState(() {
        _allCountries = countries;
        _displayedCount = _pageSize;
        _isFromCache = false;
        _isLoading = false;
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No internet connection.\nPlease check your network and try again.';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Request timed out. Please try again.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Server error (HTTP ${e.statusCode}):\n${e.message}';
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected data format received.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred:\n${e.toString()}';
      });
    }
  }

  // Refresh data in background while showing cached data
  Future<void> _refreshInBackground() async {
    try {
      final countries = await _apiService.fetchAllCountries();
      if (!mounted) return;
      _cache.put(_cacheKey, countries);
      setState(() {
        _allCountries = countries;
        _isFromCache = false;
      });
    } catch (_) {
      // Silently fail — cached data is already shown
    }
  }

  // Bonus: Pagination — show more items
  void _loadMore() {
    setState(() {
      _displayedCount = (_displayedCount + _pageSize).clamp(0, _allCountries.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Country Explorer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search countries',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
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

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCountries,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // No data state
    if (_allCountries.isEmpty) {
      return const Center(child: Text('No countries found.'));
    }

    // Data state with pagination
    final itemsToShow = _allCountries.take(_displayedCount).toList();
    final hasMore = _displayedCount < _allCountries.length;

    return Column(
      children: [
        // Bonus: "Cached" badge when data is from cache
        if (_isFromCache)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.orange.shade100,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cached, size: 16, color: Colors.orange),
                SizedBox(width: 6),
                Text(
                  'Cached',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: itemsToShow.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // "Load More" button at the bottom
              if (index == itemsToShow.length) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _loadMore,
                      child: Text(
                        'Load More (${_allCountries.length - _displayedCount} remaining)',
                      ),
                    ),
                  ),
                );
              }
              final country = itemsToShow[index];
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
          ),
        ),
      ],
    );
  }
}

class _CountryListTile extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const _CountryListTile({required this.country, required this.onTap});

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
      subtitle: Text(country.region.isNotEmpty ? country.region : 'Unknown'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
