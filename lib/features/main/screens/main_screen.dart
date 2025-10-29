import 'package:flutter/material.dart';
import 'package:wisata_application/features/explore/screens/explore_screen.dart'; // Assuming explore_screen.dart exists and is potentially translated
import 'package:wisata_application/features/favorites/screens/favorites_screen.dart'; // Assuming favorites_screen.dart exists and is potentially translated
import 'package:wisata_application/features/home/screens/home_screen.dart'; // Assuming home_screen.dart exists and is potentially translated
// Itinerary import was removed previously
import 'package:wisata_application/features/profile/screens/profile_screen.dart'; // Assuming profile_screen.dart exists and is potentially translated

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Widget list remains the same (without ItineraryScreen)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // --- TRANSLATED LABELS ---
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'), // Beranda -> Home
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore_outlined), activeIcon: Icon(Icons.travel_explore_rounded), label: 'Explore'), // Jelajah -> Explore
          // Itinerary item was removed previously
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), activeIcon: Icon(Icons.favorite_rounded), label: 'Favorites'), // Favorit -> Favorites
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'), // Profil -> Profile
          // --- END TRANSLATION ---
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Keep fixed type
      ),
    );
  }
}