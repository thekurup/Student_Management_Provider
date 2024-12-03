// Complete implementation of home.dart with Provider fixes and full documentation
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:student_db/db_control/student.dart';
import 'package:student_db/screens/details.dart';
import 'package:student_db/screens/reg.dart';
import 'package:student_db/screens/serachpage.dart';
import 'package:student_db/theme/twitter_colors.dart';
import 'package:simple_animations/simple_animations.dart';

// StudentProvider Class
// What: Central state management class for all student-related operations
// Interaction: I created a class to mannage all stateee managemnt ie ui and databse operation

// Think of Provider like a smart assistant that manages all our student information.
//  Just like how a school has one central office that keeps track of all student records, 
//  our Provider acts as that central office. Here's exactly how I implemented it:
// First, I created our central office - the StudentProvider class:
class StudentProvider extends ChangeNotifier {
  final dbhelper = DatabaseHelper();
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  // This class keeps track of everything: our student list, loading states,
  //  and even handles form data. 
  // When any information changes, it notifies all parts of the app that need to know.
  File? _selectedImage;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPlaceController = TextEditingController();
  final TextEditingController _userContactController = TextEditingController();
  
  // Getters for private state variables
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get students => _students;
  File? get selectedImage => _selectedImage;
  TextEditingController get userNameController => _userNameController;
  TextEditingController get userPlaceController => _userPlaceController;
  TextEditingController get userContactController => _userContactController;

  // Load Students Method
  // What: Fetches all students from database with loading state management
  // Why: Ensures UI reflects data loading status accurately
  // Interaction: Called on app start and manual refresh
  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    
    _students = await dbhelper.searchAll('');
    _isLoading = false;
    notifyListeners();
  }

  // Delete Student Method
  // What: Removes student from database with proper UI feedback
  // Why: Handles both database operation and user notification
  // Interaction: Called from delete confirmation dialog
 Future<void> deleteStudent(int id, BuildContext context) async {
  try {
    // Set loading state to true and notify listeners immediately
    // This triggers the loading indicator in the UI
    _isLoading = true;
    notifyListeners();  // First notification to update UI for loading state

    // Attempt to delete the student from the database
    // dbhelper.delete returns the number of rows affected (should be 1 if successful)
    final rowsDeleted = await dbhelper.delete(id);
    
    if (rowsDeleted > 0) {
      // If deletion was successful in database, update the in-memory list
      // Using where() creates a new list excluding the deleted student
      // This is more reliable than modifying the existing list
      _students = _students.where((student) => student['id'] != id).toList();
      
      // Show success message to user
      // Using ScaffoldMessenger ensures the message persists across screen transitions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student deleted successfully',
            style: TextStyle(color: TwitterColors.textPrimary),
          ),
          backgroundColor: TwitterColors.cardBg,
          behavior: SnackBarBehavior.floating,  // Makes snackbar float above content
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Rounded corners for better aesthetics
          ),
        ),
      );
    }
  } catch (e) {
    // Error handling block
    // If anything goes wrong during deletion, show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error deleting student: ${e.toString()}',
          style: TextStyle(color: TwitterColors.textPrimary),
        ),
        backgroundColor: Colors.red,  // Red background to indicate error
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  } finally {
    // Always execute this block, whether deletion succeeds or fails
    // Reset loading state and notify listeners of final state
    _isLoading = false;
    notifyListeners();  // Final notification to update UI with new state
  }
}
  // Update Student Method
  // What: Updates existing student information with validation
  // Why: Ensures data integrity and provides user feedback
  // Interaction: Called when saving edited student information
  Future<void> updateStudent(Map<String, dynamic> data, BuildContext context) async {
    if (_isLoading) return;

    final name = _userNameController.text.trim();
    final contact = int.tryParse(_userContactController.text) ?? 0;
    final place = _userPlaceController.text.trim();

    if (name.isEmpty || contact <= 0 || place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields correctly',
            style: TextStyle(color: TwitterColors.textPrimary),
          ),
          backgroundColor: TwitterColors.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    final updatedData = {
      'id': data['id'],
      'name': name,
      'contact': contact,
      'place': place,
      'imagePath': _selectedImage!.path,
    };

    final rowsUpdated = await dbhelper.update(updatedData);
    if (rowsUpdated > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student updated successfully',
            style: TextStyle(color: TwitterColors.textPrimary),
          ),
          backgroundColor: TwitterColors.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      clearForm();
    }

    await loadStudents();
  }

  // Form Management Methods
  // What: Handle form state clearing and initialization
  // Why: Maintains clean form state between operations
  // Interaction: Called when resetting or preparing forms
  void clearForm() {
    _userNameController.clear();
    _userPlaceController.clear();
    _userContactController.clear();
    _selectedImage = null;
    notifyListeners();
  }

  void setFormData(Map<String, dynamic> data) {
    _userNameController.text = data['name'];
    _userContactController.text = data['contact'].toString();
    _userPlaceController.text = data['place'];
    _selectedImage = File(data['imagePath']);
    notifyListeners();
  }

  // Image Handling Methods
  // What: Manage student photo selection and capture
  // Why: Provides multiple options for image input
  // Interaction: Called from photo selection buttons
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      _selectedImage = File(pickedImage.path);
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      _selectedImage = File(pickedImage.path);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPlaceController.dispose();
    _userContactController.dispose();
    super.dispose();
  }
}

// Animated FAB Implementation
// What: Custom floating action button with complex animations
// Why: Enhances user experience with visual feedback
// Interaction: Provides animated response to user taps
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const AnimatedFAB({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> with AnimationMixin {
  late AnimationController animationController;
  late MovieTween animationSequence;

  @override
  void initState() {
    super.initState();
    
    animationController = createController()
      ..duration = const Duration(milliseconds: 800);
    
    animationSequence = MovieTween()
      ..scene(
        begin: const Duration(milliseconds: 0),
        duration: const Duration(milliseconds: 200),
      )
        .tween(
          'scale',
          Tween<double>(begin: 1.0, end: 1.3),
          curve: Curves.easeOutCubic,
        )
        .tween(
          'elevation',
          Tween<double>(begin: 2.0, end: 15.0),
          curve: Curves.easeOutExpo,
        )
      ..scene(
        begin: const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 300),
      )
        .tween(
          'rotate',
          Tween<double>(begin: 0.0, end: 0.5),
          curve: Curves.elasticOut,
        )
        .tween(
          'scale',
          Tween<double>(begin: 1.3, end: 1.0),
          curve: Curves.elasticOut,
        )
      ..scene(
        begin: const Duration(milliseconds: 500),
        duration: const Duration(milliseconds: 300),
      )
        .tween(
          'elevation',
          Tween<double>(begin: 15.0, end: 2.0),
          curve: Curves.easeOutBack,
        )
        .tween(
          'rotate',
          Tween<double>(begin: 0.5, end: 0.0),
          curve: Curves.easeOutBack,
        );
  }

  Future<void> _handleTap() async {
    if (animationController.isAnimating) return;

    try {
      await animationController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 400));
      widget.onPressed();
    } finally {
      if (mounted) {
        animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final Movie movie = animationSequence.transform(animationController.value);
        return Transform.scale(
          scale: movie.get('scale'),
          child: Transform.rotate(
            angle: movie.get('rotate'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TwitterColors.accent.withOpacity(0.3),
                    blurRadius: movie.get('elevation') * 2,
                    spreadRadius: movie.get('elevation') / 3,
                    offset: Offset(0, movie.get('elevation') / 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _handleTap,
                backgroundColor: TwitterColors.accent,
                elevation: movie.get('elevation'),
                child: Transform.rotate(
                  angle: -movie.get('rotate'),
                  child: Icon(
                    Icons.add,
                    color: TwitterColors.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

// HomeScreen Implementation
// What: Main screen of the app with updated Provider implementation
// Why: Uses global Provider instance for consistent state management
// Interaction: Central hub for all student management operations
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper method for student image display
  // What: Creates circular avatar with error handling
  // Why: Provides consistent image display across app
  // Interaction: Shows either student photo or placeholder
  Widget _buildStudentImage(String? imagePath) {
    if (imagePath == null || !File(imagePath).existsSync()) {
      return CircleAvatar(
        backgroundColor: TwitterColors.cardBg,
        radius: 25,
        child: Icon(
          Icons.person,
          color: TwitterColors.textSecondary,
          size: 30,
        ),
      );
    }

    return CircleAvatar(
      radius: 25,
      backgroundImage: FileImage(File(imagePath)),
      backgroundColor: TwitterColors.cardBg,
      onBackgroundImageError: (_, __) {
        debugPrint('Error loading image: $imagePath');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Updated Provider Implementation
    // What: This is where we wrap our entire HomeScreen with Provider's Consumer widget.
    // Why: Ensures consistent state management across app
    // Interaction: Automatically updates UI when data changes
    return Consumer<StudentProvider>(
      // The most important part is how we connect this Provider to our main screen.
      // In the HomeScreen widget, I wrapped everything with a Consumer:
      builder: (context, provider, child) {
        // Initialize data loading when screen first builds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.students.isEmpty) {
            provider.loadStudents();
          }
        });

        return Scaffold(
          backgroundColor: TwitterColors.background,
          appBar: AppBar(
            backgroundColor: TwitterColors.background,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Students Updates",
              style: TextStyle(
                color: TwitterColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: Icon(Icons.school, color: TwitterColors.accent),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                icon: Icon(Icons.search, color: TwitterColors.accent),
                tooltip: 'Search Students',
              ),
              IconButton(
                onPressed: () => provider.loadStudents(),
                icon: Icon(Icons.refresh, color: TwitterColors.accent),
                tooltip: 'Refresh List',
              ),
            ],
          ),
          floatingActionButton: AnimatedFAB(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Register()),
              );
            },
          ),
          body: provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: TwitterColors.accent,
                  ),
                )
              : _buildStudentList(context, provider),
        );
      },
    );
  }

  // Student List Builder
  // What: Creates scrollable list of student cards
  // Why: Displays student information in consistent format
  // Interaction: Allows viewing, editing, and deleting students
  Widget _buildStudentList(BuildContext context, StudentProvider provider) {
    if (provider.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: TwitterColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No students added yet',
              style: TextStyle(
                fontSize: 18,
                color: TwitterColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Register(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TwitterColors.accent,
                foregroundColor: TwitterColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Add Student'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // List Configuration
      // What: Sets up scrollable list with proper spacing
      // Why: Ensures consistent layout and performance
      // Interaction: Creates smooth scrolling experience
      itemCount: provider.students.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final student = provider.students[index];
        return Card(
          elevation: 0,
          color: TwitterColors.cardBg,
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _showData(student, context),
            contentPadding: const EdgeInsets.all(12),
            leading: Hero(
              tag: 'student_${student['id']}',
              child: _buildStudentImage(student['imagePath']),
            ),
            title: Text(
              student['name'],
              style: TextStyle(
                color: TwitterColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              student['place'],
              style: TextStyle(
                color: TwitterColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditDialog(student, context, provider),
                  icon: Icon(
                    Icons.edit,
                    color: TwitterColors.accent,
                  ),
                  tooltip: 'Edit Student',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteDialog(student['id'], context),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Delete Student',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete Confirmation Dialog
  // What: Updated dialog implementation with correct Provider context
  // Why: Ensures proper Provider access within dialog scope
  // Interaction: Shows confirmation before deleting student
  void _showDeleteDialog(int id, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {  // Using separate dialogContext
        return AlertDialog(
          backgroundColor: TwitterColors.cardBg,
          title: Text(
            'Delete Student',
            style: TextStyle(color: TwitterColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete this student\'s data?',
            style: TextStyle(color: TwitterColors.textSecondary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: TwitterColors.textSecondary),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                // Here's what makes this better than using setState(): Imagine if each screen had to 
                // keep its own copy of student data and manually tell every other screen when something changed. It would be like having multiple offices each with their own student records, 
                // trying to keep everything in sync. With Provider, we have one office.
                Provider.of<StudentProvider>(context, listen: false)
                    .deleteStudent(id, context);
                    // Like this above code The Provider  handles everything: removing the student from the database, updating the list, and automatically refreshing all screens showing student data. No manual setState() calls needed!
                    // This approach gives us three main benefits:

                    // All student data management is centralized in one place
                    // Screens automatically update when data changes
                    // Code is cleaner and easier to maintain
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Edit Student Dialog
  // What: Updated dialog implementation with proper context handling
  // Why: Maintains form state and handles image selection
  // Interaction: Allows editing student information with live preview
  void _showEditDialog(Map<String, dynamic> data, BuildContext context, StudentProvider provider) {
    provider.setFormData(data);  // Initialize form with current data

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: TwitterColors.cardBg,
          title: Text(
            'Edit Student',
            style: TextStyle(color: TwitterColors.textPrimary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: provider.userNameController,
                  style: TextStyle(color: TwitterColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: TwitterColors.textSecondary),
                    prefixIcon: Icon(Icons.person, color: TwitterColors.accent),
                    fillColor: TwitterColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TwitterColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: provider.userContactController,
                  style: TextStyle(color: TwitterColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Contact',
                    labelStyle: TextStyle(color: TwitterColors.textSecondary),
                    prefixIcon: Icon(Icons.phone, color: TwitterColors.accent),
                    fillColor: TwitterColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TwitterColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: provider.userPlaceController,
                  style: TextStyle(color: TwitterColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Place',
                    labelStyle: TextStyle(color: TwitterColors.textSecondary),
                    prefixIcon: Icon(Icons.location_on, color: TwitterColors.accent),
                    fillColor: TwitterColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TwitterColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: TwitterColors.background,
                          border: Border.all(color: TwitterColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: provider.selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  provider.selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.image,
                                size: 50,
                                color: TwitterColors.textSecondary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => provider.pickImage(),
                          icon: Icon(
                            Icons.photo_library,
                            color: TwitterColors.accent,
                          ),
                          tooltip: 'Pick from Gallery',
                        ),
                        IconButton(
                          onPressed: () => provider.takePhoto(),
                          icon: Icon(
                            Icons.camera_alt,
                            color: TwitterColors.accent,
                          ),
                          tooltip: 'Take Photo',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: TwitterColors.textSecondary),
              ),
              onPressed: () {
                provider.clearForm();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TwitterColors.accent,
                foregroundColor: TwitterColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Save'),
              onPressed: () {
                provider.updateStudent(data, context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show Student Details
  // What: Navigation to detailed student view
  // Why: Provides full screen view of student information 
  // Interaction: Opens when tapping a student card
  void _showData(Map<String, dynamic> data, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          name: data['name'],
          place: data['place'],
          contact: data['contact'],
          imagePath: data['imagePath'],
        ),
      ),
    );
  }
}