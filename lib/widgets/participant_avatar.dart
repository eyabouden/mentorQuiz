import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mentor_quiz/models/participant.dart';

class ParticipantAvatar extends StatelessWidget {
  final Participant participant;
  final double size;
  final VoidCallback? onTap;
  
  const ParticipantAvatar({
    Key? key,
    required this.participant,
    this.size = 50,
    this.onTap,
  }) : super(key: key);

  Color _hexToColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Fallback to a default color if there's an issue
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the color from the hexadecimal string
    Color avatarColor = _hexToColor(participant.avatarColor);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarColor.withOpacity(0.2),
          border: Border.all(color: avatarColor, width: 2),
        ),
        child: Center(
          child: _buildAvatarContent(participant.avatar, participant.avatarType, size * 0.5),
        ),
      ),
    );
  }
  
  Widget _buildAvatarContent(String avatar, String type, double contentSize) {
    switch (type) {
      case 'emoji':
        return Text(
          avatar,
          style: TextStyle(fontSize: contentSize),
        );
      case 'svg':
        try {
          return SvgPicture.asset(
            avatar,
            width: contentSize,
            height: contentSize,
          );
        } catch (e) {
          // Fallback if SVG can't be loaded
          return Icon(Icons.person, size: contentSize, color: _hexToColor(participant.avatarColor));
        }
      case 'image':
        return ClipOval(
          child: Image.asset(
            avatar,
            width: contentSize,
            height: contentSize,
            fit: BoxFit.cover,
          ),
        );
      default:
        return Text(
          avatar,
          style: TextStyle(fontSize: contentSize),
        );
    }
  }
}
