import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_modal.dart';
import '../widgets/top_nav_bar.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';
import 'found_form_page.dart';
import 'login_page.dart';

class LostFormPage extends StatefulWidget {
  const LostFormPage({super.key});

  @override
  State<LostFormPage> createState() => _LostFormPageState();
}

class _LostFormPageState extends State<LostFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!ApiService.instance.isAuthenticated && currentUser.value == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _createLostListing();
  }

  Future<void> _createLostListing() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService.instance.createListing(
        type: 'lost',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _locationController.text.trim(),
        locationText: _locationController.text.trim(),
        contactChat: true,
        contactCall: true,
        contactWhatsApp: false,
      );
      if (!mounted) return;

      final priceLabel =
          "${result.amount ?? ''} ${result.currency ?? ''}".trim().isEmpty
              ? 'Paiement requis'
              : "${result.amount} ${result.currency}";

      await PaymentModal.show(
        context,
        amount: priceLabel,
        onPay: (_) async {
          await ApiService.instance.confirmPublishPayment(
            paymentId: result.paymentId ?? 0,
            listingId: result.listingId,
          );
          return true;
        },
        onPaymentSuccess: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement confirmé, annonce publiée'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: TopNavBar(
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signalement Objet Perdu',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remplissez les détails ci-dessous pour publier votre annonce.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Sélecteur Perdu / Trouvé
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: const Border(
                                  left: BorderSide(
                                    color: Color(0xFFFF6B35),
                                    width: 3,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Objet Perdu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const FoundFormPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundGray,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Objet Trouvé',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      label: "Titre de l'objet",
                      controller: _titleController,
                      hint: 'Ex: Clés de voiture BMW',
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Photos',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sélection d\'images à implémenter')),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderMedium,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Cliquez pour ajouter des photos',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'JPG, PNG (max 5MB)',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Description détaillée',
                      controller: _descriptionController,
                      hint: "Décrivez l'objet, le lieu exact, l'heure...",
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLocationField(),
                              const SizedBox(height: 20),
                              _buildPhoneField(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildLocationField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPhoneField()),
                            ],
                          ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(_submitting ? 'Traitement...' : "Publier l'annonce"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Un paiement sera demandé à l\'étape suivante.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return _buildTextField(
      label: 'Lieu',
      controller: _locationController,
      hint: 'Ville, Quartier...',
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      label: 'Numéro de téléphone',
      controller: _phoneController,
      hint: '+212 6...',
    );
  }
}
