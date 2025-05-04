import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header: Logo and App name with improved styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/isi.svg', width: 60),
                      SizedBox(width: 12),
                      Text(
                        'Mentor Quiz',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  
                  // Welcome Card
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Bienvenue sur Mentor Quiz !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'La plateforme ultime pour créer et participer à des quiz interactifs. Que vous soyez enseignant, étudiant ou simplement à la recherche de divertissement, Mentor Quiz est là pour vous !',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Features Section
                  Text(
                    'Que souhaitez-vous faire ?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Create Quiz Card
                  _buildFeatureCard(
                    context,
                    title: 'Créer un Quiz',
                    description: 'Concevez votre propre quiz personnalisé avec différents types de questions, des images et des réponses chronométrées.',
                    icon: Icons.create,
                    color: Colors.blue,
                    onTap: () async {
                      User? user = await _authService.signInWithGoogle();
                      if (user != null) {
                        Navigator.pushNamed(context, '/my-quiz');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-in failed. Please try again.'))
                        );
                      }
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Join Quiz Card
                  _buildFeatureCard(
                    context,
                    title: 'Rejoindre un Quiz',
                    description: 'Entrez un code de quiz pour participer à une session en direct avec des retours en temps réel.',
                    icon: Icons.group_add,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/join-quiz');
                    },
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Statistics Section with real-time data
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
                    builder: (context, quizzesSnapshot) {
                      int quizCount = quizzesSnapshot.hasData ? quizzesSnapshot.data!.docs.length : 0;
                      
                      // Count unique quiz creators
                      Set<String> uniqueCreators = {};
                      // Count total questions
                      int totalQuestions = 0;
                      
                      if (quizzesSnapshot.hasData) {
                        for (var doc in quizzesSnapshot.data!.docs) {
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          if (data['userId'] != null) {
                            uniqueCreators.add(data['userId']);
                          }
                          // Count questions in each quiz
                          if (data['questions'] != null) {
                            List<dynamic> questions = data['questions'];
                            totalQuestions += questions.length;
                          }
                        }
                      }
                      
                      return Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Statistiques de la Plateforme',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatistic(
                                  quizCount.toString(),
                                  'Quiz Créés',
                                  Icons.quiz,
                                  Colors.blue.shade700,
                                ),
                                _buildStatistic(
                                  uniqueCreators.length.toString(), 
                                  'Créateurs',
                                  Icons.person_add,
                                  Colors.green.shade700,
                                ),
                                _buildStatistic(
                                  totalQuestions.toString(),
                                  'Questions Totales',
                                  Icons.question_answer,
                                  Colors.purple.shade700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Footer with improved styling
                  Text(
                    'Créez et rejoignez des quiz en toute simplicité.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '© 2025 Mentor Quiz - Tous droits réservés.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistic(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}