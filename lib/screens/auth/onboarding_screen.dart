import 'package:flutter/material.dart';
import 'package:proyek3/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingContent {
  final String imagePath;
  final String title;
  final String description;

  OnboardingContent({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

final List<OnboardingContent> contents = [
  OnboardingContent(
    imagePath: 'assets/on1.jpg',
    title: 'Temukan Resep Terbaik',
    description: 'Jelajahi ribuan resep lezat dan mudah dibuat dari seluruh dunia.',
  ),
  OnboardingContent(
    imagePath: 'assets/on2.jpg',
    title: 'Masak dengan Cepat',
    description: 'Filter resep berdasarkan durasi memasak untuk hidangan cepat saji.',
  ),
  OnboardingContent(
    imagePath: 'assets/on3.jpg',
    title: 'Rencanakan Makanan Anda',
    description: 'Simpan resep favorit dan rencanakan menu mingguan Anda.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Gambar Fullscreen dengan PageView
          PageView.builder(
            controller: _controller,
            itemCount: contents.length,
            onPageChanged: (int page) {
              setState(() => currentPage = page);
            },
            itemBuilder: (_, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    contents[i].imagePath,
                    fit: BoxFit.cover, // Membuat gambar memenuhi layar
                  ),
                  // 2. Overlay Gradient agar teks terbaca jelas
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2), // Bagian atas agak terang
                          Colors.black.withOpacity(0.8), // Bagian bawah gelap untuk teks
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Konten Teks (Diposisikan di atas Gambar)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Text(
                        contents[currentPage].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Teks putih agar kontras
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        contents[currentPage].description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    contents.length,
                    (index) => buildDot(index, context),
                  ),
                ),
                const SizedBox(height: 40),

                // Tombol
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentPage == contents.length - 1) {
                        _skipToLogin();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      currentPage == contents.length - 1 ? "MULAI SEKARANG" : "LANJUT",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentPage == index ? Colors.redAccent : Colors.white38,
      ),
    );
  }
}