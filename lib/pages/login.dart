import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'home.dart';
import 'start.dart';
import '../Dietitians/homePageDietitian.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageMobile> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _goSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const signUpPage()),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    TextEditingController resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your registered email to reset your password."),
            const SizedBox(height: 10),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String resetEmail = resetEmailController.text.trim();
              if (resetEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter an email")),
                );
                return;
              }
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: resetEmail);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Password reset email has been sent")),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.message}")),
                );
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserStatus(String uid, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection("Users").doc(uid).update({
        "status": isOnline ? "online" : "offline",
        "lastSeen": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      List<String> signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This email is already registered using Email & Password."),
          ),
        );
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      print("Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in with Google.")),
      );
      return false;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    String displayName = user.displayName ?? "";
    List<String> nameParts = displayName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts.first : "";
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        "email": user.email,
        "firstName": firstName,
        "lastName": lastName,
        "age": null,
        "goals": null,
        "status": "online",
        "lastSeen": FieldValue.serverTimestamp(),
        "hasCompletedTutorial": false,
        "tutorialStep": 0,
        "role": "user", // 👈 Add default role
      });
    } else {
      await _updateUserStatus(user.uid, true);
    }
  }

  Future<void> _handlePostLogin(User user) async {
    await user.reload();
    user = FirebaseAuth.instance.currentUser!;

    final docRef = FirebaseFirestore.instance.collection("Users").doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // Save new user with default role = "user"
      await _saveUserToFirestore(user);
    } else {
      await _updateUserStatus(user.uid, true);
    }

    // ✅ Get role and tutorial status
    String role = docSnap.data()?['role'] ?? "user";
    bool hasCompletedTutorial = docSnap.data()?['hasCompletedTutorial'] ?? false;

    if (hasCompletedTutorial) {
      if (role == "dietitian") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePageDietitian()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const home()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MealPlanningScreen(userId: user.uid)),
      );
    }
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
          letterSpacing: 0.5,
          fontFamily: 'Inter',
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          CustomPaint(painter: WavePainter(), size: Size.infinite),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'EMAIL',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: passController,
                        hintText: 'PASSWORD',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            String email = emailController.text.trim();
                            String pass = passController.text.trim();

                            if (email.isEmpty || pass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("All inputs required")),
                              );
                              return;
                            }

                            try {
                              UserCredential userCredential =
                              await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: email, password: pass);
                              await _handlePostLogin(userCredential.user!);
                            } catch (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Login failed: $err")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            bool isLogged = await loginWithGoogle();
                            if (isLogged && FirebaseAuth.instance.currentUser != null) {
                              await _handlePostLogin(FirebaseAuth.instance.currentUser!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "SIGN IN WITH GOOGLE",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _goSignUp,
                        child: const Text(
                          "DON'T HAVE AN ACCOUNT? SIGN UP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.25,
      size.width * 0.5, size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.35,
      size.width, size.height * 0.25,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    final bottomPath = Path();
    bottomPath.moveTo(0, size.height);
    bottomPath.lineTo(0, size.height * 0.75);
    bottomPath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.8,
      size.width * 0.5, size.height * 0.75,
    );
    bottomPath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.8,
    );
    bottomPath.lineTo(size.width, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
