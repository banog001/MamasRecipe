// Create: lib/widgets/auth_ui_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/loginTheme.dart';

class AuthUIWidgets {
  // ==================== TERMS CHECKBOX ====================
  static Widget buildTermsCheckbox(
      BuildContext context, {
        required bool agreedToTerms,
        required Function(bool) onChanged,
        required VoidCallback onTapTerms,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: agreedToTerms,
            onChanged: (value) {
              onChanged(value ?? false);
            },
            activeColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTapTerms,
          child: RichText(
            text: TextSpan(
              style: getTextStyle(
                context,
                fontSize: 14,
                color: textColorSecondary(context),
              ),
              children: [
                const TextSpan(text: 'I agree with '),
                TextSpan(
                  text: 'Terms and Conditions',
                  style: getTextStyle(
                    context,
                    fontSize: 14,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TEXT INPUT FIELD ====================
  static Widget buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required IconData icon,
        bool obscureText = false,
        Widget? suffixIcon,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
        // Default border when not focused
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        // Active border when field is focused (green)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        // Error border when validation fails (red)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }

  // ==================== LOGIN BUTTON ====================
  static Widget buildLoginButton(
      BuildContext context, {
        required bool isLoading,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColorOnPrimary,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Show loading spinner while authenticating
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: textColorOnPrimary,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Sign In',
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

  // ==================== GOOGLE SIGN IN BUTTON ====================
  static Widget buildGoogleSignInButton(
      BuildContext context, {
        required bool isLoading,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Google logo icon
        icon: Image.asset(
          'lib/assets/icons/google_icon.svg',
          width: 18,
          height: 18,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.g_mobiledata, color: Colors.red, size: 20),
        ),
        label: Text(
          'Continue with Google',
          style: getTextStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColorPrimary(context),
          ),
        ),
      ),
    );
  }

  // ==================== BACKGROUND DECORATIVE SHAPES ====================
  static Widget buildBackgroundShapes(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: scaffoldBgColor(context),
      child: Stack(
        children: [
          // Top-left green circle decoration
          Positioned(
            top: -100,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom-right green circle decoration
          Positioned(
            bottom: -120,
            right: -180,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}