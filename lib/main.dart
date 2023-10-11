import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:optiskane/tripPage.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';

void main() {
  runApp(MaterialApp(
    title: "OptiSkane",
    theme: ThemeData.dark(useMaterial3: true),
    home: const MyApp()
  ));
}

// Converts total-seconds to "hh:mm:ss" format
String secondsToStr(int s) {
  int h = ((s ~/ 3600) % 24);
  int m = ((s ~/ 60) % 60);
  int sec = (s % 60);

  String hStr = h.toString().padLeft(2, '0');
  String mStr = m.toString().padLeft(2, '0');
  String secStr = sec.toString().padLeft(2, '0');

  return "$hStr:$mStr:$secStr";
}

// Converts "hh:mm:ss" to total-seconds
int strToSeconds(String s) {
  int h = int.parse(s.substring(0, 2));
  int m = int.parse(s.substring(3, 5));
  int sec = int.parse(s.substring(6, 8));
  return h * 3600 + m * 60 + sec;
}

int walkTimeToMeters(Trip t) {
  int diff = strToSeconds(t.arrivalTime) - strToSeconds(t.departureTime);
  return (diff / 2 / 3600 * 5 * 1000).toInt();
}

class Trip {
  late String fromStopName;
  late String fromPlatformCode;
  late String departureTime;
  late String toStopName;
  late String toPlatformCode;
  late String arrivalTime;
  late String routeName;

  Trip(this.fromStopName, this.fromPlatformCode, this.departureTime,
      this.toStopName, this.toPlatformCode, this.arrivalTime, this.routeName);

  String duration() {
    int diff = strToSeconds(arrivalTime) - strToSeconds(departureTime);
    int hours = diff ~/ 3600;
    int mins = (diff - hours * 3600) ~/ 60;
    return hours > 0 ? "$hours h $mins m" : "$mins min";
  }

  Icon getIcon() {
    if (routeName.contains("Regionbuss")) {
      return const Icon(Icons.directions_bus, color: Colors.yellow,);
    } else if (routeName.contains("Stadsbuss")) {
      return const Icon(Icons.directions_bus, color: Colors.green);
    } else if (routeName.contains("Spårvagn")) {
      return const Icon(Icons.tram, color: Colors.green,);
    } else if (routeName.contains("Pågatåg")) {
      return const Icon(Icons.train, color: Colors.deepPurple);
    } else if (routeName.contains("Öresundståg")) {
      return const Icon(Icons.train, color: Colors.grey,);
    } else if (routeName.contains("Färja")) {
      return const Icon(Icons.directions_boat, color: Colors.lightBlue);
    } else if (routeName.contains("walking")) {
      return const Icon(Icons.directions_walk, color: Colors.grey,);
    } else if (routeName.contains("SkåneExpressen")) {
      return const Icon(Icons.directions_bus, color: Colors.yellow,);
    } else {
      return const Icon(Icons.question_mark);
    }
  }

  String getName(int tripCount) {
    if (routeName.contains("Regionbuss") | routeName.contains("SkåneExpressen")) {
      List<String> splitted = routeName.split(" ");
      return tripCount <= 2 ? routeName : tripCount == 3 ? "Buss ${splitted[1]}" : splitted[1];
    } else if (routeName.contains("Stadsbuss")) {
      List<String> splitted = routeName.split(" ");
      return tripCount <= 2 ? "Stadsbuss ${splitted[2]}" : tripCount <= 4 ? "Buss ${splitted[2]}" : splitted[2];
    } else if (routeName.contains("Spårvagn")) {
      List<String> splitted = routeName.split(" ");
      return tripCount <= 3 ? routeName : splitted[1];
    } else if (routeName.contains("Pågatåg")) {
      return "Pågatåg";
    } else if (routeName.contains("Öresundståg")) {
      return "Öresundståg";
    } else if (routeName.contains("Färja")) {
      return "Färja";
    } else if (routeName.contains("walking")) {
      return "${205} m";
    } else {
      return routeName;
    }
  }

  Widget asSmallWidget(int tripCount) {
    return Flexible(
      flex: 1,
      child: Material(child: Row(children: [
        getIcon(),
        Flexible(child: Text(getName(tripCount), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis,))
      ],),),
    );
  }

  Widget asBigWidget() {
    return SizedBox(
      width: double.infinity,
      height: routeName == "walking" ? 75 : 150,
      child: Card(child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [

          Column(children: [
            Text(departureTime.substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold),),
            const Spacer(),
            if (routeName != "walking")
              Text(arrivalTime.substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold),),
            const SizedBox(height: 12,)
          ],),

          const SizedBox(width: 3,),
          Column(children: [
            getIcon(),
            if (routeName != "walking")
              const Expanded(child: VerticalDivider(color: Colors.grey, width: 10,)),
            if (routeName != "walking")
              const Icon(Icons.location_on_outlined),
            const SizedBox(height: 7,)
          ],),

          const SizedBox(width: 3,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(fromStopName == "origin" ? "Min position" : fromStopName, style: const TextStyle(fontSize: 15),),
            Text(routeName != "walking" ? "$routeName\nLäge $fromPlatformCode" : "Cirka: ${walkTimeToMeters(this)} m", style: const TextStyle(fontSize: 12),),
            const Spacer(),
            if (routeName != "walking")
              Text(toStopName, style: const TextStyle(fontSize: 15),),
            if (routeName != "walking")
              Text("Läge $toPlatformCode", style: const TextStyle(fontSize: 12))
          ],),

          const Spacer(),
          Column(children: [
            const Spacer(),
            Text("Restid: ${duration()}")
          ],)
          
        ],),
      ),),
    );
  }
}

class Journey {
  late List<Trip> trips;
  late int totalDuration;
  late int arrivalTime;
  late int nTransfers;

  Journey(this.trips, this.totalDuration, this.arrivalTime, this.nTransfers);

  String prettyDuration() {
    int nHours = ((totalDuration ~/ 3600) % 24);
    int nMins = ((totalDuration ~/ 60) % 60);
    return nHours > 0 ? "${nHours}h ${nMins}m" : "$nMins min";
  }

  Widget asRowWidget() {
    Iterable<Trip> nonWalkTrips = trips.where((trip) => trip.routeName != "walking");
    List<Widget> tripWidgets = nonWalkTrips.map((trip) => trip.asSmallWidget(nonWalkTrips.length)).toList();
    return Column(children: [

      Row(children: [
        Text(trips[1].departureTime.substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold),),
        const Spacer(),
        Text(trips[trips.length - 2].arrivalTime.substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold))
      ],),

      Row(children: [
        Text("${trips[1].fromStopName}, Läge ${trips[1].fromPlatformCode}", style: const TextStyle(fontSize: 13),),
        const Spacer(),
        Text(prettyDuration(), style: const TextStyle(fontSize: 13),)
      ],),

      Row(children: tripWidgets,)

    ],);
  }
  
}

class GeoPoint {
  late String name;
  late String address;
  late double latitude;
  late double longitude;

  GeoPoint(this.name, this.address, this.latitude, this.longitude);

  GeoPoint.fromStr(String s) {
    List<String> attrs = s.split("|");
    name = attrs[0];
    address = attrs[1];
    latitude = double.parse(attrs[2]);
    longitude = double.parse(attrs[3]);
  }

  LatLng pos() {
    return LatLng(latitude, longitude);
  }

  String displayName() {
    return address.isNotEmpty ? "$name, $address" : name;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() {
    return "$name|$address|$latitude|$longitude";
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Controllers
  late GoogleMapController mapController;
  FloatingSearchBarController searchBarController = FloatingSearchBarController();
  GlobalKey<ExpandableBottomSheetState> bottomSheetController = GlobalKey();

  // GoogleMap specific variables
  String mapStyle = '[ { "elementType": "geometry", "stylers": [ { "color": "#242f3e" } ] }, { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] }, { "elementType": "labels.text.stroke", "stylers": [ { "color": "#242f3e" } ] }, { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#263c3f" } ] }, { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#6b9a76" } ] }, { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#38414e" } ] }, { "featureType": "road", "elementType": "geometry.stroke", "stylers": [ { "color": "#212a37" } ] }, { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca5b3" } ] }, { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#746855" } ] }, { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#1f2835" } ] }, { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3d19c" } ] }, { "featureType": "transit", "elementType": "geometry", "stylers": [ { "color": "#2f3948" } ] }, { "featureType": "transit.line", "stylers": [ { "visibility": "on" } ] }, { "featureType": "transit.station", "stylers": [ { "visibility": "on" } ] }, { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] }, { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#17263c" } ] }, { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#515c6d" } ] }, { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [ { "color": "#17263c" } ] } ]';
  Set<Marker> markers = {};

  // Shared preferences
  late SharedPreferences prefs;
  List<GeoPoint> recentSearches = [];
  List<GeoPoint> searchBookmarks = [GeoPoint("Hem", "", 0, 0),
                                    GeoPoint("LTH", "", 55.71125, 13.20989)];

  // MapBox search API
  var placesSearch = PlacesSearch(
      apiKey: "",
      country: "SE",
      limit: 5,
      language: "SE"
  );
  List<GeoPoint> searchResults = [];

  // Current search origin & destination
  bool setDestination = true;
  GeoPoint searchOrigin = GeoPoint("Min position", "", 0, 0);  // dummy
  late GeoPoint searchDestination;
  List<Journey> journeys = [];

  // Loads recentSearches & searchBookmarks from SharedPreferences
  Future<void> loadAllData() async {
    prefs = await SharedPreferences.getInstance();
    List<String> tmpRecentSearches = prefs.getStringList("recentSearches") ??
        [];
    tmpRecentSearches.map((s) => recentSearches.add(GeoPoint.fromStr(s)));
    List<String> tmpSearchBookmarks = prefs.getStringList("searchBookmarks") ??
        [];
    tmpSearchBookmarks.map((s) => searchBookmarks.add(GeoPoint.fromStr(s)));
  }

  // Saves provided data to SharedPreferences
  Future<void> saveData(String key, List<String> data) async {
    prefs.setStringList(key, data);
  }

  // Gets user's current location
  Future<LatLng> getCurrentLocation() async {
    // Ask for location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Get current location
    Position pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  // Performs journey search after map is tapped
  Future<void> mapTapped(LatLng pos) async {
    // Update current destination
    List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    searchDestination = GeoPoint(
        placemarks.first.street ?? "", placemarks.last.street ?? "",
        pos.latitude, pos.longitude);
    searchJourneys();
  }

  // Goes to a certain location
  Future<void> goToLocation({LatLng? pos, bool mark = true}) async {
    // Sets position to current location
    pos ??= await getCurrentLocation();

    // Add marker to map & update searchBar
    if (mark) {
      markers.clear();
      markers.add(Marker(markerId: const MarkerId(""), position: pos));
      searchBarController.query = searchDestination.displayName();
      setState(() {});
    }

    // Update camera to new location
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(mark ? pos.latitude - 0.004 : pos.latitude, pos.longitude),
      zoom: 15
    )));
  }

  // Set searchOrigin to current location
  Future<void> setOriginToCurrentLocation() async {
    LatLng curPos = await getCurrentLocation();
    searchOrigin = GeoPoint("Min position", "", curPos.latitude, curPos.longitude);
  }

  // MapBox search autocompletion
  Future<void> getSearchResults(String query) async {
    searchResults.clear();
    if (query.length > 2) {
      // Gather places
      var places = await placesSearch.getPlaces(query);

      // Update searchResults
      places?.forEach((place) {
        String name = place.text as String;
        String address = place.placeName?.replaceAll("$name, ", "") as String;
        List<double> coords = place.geometry?.coordinates as List<double>;
        searchResults.add(GeoPoint(name, address, coords[1], coords[0]));
      });
    }
    setState(() {});
  }

  // Searches journeys
  Future<void> searchJourneys() async {
    // Go to destination on map & mark it
    goToLocation(pos: searchDestination.pos());

    // Expand bottom
    bottomSheetController.currentState?.expand();

    // Request journeys
    DateTime now = DateTime.now();
    var r = await Requests.post("http://000000:8000/search", json: {
      "origin": [searchOrigin.latitude, searchOrigin.longitude],
      "destination": [searchDestination.latitude, searchDestination.longitude],
      "departure_time": DateFormat("HH:mm:ss").format(now)
    });

    // Extract journeys
    List<dynamic> data = r.json() as List;
    journeys.clear();
    for (var journey in data) {
      List<Trip> trips = [];
      for (var trip in (journey["path"] as List)) {trips.add(Trip(
          trip["from_stop_name"],
          trip["from_platform_code"] ?? "",
          secondsToStr(trip["departure_time"].toInt()),
          trip["to_stop_name"],
          trip["to_platform_code"] ?? "",
          secondsToStr(trip["arrival_time"].toInt()),
          trip["route_name"])
      );}
      journeys.add(Journey(trips, journey["total_duration"].toInt(), journey["arrival_time"].toInt(), journey["n_transfers"].toInt()));
    }
    journeys.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent
    ));
    loadAllData();
    setOriginToCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(children: [

          GoogleMap(
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            markers: markers,
            initialCameraPosition: const CameraPosition(
                target: LatLng(55.80848, 13.47307),
                zoom: 8
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              mapController.setMapStyle(mapStyle);
              goToLocation(mark: false);
            },
            onTap: (LatLng pos) {
              mapTapped(pos);
            },
          ),

          Positioned(right: 15, bottom: 15, child: FloatingActionButton(
            backgroundColor: Colors.black87,
            child: const Icon(Icons.my_location),
            onPressed: () {goToLocation(mark: false);},
          )),

          ExpandableBottomSheet(
            key: bottomSheetController,
            enableToggle: true,
            background: Container(),
            // persistentContentHeight: searchBarController.query.isEmpty ? 0 : 25, // nej.
            expandableContent: SizedBox(
                height: 450,
                child: Material(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)
                  ),
                  child: Column(children: [

                    Container(height: 15,),
                    SizedBox(
                      height: 50,
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: InkWell(
                          onTap: () {
                            setDestination = false;
                            searchBarController.open();
                            searchBarController.query = "";
                          },
                          child: Card(child: Row(children: [
                            const SizedBox(width: 5,),
                            const Icon(Icons.trip_origin),
                            const Text(" Från:  "),
                            Expanded(child: Text(searchOrigin.displayName(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ))
                          ]))
                      ),
                    ),

                    Container(height: 15,),
                    SizedBox(
                      height: 370,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (_, index) {
                          Journey journey = journeys[index];
                          return ListTile(
                            leading: Column(children: [
                              Text(journey.trips.first.departureTime.substring(0, 5)),
                              Text("${walkTimeToMeters(journey.trips.first)} m"),
                              const SizedBox(height: 2,),
                              const Flexible(child: Icon(Icons.directions_walk, size: 30,))
                            ],),
                            trailing: Column(children: [
                              Text(journey.trips.last.arrivalTime.substring(0, 5)),
                              Text("${walkTimeToMeters(journey.trips.last)} m"),
                              const SizedBox(height: 2,),
                              const Flexible(child: Icon(Icons.directions_walk, size: 30,))
                            ],),
                            title: journey.asRowWidget(),
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => TripPage(journey: journey, origin: searchOrigin, destination: searchDestination)));
                            },
                          );},
                        separatorBuilder: (_, __) => const Divider(),
                        itemCount: journeys.length
                      ),
                    )

                  ],)
                  ,)
            ),
          ),

          FloatingSearchBar(
            hint: "Sök destination",
            height: 42,
            borderRadius: BorderRadius.circular(36),
            clearQueryOnClose: false,
            controller: searchBarController,
            transition: ExpandingFloatingSearchBarTransition(),
            leadingActions: [
              FloatingSearchBarAction.icon(
                  icon: const Icon(Icons.pin_drop), onTap: () {}),
              FloatingSearchBarAction.back()
            ],
            actions: [
              FloatingSearchBarAction.searchToClear(showIfClosed: false),
              if (searchBarController.isClosed & searchBarController.query.isNotEmpty)
                IconButton(onPressed: () {
                  setState(() {
                    searchBarController.query = "";
                    setOriginToCurrentLocation();
                    bottomSheetController.currentState?.contract();
                    journeys.clear();
                  });
                  }, icon: const Icon(Icons.clear))
            ],
            onQueryChanged: (query) {
              getSearchResults(query);
            },
            builder: (context, transition) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (searchResults.isEmpty)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        height: 74,
                        child: ListView.separated(
                            itemBuilder: (_, index) {
                              return InkWell(
                                onTap: () {
                                  // Update origin/destination
                                  if (setDestination) {
                                    searchDestination = searchBookmarks[index];
                                  } else {
                                    searchOrigin = searchBookmarks[index];
                                    setDestination = true;
                                  }

                                  // Search new journeys
                                  searchJourneys();
                                  searchBarController.close();
                                },
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      Icon(searchBookmarks[index].name == "Hem" ? Icons.home : Icons.school),
                                      const SizedBox(width: 5,),
                                      Text(searchBookmarks[index].name, style: const TextStyle(fontWeight: FontWeight.bold),)
                                    ],)
                                  ),
                                ),
                              );
                            },
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (_, __) => const Divider(),
                            itemCount: searchBookmarks.length
                        ),
                      ),
                      const Divider(),
                      const Text("  Senaste", style: TextStyle(fontWeight: FontWeight.bold),),
                      const SizedBox(height: 10,),
                    ],),

                  SizedBox(
                    height: 600,
                    child: ListView.separated(
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (_, index) {
                          GeoPoint gp = searchResults.isEmpty ? recentSearches[index] : searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.alarm),
                            title: Text(gp.name),
                            subtitle: Text(gp.address),
                            onTap: () {
                              // Update origin/destination
                              if (setDestination) {
                                searchDestination = gp;
                              } else {
                                searchOrigin = gp;
                                setDestination = true;
                              }

                              // Search new journeys
                              searchJourneys();
                              searchBarController.close();

                              // Update recent searches
                              if (!recentSearches.contains(gp)) {
                                recentSearches.add(gp);
                              }
                              if (recentSearches.length > 5) {
                                recentSearches = recentSearches.sublist(recentSearches.length - 5);
                              }
                              saveData("recentSearches", recentSearches.map((gp) => gp.toString()).toList());
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(),
                        itemCount: searchResults.isEmpty ? recentSearches.length : searchResults.length),
                  )

                ],
              );
            },
          ),
        ])
    );
  }
}
