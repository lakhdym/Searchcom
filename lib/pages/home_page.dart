// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../widgets/home/home_action_card.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/recent_publications_section.dart';
import '../widgets/top_nav_bar.dart';
import 'found_form_page.dart';
import 'login_page.dart';

/// Home page with action cards, search bar, and recent publications list.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _feedRefreshSignal = ValueNotifier<int>(0);

  @override
  void dispose() {
    _scrollController.dispose();
    _feedRefreshSignal.dispose();
    super.dispose();
  }

  Future<void> _openLost() async {
    await _guardAuthThen(
      context,
      onAllowed: () => _openCreationPage('lost'),
      title: 'Connexion requise',
      message: 'Vous devez vous connecter pour publier une annonce perdue.',
    );
  }

  Future<void> _openFound() async {
    await _guardAuthThen(
      context,
      onAllowed: () => _openCreationPage('found'),
      title: 'Connexion requise',
      message: 'Vous devez vous connecter pour publier une annonce.',
    );
  }

  Future<void> _openCreationPage(String type) async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => FoundFormPage(type: type)));
    if (!mounted || created != true) return;

    _feedRefreshSignal.value++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Annonce publiée avec succès')),
    );
  }

  Future<void> _guardAuthThen(
    BuildContext context, {
    required Future<void> Function() onAllowed,
    required String title,
    required String message,
  }) async {
    final storedToken = await AuthLocalStorage.instance.getToken();
    debugPrint(
      '[GuardLostFound] tokenPresent=${storedToken != null && storedToken.isNotEmpty}',
    );

    if (storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setToken(storedToken);
      await onAllowed();
      return;
    }

    final navigator = Navigator.of(context);

    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );

    if (!navigator.mounted) return;

    if (goLogin == true) {
      navigator.push(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 760;

    final lostCard = HomeActionCard(
      title: "J'ai perdu",
      subtitle:
          'Signalez un objet perdu pour augmenter vos chances de le retrouver.',
      height: 150,
      backgroundColor: const Color(0xFFFFF1F1),
      smallIconBackground: const Color(0xFFFFE4E4),
      smallIcon: Icons.heart_broken,
      smallIconColor: const Color(0xFFE53935),
      bigIcon: Icons.search,
      bigIconColor: const Color(0xFFE53935).withValues(alpha: 0.08),
      onTap: _openLost,
    );

    final foundCard = HomeActionCard(
      title: "J'ai trouvé",
      subtitle: "Aidez quelqu'un à retrouver son bien en publiant une annonce.",
      height: 150,
      backgroundColor: const Color(0xFFF1FBF5),
      smallIconBackground: const Color(0xFFDFF5E7),
      smallIcon: Icons.handshake,
      smallIconColor: const Color(0xFFF9A825),
      bigIcon: Icons.check_circle,
      bigIconColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
      onTap: _openFound,
    );

    final cardsSection = isWide
        ? Row(
            children: [
              Expanded(child: lostCard),
              const SizedBox(width: 20),
              Expanded(child: foundCard),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [lostCard, const SizedBox(height: 20), foundCard],
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: widget.showAppBar ? const TopNavBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cardsSection,
              const SizedBox(height: 20),
              RecentPublicationsSection(
                scrollController: _scrollController,
                refreshListenable: _feedRefreshSignal,
                headerBuilder: (onSearchChanged) => Column(
                  children: [
                    SearchBarWithFilter(
                      onChanged: onSearchChanged,
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
