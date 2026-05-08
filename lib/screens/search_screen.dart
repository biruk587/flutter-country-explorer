import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/api_exception.dart';
import '../services/country_api_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CountryApiService _apiService = CountryApiService();
  final TextEditingController _controller = TextEditingController();

  // Bonus: Debounce timer — delays API call by 400ms
  Timer? _debounceTimer;
  Future<List<Country>>? _searchFuture;
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  // Called every time text changes — debounces for 400ms
  void _onSearchChanged() {
    final query = _controller.text.trim();

    // Cancel any previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
        _isDebouncing = false;
      });
      return;
    }

    // Show debouncing indicator
    setState(() => _isDebouncing = true);

    // Wait 400ms after user stops typing, then search
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _isDebouncing = false;
        _searchFuture = _apiService.searchByName(query);
      });
    });
  }

  // Manual search (from FAB or keyboard submit)
  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _debounceTimer?.cancel();
    setState(() {
      _isDebouncing = false;
      _searchFuture = _apiService.searchByName(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Countries'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Enter a country name…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _search,
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildResults() {
    // No search yet
    if (_searchFuture == null && !_isDebouncing) {
      return const Center(
        child: Text(
          'Start typing to search countries.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Debouncing — waiting for user to stop typing
    if (_isDebouncing) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Country>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error!);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No results for "${_controller.text.trim()}".' ),
          );
        }
        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final country = results[index];
            return ListTile(
              leading: Text(
                country.flagEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                country.commonName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(country.region),
              trailing: const Icon(Icons.chevron_right),
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
    );
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
              onPressed: _search,
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
