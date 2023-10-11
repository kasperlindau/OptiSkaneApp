import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:optiskane/main.dart';


class TripPage extends StatelessWidget {
  final Journey journey;
  final GeoPoint origin;
  final GeoPoint destination;

  TripPage({super.key, required this.journey, required this.origin, required this.destination});

  // GoogleMap specific variables
  String mapStyle = '[ { "elementType": "geometry", "stylers": [ { "color": "#242f3e" } ] }, { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] }, { "elementType": "labels.text.stroke", "stylers": [ { "color": "#242f3e" } ] }, { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#263c3f" } ] }, { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#6b9a76" } ] }, { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#38414e" } ] }, { "featureType": "road", "elementType": "geometry.stroke", "stylers": [ { "color": "#212a37" } ] }, { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca5b3" } ] }, { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#746855" } ] }, { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#1f2835" } ] }, { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3d19c" } ] }, { "featureType": "transit", "elementType": "geometry", "stylers": [ { "color": "#2f3948" } ] }, { "featureType": "transit.line", "stylers": [ { "visibility": "on" } ] }, { "featureType": "transit.station", "stylers": [ { "visibility": "on" } ] }, { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#17263c" } ] }, { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#515c6d" } ] }, { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [ { "color": "#17263c" } ] } ]';

  LatLng getCameraTarget() {
    return LatLng(
      (origin.latitude + destination.latitude) / 2,
      (origin.longitude + destination.longitude) / 2);
  }

  double haversine() {
    double lat1 = origin.latitude;
    double lon1 = origin.longitude;
    double lat2 = destination.latitude;
    double lon2 = destination.longitude;

    // Convert latitude and longitude from degrees to radians
    lat1 = lat1 * (pi / 180.0);
    lon1 = lon1 * (pi / 180.0);
    lat2 = lat2 * (pi / 180.0);
    lon2 = lon2 * (pi / 180.0);

    // Haversine formula
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = 6371 * c;
    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        toolbarHeight: 30,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text("${origin.name} --> ${destination.name}", style: TextStyle(fontSize: 14),),
          Text("Byten: ${journey.nTransfers}    Restid: ${journey.prettyDuration()}", style: TextStyle(fontSize: 12),)
        ]),
      ),
      body: Column(children: [

        const SizedBox(height: 20,),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId("origin"),
                  // icon: BitmapDescriptor.defaultMarker,
                  position: LatLng(origin.latitude, origin.longitude),),
                Marker(
                  markerId: const MarkerId("destination"),
                  // icon: BitmapDescriptor.defaultMarker,
                  position: LatLng(destination.latitude, destination.longitude))
              },
              initialCameraPosition: CameraPosition(
                target: getCameraTarget(),
                zoom: 12 - log(haversine())
              ),
              onMapCreated: (GoogleMapController controller) {
                controller.setMapStyle(mapStyle);
              },
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(0),
            itemBuilder: (_, index) => journey.trips[index].asBigWidget(),
            itemCount: journey.trips.length
          ),
        )

      ],),
    );



  }
}










