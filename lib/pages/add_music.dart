import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMusicPage extends StatefulWidget {
  @override
  _AddMusicPageState createState() => _AddMusicPageState();
}

class _AddMusicPageState extends State<AddMusicPage> {
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  File? _imageFile;
  File? _mp3File;

  final String cloudName = 'cxlx';
  final String uploadPreset = 'YOUR_UPLOAD_PRESET';

  Future<String> uploadToCloudinary(File file, String type) async {
    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/${type == "audio" ? "video" : "image"}/upload");
    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final res = await http.Response.fromStream(response);
    final json = jsonDecode(res.body);
    return json['secure_url'];
  }

  Future<void> pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == "audio" ? FileType.audio : FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (type == "audio") {
          _mp3File = File(result.files.single.path!);
        } else {
          _imageFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> handleSubmit() async {
    if (_songController.text.isEmpty ||
        _artistController.text.isEmpty ||
        _imageFile == null ||
        _mp3File == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fill all fields")));
      return;
    }

    final imageUrl = await uploadToCloudinary(_imageFile!, "image");
    final audioUrl = await uploadToCloudinary(_mp3File!, "audio");

    await FirebaseFirestore.instance.collection("MusicApp").add({
      "songName": _songController.text,
      "artistName": _artistController.text,
      "imageUrl": imageUrl,
      "mp3Url": audioUrl,
      "timestamp": FieldValue.serverTimestamp()
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Music uploaded!")));

    _songController.clear();
    _artistController.clear();
    setState(() {
      _imageFile = null;
      _mp3File = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Music")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _songController,
                decoration: InputDecoration(labelText: "Song Name")),
            TextField(
                controller: _artistController,
                decoration: InputDecoration(labelText: "Artist Name")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => pickFile("image"),
              child: Text(_imageFile == null ? "Pick Image" : "Change Image"),
            ),
            ElevatedButton(
              onPressed: () => pickFile("audio"),
              child:
                  Text(_mp3File == null ? "Pick MP3 File" : "Change MP3 File"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleSubmit,
              child: Text("Upload Song"),
            )
          ],
        ),
      ),
    );
  }
}
