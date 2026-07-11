import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // These will eventually be replaced by your actual Front and Back pages
  final List<Widget> _pages = [
    const Center(child: Text("Front-of-House (Cashier/POS)")),
    const Center(child: Text("Back-of-House (Kitchen/Prep)")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody ensures the background color/widgets flow under the floating nav
      extendBody: true, 
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale_rounded),
                  label: 'Front',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.kitchen_rounded),
                  label: 'Back',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}