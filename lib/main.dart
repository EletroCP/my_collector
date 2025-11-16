import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(home: OCRSelectorApp()));
}

class OCRSelectorApp extends StatefulWidget {
  const OCRSelectorApp({super.key});

  @override
  State<OCRSelectorApp> createState() => _OCRSelectorAppState();
}

class _OCRSelectorAppState extends State<OCRSelectorApp> {
  ui.Image? _image;
  File? _imageFile;
  final List<Rect> _selectedAreas = [];
  Rect? _currentRect;
  Offset? _startPoint;
  String _resultado = "";
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
        _imageFile = file;
        _selectedAreas.clear();
        _resultado = "";
      });
    }
  }

  Future<void> _processOCR() async {
    if (_imageFile == null || _selectedAreas.length != 2) return;
    final raw = await _imageFile!.readAsBytes();
    final original = img.decodeImage(raw);
    if (original == null) return;

    final scaleX = original.width / _image!.width;
    final scaleY = original.height / _image!.height;

    List<String> resultados = [];

    for (final area in _selectedAreas) {
      final crop = img.copyCrop(
        original,
        x: (area.left * scaleX).round(),
        y: (area.top * scaleY).round(),
        width: (area.width * scaleX).round(),
        height: (area.height * scaleY).round(),
      );

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File(tempPath)..writeAsBytesSync(img.encodePng(crop));

      final inputImage = InputImage.fromFile(croppedFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      resultados.add(result.text.replaceAll('\n', '').trim());
    }

    setState(() {
      _resultado = "${resultados[0]};${resultados[1]}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Áreas para OCR')),
      body: Column(
        children: [
          Expanded(
            child: _image == null
                ? const Center(child: Text("Nenhuma imagem selecionada."))
                : GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _startPoint = details.localPosition;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        final current = details.localPosition;
                        _currentRect = Rect.fromPoints(_startPoint!, current);
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        if (_currentRect != null && _selectedAreas.length < 2) {
                          _selectedAreas.add(_currentRect!);
                        }
                        _currentRect = null;
                      });
                    },
                    child: CustomPaint(
                      painter: ImagePainter(image: _image!, areas: _selectedAreas, current: _currentRect),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
          ),
          if (_resultado.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Resultado: $_resultado", style: const TextStyle(fontSize: 16)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: _pickImage, child: const Text("Selecionar Imagem")),
              ElevatedButton(
                onPressed: _selectedAreas.length == 2 ? _processOCR : null,
                child: const Text("Ler OCR"),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Rect> areas;
  final Rect? current;

  ImagePainter({required this.image, required this.areas, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);

    final border = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final rect in areas) {
      canvas.drawRect(rect, border);
    }

    if (current != null) {
      canvas.drawRect(current!, border);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
