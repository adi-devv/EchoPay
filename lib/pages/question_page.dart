import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:echopay/components/utils.dart'; // Make sure this path is correct for your project

class QuestionPage extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;

  const QuestionPage({
    super.key,
    required this.questionId,
    required this.questionData,
  });

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final TextEditingController _replyController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _repliesStream;
  String? _questionAuthorId;

  @override
  void initState() {
    super.initState();
    _repliesStream = _firestore
        .collection('Questions')
        .doc(widget.questionId)
        .collection('Replies')
        .orderBy('timestamp', descending: true)
        .snapshots();

    _questionAuthorId = widget.questionData['userID'];
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post a reply.')),
      );
      return;
    }

    final String replyText = _replyController.text.trim();
    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply cannot be empty.')),
      );
      return;
    }

    try {
      await _firestore
          .collection('Questions')
          .doc(widget.questionId)
          .collection('Replies')
          .add({
        'userID': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'replyText': replyText,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'upvoters': [],
        'downvoters': [],
        'isSolution': false, // Initialize 'isSolution' field
      });

      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply posted successfully!')),
      );
    } catch (e) {
      print('Error posting reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post reply: ${e.toString()}')),
      );
    }
  }

  Future<void> _voteReply(String replyId, bool isUpvote, List<dynamic> currentUpvoters, List<dynamic> currentDownvoters) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to vote.')),
      );
      return;
    }

    String userId = user.uid;
    bool alreadyUpvoted = currentUpvoters.contains(userId);
    bool alreadyDownvoted = currentDownvoters.contains(userId);

    DocumentReference replyRef = _firestore
        .collection('Questions')
        .doc(widget.questionId)
        .collection('Replies')
        .doc(replyId);

    try {
      if (isUpvote) {
        if (alreadyUpvoted) {
          await replyRef.update({
            'upvotes': FieldValue.increment(-1),
            'upvoters': FieldValue.arrayRemove([userId]),
          });
        } else {
          await replyRef.update({
            'upvotes': FieldValue.increment(1),
            'upvoters': FieldValue.arrayUnion([userId]),
          });
          if (alreadyDownvoted) {
            await replyRef.update({
              'downvotes': FieldValue.increment(-1),
              'downvoters': FieldValue.arrayRemove([userId]),
            });
          }
        }
      } else { // isDownvote
        if (alreadyDownvoted) {
          await replyRef.update({
            'downvotes': FieldValue.increment(-1),
            'downvoters': FieldValue.arrayRemove([userId]),
          });
        } else {
          await replyRef.update({
            'downvotes': FieldValue.increment(1),
            'downvoters': FieldValue.arrayUnion([userId]),
          });
          if (alreadyUpvoted) {
            await replyRef.update({
              'upvotes': FieldValue.increment(-1),
              'upvoters': FieldValue.arrayRemove([userId]),
            });
          }
        }
      }
    } catch (e) {
      print('Error voting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cast vote: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAsSolution(String replyId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != _questionAuthorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the question author can mark a solution.')),
      );
      return;
    }

    if (widget.questionData['solved'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This question is already marked as solved.')),
      );
      return;
    }

    try {
      await _firestore
          .collection('Questions')
          .doc(widget.questionId)
          .update({'solved': true});

      await _firestore
          .collection('Questions')
          .doc(widget.questionId)
          .collection('Replies')
          .doc(replyId)
          .update({'isSolution': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question marked as solved!')),
      );
    } catch (e) {
      print('Error marking as solution: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as solution: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.questionData['title'] ?? 'No Title';
    String description = widget.questionData['description'] ?? 'No Description';
    String userName = widget.questionData['userName'] ?? 'Unknown';

    List<dynamic> tagsDynamic = widget.questionData['tags'] ?? [];
    List<String> tags = tagsDynamic.map((item) => '#${item.toString()}').toList();
    String formattedTags = tags.isNotEmpty ? tags.join(' ') : 'No Tags';

    Timestamp? timestamp = widget.questionData['timestamp'] as Timestamp?;

    bool isSolved = widget.questionData['solved'] == true;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formattedTags,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Author: $userName',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Posted ${Utils.timeAgo(timestamp?.toDate())}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (isSolved)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'This question is SOLVED! ✅',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Text(
                    'Replies:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _repliesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading replies: ${snapshot.error}');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text('No replies yet. Be the first to answer!'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot replyDoc = snapshot.data!.docs[index];
                          Map<String, dynamic> replyData = replyDoc.data() as Map<String, dynamic>;

                          String replyText = replyData['replyText'] ?? 'No Reply Text';
                          String replierName = replyData['userName'] ?? 'Anonymous';
                          Timestamp? replyTimestamp = replyData['timestamp'] as Timestamp?;
                          String formattedReplyTime = Utils.timeAgo(replyTimestamp?.toDate());

                          int upvotes = replyData['upvotes'] ?? 0;
                          int downvotes = replyData['downvotes'] ?? 0;
                          List<dynamic> upvoters = replyData['upvoters'] ?? [];
                          List<dynamic> downvoters = replyData['downvoters'] ?? [];
                          bool isThisReplyTheSolution = replyData['isSolution'] == true;

                          String? currentUserId = _auth.currentUser?.uid;
                          bool currentUserUpvoted = currentUserId != null && upvoters.contains(currentUserId);
                          bool currentUserDownvoted = currentUserId != null && downvoters.contains(currentUserId);
                          bool isCurrentUserAuthor = currentUserId == _questionAuthorId;
                          bool isQuestionSolved = widget.questionData['solved'] == true;


                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            color: isThisReplyTheSolution
                                ? Colors.green.shade50
                                : Theme.of(context).colorScheme.tertiary,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$replierName replied $formattedReplyTime',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (isThisReplyTheSolution)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Solution ✅',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (isCurrentUserAuthor && !isQuestionSolved)
                                        ElevatedButton.icon(
                                          onPressed: () => _markAsSolution(replyDoc.id),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Mark as Solution'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_circle_up,
                                                color: currentUserUpvoted ? Colors.green : Colors.grey,
                                              ),
                                              onPressed: () {
                                                _voteReply(replyDoc.id, true, upvoters, downvoters);
                                              },
                                            ),
                                            Text('$upvotes'),
                                            const SizedBox(width: 15),
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_circle_down,
                                                color: currentUserDownvoted ? Colors.red : Colors.grey,
                                              ),
                                              onPressed: () {
                                                _voteReply(replyDoc.id, false, upvoters, downvoters);
                                              },
                                            ),
                                            Text('$downvotes'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _postReply,
                  child: const Icon(Icons.send),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}