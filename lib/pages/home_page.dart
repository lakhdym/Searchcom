import 'package:flutter/material.dart';
import 'found_form_page.dart';
import 'lost_form_page.dart';

/// Home page with two action cards and a search bar with filter button.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openLost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LostFormPage()),
    );
  }

  void _openFound(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoundFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 760;

    final lostCard = HomeActionCard(
      title: "J'ai perdu",
      subtitle:
          "Signalez un objet perdu pour augmenter vos chances de le retrouver.",
      height: 150,
      backgroundColor: const Color(0xFFFFF1F1),
      smallIconBackground: const Color(0xFFFFE4E4),
      smallIcon: Icons.heart_broken,
      smallIconColor: const Color(0xFFE53935),
      bigIcon: Icons.search,
      bigIconColor: const Color(0xFFE53935).withOpacity(0.08),
      onTap: () => _openLost(context),
    );

    final foundCard = HomeActionCard(
      title: "J'ai trouv\u00e9",
      subtitle:
          "Aidez quelqu'un \u00e0 retrouver son bien en publiant une annonce.",
      height: 150,
      backgroundColor: const Color(0xFFF1FBF5),
      smallIconBackground: const Color(0xFFDFF5E7),
      smallIcon: Icons.handshake,
      smallIconColor: const Color(0xFFF9A825),
      bigIcon: Icons.check_circle,
      bigIconColor: const Color(0xFF2E7D32).withOpacity(0.08),
      onTap: () => _openFound(context),
    );

    Widget cardsRow() => Row(
          children: [
            Expanded(child: lostCard),
            const SizedBox(width: 20),
            Expanded(child: foundCard),
          ],
        );

    Widget cardsColumn() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            lostCard,
            const SizedBox(height: 20),
            foundCard,
          ],
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: isWide
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cardsRow(),
                    const SizedBox(height: 20),
                    const SearchBarWithFilter(),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardsColumn(),
                      const SizedBox(height: 20),
                      const SearchBarWithFilter(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color smallIconBackground;
  final IconData smallIcon;
  final Color smallIconColor;
  final IconData bigIcon;
  final Color bigIconColor;
  final double height;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.smallIconBackground,
    required this.smallIcon,
    required this.smallIconColor,
    required this.bigIcon,
    required this.bigIconColor,
    required this.onTap,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.black.withOpacity(0.05),
        highlightColor: Colors.black.withOpacity(0.02),
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.fromLTRB(24, 24, 80, 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: smallIconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      smallIcon,
                      color: smallIconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6C7B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    bigIcon,
                    size: 120,
                    color: bigIconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBarWithFilter extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWithFilter({super.key, this.onChanged, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Rechercher (objet, lieu, mot-cl\u00e9\u2026)",
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                // contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onFilterTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text(
                'Filtrer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
