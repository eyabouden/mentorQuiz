import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Méthode pour se connecter avec Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Erreur d'authentification Google : $e");
      return null;
    }
  }

 Future<void> signOut() async {
    try {
      // Vérifier si l'utilisateur s'est connecté avec Google
      final isSignedInWithGoogle = await _googleSignIn.isSignedIn();
      
      // Déconnecter de Google s'il était connecté avec Google
      if (isSignedInWithGoogle) {
        await _googleSignIn.signOut();
      }
      
      // Déconnecter de Firebase Auth en dernier
      await _auth.signOut();
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
      // Essayer de déconnecter uniquement Firebase Auth en cas d'erreur
      await _auth.signOut();
    }
  }

  // Getter pour obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Getter pour obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;
}

