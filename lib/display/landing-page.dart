import 'package:flutter/material.dart';
import 'signin_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            children: [
              const SlidePage(image: 'assets/images/ss1.png'),
              const SlidePage(image: 'assets/images/ss2.png'),
              SlidePage(
                image: 'assets/images/ss3.png',
                isLast: true,
                onFinish: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SigninPage()),
                  );
                },
              ),
            ],
          ),
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SigninPage()),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlidePage extends StatelessWidget {
  final String image;
  final bool isLast;
  final VoidCallback? onFinish;

  const SlidePage({
    super.key,
    required this.image,
    this.isLast = false,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
        ),
        if (isLast)
          Positioned(
            bottom: 0,
            left: 150,
            child: Center(
              child: ElevatedButton(
                onPressed: onFinish,
                child: const Text('Get Started'),
              ),
            ),
          ),
      ],
    );
  }
}
