import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modal de paiement pour la publication d'annonce "Objet perdu"
class PaymentModal extends StatefulWidget {
  final String amount;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onCancel;

  const PaymentModal({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
    this.onCancel,
  });

  /// Affiche le modal de paiement
  static Future<void> show(
    BuildContext context, {
    required String amount,
    required VoidCallback onPaymentSuccess,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentModal(
        amount: amount,
        onPaymentSuccess: onPaymentSuccess,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = 'card'; // 'card' ou 'paypal'
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // Simulation du paiement (2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);
    Navigator.of(context).pop();
    widget.onPaymentSuccess();
  }

  void _handleCancel() {
    Navigator.of(context).pop();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec titre et bouton fermer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Finaliser la publication',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppTheme.textMuted,
                        onPressed: _handleCancel,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Message d'information dans une boîte violette
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryVioletLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryVioletLighter,
                        width: 1,
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryVioletDark,
                        ),
                        children: [
                          const TextSpan(text: 'Pour publier une annonce '),
                          TextSpan(
                            text: '"Objet perdu"',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ', une participation de '),
                          TextSpan(
                            text: widget.amount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(text: ' est requise.'),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section Moyen de paiement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moyen de paiement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Option Carte Bancaire
                      _PaymentMethodOption(
                        title: 'Carte Bancaire',
                        icon: Icons.credit_card,
                        iconColor: const Color(0xFF2563EB),
                        iconBackground: const Color(0xFFDBEAFE),
                        isSelected: _selectedMethod == 'card',
                        onTap: () => setState(() => _selectedMethod = 'card'),
                      ),
                      const SizedBox(height: 12),

                      // Option PayPal
                      _PaymentMethodOption(
                        title: 'PayPal',
                        icon: Icons.account_balance_wallet,
                        iconColor: const Color(0xFF003087),
                        iconBackground: const Color(0xFFE6F0FF),
                        isSelected: _selectedMethod == 'paypal',
                        onTap: () => setState(() => _selectedMethod = 'paypal'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Footer avec sécurité et boutons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicateur de sécurité
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Paiement sécurisé',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Boutons d'action
                      Row(
                        children: [
                          TextButton(
                            onPressed: _isProcessing ? null : _handleCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isProcessing ? null : _handlePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryViolet,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Payer ${widget.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
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

/// Widget pour une option de moyen de paiement
class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryVioletLight : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryViolet
                : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryViolet
                      : AppTheme.borderMedium,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryViolet,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Icône du moyen de paiement
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Titre
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
