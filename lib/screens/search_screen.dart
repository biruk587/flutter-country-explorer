// lib/screens/search_screen.dart
// Search screen — lets the user type a country name and fetches matching
// results via GET /name/{name}.
//
// Uses a TextEditingController and a StatefulWidget; the search is
// triggered by pressing the search icon or keyboard "Done" action.
// Results are displayed using a FutureBuilder (or a stateful list when
// the user has not yet searched).
//
// NOTE: No http imports here — all networking is in CountryApiService.

import 'package:flutter/material.dart';

import '../models/country.dart';
import '../services/country_api_service.dart';
import '../services/api_exception.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CountryApiService _apiService = CountryApiService();
  final TextEditingController _controller = TextEditingController();

  // Null means "user hasn't searched yet". A non-null Future drives results.
  Future<List<Country>>? _searchFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Kicks off a search when the user submits the text field.
  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
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
          // ── Search bar ──────────────────────────────────────────────────
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
                    setState(() {
                      _searchFuture = null;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),

          // ── Results area ────────────────────────────────────────────────
          Expanded(
            child: _searchFuture == null
                ? const Center(
                    child: Text(
                      'Type a country name above and press Search.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : FutureBuilder<List<Country>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      // State 1: Loading
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // State 2: Error
                      if (snapshot.hasError) {
                        return _buildErrorWidget(snapshot.error!);
                      }

                      // State 3: No data
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No results for "${_controller.text.trim()}".',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // State 4: Data
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
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
                  ),
          ),
        ],
      ),

      // Search button in the bottom-right corner.
      floatingActionButton: FloatingActionButton(
        onPressed: _search,
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
    );
  }

  /// Builds a user-friendly error widget for all 5 required error types.
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
              onPressed: _search,
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
    if (error.toString().contains('SocketException') ||
        error.toString().contains('No internet') ||
        error.toString().contains('Failed host lookup')) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (error is ApiException) {
      return 'Server error (HTTP ${error.statusCode}):\n${error.message}';
    }
    if (error.toString().contains('FormatException')) {
      return 'Unexpected data format received.';
    }
    return 'An unexpected error occurred:\n${error.toString()}';
  }
}
