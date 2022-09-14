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
            title: const Text("Image RP : 32 (5공학관 6층 5648호)"),
            subtitle: const Text("RSSI RP : 46"),
          )
        ],
      ),
    );
  }
}
