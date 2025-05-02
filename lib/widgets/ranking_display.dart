import 'package:flutter/material.dart';
import 'package:mentor_quiz/models/participant.dart';

class RankingDisplay extends StatelessWidget {
  final List<Participant> participants;
  final double? height;

  const RankingDisplay({
    Key? key,
    required this.participants,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Trier les participants par score
    final sortedParticipants = [...participants];
    sortedParticipants.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Container(
      height: height,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Classement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: sortedParticipants.length,
              itemBuilder: (context, index) {
                final participant = sortedParticipants[index];
                final isTopThree = index < 3;
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(index),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isTopThree ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getMedalColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildAvatar(participant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Score: ${participant.totalScore}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isTopThree) _buildMedalIcon(index),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Participant participant) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(int.parse(participant.avatarColor.replaceAll('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: participant.avatarType == 'emoji'
            ? Text(
                participant.avatar,
                style: TextStyle(fontSize: 24),
              )
            : Image.network(
                participant.avatar,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, color: Colors.white);
                },
              ),
      ),
    );
  }

  Color _getBackgroundColor(int index) {
    switch (index) {
      case 0:
        return Colors.yellow[100] ?? Colors.yellow;
      case 1:
        return Colors.grey[100] ?? Colors.grey;
      case 2:
        return Colors.orange[100] ?? Colors.orange;
      default:
        return Colors.white;
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.yellow[700] ?? Colors.yellow;
      case 1:
        return Colors.grey[400] ?? Colors.grey;
      case 2:
        return Colors.orange[700] ?? Colors.orange;
      default:
        return Colors.blue[300] ?? Colors.blue;
    }
  }

  Widget _buildMedalIcon(int index) {
    IconData iconData;
    Color color;

    switch (index) {
      case 0:
        iconData = Icons.emoji_events;
        color = Colors.yellow[700] ?? Colors.yellow;
        break;
      case 1:
        iconData = Icons.emoji_events;
        color = Colors.grey[400] ?? Colors.grey;
        break;
      case 2:
        iconData = Icons.emoji_events;
        color = Colors.orange[700] ?? Colors.orange;
        break;
      default:
        iconData = Icons.emoji_events;
        color = Colors.blue;
    }

    return Icon(iconData, color: color, size: 30);
  }
} 