import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:student_db/db_control/student.dart';
import 'package:student_db/screens/details.dart';
import 'package:student_db/theme/twitter_colors.dart'; // Import Twitter theme colors

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  // Controllers and state management
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _animationController;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _noResults = false;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for the "not found" animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Search functionality with debouncing
  Future<void> _onSearchChanged() async {
    final searchText = _searchController.text.trim();
    setState(() => _isSearching = true);

    if (searchText.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _noResults = false;
      });
      return;
    }

    final results = await _dbHelper.searchAll(searchText);
    
    setState(() {
      _suggestions = results;
      _isSearching = false;
      _noResults = results.isEmpty;
    });

    if (_noResults) {
      _animationController.forward();
    } else {
      _animationController.reset();
    }
  }

  // Enhanced student image builder with Twitter styling
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
    return Scaffold(
      backgroundColor: TwitterColors.background,
      appBar: AppBar(
        title: Text(
          'Search Students',
          style: TextStyle(
            color: TwitterColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: TwitterColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: TwitterColors.accent),
      ),
      body: Column(
        children: [
          // Search bar with Twitter styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TwitterColors.background,
              border: Border(
                bottom: BorderSide(
                  color: TwitterColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: TwitterColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search students by name...',
                hintStyle: TextStyle(color: TwitterColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: TwitterColors.accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: TwitterColors.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Content area with animated transitions
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Content builder with different states
  Widget _buildContent() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          color: TwitterColors.accent,
        ),
      );
    }

    if (_noResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/not_found.json',
              controller: _animationController,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'No students found',
              style: TextStyle(
                color: TwitterColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: TwitterColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search students',
              style: TextStyle(
                color: TwitterColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Search results list with Twitter styling
    return ListView.builder(
      itemCount: _suggestions.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final student = _suggestions[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 0,
            color: TwitterColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
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
                style: TextStyle(color: TwitterColors.textSecondary),
              ),
              onTap: () => _navigateToDetails(student),
            ),
          ),
        );
      },
    );
  }

  // Navigation to details page
  void _navigateToDetails(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          name: student['name'],
          contact: student['contact'],
          place: student['place'],
          imagePath: student['imagePath'],
        ),
      ),
    );
  }
}