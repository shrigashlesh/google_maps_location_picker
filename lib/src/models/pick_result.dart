import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:flutter_google_maps_webservices/places.dart';

class PickResult {
  PickResult({
    this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
    this.adrAddress,
    this.formattedPhoneNumber,
    this.id,
    this.reference,
    this.icon,
    this.name,
    this.openingHours,
    this.photos,
    this.internationalPhoneNumber,
    this.priceLevel,
    this.rating,
    this.scope,
    this.url,
    this.vicinity,
    this.utcOffset,
    this.website,
    this.reviews,
  });

  final String? placeId;
  final Geometry? geometry;
  final String? formattedAddress;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;

  // Below results will not be fetched if 'usePlaceDetailSearch' is set to false (Defaults to false).
  final String? adrAddress;
  final String? formattedPhoneNumber;
  final String? id;
  final String? reference;
  final String? icon;
  final String? name;
  final OpeningHoursDetail? openingHours;
  final List<Photo>? photos;
  final String? internationalPhoneNumber;
  final PriceLevel? priceLevel;
  final num? rating;
  final String? scope;
  final String? url;
  final String? vicinity;
  final num? utcOffset;
  final String? website;
  final List<Review>? reviews;

  factory PickResult.fromGeocodingResult(GeocodingResult result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
    );
  }

  factory PickResult.fromPlaceDetailResult(PlaceDetails result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
      adrAddress: result.adrAddress,
      formattedPhoneNumber: result.formattedPhoneNumber,
      id: result.id,
      reference: result.reference,
      icon: result.icon,
      name: result.name,
      openingHours: result.openingHours,
      photos: result.photos,
      internationalPhoneNumber: result.internationalPhoneNumber,
      priceLevel: result.priceLevel,
      rating: result.rating,
      scope: result.scope,
      url: result.url,
      vicinity: result.vicinity,
      utcOffset: result.utcOffset,
      website: result.website,
      reviews: result.reviews,
    );
  }
}

extension PickResultX on PickResult {
  String get shortenedAddress {
    const fallback = 'N.A';
    final loc = geometry?.location;

    String coordinatesLabel() {
      if (loc == null) return fallback;
      final lat = loc.lat;
      final lng = loc.lng;
      return '${lat.toStringAsPrecision(6)}, ${lng.toStringAsPrecision(6)}';
    }

    final components = addressComponents ?? <AddressComponent>[];
    final addressParts = <String>[];

    // Collect relevant address components in order of priority
    for (final component in components) {
      final types = component.types;
      if (types.contains('route') ||
          types.contains('sublocality') ||
          types.contains('locality') ||
          types.contains('administrative_area_level_1')) {
        final piece = component.longName.trim();
        if (piece.isNotEmpty) {
          addressParts.add(piece);
        }
      }
    }

    if (addressParts.isEmpty) {
      return coordinatesLabel();
    }

    // Limit to 4 components + country short name (if available)
    final shortenedAddressParts = addressParts.take(4).toList();

    final countryComponent = components.firstWhere(
      (c) => c.types.contains('country'),
      orElse: () =>
          AddressComponent(longName: '', shortName: '', types: const []),
    );

    final countryCode = countryComponent.shortName.trim();
    if (countryCode.isNotEmpty) {
      shortenedAddressParts.add(countryCode);
    }

    return shortenedAddressParts.join(', ');
  }
}
