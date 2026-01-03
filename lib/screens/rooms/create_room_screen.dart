import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/room_model.dart';
import '../../providers/room_provider.dart';

// Clean Modern Theme
class _Theme {
  // Core colors
  static const Color background = Color(0xFF000000);
  static const Color card = Color(0xFF121212);
  static const Color cardElevated = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2D2D2D);

  // Text colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGray = Color(0xFFAAAAAA);
  static const Color textDark = Color(0xFF777777);

  // Accent colors
  static const Color primary = Color(0xFF00D26A);  // Bright green
  static const Color green = Color(0xFF00D26A);
}

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  RoomType _selectedType = RoomType.audio;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    final roomProvider = context.read<RoomProvider>();

    final room = await roomProvider.createRoom(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
    );

    if (room != null && mounted) {
      Navigator.pushReplacementNamed(
        context,
        _selectedType == RoomType.video ? RouteNames.videoCall : RouteNames.room,
        arguments: {'roomId': room.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Theme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 28),
                    _buildFormCard(),
                    const SizedBox(height: 28),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: BoxDecoration(
        color: _Theme.card,
        border: Border(bottom: BorderSide(color: _Theme.border, width: 1)),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Room',
                  style: GoogleFonts.plusJakartaSans(
                    color: _Theme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Start a live conversation',
                  style: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _Theme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedType == RoomType.audio ? Icons.mic_rounded : Icons.videocam_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.category_rounded, text: 'Room Type'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                icon: Icons.mic_rounded,
                title: 'Audio',
                subtitle: 'Voice only',
                isSelected: _selectedType == RoomType.audio,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = RoomType.audio);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeCard(
                icon: Icons.videocam_rounded,
                title: 'Video',
                subtitle: 'Face to face',
                isSelected: _selectedType == RoomType.video,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = RoomType.video);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _SectionLabel(icon: Icons.edit_rounded, text: 'Room Title', required: true),
          const SizedBox(height: 12),
          _InputField(
            controller: _titleController,
            hint: 'What\'s this room about?',
            maxLength: AppConstants.maxRoomTitleLength,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a room title';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Description
          _SectionLabel(icon: Icons.notes_rounded, text: 'Description'),
          const SizedBox(height: 12),
          _InputField(
            controller: _descriptionController,
            hint: 'Add more details (optional)',
            maxLines: 3,
            maxLength: AppConstants.maxRoomDescriptionLength,
          ),
          const SizedBox(height: 20),
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Theme.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _Theme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, size: 18, color: _Theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public Room',
                        style: GoogleFonts.plusJakartaSans(
                          color: _Theme.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Anyone can join',
                        style: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _Theme.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: _Theme.green),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: GoogleFonts.plusJakartaSans(
                          color: _Theme.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, _) {
        return _PrimaryButton(
          text: 'Start Room',
          icon: _selectedType == RoomType.audio ? Icons.mic_rounded : Icons.videocam_rounded,
          isLoading: roomProvider.isLoading,
          onTap: _createRoom,
        );
      },
    );
  }
}

// ==================== WIDGETS ====================

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _Theme.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _Theme.textLight, size: 22),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool required;

  const _SectionLabel({required this.icon, required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _Theme.textDark),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: _Theme.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.plusJakartaSans(color: _Theme.primary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _TypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? _Theme.primary.withAlpha(15) : _Theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected ? _Theme.primary : _Theme.border,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.isSelected ? _Theme.primary : _Theme.cardElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.isSelected ? Colors.white : _Theme.textGray,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.plusJakartaSans(
                  color: widget.isSelected ? _Theme.textWhite : _Theme.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: widget.isSelected ? _Theme.textGray : _Theme.textDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.isSelected ? _Theme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? _Theme.primary : _Theme.border,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Theme.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Theme.border),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.plusJakartaSans(
          color: _Theme.textWhite,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: GoogleFonts.plusJakartaSans(color: _Theme.textDark, fontSize: 11),
        ),
        validator: validator,
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: widget.isLoading ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _Theme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.text,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
