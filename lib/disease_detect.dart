import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';
import 'camera_screen.dart';
import 'home_page.dart';

class CropDiseaseHome extends StatefulWidget {
  @override
  _CropDiseaseHomeState createState() => _CropDiseaseHomeState();
}

class _CropDiseaseHomeState extends State<CropDiseaseHome> {
  Uint8List? _imageData;
  String _prediction = '';
  String _symptoms = '';
  bool _isLoading = false;
  int _currentIndex = 2;
  Map<String, dynamic> _symptomsData = {};
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadSymptomsData();
  }

  // Load the model using tflite_flutter
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/crop_disease_model.tflite');
      print("Model loaded successfully!");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  // Load symptoms data from JSON file
  Future<void> _loadSymptomsData() async {
    try {
      String data = await rootBundle.loadString("assets/data/labels_with_symptoms.json");
      setState(() {
        _symptomsData = json.decode(data);
      });
    } catch (e) {
      print("Failed to load symptoms data: $e");
    }
  }

  // Image picker function
  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose an option'),
          actions: [
            TextButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  _imageData = await pickedFile.readAsBytes();
                  Navigator.of(context).pop();
                  await _sendImage(_imageData!);
                }
              },
              child: Text('Upload from Gallery'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final imageBytes = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );

                if (imageBytes != null) {
                  setState(() {
                    _imageData = imageBytes;
                  });
                  await _sendImage(_imageData!);
                }
              },
              child: Text('Take a Picture'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Send image to model for prediction using tflite_flutter
  Future<void> _sendImage(Uint8List imageData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_image.jpg';
      final imageFile = File(filePath)..writeAsBytesSync(imageData);

      var input = imageData.buffer.asUint8List(); // Convert image data to input format
      var output = List.filled(1, 0).reshape([1, 1]);  // Example output shape

      _interpreter.run(input, output);

      setState(() {
        _prediction = output[0]; // Process output as required
      });
      await _loadSymptoms(); // Load symptoms for prediction
    } catch (e) {
      setState(() {
        _prediction = 'Error: $e';
        _symptoms = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load symptoms for the predicted label
  Future<void> _loadSymptoms() async {
    try {
      final List<String>? symptomsList = _symptomsData[_prediction]?['symptoms']?.cast<String>();
      setState(() {
        _symptoms = symptomsList != null
            ? symptomsList.join("\n")
            : 'Symptoms not available for this label';
      });
    } catch (e) {
      print("Failed to load symptoms for prediction: $e");
      setState(() {
        _symptoms = 'Error loading symptoms data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'CropFit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/graphic_image.png', height: 200, width: 200),
            Text('Prediction: $_prediction'),
            Text('Symptoms: $_symptoms'),
          ],
        ),
      ),
    );
  }
}
