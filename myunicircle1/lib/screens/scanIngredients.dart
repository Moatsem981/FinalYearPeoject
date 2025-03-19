import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle; // Import for rootBundle
import 'package:image/image.dart' as img; // Use a prefix for the image package

class ScanIngredientsScreen extends StatefulWidget {
  @override
  _ScanIngredientsScreenState createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  List<File> _selectedImages = [];
  List<String> _predictions = [];
  List<String> _labels = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // ✅ Check if the asset exists before loading
      _labels = await _loadLabels("assets/labels.txt");
      final byteData = await rootBundle.load('assets/FVmodel.tflite');
      if (byteData.lengthInBytes == 0) {
        print("❌ FVmodel.tflite exists but is empty!");
        return;
      }

      _interpreter = await Interpreter.fromAsset('assets/FVmodel.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
      _predictImage(File(pickedFile.path));
    }
  }

  Future<void> _predictImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      print("❌ Model or labels not loaded");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Get correctly formatted input tensor
      var inputImage = await _preprocessImage(imageFile);
      if (inputImage.isEmpty) return;

      // ✅ Check number of labels
      print("📌 Number of labels: ${_labels.length}");

      // ✅ Ensure output shape matches the number of labels
      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      // 🔥 Run inference
      _interpreter!.run(inputImage, output);

      // ✅ Convert output to List<double>
      List<double> outputList = List<double>.from(output[0]);

      // ✅ Get index of highest probability
      int predictedIndex = outputList.indexOf(
        outputList.reduce((a, b) => a > b ? a : b),
      );

      // ✅ Get label from index
      String predictedLabel = _labels[predictedIndex];

      setState(() {
        _predictions.add(predictedLabel);
      });

      print("✅ Prediction: $predictedLabel");
    } catch (e) {
      print("❌ Error during prediction: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
    File imageFile,
  ) async {
    var imageBytes = await imageFile.readAsBytes();
    var image = img.decodeImage(imageBytes);

    if (image == null) {
      print("❌ Failed to decode image");
      return [];
    }

    // ✅ Resize image to the correct shape (MATCH IT TO YOUR MODEL)
    var resizedImage = img.copyResize(
      image,
      width: 150,
      height: 150,
    ); // Change to 224 if needed

    // ✅ Normalize pixels (Ensure values are in range 0-1)
    var normalizedImage = List.generate(
      150, // Change to 224 if your model expects 224x224
      (y) => List.generate(150, (x) {
        var pixel = resizedImage.getPixel(x, y);
        return [
          img.getRed(pixel) / 255.0, // Normalize Red channel
          img.getGreen(pixel) / 255.0, // Normalize Green channel
          img.getBlue(pixel) / 255.0, // Normalize Blue channel
        ];
      }),
    );

    // ✅ Reshape image for model input (batch size of 1)
    return [normalizedImage];
  }

  Future<List<String>> _loadLabels(String labelsPath) async {
    final labels = await rootBundle.loadString(labelsPath);
    return labels.split('\n').where((label) => label.isNotEmpty).toList();
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
      _predictions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.green.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Center(
                child: Text(
                  "Scan Ingredients",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              _selectedImages.isEmpty
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.green,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Tap to Upload Image",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _selectedImages.last,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Upload or take a photo of your ingredients",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedImages.isNotEmpty) ...[
                Card(
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, color: Colors.green),
                            SizedBox(width: 10),
                            Text(
                              "Uploaded Images",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.image, color: Colors.green),
                              title: Text(
                                "Image ${index + 1}",
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle:
                                  _predictions.length > index
                                      ? Text(
                                        "Prediction: ${_predictions[index]}",
                                        style: TextStyle(color: Colors.green),
                                      )
                                      : Text(
                                        "Processing...",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                    _predictions.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
              if (_isLoading) CircularProgressIndicator(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera, color: Colors.white),
                    label: Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.upload, color: Colors.white),
                    label: Text(
                      "Add Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (_selectedImages.isNotEmpty) ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _clearAll,
                    icon: Icon(Icons.clear, color: Colors.white),
                    label: Text(
                      "Clear All",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
