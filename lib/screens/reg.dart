import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:student_db/db_control/student.dart';
import 'package:student_db/screens/home.dart';

// Custom animated button widget that provides beautiful animations and visual feedback
class AnimatedCustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const AnimatedCustomButton({
    required this.text,
    required this.onPressed,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  _AnimatedCustomButtonState createState() => _AnimatedCustomButtonState();
}

class _AnimatedCustomButtonState extends State<AnimatedCustomButton>
    with SingleTickerProviderStateMixin {
  // Animation controller for managing the button's animations
  late AnimationController _animationController;
  // Scale animation for the press effect
  late Animation<double> _scaleAnimation;
  // Shadow animation for depth effect
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Create a scale animation that slightly shrinks the button when pressed
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Create a shadow animation that reduces the shadow when pressed
    _shadowAnimation = Tween<double>(begin: 8.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) {
            _animationController.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _animationController.reverse(),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.8),
                  ],
                ),
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  File? _selectedImage;
  final dbHelper = DatabaseHelper();
  final _userNameController = TextEditingController();
  final _userPlaceController = TextEditingController();
  final _userContactController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Validation method for the name field
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    
    if (value.length < 3) {
      return 'Name must be at least 3 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name must contain only alphabets';
    }
    
    return null;
  }

  // Validation method for the phone number field
  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone number must contain exactly 10 digits';
    }
    
    return null;
  }

  // Validation method for the place field
  String? validatePlace(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your place';
    }
    
    if (value.length < 2) {
      return 'Place name must be at least 2 characters long';
    }
    
    return null;
  }

  // Show error dialog for validation errors
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Validation Error'),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 126, 126, 126),
        title: Text(
          "Registration",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 24),
                Text(
                  "Add New Student",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Image selection section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add student photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: Icon(Icons.photo_library),
                          tooltip: "Select from gallery",
                          iconSize: 32,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 16),
                        IconButton(
                          onPressed: _photoImage,
                          icon: Icon(Icons.camera_alt),
                          tooltip: "Open camera",
                          iconSize: 32,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Name input field
                TextFormField(
                  controller: _userNameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelText: "Name",
                    hintText: "Enter Name",
                    prefixIcon: Icon(Icons.person),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  validator: validateName,
                  onChanged: (value) {
                    _formKey.currentState?.validate();
                  },
                ),
                SizedBox(height: 16),
                // Phone number input field
                TextFormField(
                  controller: _userContactController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelText: "Phone Number",
                    hintText: "Enter Phone Number",
                    prefixIcon: Icon(Icons.phone),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: validatePhoneNumber,
                  onChanged: (value) {
                    _formKey.currentState?.validate();
                  },
                ),
                SizedBox(height: 16),
                // Place input field
                TextFormField(
                  controller: _userPlaceController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelText: "Place",
                    hintText: "Enter Student Place",
                    prefixIcon: Icon(Icons.location_on),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  validator: validatePlace,
                  onChanged: (value) {
                    _formKey.currentState?.validate();
                  },
                ),
                SizedBox(height: 32),
                // Action buttons with new animated design
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedCustomButton(
                      text: 'Submit',
                      onPressed: () => _insertData(context),
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 20),
                    AnimatedCustomButton(
                      text: 'Clear',
                      onPressed: () {
                        _userContactController.text = '';
                        _userNameController.text = '';
                        _userPlaceController.text = '';
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      color: Color(0xFFE53935),
                    ),
                  ],
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to handle data insertion
  void _insertData(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Please fix the validation errors before submitting.');
      return;
    }

    if (_selectedImage == null) {
      _showErrorDialog('Please select a student photo.');
      return;
    }

    final String name = _userNameController.text;
    final int contact = int.tryParse(_userContactController.text) ?? 0;
    final String place = _userPlaceController.text;

    // Save the image to temporary directory
    final imageFileName = 'student_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageFile = File('${(await getTemporaryDirectory()).path}/$imageFileName');
    await _selectedImage!.copy(imageFile.path);

    // Prepare data for database insertion
    final row = {
      'name': name,
      'place': place,
      'contact': contact,
      'imagePath': imageFile.path,
    };

    // Insert data into database
    await dbHelper.insert(row);
    
    // Clear form after successful insertion
    setState(() {
      _userNameController.clear();
      _userPlaceController.clear();
      _userContactController.clear();
      _selectedImage = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Student registered successfully!',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // Navigate to home screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  // Method to capture image from camera
  Future<void> _photoImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }
}