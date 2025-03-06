// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
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

typedef SearchFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focus,
);

typedef MapActionsBuilder = Widget Function(
  BuildContext context,
  PlaceProvider? provider,
  VoidCallback? moveToCurrentLocation,
);

enum PinState { Preparing, Idle, Dragging }

enum SearchingState { Idle, Searching }

class PredictionTileTheme {
  final TextStyle? matchedStyle;
  final TextStyle? regularStyle;
  final Widget? leading;

  PredictionTileTheme({
    this.matchedStyle,
    this.regularStyle,
    this.leading,
  });
}

class LocationPickerViewer extends StatefulWidget {
  LocationPickerViewer({
    Key? key,
    required this.apiKey,
    this.initialPosition,
    this.initialZoomLevel = 15,
    this.useCurrentLocation = false,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.allowedMapType = MapType.values,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteTypes,
    this.autocompleteComponents,
    this.strictBounds,
    this.region,
    this.pickArea,
    this.resizeToAvoidBottomInset = true,
    this.selectInitialPosition = false,
    required this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.proxyBaseUrl,
    this.httpClient,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.ignoreLocationPermissionErrors = false,
    this.onTapBack,
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.searchingWidgetBuilder,
    required this.searchFieldBuilder,
    required this.allowSearching,
    this.polygons = const <Polygon>{},
    this.markers = const <Marker>{},
    this.clusterManagers = const <ClusterManager>{},
    this.errorBuilder,
    this.onTap,
    this.style,
    this.searchedOverlayDecoration,
    this.predictionTileTheme,
    this.mapActionsBuilder,
    this.floatingBtnsColor,
  }) : super(key: key);

  final String apiKey;

  final LatLng? initialPosition;
  final double initialZoomLevel;
  final bool useCurrentLocation;
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
  final List<MapType> allowedMapType;
  final int myLocationButtonCooldown;

  final bool allowSearching;
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

  /// Required - builds selected place's UI
  ///
  final SelectedPlaceWidgetBuilder selectedPlaceWidgetBuilder;

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
  final WidgetBuilder? searchingWidgetBuilder;

  /// optional - builds actions UI
  ///
  /// It is provided by default if you leave it as a null.
  final MapActionsBuilder? mapActionsBuilder;

  /// search textfield builder
  ///
  final SearchFieldBuilder searchFieldBuilder;

  /// Markers to be placed on the map.
  ///
  /// Defaults to `const <Marker>{}`
  final Set<Marker> markers;
  final Set<ClusterManager> clusterManagers;

  final String? style;
  final WidgetBuilder? errorBuilder;

  final Color? floatingBtnsColor;
  final ArgumentCallback<LatLng>? onTap;

  final Decoration? searchedOverlayDecoration;
  final PredictionTileTheme? predictionTileTheme;
  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<LocationPickerViewer> {
  GlobalKey appBarKey = GlobalKey();
  late final Future<PlaceProvider> _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();
  bool showIntroModal = true;

  @override
  void initState() {
    super.initState();
    assert(
      widget.initialPosition != null || widget.useCurrentLocation,
      'If initialPosition is null, useCurrentLocation must be true.',
    );
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
    if (widget.useCurrentLocation) {
      await provider.updateCurrentLocation(
          gracefully: widget.ignoreLocationPermissionErrors);
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (willPOP, __) {
        if (willPOP) return;
        searchBarController.clearOverlay();
      },
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

          if (snapshot.hasError) {
            return widget.errorBuilder == null
                ? Scaffold(
                    body: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: ${snapshot.error}'),
                      )
                    ],
                  ))
                : widget.errorBuilder!(context);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    if (provider!.currentPosition == null && widget.initialPosition == null) {
      return SizedBox.shrink();
    }
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
                padding: EdgeInsets.zero)
            : SizedBox.shrink(),
        if (widget.allowSearching)
          Expanded(
            child: AutoCompleteSearch(
              appBarKey: appBarKey,
              searchedOverlayDecoration: widget.searchedOverlayDecoration,
              searchBarController: searchBarController,
              usePinPointingSearch: widget.usePinPointingSearch,
              searchFieldBuilder: widget.searchFieldBuilder,
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
              predictionTileTheme: widget.predictionTileTheme,
            ),
          ),
        SizedBox(width: 15),
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
      if (widget.initialPosition != null)
        return _buildMap(widget.initialPosition!);
    } else {
      return _buildMap(LatLng(provider!.currentPosition!.latitude,
          provider!.currentPosition!.longitude));
    }
    return widget.errorBuilder == null
        ? Center(
            child: Text("No location specified"),
          )
        : widget.errorBuilder!(context);
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapLocationPicker(
      clusterManagers: widget.clusterManagers,
      fullMotion: !widget.resizeToAvoidBottomInset,
      initialTarget: initialTarget,
      style: widget.style,
      mapActionsBuilder: widget.mapActionsBuilder,
      floatingBtnsColor: widget.floatingBtnsColor,
      initialZoomLevel: widget.initialZoomLevel,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
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
      onDefaultMapTypeToggle: () {
        if (provider == null) return;
        provider!.switchMapType();
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
            gracefully: widget.ignoreLocationPermissionErrors,
          );

          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {},
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      polygons: widget.polygons,
      allowSearching: widget.allowSearching,
      markers: widget.markers,
      onTap: widget.onTap,
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
            : SizedBox.shrink();
      },
    );
  }
}
