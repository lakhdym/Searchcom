import 'package:flutter/material.dart';

import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/top_nav_bar.dart';
import 'home_page.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>
    with SingleTickerProviderStateMixin {
  final LanguageService _languageService = LanguageService.instance;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    await _languageService.setLanguage(languageCode);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final maxWidth = isMobile ? screenWidth : 500.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const TopNavBar(showLoginAction: false),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: maxWidth,
                padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr(context, 'welcome'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'select_language_first'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ...LanguageService.supportedLanguages.map((language) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _LanguageButton(
                          language: language,
                          onTap: () => _selectLanguage(language.code),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatefulWidget {
  const _LanguageButton({required this.language, required this.onTap});

  final LanguageOption language;
  final VoidCallback onTap;

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primaryVioletLight
                : AppTheme.backgroundGray,
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryVioletMedium
                  : AppTheme.borderLight,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppTheme.primaryVioletLighter
                      : AppTheme.borderLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.primaryVioletMedium
                        : AppTheme.borderMedium,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.flag,
                  color: _isHovered
                      ? AppTheme.primaryViolet
                      : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language.nativeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _isHovered
                            ? AppTheme.primaryVioletDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.language.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isHovered
                            ? AppTheme.primaryViolet
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _isHovered
                    ? AppTheme.primaryVioletMedium
                    : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
