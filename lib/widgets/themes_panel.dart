// lib/screens/admin/widgets/themes_panel.dart
import 'package:flutter/material.dart';

class ThemesPanel extends StatelessWidget {
  final List<String> backgroundImages;
  final String selectedBackgroundImage;
  final Function(String) onThemeSelected;

  const ThemesPanel({
    Key? key,
    required this.backgroundImages,
    required this.selectedBackgroundImage,
    required this.onThemeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thèmes disponibles",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          "Sélectionnez un arrière-plan pour votre question:",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: backgroundImages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () => onThemeSelected(''),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Pas de thème", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              } else {
                String imagePath = backgroundImages[index - 1];
                return GestureDetector(
                  onTap: () => onThemeSelected(imagePath),
                  child: Card(
                    elevation: 2,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (selectedBackgroundImage == imagePath)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(height: 20),
        Text(
          "Note: L'image sera appliquée uniquement à la question sélectionnée.",
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }
}