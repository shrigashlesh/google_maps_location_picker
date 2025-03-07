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
    if (addressComponents == null || addressComponents!.isEmpty) {
      return geometry?.location != null
          ? '${geometry!.location.lat.toStringAsPrecision(6)}, ${geometry!.location.lng.toStringAsPrecision(6)}'
          : 'N.A';
    }

    List<String> addressParts = [];

    // Collect relevant address components in order of priority
    for (var component in addressComponents!) {
      if (component.types.contains('route') || // Street name
          component.types.contains('sublocality') || // Sub-locality
          component.types.contains('locality') || // City
          component.types.contains('administrative_area_level_1')) {
        // State
        addressParts.add(component.longName);
      }
    }

    // If address parts are empty, return lat/lng instead
    if (addressParts.isEmpty) {
      return geometry?.location != null
          ? '${geometry!.location.lat}, ${geometry!.location.lng}'
          : 'N.A';
    }

    // Limit to 3 components + country short name (if available)
    addressParts = addressParts.take(3).toList();

    // Replace country with its short name if available
    var countryComponent = addressComponents!.firstWhere(
      (c) => c.types.contains('country'),
      orElse: () => AddressComponent(longName: '', shortName: '', types: []),
    );

    if (countryComponent.shortName.isNotEmpty) {
      addressParts.add(countryComponent.shortName);
    }

    return addressParts.join(', ');
  }
}
