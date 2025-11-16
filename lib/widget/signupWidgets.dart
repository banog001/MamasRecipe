import 'package:flutter/material.dart';
import '../theme/signupTheme.dart';

class SignupWidgets {
  // ==================== BUILD TEXT FIELD ====================
  static Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: getTextStyle(context, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: getTextStyle(
          context,
          color: textColorSecondary(context),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: scaffoldBgColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  // ==================== BUILD SIGN UP BUTTON ====================
  static Widget buildSignUpButton(
      BuildContext context, {
        required bool isLoading,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColorOnPrimary,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: textColorOnPrimary,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Create Account',
          style: getTextStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColorOnPrimary,
          ),
        ),
      ),
    );
  }

  // ==================== BUILD LOGIN LINK ====================
  static Widget buildLoginLink(
      BuildContext context, {
        required VoidCallback onPressed,
      }) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: getTextStyle(
              context,
              fontSize: 14,
              color: textColorSecondary(context),
            ),
            children: [
              TextSpan(
                text: 'Sign In',
                style: getTextStyle(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
