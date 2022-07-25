import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fi-Vi Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Fi-Vi Demo😸'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? image;

  Future captureImage() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 30);

      if (image == null) return;
      final imageTemp = XFile(image.path);

      setState(() {
        this.image = imageTemp;
      });
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 30);

      if (image == null) return;
      final imageTemp = XFile(image.path);

      setState(() {
        this.image = imageTemp;
      });
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future sendImage() async {
    Dio dio = new Dio();
    if (image != null) {
      dynamic sendData = image?.path;

      dynamic formData =
          FormData.fromMap({'image': await MultipartFile.fromFile(sendData)});
      var response = await dio.post(
        'http://117.17.157.104:15261/visual_map_predict',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      // .timeout(const Duration(seconds: 10));
      print(response);
    } else {
      print('이미지를 업로드 해주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    captureImage();
                  },
                  child: const Text("Capture Image"),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.all(10.0),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    pickImage();
                  },
                  child: const Text("Select Image"),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.all(10.0),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Center(
                child: image == null
                    ? const Text(
                        '3D Viewpoint result of the most probability RP')
                    : Image.file(File(image!.path)),
              ),
              height: 250,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              width: double.infinity,
              height: 80.0,
              child: const Center(
                child: Text(
                  'Candidate RP a: probability',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 1.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              width: double.infinity,
              height: 80.0,
              child: const Center(
                child: Text(
                  'Candidate RP b: probability',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 1.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              width: double.infinity,
              height: 80.0,
              child: const Center(
                child: Text(
                  'Candidate RP c: probability',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 1.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.only(left: 10.0),
                    child: const Center(
                      child: Text(
                        'Detail',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    height: 50,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    child: const Center(
                      child: Text(
                        'Select button for\nSearch algorithm',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    height: 50,
                  ),
                )
              ],
            ),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              width: double.infinity,
              height: 60.0,
              child: ElevatedButton(
                onPressed: () {
                  sendImage();
                },
                child: const Text("Search"),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.all(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
