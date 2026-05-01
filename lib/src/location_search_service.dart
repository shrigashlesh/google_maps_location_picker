import 'package:flutter/foundation.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:http/http.dart';

import '../providers/place_provider.dart';
import 'models/pick_result.dart';

class LocationSearchService {
  late final GoogleMapsPlaces _places;
  late final GoogleMapsGeocoding _geocoding;

  LocationSearchService._({
    required GoogleMapsPlaces places,
    required GoogleMapsGeocoding geocoding,
  })  : _places = places,
        _geocoding = geocoding;

  LocationSearchService.fromClients({
    required GoogleMapsPlaces places,
    required GoogleMapsGeocoding geocoding,
  })  : _places = places,
        _geocoding = geocoding;

  LocationSearchService.fromProvider(PlaceProvider provider)
      : _places = provider.places,
        _geocoding = provider.geocoding;

  factory LocationSearchService.withApiKey(
    String apiKey,
    String? proxyBaseUrl,
    BaseClient? httpClient,
    Map<String, dynamic> apiHeaders,
  ) {
    final places = GoogleMapsPlaces(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
    final geocoding = GoogleMapsGeocoding(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders as Map<String, String>?,
    );
    return LocationSearchService._(places: places, geocoding: geocoding);
  }

  static Future<LocationSearchService> create({
    required String apiKey,
    String? proxyBaseUrl,
    BaseClient? httpClient,
  }) async {
    final headers = await GoogleApiHeaders().getHeaders();
    return LocationSearchService.withApiKey(
      apiKey,
      proxyBaseUrl,
      httpClient,
      headers,
    );
  }

  /// Reverse-geocodes a lat/lng pair and returns a [PickResult].
  ///
  /// When [usePlaceDetailSearch] is `true`, an extra Places Detail request is
  /// made to enrich the result with fields like name, phone, photos, etc.
  Future<PickResult> searchByLocation({
    required double latitude,
    required double longitude,
    String? language,
    bool usePlaceDetailSearch = false,
  }) async {
    // Latitude must be in [-90, 90]. If it's outside that range but longitude
    // is within it, the caller almost certainly swapped the two values.
    if (latitude.abs() > 90 && longitude.abs() <= 90) {
      debugPrint(
          '[LocationSearchService] Detected swapped lat/lng ($latitude, $longitude) — correcting');
      final tmp = latitude;
      latitude = longitude;
      longitude = tmp;
    }

    debugPrint(
        '[LocationSearchService] Searching by location: lat=$latitude, lng=$longitude, language=$language, usePlaceDetailSearch=$usePlaceDetailSearch');

    final response = await _geocoding.searchByLocation(
      Location(lat: latitude, lng: longitude),
      language: language,
    );

    debugPrint(
        '[LocationSearchService] Geocoding response status: ${response.status}, error: ${response.errorMessage}');

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      throw LocationSearchException(
        response.errorMessage ?? response.status,
      );
    }

    if (response.results.isEmpty) {
      debugPrint('[LocationSearchService] No geocoding results found');
      throw LocationSearchException('No results found');
    }

    if (usePlaceDetailSearch) {
      final detailResponse = await _places.getDetailsByPlaceId(
        response.results[0].placeId,
        language: language,
      );

      debugPrint(
          '[LocationSearchService] Place details response status: ${detailResponse.status}, error: ${detailResponse.errorMessage}');

      if (detailResponse.errorMessage?.isNotEmpty == true ||
          detailResponse.status == "REQUEST_DENIED") {
        throw LocationSearchException(
          detailResponse.errorMessage ?? detailResponse.status,
        );
      }

      return PickResult.fromPlaceDetailResult(detailResponse.result);
    }

    return PickResult.fromGeocodingResult(response.results[0]);
  }

  /// Runs Places Autocomplete. Returns `null` when the API returns an error or
  /// `REQUEST_DENIED` (after invoking [onSearchFailed] if provided).
  Future<PlacesAutocompleteResponse?> placesAutocomplete({
    required String searchTerm,
    String? sessionToken,
    Location? location,
    num? offset,
    num? radius,
    String? language,
    List<String>? types,
    List<Component>? components,
    bool strictbounds = false,
    String? region,
    void Function(String status)? onSearchFailed,
  }) async {
    final PlacesAutocompleteResponse response = await _places.autocomplete(
      searchTerm,
      sessionToken: sessionToken,
      location: location,
      offset: offset,
      radius: radius,
      language: language,
      types: types ?? const [],
      components: components ?? const [],
      strictbounds: strictbounds,
      region: region,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      onSearchFailed?.call(response.status);
      return null;
    }

    return response;
  }

  /// Loads Place Details for [placeId]. Returns `null` when the API returns an
  /// error or `REQUEST_DENIED` (after invoking [onFailed] if provided).
  Future<PickResult?> pickResultFromPlaceId({
    required String placeId,
    String? sessionToken,
    String? language,
    void Function(String status)? onFailed,
  }) async {
    final PlacesDetailsResponse response = await _places.getDetailsByPlaceId(
      placeId,
      sessionToken: sessionToken,
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      onFailed?.call(response.status);
      return null;
    }

    return PickResult.fromPlaceDetailResult(response.result);
  }
}

class LocationSearchException implements Exception {
  final String message;

  LocationSearchException(this.message);

  @override
  String toString() => 'LocationSearchException: $message';
}
