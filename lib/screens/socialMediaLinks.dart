import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome icons

class SocialMediaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        title: Text('Connect With Me'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/image.jpeg'),
            ),
            SizedBox(height: 20),
            Text(
              'Emdad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Social Media Links',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            SocialMediaButtons(),
          ],
        ),
      ),
    );
  }
}

class SocialMediaButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(FontAwesomeIcons.facebook,
              color: Colors.blue[800], size: 40),
          onPressed: () {
            // Open Facebook link
          },
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.instagram,
              color: Colors.pinkAccent, size: 40),
          onPressed: () {
            // Open Instagram link
          },
        ),
        IconButton(
          icon:
              Icon(FontAwesomeIcons.twitter, color: Colors.lightBlue, size: 40),
          onPressed: () {
            // Open Twitter link
          },
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.linkedin,
              color: Colors.blue[600], size: 40),
          onPressed: () {
            // Open LinkedIn link
          },
        ),
      ],
    );
  }
}
