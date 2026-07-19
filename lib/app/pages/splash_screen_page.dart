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
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'assets/bi/logo.jpg',
                    fit: BoxFit.contain,
                  ),
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
