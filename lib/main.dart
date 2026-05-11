import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  File? _image;

  final picker = ImagePicker();

  Interpreter? interpreter;

  String result = "";
  double confidence = 0;
  String suggestion = "";

  final List<String> labels = [
    "High",
    "Medium",
    "Normal"
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  // LOAD MODEL
  Future loadModel() async {

    interpreter = await Interpreter.fromAsset(
      'assets/cataract_model.tflite',
    );

    print("Model Loaded Successfully");
  }

  // PICK IMAGE
  Future pickImage() async {

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {

      setState(() {
        _image = File(pickedFile.path);
      });

      runModel(_image!);
    }
  }

  // TAKE PHOTO
  Future takePhoto() async {

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {

      setState(() {
        _image = File(pickedFile.path);
      });

      runModel(_image!);
    }
  }

  // RUN MODEL
  Future runModel(File imageFile) async {

    try {

      Uint8List imageBytes =
          await imageFile.readAsBytes();

      img.Image? originalImage =
          img.decodeImage(imageBytes);

      if (originalImage == null) {
        print("Image Decode Failed");
        return;
      }

      // RESIZE IMAGE
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: 224,
        height: 224,
      );

      // INPUT
      var input = List.generate(
        1,
        (index) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {

              var pixel =
                  resizedImage.getPixel(x, y);

              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // OUTPUT
      var output = List.generate(
        1,
        (index) => List.filled(3, 0.0),
      );

      interpreter!.run(input, output);

      print(output);

      double high = output[0][0];
      double medium = output[0][1];
      double normal = output[0][2];

      List<double> values = [
        high,
        medium,
        normal
      ];

      double maxValue =
          values.reduce((a, b) => a > b ? a : b);

      int index = values.indexOf(maxValue);

      String prediction = labels[index];

      setState(() {

        result = prediction;

        confidence = maxValue * 100;

        if (prediction == "High") {

          suggestion =
              "High cataract detected. Visit doctor immediately.";

        } else if (prediction == "Medium") {

          suggestion =
              "Medium cataract detected. Consult eye specialist.";

        } else {

          suggestion =
              "Eye looks healthy and normal.";
        }
      });

    } catch (e) {

      print("MODEL ERROR:");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Color(0xFFEDE7F6),

      appBar: AppBar(

        backgroundColor: Colors.deepPurple,

        title: Text(
          "Visris AI",

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        child: Center(

          child: Padding(

            padding: EdgeInsets.all(20),

            child: Column(

              children: [

                SizedBox(height: 30),

                // IMAGE
                _image == null

                    ? Container(

                        height: 250,
                        width: 300,

                        decoration: BoxDecoration(

                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Center(

                          child: Text(

                            "No Image Selected",

                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      )

                    : ClipRRect(

                        borderRadius:
                            BorderRadius.circular(20),

                        child: Image.file(

                          _image!,

                          height: 250,
                          width: 300,

                          fit: BoxFit.cover,
                        ),
                      ),

                SizedBox(height: 30),

                // PICK IMAGE BUTTON
                ElevatedButton(

                  onPressed: pickImage,

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.deepPurple,

                    padding: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),

                    shape: StadiumBorder(),
                  ),

                  child: Text(

                    "Pick Image",

                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // TAKE PHOTO BUTTON
                ElevatedButton(

                  onPressed: takePhoto,

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.deepPurple,

                    padding: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),

                    shape: StadiumBorder(),
                  ),

                  child: Text(

                    "Take Photo",

                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // RESULT
                if (result.isNotEmpty)

                  Column(

                    children: [

                      Text(

                        "Prediction: $result",

                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 15),

                      Text(

                        "Confidence: ${confidence.toStringAsFixed(2)}%",

                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(

                        suggestion,

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}