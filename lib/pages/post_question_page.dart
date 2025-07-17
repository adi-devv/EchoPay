import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:echopay/components/utils.dart';

class PostQuestionPage extends StatefulWidget {
  PostQuestionPage({super.key});

  @override
  State<PostQuestionPage> createState() => _PostQuestionPageState();
}

class _PostQuestionPageState extends State<PostQuestionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submitQuestion(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in!')),
      );
      return;
    }

    // Get the question details from the text controllers
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String tags = _tagsController.text.trim(); // Consider parsing tags into a List<String>

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields (Title and Description).')),
      );
      return;
    }

    try {
      Utils.showLoading(context);
      await FirebaseFirestore.instance.collection('Questions').add({
        'userID': user.uid,
        'userName':user.displayName,
        'title': title,
        'description': description,
        'tags': tags.split(',').map((tag) => tag.trim()).toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'solved':false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question Submitted Successfully!')),
      );

      // Clear the text fields after successful submission
      _titleController.clear();
      _descriptionController.clear();
      _tagsController.clear();
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit question: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder minimalisticBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 1.0),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Post Your Question',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                'Title',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your question title',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                  // Background of the text field
                  enabledBorder: minimalisticBorder,
                  focusedBorder: minimalisticBorder,
                  border: minimalisticBorder,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                ),
              ),
              SizedBox(height: 25.0),

              Text(
                'Description',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
              ),
              SizedBox(height: 8.0),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 1.0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.format_bold, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.format_italic, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.format_underline, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.format_list_bulleted,
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.link, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.image, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.code, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                    Icon(Icons.format_align_left,
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
                  ],
                ),
              ),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                maxLines: null,
                // Allows for multiline input
                minLines: 8,
                // Initial height
                textAlignVertical: TextAlignVertical.top,
                // Align text to top
                expands: false,
                // Don't expand beyond viewport
                decoration: InputDecoration(
                  hintText: 'Enter a detailed description of your question',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                ),
              ),
              SizedBox(height: 25.0),

              // Tags Section
              Text(
                'Tags',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _tagsController,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g., flutter, dart, firebase (comma-separated)',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                  enabledBorder: minimalisticBorder,
                  focusedBorder: minimalisticBorder,
                  border: minimalisticBorder,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                ),
              ),
              SizedBox(height: 40.0),

              // Submit Button
              Center(
                child: SizedBox(
                  width: 150, // Fixed width for the button
                  height: 45, // Fixed height for the button
                  child: OutlinedButton(
                    onPressed: () {
                      _submitQuestion(context); // Make sure you are passing the context
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 1.0), // White outline
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // Rounded corners
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
