import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echopay/components/my_drawer.dart';
import 'package:echopay/pages/post_question_page.dart';
import 'package:echopay/pages/question_page.dart';

enum SortMethod { newest, unanswered } // Define an enum for clarity

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SortMethod _sortMethod = SortMethod.newest; // Default sort method

  @override
  void initState() {
    super.initState();
    print("HOME PAGE INIT");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      // Using tertiary for Scaffold background
      drawer: MyDrawer(),
      appBar: AppBar(
        title: const Text('StackIt'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          // Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // Using ElevatedButton.icon for better visibility
                    onPressed: () {
                      setState(() {
                        _sortMethod = SortMethod.newest;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sortMethod == SortMethod.newest
                          ? Colors.lightBlueAccent // Active color
                          : Theme.of(context).colorScheme.secondary, // Inactive color
                      foregroundColor:
                          _sortMethod == SortMethod.newest ? Colors.white : Theme.of(context).colorScheme.onSecondary,
                    ),
                    icon: const Icon(Icons.new_releases),
                    label: const Text('Newest'),
                  ),
                ),
                const SizedBox(width: 10), // Spacing between buttons
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _sortMethod = SortMethod.unanswered;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sortMethod == SortMethod.unanswered
                          ? Colors.lightBlueAccent
                          : Theme.of(context).colorScheme.secondary,
                      foregroundColor: _sortMethod == SortMethod.unanswered
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSecondary,
                    ),
                    icon: Icon(Icons.question_mark),
                    label: const Text('Unanswered'),
                  ),
                ),
              ],
            ),
          ),
          // Question List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuestionsStream(), // Call a method to get the stream dynamically
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  String message = _sortMethod == SortMethod.unanswered
                      ? 'No unanswered questions yet!'
                      : 'No questions yet! Ask one.';
                  return Center(child: Text(message));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot questionDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = questionDoc.data() as Map<String, dynamic>;

                    String title = data['title'] ?? 'No Title';
                    String userName = data['userName'] ?? 'Unknown';
                    String description = data['description'] ?? 'No Description';
                    String questionId = questionDoc.id;
                    List<dynamic> tagsDynamic = data['tags'] ?? [];
                    List<String> tags = tagsDynamic.map((item) => '#${item.toString()}').toList();
                    String formattedTags = tags.isNotEmpty ? tags.join(' ') : 'No Tags';

                    // Check for 'solved' field
                    bool isSolved = data['solved'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 2.0,
                      color: Colors.white,
                      child: ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTags,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              'Author: $userName',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            if (isSolved)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Solved ✅',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionPage(
                                questionId: questionId,
                                questionData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostQuestionPage(),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.edit_note),
        label: const Text('Ask new question'),
      ),
    );
  }

  Stream<QuerySnapshot> _getQuestionsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('Questions');

    if (_sortMethod == SortMethod.unanswered) {
      query = query.where('solved', isEqualTo: false).orderBy('timestamp', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }
    return query.snapshots();
  }
}
