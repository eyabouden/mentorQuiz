import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarOption {
  final String id;
  final dynamic content; // Can be a String (emoji), IconData, or asset path
  final String type; // 'emoji', 'svg', or 'image'
  
  AvatarOption({required this.id, required this.content, required this.type});
}

class AvatarSelectionModal extends StatefulWidget {
  final Function(AvatarOption) onSelect;
  final AvatarOption? initialSelection;
  final Color selectedColor;
  
  const AvatarSelectionModal({
    Key? key, 
    required this.onSelect,
    this.initialSelection,
    required this.selectedColor,
  }) : super(key: key);

  @override
  _AvatarSelectionModalState createState() => _AvatarSelectionModalState();
}

class _AvatarSelectionModalState extends State<AvatarSelectionModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AvatarOption _selectedAvatar;
  
  // All our avatar options organized by category
  final List<AvatarOption> _emojiOptions = [
    AvatarOption(id: 'smile', content: '😀', type: 'emoji'),
    AvatarOption(id: 'cool', content: '😎', type: 'emoji'),
    AvatarOption(id: 'nerd', content: '🤓', type: 'emoji'),
    AvatarOption(id: 'laugh', content: '😂', type: 'emoji'),
    AvatarOption(id: 'heart', content: '😍', type: 'emoji'),
    AvatarOption(id: 'surprise', content: '😮', type: 'emoji'),
    AvatarOption(id: 'think', content: '🤔', type: 'emoji'),
    AvatarOption(id: 'wink', content: '😉', type: 'emoji'),
  ];
  
  final List<AvatarOption> _animalOptions = [
    AvatarOption(id: 'fox', content: '🦊', type: 'emoji'),
    AvatarOption(id: 'cat', content: '🐱', type: 'emoji'),
    AvatarOption(id: 'dog', content: '🐶', type: 'emoji'),
    AvatarOption(id: 'lion', content: '🦁', type: 'emoji'),
    AvatarOption(id: 'tiger', content: '🐯', type: 'emoji'),
    AvatarOption(id: 'panda', content: '🐼', type: 'emoji'),
    AvatarOption(id: 'koala', content: '🐨', type: 'emoji'),
    AvatarOption(id: 'monkey', content: '🐵', type: 'emoji'),
  ];
  
  final List<AvatarOption> _customOptions = [
    // For SVG avatars, you'll need to add these assets to your project
    // and update pubspec.yaml with the appropriate asset paths
    AvatarOption(id: 'avatar1', content: 'assets/avatars/avatar1.svg', type: 'svg'),
    AvatarOption(id: 'avatar2', content: 'assets/avatars/avatar2.svg', type: 'svg'),
    AvatarOption(id: 'avatar3', content: 'assets/avatars/avatar3.svg', type: 'svg'),
    AvatarOption(id: 'avatar4', content: 'assets/avatars/avatar4.svg', type: 'svg'),
    AvatarOption(id: 'avatar5', content: 'assets/avatars/avatar5.svg', type: 'svg'),
    AvatarOption(id: 'avatar6', content: 'assets/avatars/avatar6.svg', type: 'svg'),
    AvatarOption(id: 'avatar7', content: 'assets/avatars/avatar7.svg', type: 'svg'),
    AvatarOption(id: 'avatar8', content: 'assets/avatars/avatar8.svg', type: 'svg'),
  ];
  
  final List<AvatarOption> _fantasyOptions = [
    AvatarOption(id: 'unicorn', content: '🦄', type: 'emoji'),
    AvatarOption(id: 'ghost', content: '👻', type: 'emoji'),
    AvatarOption(id: 'robot', content: '🤖', type: 'emoji'),
    AvatarOption(id: 'alien', content: '👽', type: 'emoji'),
    AvatarOption(id: 'superhero', content: '🦸', type: 'emoji'),
    AvatarOption(id: 'ninja', content: '🥷', type: 'emoji'),
    AvatarOption(id: 'fairy', content: '🧚', type: 'emoji'),
    AvatarOption(id: 'mage', content: '🧙', type: 'emoji'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial selection or default to first emoji
    if (widget.initialSelection != null) {
      _selectedAvatar = widget.initialSelection!;
    } else {
      _selectedAvatar = _emojiOptions.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAvatarGrid(List<AvatarOption> options) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _selectedAvatar.id == option.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatar = option;
            });
            widget.onSelect(option);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? widget.selectedColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: widget.selectedColor, width: 3)
                  : Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: widget.selectedColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )]
                  : null,
            ),
            child: Center(
              child: _buildAvatarContent(option),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAvatarContent(AvatarOption option) {
    switch (option.type) {
      case 'emoji':
        return Text(
          option.content,
          style: TextStyle(fontSize: 36),
        );
      case 'svg':
        try {
          return SvgPicture.asset(
            option.content,
            width: 40,
            height: 40,
          );
        } catch (e) {
          // Fallback if SVG can't be loaded
          return Icon(Icons.person, size: 36, color: Colors.grey);
        }
      case 'image':
        return Image.asset(
          option.content,
          width: 40,
          height: 40,
        );
      default:
        return Icon(Icons.person, size: 36);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                'Choisissez votre avatar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selectedColor.withOpacity(0.2),
                    border: Border.all(color: widget.selectedColor, width: 3),
                  ),
                  child: Center(
                    child: _buildAvatarContent(_selectedAvatar),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: Icon(Icons.emoji_emotions), text: 'Émojis'),
                Tab(icon: Icon(Icons.pets), text: 'Animaux'),
                Tab(icon: Icon(Icons.person), text: 'Avatars'),
                Tab(icon: Icon(Icons.auto_awesome), text: 'Fantasy'),
              ],
              labelColor: widget.selectedColor,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvatarGrid(_emojiOptions),
                  _buildAvatarGrid(_animalOptions),
                  _buildAvatarGrid(_customOptions),
                  _buildAvatarGrid(_fantasyOptions),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSelect(_selectedAvatar);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.selectedColor,
                    ),
                    child: Text('Confirmer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}