import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_location_picker/google_maps_location_picker.dart';
import 'dart:async';

import 'package:google_maps_location_picker_demo/keys.dart';
import 'package:the_widget_marker/the_widget_marker.dart';

class PersonalMapPage extends StatefulWidget {
  const PersonalMapPage({super.key});

  @override
  State<PersonalMapPage> createState() => _PersonalMapPageState();
}

class _PersonalMapPageState extends State<PersonalMapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LocationPickerViewer(
      allowSearching: true,
      markers: markers.values.toSet(),
      onMapCreated: (controller) async {
        _controller.complete(controller);

        final marker = Marker(
          markerId: const MarkerId("iddd"),
          icon: await MarkerIcon.downloadResizePictureCircle(
            'https://file-dev.flytechy.com/public/detection/8d308228-ceda-409f-b9be-b2d2861e7a7d_inside_2000_.jpeg',
            size: 160,
            addBorder: true,
            borderColor: Colors.white,
            borderSize: 15,
          ),
          position: const LatLng(37.785834, -122.406417),
        );

        setState(() {
          markers.clear();
          markers[const MarkerId('iddd')] = marker;
        });
        print(markers);
      },
      apiKey: Platform.isAndroid ? APIKeys.androidApiKey : APIKeys.iosApiKey,
      selectedPlaceWidgetBuilder: (BuildContext context,
          PickResult? selectedPlace,
          SearchingState state,
          bool isSearchBarFocused) {
        return const SizedBox.shrink();
      },
      initialZoomLevel: 12,
      useCurrentLocation: true,
      selectInitialPosition: true,
      usePinPointingSearch: true,
      usePlaceDetailSearch: true,
      zoomGesturesEnabled: true,
      automaticallyImplyAppBarLeading: false,
      ignoreLocationPermissionErrors: true,
      zoomControlsEnabled: false,
      predictionTileTheme: PredictionTileTheme(
        leading: Icon(Icons.abc_outlined),
        matchedStyle: TextStyle(color: Colors.green),
        regularStyle: TextStyle(),
      ),
      searchFieldBuilder: (context, controller, focus) {
        return TextField(
          controller: controller,
          focusNode: focus,
        );
      },
      searchedOverlayDecoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
    );
  }
}
