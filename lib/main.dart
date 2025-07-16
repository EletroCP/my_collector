import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Collector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImagePickerPage(),
    );
  }
}

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _image;
  String _recognizedText = '';
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedText = '';
        _loading = true;
      });

      await _doOCR(File(pickedFile.path));
    }
  }

  Future<void> _doOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      _recognizedText = recognizedText.text;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leitura de Imagem")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 300),
            const SizedBox(height: 10),
            if (_loading)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SelectableText(
                  _recognizedText.isEmpty ? "Nenhum texto reconhecido ainda." : _recognizedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tirar Foto"),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Escolher da Galeria"),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
