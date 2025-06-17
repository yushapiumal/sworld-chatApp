import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StickerScreen extends StatefulWidget {
  static String routeName = "StickerScreen";
  

  const StickerScreen({super.key});

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  // Sample sticker data - replace with your actual stickers
  final List<String> stickerPaths = [
    'assets/sticker/congrats.png',
    'assets/sticker/happy-birthday.png',
    'assets/sticker/dumbbell.png',
    'assets/sticker/woman.png',
    'assets/sticker/i-am-proud-of-you.png',
    'assets/sticker/self-learning.png',
    'assets/sticker/drinkwoman.png',
    'assets/sticker/listening.png',
    'assets/sticker/make-a-wish.png',
    // Add all your sticker paths here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stickers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement sticker search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticker categories tab bar
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryButton('Popular', true),
                _buildCategoryButton('Emotions', true),
                _buildCategoryButton('Animals', false),
                _buildCategoryButton('Food', false),
                _buildCategoryButton('Celebration', false),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sticker grid view
          Expanded(
            child: MasonryGridView.count(
              padding: const EdgeInsets.all(8),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: stickerPaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Return the selected sticker to the chat screen
                    Navigator.pop(context, stickerPaths[index]);
                  },
                  child: Image.asset(
                    stickerPaths[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}