import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var status = await Permission.location.request();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  if (status.isGranted) {
    runApp(const MyApp());
  } else {
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fullscreen WebView App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FullScreenWebView(),
    );
  }
}

class FullScreenWebView extends StatelessWidget {
  final String url = "https://saengbang.xyz";
  final String url2= "http://192.168.192.204";
  String? _currentAddress;
  Position? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: Uri.parse(url2),
                ),
                onWebViewCreated: (controller) async{
                  _currentPosition ??= await _getCurrentPosition();
                  controller.addJavaScriptHandler(handlerName: 'getLocation', callback: (args) async{
                    var position = {
                      'lat': _currentPosition?.latitude, 'lon': _currentPosition?.longitude
                    };
                    print(position);
                    return position;
                  });
                },
                onLoadStop:(InAppWebViewController controller, Uri? uri) async {
                  if(uri != null && uri.origin == url) {
                    await _getCurrentPosition();
                    print(_currentPosition?.latitude??"");
                    print(_currentPosition?.longitude??"");
                    print(uri.origin);
                  }
                },
                initialOptions: InAppWebViewGroupOptions(
                  android: AndroidInAppWebViewOptions(
                    useHybridComposition: true,
                    useWideViewPort: true,
                    geolocationEnabled: true,
                  ),
                  ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true,
                  ),
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      _currentAddress ='${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }
}