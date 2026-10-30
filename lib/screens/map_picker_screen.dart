
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _defaultCenter = LatLng(30.0, 70.0);

  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController();

  LatLng? _selected;
  bool _searching = false;

  Timer? _suggestionDebounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;
  int _suggestionRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _suggestionRequestId++;
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Create fallback queries for detailed place searches.
  List<String> _buildFallbackQueries(String query) {
    final cleaned = query
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');

    final queries = <String>[cleaned];

    final commaParts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (commaParts.length > 1) {
      queries.add('${commaParts.first}, Jamshoro');
      queries.add('${commaParts.first}, Sindh');
      queries.add(commaParts.first);
    } else {
      final shopName = cleaned
          .replaceAll(
            RegExp(
              r'\b(society|phase[-\s]*\d+|jamshoro|sindh|pakistan)\b',
              caseSensitive: false,
            ),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (shopName.isNotEmpty && shopName != cleaned) {
        queries.add('$shopName, Jamshoro');
        queries.add('$shopName, Sindh');
        queries.add(shopName);
      }

      final words = cleaned.split(' ');
      if (words.length > 2) {
        queries.add('${words.take(2).join(' ')}, Jamshoro');
        queries.add(words.take(2).join(' '));
      }
    }

    return queries
        .where((q) => q.isNotEmpty)
        .toSet()
        .toList();
  }

  // Nominatim search shared by autocomplete and manual search.
  Future<List<Map<String, dynamic>>> _nominatimSearch(
    String query, {
    int limit = 5,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '$limit',
        'countrycodes': 'pk',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'Nominatim HTTP ${response.statusCode}: $query',
      );
      return [];
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<LatLng?> _findAddress(String query) async {
    if (kIsWeb) {
      final candidates = _buildFallbackQueries(query);

      for (var i = 0; i < candidates.length; i++) {
        final candidate = candidates[i];

        try {
          debugPrint('Searching: $candidate');

          final results = await _nominatimSearch(
            candidate,
            limit: 1,
          );

          if (results.isNotEmpty) {
            final result = results.first;

            final latitude = double.tryParse(
              result['lat']?.toString() ?? '',
            );
            final longitude = double.tryParse(
              result['lon']?.toString() ?? '',
            );

            if (latitude != null && longitude != null) {
              return LatLng(latitude, longitude);
            }
          }
        } catch (e) {
          debugPrint('Search attempt failed: $e');
        }

        // Avoid sending rapid repeated requests to the public service.
        if (i < candidates.length - 1) {
          await Future<void>.delayed(
            const Duration(milliseconds: 1100),
          );
        }
      }

      return null;
    }

    // Preserve native geocoding for Android/iOS.
    final geocoding = Geocoding();
    final results = await geocoding.locationFromAddress(query);

    if (results.isEmpty) return null;

    return LatLng(
      results.first.latitude,
      results.first.longitude,
    );
  }

  // Called when the user types into the search field.
  void _onSearchChanged(String value) {
    _suggestionDebounce?.cancel();

    final query = value.trim();
    final requestId = ++_suggestionRequestId;

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _suggestions = [];
      _loadingSuggestions = true;
    });

    _suggestionDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchSuggestions(query, requestId),
    );
  }

  Future<void> _fetchSuggestions(
    String query,
    int requestId,
  ) async {
    try {
      List<Map<String, dynamic>> results = [];

      if (kIsWeb) {
        for (final candidate in _buildFallbackQueries(query)) {
          if (!mounted || requestId != _suggestionRequestId) {
            return;
          }

          results = await _nominatimSearch(candidate);

          if (results.isNotEmpty) break;

          // Public Nominatim has strict usage limits.
          await Future<void>.delayed(
            const Duration(milliseconds: 1100),
          );
        }
      } else {
        // Native platforms continue to use the geocoding package.
        final geocoding = Geocoding();
        final locations =
            await geocoding.locationFromAddress(query);

        results = locations.take(5).map((location) {
          return <String, dynamic>{
            'display_name':
                'Location (${location.latitude.toStringAsFixed(5)}, '
                '${location.longitude.toStringAsFixed(5)})',
            'lat': location.latitude.toString(),
            'lon': location.longitude.toString(),
          };
        }).toList();
      }

      if (!mounted || requestId != _suggestionRequestId) return;

      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    } catch (e) {
      if (!mounted || requestId != _suggestionRequestId) return;

      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });

      debugPrint('Autocomplete error: $e');
    }
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final latitude = double.tryParse(
      place['lat']?.toString() ?? '',
    );
    final longitude = double.tryParse(
      place['lon']?.toString() ?? '',
    );

    if (latitude == null || longitude == null) return;

    final point = LatLng(latitude, longitude);
    final name = place['display_name']?.toString() ?? '';

    _suggestionDebounce?.cancel();
    _suggestionRequestId++;

    FocusScope.of(context).unfocus();

    setState(() {
      _searchController.text = name;
      _searchController.selection = TextSelection.collapsed(
        offset: name.length,
      );
      _selected = point;
      _suggestions = [];
      _loadingSuggestions = false;
    });

    _mapController.move(point, 17);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();

    if (query.isEmpty || _searching) return;

    _suggestionDebounce?.cancel();
    _suggestionRequestId++;

    FocusScope.of(context).unfocus();

    setState(() {
      _searching = true;
      _suggestions = [];
      _loadingSuggestions = false;
    });

    try {
      final point = await _findAddress(query);

      if (!mounted) return;

      if (point == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location not found. Try a shorter name or tap the map.',
            ),
          ),
        );
        return;
      }

      setState(() => _selected = point);
      _mapController.move(point, 16);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address search failed. Check your internet connection or tap the map.',
          ),
        ),
      );

      debugPrint('Map address search error: $e');
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Incident Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _searchAddress(),
                        decoration: InputDecoration(
                          labelText: 'Search place or address',
                          hintText:
                              'e.g. Hyderabad, Sindh, Pakistan',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _loadingSuggestions
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Search address',
                      onPressed:
                          _searching ? null : _searchAddress,
                      icon: _searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search),
                    ),
                  ],
                ),

                // Autocomplete dropdown.
                if (_suggestions.isNotEmpty)
                  Container(
                    constraints:
                        const BoxConstraints(maxHeight: 220),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        final name =
                            place['display_name']?.toString() ??
                                'Unknown place';

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                          ),
                          title: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSuggestion(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Search for a place, then tap the exact incident point on the map.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    widget.initialLocation ?? _defaultCenter,
                initialZoom:
                    widget.initialLocation == null ? 5 : 15,
                onTap: (tapPosition, point) {
                  setState(() => _selected = point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safewalk',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selected == null
                        ? 'No location selected yet'
                        : 'Selected: '
                            '${_selected!.latitude.toStringAsFixed(6)}, '
                            '${_selected!.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
                    icon: const Icon(Icons.check),
                    label: const Text('Save Location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
