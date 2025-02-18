import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import 'package:uuid/uuid.dart';

import '../google_maps_location_picker.dart';
import '../providers/place_provider.dart';
import 'autocomplete_search.dart';
import 'controllers/autocomplete_search_controller.dart';
import 'google_map_location_picker.dart';

typedef IntroModalWidgetBuilder = Widget Function(
  BuildContext context,
  Function? close,
);

typedef SearchingWidgetBuilder = Widget Function(
  BuildContext context,
);

typedef SearchDecorator = InputDecoration Function(
  VoidCallback onClear,
  bool hasText,
);

enum PinState { Preparing, Idle, Dragging }

enum SearchingState { Idle, Searching }

class LocationPicker extends StatefulWidget {
  LocationPicker({
    Key? key,
    required this.apiKey,
    required this.onPlacePicked,
    required this.initialPosition,
    this.initialZoomLevel = 15,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictBounds,
    this.region,
    this.pickArea,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.ignoreLocationPermissionErrors = false,
    this.onTapBack,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTypeChanged,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.polygons = const <Polygon>{},
    this.searchingWidgetBuilder,
    this.searchDecorator,
  }) : super(key: key);

  final String apiKey;

  final LatLng initialPosition;
  final double initialZoomLevel;
  final bool? useCurrentLocation;
  final LocationAccuracy desiredLocationAccuracy;

  final String? hintText;
  final String? searchingText;
  final String? selectText;
  final String? outsideOfPickAreaText;

  final ValueChanged<String>? onAutoCompleteFailed;
  final ValueChanged<String>? onGeocodingSearchFailed;
  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final MapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;

  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictBounds;
  final String? region;

  /// If set the picker can only pick addresses in the given circle area.
  /// The section will be highlighted.
  final CircleArea? pickArea;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult> onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// IMPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - builds customized introduction panel.
  ///
  /// None is provided / the map is instantly accessible if you leave it as a null.
  final IntroModalWidgetBuilder? introModalWidgetBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Whether to display appbar back button. Defaults to true.
  final bool automaticallyImplyAppBarLeading;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  /// Whether to hide place details when dragging pin. Defaults to true.
  final bool hidePlaceDetailsWhenDraggingPin;

  /// Whether to ignore location permission errors. Defaults to false.
  /// If this is set to `true` the UI will be blocked.
  final bool ignoreLocationPermissionErrors;

  // Raised when clicking on the back arrow.
  // This will not listen for the system back button on Android devices.
  // If this is not set, but the back button is visible through automaticallyImplyLeading,
  // the Navigator will try to pop instead.
  final VoidCallback? onTapBack;

  /// GoogleMap pass-through events:

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final MapCreatedCallback? onMapCreated;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final Function(PlaceProvider)? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final CameraPositionCallback? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final Function(PlaceProvider)? onCameraIdle;

  /// Called when the map type has been changed.
  final Function(MapType)? onMapTypeChanged;

  /// Toggle on & off zoom gestures
  final bool zoomGesturesEnabled;

  /// Allow user to make visible the zoom button
  final bool zoomControlsEnabled;

  /// Polygons to be placed on the map.
  ///
  /// Defaults to `const <Polygon>{}`
  final Set<Polygon> polygons;

  /// optional - builds searching UI
  ///
  /// It is provided by default if you leave it as a null.
  final SearchingWidgetBuilder? searchingWidgetBuilder;

  /// optional - search textfield input decorator
  ///
  final SearchDecorator? searchDecorator;
  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<LocationPicker> {
  GlobalKey appBarKey = GlobalKey();
  late final Future<PlaceProvider> _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();
  bool showIntroModal = true;

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = Uuid().v4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      await provider.updateCurrentLocation(
          gracefully: widget.ignoreLocationPermissionErrors);
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (_, __) => searchBarController.clearOverlay(),
        child: FutureBuilder<PlaceProvider>(
          future: _futureProvider,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              provider = snapshot.data;
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
                ],
                child: Stack(children: [
                  Scaffold(
                    key: ValueKey<int>(provider.hashCode),
                    resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      key: appBarKey,
                      automaticallyImplyLeading: false,
                      iconTheme: Theme.of(context).iconTheme,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      titleSpacing: 0.0,
                      title: _buildSearchBar(context),
                    ),
                    body: _buildMapWithLocation(),
                  ),
                  _buildIntroModal(context),
                ]),
              );
            }

            final children = <Widget>[];
            if (snapshot.hasError) {
              children.addAll([
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ]);
            } else {
              children.add(CircularProgressIndicator());
            }

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        ));
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 15),
        provider!.placeSearchingState == SearchingState.Idle &&
                (widget.automaticallyImplyAppBarLeading ||
                    widget.onTapBack != null)
            ? IconButton(
                onPressed: () {
                  if (!showIntroModal ||
                      widget.introModalWidgetBuilder == null) {
                    provider?.debounceTimer?.cancel();
                    if (widget.onTapBack != null) {
                      widget.onTapBack!();
                      return;
                    }
                    Navigator.maybePop(context);
                  }
                },
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                ),
                color: Colors.black.withAlpha(128),
                padding: EdgeInsets.zero)
            : Container(),
        Expanded(
          child: AutoCompleteSearch(
            appBarKey: appBarKey,
            searchBarController: searchBarController,
            searchDecorator: widget.searchDecorator,
            searchingWidgetBuilder: widget.searchingWidgetBuilder,
            sessionToken: provider!.sessionToken,
            debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
            onPicked: (prediction) {
              if (mounted) {
                _pickPrediction(prediction);
              }
            },
            onSearchFailed: (status) {
              if (widget.onAutoCompleteFailed != null) {
                widget.onAutoCompleteFailed!(status);
              }
            },
            autocompleteOffset: widget.autocompleteOffset,
            autocompleteRadius: widget.autocompleteRadius,
            autocompleteLanguage: widget.autocompleteLanguage,
            autocompleteComponents: widget.autocompleteComponents,
            autocompleteTypes: widget.autocompleteTypes,
            strictBounds: widget.strictBounds,
            region: widget.region,
            initialSearchString: widget.initialSearchString,
            searchForInitialValue: widget.searchForInitialValue,
            autocompleteOnTrailingWhitespace:
                widget.autocompleteOnTrailingWhitespace,
          ),
        ),
        SizedBox(width: 5),
      ],
    );
  }

  _pickPrediction(Prediction prediction) async {
    provider!.placeSearchingState = SearchingState.Searching;

    final PlacesDetailsResponse response =
        await provider!.places.getDetailsByPlaceId(
      prediction.placeId!,
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }

    provider!.selectedPlace = PickResult.fromPlaceDetailResult(response.result);

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
        provider!.selectedPlace!.geometry!.location.lng);

    if (provider == null) return;
    provider!.placeSearchingState = SearchingState.Idle;
  }

  _moveTo(double latitude, double longitude) async {
    if (provider?.mapController == null) return;
    GoogleMapController? controller = provider!.mapController;
    await controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  _moveToCurrentPosition() async {
    if (provider?.currentPosition == null) return;
    await _moveTo(provider!.currentPosition!.latitude,
        provider!.currentPosition!.longitude);
  }

  Widget _buildMapWithLocation() {
    if (provider!.currentPosition == null) {
      return _buildMap(widget.initialPosition);
    }
    return _buildMap(LatLng(provider!.currentPosition!.latitude,
        provider!.currentPosition!.longitude));
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapLocationPicker(
      fullMotion: !widget.resizeToAvoidBottomInset,
      initialTarget: initialTarget,
      initialZoomLevel: widget.initialZoomLevel,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      pickArea: widget.pickArea,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      selectText: widget.selectText,
      outsideOfPickAreaText: widget.outsideOfPickAreaText,
      onToggleMapType: () {
        if (provider == null) return;
        provider!.switchMapType();
        if (widget.onMapTypeChanged != null) {
          widget.onMapTypeChanged!(provider!.mapType);
        }
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider == null) return;
        if (provider!.isOnUpdateLocationCooldown == false) {
          provider!.isOnUpdateLocationCooldown = true;
          Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
            provider!.isOnUpdateLocationCooldown = false;
          });
          await provider!.updateCurrentLocation(
              gracefully: widget.ignoreLocationPermissionErrors);
          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        if (provider == null) return;
      },
      onPlacePicked: widget.onPlacePicked,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      polygons: widget.polygons,
    );
  }

  Widget _buildIntroModal(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return showIntroModal && widget.introModalWidgetBuilder != null
            ? Stack(children: [
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: Material(
                    type: MaterialType.canvas,
                    color: Color.fromARGB(128, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    child: ClipRect(),
                  ),
                ),
                widget.introModalWidgetBuilder!(context, () {
                  if (mounted) {
                    setState(() {
                      showIntroModal = false;
                    });
                  }
                })
              ])
            : Container();
      },
    );
  }
}
