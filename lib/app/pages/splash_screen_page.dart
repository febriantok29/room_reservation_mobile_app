import 'package:flutter/material.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overScroll) {
              overScroll.disallowIndicator();
              return false;
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                AspectRatio(
                  aspectRatio: 11 / 3,
                  child: Icon(Icons.meeting_room, size: 48),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32.0, bottom: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                const Text('Memuat data...', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
