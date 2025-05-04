import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:mentor_quiz/models/quizsession.dart';
import 'package:mentor_quiz/models/participant.dart';
import 'package:mentor_quiz/screens/participant/ParticipantQuizPage.dart';


class JoinQuizPage extends StatefulWidget {
  @override
  _JoinQuizPageState createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  
  // Avatar/emoji selection
  final List<String> _avatarOptions = [
    '😀', '😎', '🤓', '🦊', '🐱', '🐶', '🦁', '🐯', 
    '🐼', '🐨', '🐵', '🦄', '👻', '🤖', '👽', '🦸'
  ];
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];
  String _selectedAvatar = '😀';
  Color _selectedColor = Colors.blue;
  String get _selectedColorHex => '#${_selectedColor.value.toRadixString(16).substring(2)}';
  late AnimationController _avatarAnimController;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _avatarAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _avatarScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _avatarAnimController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _selectAvatar(String avatar) {
    setState(() {
      _selectedAvatar = avatar;
    });
    // Play selection animation
    _avatarAnimController.reset();
    _avatarAnimController.forward();
  }
  
  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _joinQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String username = _usernameController.text.trim();
    String code = _codeController.text.trim().toUpperCase();

    try {
      // S'authentifier anonymement pour avoir les permissions nécessaires
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Rechercher le quiz avec ce code de participation
      QuerySnapshot quizQuery = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('participationCode', isEqualTo: code)
          .limit(1)
          .get();

      if (quizQuery.docs.isEmpty) {
        _showError("Code de participation invalide.");
        return;
      }

      DocumentSnapshot quizDoc = quizQuery.docs.first;
      String quizId = quizDoc.id;

      // Rechercher une session active pour ce quiz
      QuerySnapshot sessionQuery = await FirebaseFirestore.instance
          .collection('quizSessions')
          .where('quizId', isEqualTo: quizId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) {
        _showError("Aucune session active trouvée pour ce quiz.");
        return;
      }

      DocumentSnapshot sessionDoc = sessionQuery.docs.first;
      QuizSession session = QuizSession.fromFirestore(sessionDoc);
      
      // Vérifier si le nom d'utilisateur est déjà pris
      bool usernameExists = session.participants.any((p) => p.username.toLowerCase() == username.toLowerCase());
      if (usernameExists) {
        _showError("Ce nom d'utilisateur est déjà utilisé. Veuillez en choisir un autre.");
        return;
      }

      // Créer un nouveau participant avec l'avatar et la couleur sélectionnés
      var participantId = const Uuid().v4();
      Participant newParticipant = Participant(
        id: participantId,
        username: username,
        avatar: _selectedAvatar,
        avatarColor: _selectedColorHex,
        totalScore: 0,
      );

      // Utiliser une opération atomique pour ajouter le participant
      await FirebaseFirestore.instance
          .collection('quizSessions')
          .doc(session.id)
          .update({
        'participants': FieldValue.arrayUnion([newParticipant.toMap()]),
      });

      // Information pour l'utilisateur si le quiz a déjà commencé
      if (session.state != QuestionState.waitingForParticipants) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Le quiz a déjà commencé. Vous rejoignez à la question active."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Rediriger vers la page du quiz pour le participant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParticipantQuizPage(
            sessionId: session.id,
            participantId: participantId,
          ),
        ),
      );
    } catch (e) {
      print("Erreur détaillée: $e");
      _showError("Erreur lors de la tentative de connexion : ${e.toString().split(']').last}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rejoindre un Quiz"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Entrez votre nom et le code de participation",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // Avatar selection section
                Text(
                  "Choisissez votre avatar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                
                // Currently selected avatar with animation
                Center(
                  child: AnimatedBuilder(
                    animation: _avatarScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _avatarScaleAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedColor.withOpacity(0.2),
                            border: Border.all(color: _selectedColor, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              _selectedAvatar,
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Avatar grid
                Container(
                  height: 150,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                    ),
                    itemCount: _avatarOptions.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatarOptions[index];
                      final isSelected = avatar == _selectedAvatar;
                      
                      return GestureDetector(
                        onTap: () => _selectAvatar(avatar),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: _selectedColor, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Color selection
                Text(
                  "Choisissez une couleur",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 10),
                
                // Color grid
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final color = _colorOptions[index];
                      final isSelected = color == _selectedColor;
                      
                      return GestureDetector(
                        onTap: () => _selectColor(color),
                        child: AnimatedContainer(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          duration: Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : color,
                              width: isSelected ? 3 : 0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 20),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom d\'utilisateur';
                    }
                    if (value.length < 3) {
                      return 'Le nom doit comporter au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: "Code de participation",
                    prefixIcon: Icon(Icons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le code de participation';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _joinQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading 
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "REJOINDRE LE QUIZ",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}