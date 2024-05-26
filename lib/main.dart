import 'package:flutter/material.dart' show AppBar, BuildContext, Center, CircularProgressIndicator, Colors, Column, ElevatedButton, Icon, IconButton, Icons, MainAxisAlignment, MaterialApp, Row, Scaffold, ScaffoldMessenger, SizedBox, SnackBar, State, StatefulWidget, StatelessWidget, Text, ThemeData, Widget, runApp;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luftqualität Bewertung',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

// ignore: use_key_in_widget_constructors
class MyHomePage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _rating = 1;
  bool _isSending = false;

  void _setRating(int rating) {
    setState(() {
      _rating = rating;
    });
  }

  Future<void> _sendData() async {
    setState(() {
      _isSending = true;
    });



    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    var url = Uri.parse('http://192.168.178.58:3000/rating');
    var response = await http.post(url, body: {
      'rating': _rating.toString(),
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
    });

    setState(() {
      _isSending = false;
    });

    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daten erfolgreich gesendet!')));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Senden der Daten')));
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
