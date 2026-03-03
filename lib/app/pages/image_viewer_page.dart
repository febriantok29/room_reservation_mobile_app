import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final ImageProvider imageProvider;

  const ImageViewerPage({super.key, required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dismissible(
        key: const Key('image_viewer_dismissible'),
        direction: DismissDirection.vertical,
        onDismissed: (_) {
          Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
