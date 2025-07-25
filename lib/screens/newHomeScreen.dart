import 'package:flutter/material.dart';

class FawranHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // App Bar with logo and hamburger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.menu, color: Colors.white),
                    Image.asset('assets/logo.png', height: 30), // Replace with actual logo
                  ],
                ),
              ),

              // Filter Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterButton('Home Maid'),
                    SizedBox(width: 12),
                    _buildFilterButton('Private Driver'),
                  ],
                ),
              ),

              // Promo Card
              _buildPromoCard(),

              // Our Services
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  children: [
                    Text('Our Services', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: _buildServiceCard('Home Maid', 'assets/home_maid.png')),
                    SizedBox(width: 8),
                    Expanded(child: _buildServiceCard('Private Driver', 'assets/driver.png')),
                  ],
                ),
              ),

              // Special Packages
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  children: [
                    Text('Special Packages', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildPromoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildPromoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage('assets/promo.png'), // Replace with actual image
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('1 Month - Home Maid\n-15%', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, String imagePath) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 40),
            SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
