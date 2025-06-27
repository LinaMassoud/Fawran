import 'package:flutter/material.dart';

class ServiceChoicePage extends StatelessWidget {
  const ServiceChoicePage({super.key});

  void _handleChoice(BuildContext context, String serviceName) {
    // Navigate based on selected service
    if (serviceName == 'Hourly Maid') {
      Navigator.of(context).pushReplacementNamed('/hourly');
    } else if (serviceName == 'Permanent Maid') {
      Navigator.of(context).pushNamed('/selectAddress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose a Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildServiceBox(
              context,
              title: 'Hourly Maid',
              icon: Icons.access_time,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),
            _buildServiceBox(
              context,
              title: 'Permanent Maid',
              icon: Icons.cleaning_services,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceBox(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _handleChoice(context, title),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
