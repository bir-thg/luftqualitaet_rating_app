import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luftqualität Bewertung',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _rating = 1;
  bool _isSending = false;
  String serverUrl = 'http://broesel.net:40081/rating';

  void _setRating(int rating) {
    setState(() {
      _rating = rating;
    });
  }

  Future<void> _sendData() async {
    setState(() {
      _isSending = true;
    });

    try {
      var url = Uri.parse(serverUrl);
      http.Response response;

      if (Platform.isLinux) {
        // Auf Linux nur die Bewertung senden
        response = await http.post(url, body: {
          'rating': _rating.toString(),
        });
      } else {
        // Auf anderen Plattformen Geokoordinaten ermitteln
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'Location services are disabled.';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Location permissions are denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'Location permissions are permanently denied, we cannot request permissions.';
        }

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark placemark = placemarks[0];

        response = await http.post(url, body: {
          'rating': _rating.toString(),
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'country': placemark.country ?? '',
          'locality': placemark.locality ?? '',
          'street': placemark.street ?? '',
          'postalCode': placemark.postalCode ?? '',
        });
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daten erfolgreich gesendet!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Senden der Daten')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luftqualität Bewertung'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Wie bewerten Sie die Luftqualität?'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: _rating > index ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () => _setRating(index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),
            _isSending
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendData,
                    child: const Text('Bewertung senden'),
                  ),
          ],
        ),
      ),
    );
  }
}
