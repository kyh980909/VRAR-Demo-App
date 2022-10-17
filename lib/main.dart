import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:demo/selectImage.dart';
import 'package:demo/selectResultImage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  Uint8List? _FiViSearchImage;
  Uint8List? _AllSearchImage;
  double _searchTime = 0.0;
  double _allSearchTime = 0.0;
  int _filteredImageLength = 0;
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();
  final List<String> _imageSearchAlgoList = ['euclidean', 'manhattan'];
  String _selectedImageSearchAlgo = 'euclidean';

  final List<int> _rssiCandidateMaxRPList = [1, 2, 3, 4, 5];
  int _selectedRssiCandidateMaxRP = 1;

  final List<String> _rssiModelList = ["Floor", "Space", "Case1", "Case2", "Case3"];
  String _selectedRssiModel = "Case1";

  Map<String, dynamic> rssi = {};
  String region = "";
  List<dynamic> rssi_rp = [];
  List<dynamic> rssi_rp_prob = [];
  String building = "";
  String floor = "";
  String visual_rp = "";
  String dist = "";
  String _allSearchDist = "";

  List<Map<String, dynamic>> resultDataList = [];

  final totalImageLength = 12390;

  double performanceCalculator(searchTime, allSearchTime) {
    return (allSearchTime - searchTime) * 100 / searchTime;
  }

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

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('test_data/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
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

  Future sendImage() async {
    Dio dio = Dio();
    resultDataList.clear();
    if (_image != null) {
      dynamic sendData = _image?.path;

      if (rssi_rp.isEmpty) rssi_rp = ['total'];

      for (int i = 0; i < _selectedRssiCandidateMaxRP; i++) {
        dynamic formData = FormData.fromMap({'image': await MultipartFile.fromFile(sendData)});
        Map<String, dynamic> _resultData = {};
        String sendRssiRp = rssi_rp.toString();

        var image_search_api = await dio.post(
          "http://117.17.157.101:58961/regionPoint?Building=$building&Floor=$floor&RP=${sendRssiRp.substring(1,sendRssiRp.length-1)}&Method=$_selectedImageSearchAlgo",
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ),
        );

        if (image_search_api.statusCode == 200) {
          try {
            _FiViSearchImage =
                base64Decode(image_search_api.data['img'].toString());
            dist = image_search_api.data['dist'].toString();
            visual_rp = image_search_api.data['rp'].toString();
            _searchTime = image_search_api.data['searchTime'];
            _filteredImageLength = image_search_api.data['length'];
            if(i == 0) {
              setState(() {});
            }
            _resultData['image'] = _FiViSearchImage;
            _resultData['dist'] = dist;
            _resultData['visual_rp'] = visual_rp;
            _resultData['search_time'] = _searchTime;
            _resultData['filtered_image_length'] = _filteredImageLength;

            resultDataList.add(_resultData);
          } catch (e) {
            print(e);
          }
        }
      }

      dynamic formData2 =
          FormData.fromMap({'image': await MultipartFile.fromFile(sendData)});
      var all_search = await dio.post(
        "http://117.17.157.101:58961/regionPoint?Building=0&Floor=0&RP=&Method=$_selectedImageSearchAlgo",
        data: formData2,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (all_search.statusCode == 200) {
        try {
          setState(() {
            _AllSearchImage = base64Decode(all_search.data['img'].toString());
            _allSearchTime = all_search.data['searchTime'];
            _allSearchDist = all_search.data['dist'];
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
          queryParameters: {'max_rp': _selectedRssiCandidateMaxRP, 'selected_model' : _selectedRssiModel},
          options: Options(
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ),
        );
        if (response.statusCode == 200) {
          print(response.data);
          setState(() {
            region = response.data['region'].toString();
            rssi_rp = response.data['rp'];
            rssi_rp_prob = response.data['prob'];
            building = response.data['building'];
            floor = response.data['floor'];
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectImage(),
                      ),
                    );
                    final image_path =
                        await getImageFileFromAssets('test_image$result.jpg');
                    final rssi_json = await rootBundle
                        .loadString('test_data/test_rssi$result.json');
                    final data = json.decode(rssi_json);

                    setState(() {
                      _image = PickedFile(image_path.path);
                      rssi = data;

                      _FiViSearchImage = null;
                      dist = "";
                      visual_rp = "";
                      _searchTime = 0.0;
                      _filteredImageLength = 0;

                      _AllSearchImage = null;
                      _allSearchTime = 0.0;
                      _allSearchDist = "";
                    });
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
              height: 400,
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(
                    width: 200,
                    height: 400,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20.0,
                          child: const Center(
                            child: Text(
                              'Query Image',
                              style: TextStyle(fontSize: 15.0),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.green, width: 1.0),
                          ),
                        ),
                        Expanded(
                          child: _image == null
                              ? const Center(child: Text("Empty"))
                              : Image.file(File(_image!.path), height: 370),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    height: 400,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectResultImage(resultDataList: resultDataList),
                              ),
                            );

                            if(result != null) {
                              setState(() {
                                _FiViSearchImage =
                                resultDataList[result]['image'];
                                dist = resultDataList[result]['dist'];
                                visual_rp = resultDataList[result]['visual_rp'];
                                _searchTime =
                                resultDataList[result]['search_time'];
                                _filteredImageLength =
                                resultDataList[result]['filtered_image_length'];
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 20.0,
                            child: const Center(
                              child: Text(
                                'Fi-Vi Search Image',
                                style: TextStyle(fontSize: 15.0),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.green, width: 1.0),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _FiViSearchImage == null
                              ? const Center(child: Text("Empty"))
                              : GestureDetector(
                                  child: Image.memory(_FiViSearchImage!,
                                      height: 248),
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
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    height: 400,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20.0,
                          child: const Center(
                            child: Text(
                              'All Search Image',
                              style: TextStyle(fontSize: 15.0),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.green, width: 1.0),
                          ),
                        ),
                        Expanded(
                          child: _AllSearchImage == null
                              ? const Center(child: Text("Empty"))
                              : GestureDetector(
                                  child: Image.memory(_AllSearchImage!,
                                      height: 248),
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
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: GestureDetector(
                child: Center(
                  child: rssi_rp_prob.isNotEmpty
                      ? Column(
                          children: [
                            const Text("1st location estimate result",
                                style: TextStyle(fontSize: 14.0)),
                            Text(
                              'Building : $building, Floor : $floor\nRegion : $region, RP : $rssi_rp\nProbability : ${rssi_rp_prob[0].toStringAsFixed(4)}%',
                              style: const TextStyle(fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Text("1st location estimate result",
                                style: TextStyle(fontSize: 14.0)),
                            const Text(
                              'Building : , Floor : , Region : \nProbability : ',
                              style: TextStyle(fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                border: Border.all(color: Colors.deepOrange, width: 2.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        const Text("RSSI model"),
                        Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              isExpanded: true,
                              value: _selectedRssiModel,
                              items: _rssiModelList.map((value) {
                                return DropdownMenuItem(
                                    value: value,
                                    child: Center(child: Text(value.toString())));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRssiModel = value.toString();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.deepOrange, width: 2.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    height: 70,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        const Text("Maximum Candidate"),
                        Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              isExpanded: true,
                              value: _selectedRssiCandidateMaxRP,
                              items: _rssiCandidateMaxRPList.map((value) {
                                return DropdownMenuItem(
                                    value: value,
                                    child: Center(child: Text(value.toString())));
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
                      border: Border.all(color: Colors.deepOrange, width: 2.0),
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
                child: const Text("1st location estimate(RSSI Search)"),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.deepOrange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.all(10.0),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('Fi-Vi search result', style: TextStyle(fontSize: 14.0),),
                          Text(
                            'Similarity : $dist\nSearch Time : ${_searchTime.toStringAsFixed(2)}s',
                            style: const TextStyle(fontSize: 17.0),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue.shade300, width: 2.0),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('All search result', style: TextStyle(fontSize: 14.0),),
                          Text(
                            'Similarity : $_allSearchDist\nAll Search Time: ${_allSearchTime.toStringAsFixed(2)}s',
                            style: const TextStyle(fontSize: 17.0),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue.shade300, width: 2.0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12.5),
              child: Column(
                children: [
                  Text(
                    '개선율 : ${_searchTime == 0 && _allSearchTime == 0 ? 0 : performanceCalculator(_searchTime, _allSearchTime).toStringAsFixed(4)}%\n필터링 된 이미지 : ${(_filteredImageLength/totalImageLength*100).toStringAsFixed(4)}%($_filteredImageLength/$totalImageLength)',
                    style: const TextStyle(fontSize: 17.0),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue.shade300, width: 2.0),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Center(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    isExpanded: true,
                    value: _selectedImageSearchAlgo,
                    items: _imageSearchAlgoList.map((value) {
                      return DropdownMenuItem(
                          value: value, child: Center(child: Text(value)));
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
                border: Border.all(color: Colors.blue.shade300, width: 2.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              height: 30,
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
                child: const Text("2nd location estimate(Image Search)"),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue.shade300),
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
        backgroundDecoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}
