import 'package:flutter/material.dart';

class SelectImage extends StatefulWidget {
  const SelectImage({Key? key}) : super(key: key);

  @override
  State<SelectImage> createState() => _SelectImageState();
}

class _SelectImageState extends State<SelectImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          ListTile(
            onTap: () {
              Navigator.pop(context, '1');
            },
            leading: Container(
              child: const Image(
                height: 150,
                image: AssetImage('test_data/test_image1.jpg'),
              ),
            ),
            title: const Text("Image RP : 32 (5공학관 6층)"),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context, '2');
            },
            leading: Container(
              child: const Image(
                height: 150,
                image: AssetImage('test_data/test_image2.jpg'),
              ),
            ),
            title: const Text("Image RP : 4 (5공학관 5층)"),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context, '3');
            },
            leading: Container(
              child: const Image(
                height: 150,
                image: AssetImage('test_data/test_image3.jpg'),
              ),
            ),
            title: const Text("Image RP : 1 (5공학관 5층)"),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context, '4');
            },
            leading: Container(
              child: const Image(
                height: 150,
                image: AssetImage('test_data/test_image4.jpg'),
              ),
            ),
            title: const Text("Image RP : 13 (5공학관 6층)"),
          )
        ],
      ),
    );
  }
}
