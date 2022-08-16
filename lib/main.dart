import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:wifi_hunter/wifi_hunter_result.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  PickedFile? _image;
  Uint8List? _searchImage;
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();
  final List<String> _imageSearchAlgoList = [
    'feature_extract',
    'feature_match'
  ];
  String _selectedImageSearchAlgo = 'feature_extract';

  final List<int> _rssiCandidateMaxRPList = [1, 2, 3, 4, 5];
  int _selectedRssiCandidateMaxRP = 1;

  Map<String, int> rssi = {};
  List<dynamic> rssi_rp = [];
  List<dynamic> rssi_rp_prob = [];
  String visual_rp = "";
  String dist = "";

  Future<void> permissionRequest() async {
    if (await Permission.camera.request().isGranted) {
      debugPrint('camera');
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
    ].request();
  }

  Future huntWiFis() async {
    try {
      wiFiHunterResult = (await WiFiHunter.huntWiFiNetworks)!;
      for (var data in wiFiHunterResult.results) {
        rssi[data.BSSID] = data.level;
      }
    } on PlatformException catch (exception) {
      debugPrint(exception.toString());
    }
  }

  Future captureImage() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 30);

      if (image == null) return;
      final imageTemp = PickedFile(image.path);

      setState(() {
        _image = imageTemp;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to pick image: $e");
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 30);

      if (image == null) return;
      final imageTemp = PickedFile(image.path);

      setState(() {
        _image = imageTemp;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to pick image: $e");
    }
  }

  Future sendImage() async {
    Dio dio = Dio();
    if (_image != null) {
      dynamic sendData = _image?.path;

      dynamic formData =
          FormData.fromMap({'image': await MultipartFile.fromFile(sendData)});

      var response = await dio.post(
        'http://117.17.157.104:15261/visual_map_predict/$_selectedImageSearchAlgo',
        queryParameters: {'rp': rssi_rp},
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      if (response.statusCode == 200) {
        try {
          setState(() {
            _searchImage = base64Decode(response.data['img'].toString());
            dist = response.data['dist'].toString();
            visual_rp = response.data['rp'].toString();
          });
        } catch (e) {
          print(e);
        }
      }
    } else {
      debugPrint('이미지를 업로드 해주세요');
    }
  }

  Future sendRssi() async {
    Dio dio = Dio();
    try {
      if (rssi.isNotEmpty) {
        Response response = await dio.post(
          'http://117.17.157.104:15261/radio_map_predict',
          data: jsonEncode({'rssi': rssi}),
          queryParameters: {'max_rp': _selectedRssiCandidateMaxRP},
          options: Options(
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ),
        );
        if (response.statusCode == 200) {
          setState(() {
            rssi_rp = response.data['rp'];
            rssi_rp_prob = response.data['prob'];
          });
          // rssi.clear();
        }
      } else {
        debugPrint('RSSI를 수집해주세요');
      }
    } catch (e) {
      Exception(e);
      debugPrint(e.toString());
    } finally {
      dio.close();
    }
  }

  @override
  void initState() {
    super.initState();
    permissionRequest();
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
                    huntWiFis();
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20.0,
                          child: const Center(
                            child: Text(
                              'Query Image',
                              style: TextStyle(fontSize: 10.0),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.lightBlueAccent, width: 1.0),
                          ),
                        ),
                        Container(
                          child: _image == null
                              ? const Text('')
                              : Image.file(File(_image!.path), height: 248),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20.0,
                        child: const Center(
                          child: Text(
                            'Search Image',
                            style: TextStyle(fontSize: 10.0),
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Colors.lightBlueAccent, width: 1.0),
                        ),
                      ),
                      Container(
                        child: _searchImage == null
                            ? const Text('')
                            : GestureDetector(
                                child: Image.memory(_searchImage!, height: 248),
                                onTap: () async {
                                  await showDialog(
                                      context: context,
                                      builder: (_) =>
                                          ImageDialog(visual_rp: visual_rp));
                                },
                                onDoubleTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => WebView(
                                      initialUrl:
                                          "https://my.matterport.com/show/?m=evfzqBJihod&sr=-2.9,-.22&ss=$visual_rp",
                                      javascriptMode:
                                          JavascriptMode.unrestricted,
                                      gestureNavigationEnabled: true,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ))
                ],
              ),
              height: 270,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              width: double.infinity,
              height: 80.0,
              child: Center(
                child: Text(
                  'Visual RP : $visual_rp\nL2 distance similarity : $dist',
                  style: const TextStyle(fontSize: 20.0),
                  textAlign: TextAlign.center,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue.shade300, width: 3.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: GestureDetector(
                child: Center(
                  child: rssi_rp.isNotEmpty
                      ? Text(
                          'RSSI RP : ${rssi_rp[0]}\nProbability : ${rssi_rp_prob[0].toStringAsFixed(4)}%',
                          style: const TextStyle(fontSize: 20.0),
                          textAlign: TextAlign.center,
                        )
                      : const Text(
                          'RSSI RP :\nProbability : ',
                          style: TextStyle(fontSize: 20.0),
                          textAlign: TextAlign.center,
                        ),
                ),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => RPDialog(
                      rssi_rp: rssi_rp,
                      rssi_rp_prob: rssi_rp_prob,
                    ),
                  );
                },
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              height: 70,
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        const Text("Maximum Candidate RSSI RP"),
                        Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              isExpanded: true,
                              value: _selectedRssiCandidateMaxRP,
                              items: _rssiCandidateMaxRPList.map((value) {
                                return DropdownMenuItem(
                                    value: value,
                                    child:
                                        Center(child: Text(value.toString())));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRssiCandidateMaxRP =
                                      int.parse(value.toString());
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    height: 70,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Center(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          isExpanded: true,
                          value: _selectedImageSearchAlgo,
                          items: _imageSearchAlgoList.map((value) {
                            return DropdownMenuItem(
                                value: value,
                                child: Center(child: Text(value)));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedImageSearchAlgo = value.toString();
                            });
                          },
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    height: 70,
                  ),
                ),
              ],
            ),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              width: double.infinity,
              height: 60.0,
              child: ElevatedButton(
                onPressed: () {
                  sendRssi();
                },
                child: const Text("Fi-Vi 1st Search(RSSI Search)"),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.all(10.0),
                  ),
                ),
              ),
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
                child: const Text("Fi-Vi 2nd Search(Visual Search)"),
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

class RPDialog extends StatefulWidget {
  const RPDialog({Key? key, required this.rssi_rp, required this.rssi_rp_prob})
      : super(key: key);

  final List rssi_rp;
  final List rssi_rp_prob;

  @override
  State<RPDialog> createState() => _RPDialogState();
}

class _RPDialogState extends State<RPDialog> {
  @override
  Widget build(BuildContext context) {
    print(widget.rssi_rp);
    print(widget.rssi_rp_prob);
    return Dialog(
      child: SizedBox(
        height: 250,
        child: ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(
                    "${widget.rssi_rp[index].toString()} : ${widget.rssi_rp_prob[index].toStringAsFixed(4)}%"),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(thickness: 1);
            },
            itemCount: widget.rssi_rp.length),
      ),
    );
  }
}

class ImageDialog extends StatefulWidget {
  const ImageDialog({Key? key, required this.visual_rp}) : super(key: key);

  final String visual_rp;

  @override
  State<ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: PhotoView(
        imageProvider: AssetImage('images/visual_rp_${widget.visual_rp}.png'),
        backgroundDecoration: BoxDecoration(color: Colors.white),
      ),
    );
  }
}
