import 'package:flutter/material.dart';

class SelectResultImage extends StatefulWidget {
  final List<Map<String, dynamic>> resultDataList;

  const SelectResultImage({Key? key, required this.resultDataList})
      : super(key: key);

  @override
  State<SelectResultImage> createState() => _SelectResultImage();
}

class _SelectResultImage extends State<SelectResultImage> {
  @override
  Widget build(BuildContext context) {
    return widget.resultDataList.isEmpty
        ? const Scaffold(
            body: Center(
              child: Text("Empty"),
            ),
          )
        : Scaffold(
            body: ListView.builder(
              itemCount: widget.resultDataList.length,
              itemBuilder: (context, i) {
                return ListTile(
                  onTap: () {
                    Navigator.pop(context, i);
                  },
                  leading: Image.memory(widget.resultDataList[i]["image"]),
                  title:
                      Text("Similarity : ${widget.resultDataList[i]["dist"]}"),
                );
              },
            ),
          );
  }
}
