import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "SYNC EVERYTHING",
      description: "The world's fastest messaging app. Free, secure, and always in sync.",
      icon: Icons.sync_alt,
      color: const Color(0xFF24A1DE),
    ),
    OnboardingData(
      title: "UNBREAKABLE SECURITY",
      description: "SYNC keeps your messages safe with state-of-the-art encryption.",
      icon: Icons.lock_outline,
      color: const Color(0xFFFF6B6B),
    ),
    OnboardingData(
      title: "CLOUD POWERED",
      description: "Access your chats from anywhere. Your data is yours, everywhere.",
      icon: Icons.cloud_queue,
      color: const Color(0xFF4ECDC4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedContainer(
      duration: 800.ms,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _pages[_currentPage].color.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms);
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildExpressiveIcon(data),
          const SizedBox(height: 60),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.title,
              style: GoogleFonts.syne(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ).animate(key: ValueKey('title_$_currentPage')).fadeIn(delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(key: ValueKey('desc_$_currentPage')).fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildExpressiveIcon(OnboardingData data) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(80).copyWith(
              topLeft: const Radius.circular(120),
              bottomRight: const Radius.circular(120),
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 3.seconds, curve: Curves.easeInOutSine)
         .rotate(begin: -0.05, end: 0.05, duration: 4.seconds),
        
        Icon(
          data.icon,
          size: 100,
          color: data.color,
        ).animate(key: ValueKey('icon_$_currentPage'))
         .fadeIn(duration: 600.ms)
         .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 64),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "START MESSAGING",
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ).animate().slideY(begin: 0.1, curve: Curves.easeOutCubic).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: isSelected ? 32 : 10,
      decoration: BoxDecoration(
        color: isSelected 
            ? _pages[_currentPage].color 
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
