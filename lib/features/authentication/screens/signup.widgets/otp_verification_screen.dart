import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/signup/verify_otp_controller.dart';
import '../../../../common/widgets/appbar/appbar.dart';

class OTPVerificationScreen extends StatelessWidget {
  final String email;
  final Map<String, dynamic> userData;
  final bool isSignupFlow;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.userData,
    this.isSignupFlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OTPVerificationController());
    controller.emailController.text = email;
    controller.initializeFlow(isSignupFlow, userData);

    controller.startTimer();

    return Scaffold(
      appBar: TAppBar(
        title: Text(isSignupFlow
            ? 'Vérification Inscription'
            : 'Vérification Connexion'),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isSignupFlow ? 'Finalisez votre inscription' : 'Connectez-vous',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Entrez le code reçu à l\'adresse $email',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // OTP Fields
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (index) {
                return Flexible(
                  child: SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          final text = controller.otpController.text;
                          final newText = text.padRight(6, ' ');
                          controller.otpController.text =
                              newText.replaceRange(index, index + 1, val);

                          if (index < 5) FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Bouton vérification
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.verifyOTP(),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isSignupFlow ? 'Créer le compte' : 'Se connecter'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Resend OTP Section
            Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Vous n'avez pas reçu le code ? ",
                  ),
                  TextButton(
                    onPressed: controller.isResendAvailable.value
                        ? () => controller.resendOTP()
                        : null,
                    child: Text(
                      controller.isResendAvailable.value
                          ? 'Renvoyer'
                          : 'Renvoyer (${controller.secondsRemaining.value}s)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
