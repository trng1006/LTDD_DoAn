import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/topic_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/topic_provider.dart';

/// Màn hình "Chọn đề tài" cho trưởng nhóm, layout mobile theo mẫu.
class SelectTopicScreen extends StatefulWidget {
  final GroupModel group;
  const SelectTopicScreen({super.key, required this.group});

  @override
  State<SelectTopicScreen> createState() => _SelectTopicScreenState();
}

class _SelectTopicScreenState extends State<SelectTopicScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<TopicModel> _topics = [];
  String? _selectedTopicId;

  /// Nhóm đã có đề tài từ trước hay chưa (để đổi nhãn "Chọn"/"Đổi").
  bool get _hasTopic => widget.group.topicId != null && widget.group.topicId!.isNotEmpty;

  // Bảng màu + icon Lucide gán luân phiên cho từng đề tài để giống mẫu.
  static const List<_TopicStyle> _styles = [
    _TopicStyle(LucideIcons.shoppingCart, Color(0xFF2F6BFF)),
    _TopicStyle(LucideIcons.graduationCap, Color(0xFF2F6BFF)),
    _TopicStyle(LucideIcons.clipboardList, Color(0xFF2F6BFF)),
    _TopicStyle(LucideIcons.house, Color(0xFF2F6BFF)),
    _TopicStyle(LucideIcons.plane, Color(0xFF2F6BFF)),
    _TopicStyle(LucideIcons.chartColumnBig, Color(0xFF2F6BFF)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.group.topicId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTopics());
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final topics = await context
        .read<TopicProvider>()
        .getAvailableTopics(courseId: widget.group.courseId);
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedTopicId == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Validation số lượng thành viên tối thiểu trước khi gửi lên backend
    if (widget.group.memberIds.length < widget.group.minMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nhóm chưa đủ thành viên tối thiểu (${widget.group.memberIds.length}/${widget.group.minMembers}). Vui lòng bổ sung thành viên trước khi đăng ký.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await context.read<GroupProvider>().registerTopic(
          widget.group.id,
          _selectedTopicId!,
          user.id,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_hasTopic ? 'Đổi đề tài thành công!' : 'Đăng ký đề tài thành công!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseName = context
            .watch<CourseProvider>()
            .getCourseById(widget.group.courseId)
            ?.name ??
        'Chưa rõ môn học';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseCard(courseName),
                  const SizedBox(height: 24),
                  Text(
                    _hasTopic ? 'Đổi đề tài' : 'Chọn đề tài',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasTopic
                        ? 'Chọn đề tài khác để thay cho đề tài hiện tại'
                        : 'Chọn 1 đề tài phù hợp với nhóm của bạn',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildTopicList(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D6BF3), Color(0xFF2F8BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            _hasTopic ? 'Đổi đề tài' : 'Danh sách đề tài',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(String courseName) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.bookMarked, color: Color(0xFF2F6BFF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Môn học hiện tại',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Hiện chưa có đề tài nào còn trống cho môn này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_topics.length, (index) {
        final topic = _topics[index];
        final style = _styles[index % _styles.length];
        final bool selected = _selectedTopicId == topic.id;
        return _buildTopicCard(topic, style, selected);
      }),
    );
  }

  Widget _buildTopicCard(TopicModel topic, _TopicStyle style, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTopicId = topic.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildRadio(selected),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(selected),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF2F6BFF) : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2F6BFF),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(bool selected) {
    final Color bg = selected ? const Color(0xFFFDE8E8) : const Color(0xFFE9F8EF);
    final Color fg = selected ? const Color(0xFFE5484D) : const Color(0xFF22A65A);
    final String text = selected ? 'Đã chọn' : 'Còn trống';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool enabled = _selectedTopicId != null && !_isSubmitting;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: enabled ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6BFF),
                disabledBackgroundColor: const Color(0xFF2F6BFF).withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _hasTopic ? 'Đổi đề tài' : 'Tiếp tục',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.info, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Bạn chỉ có thể chọn 1 đề tài cho nhóm',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicStyle {
  final IconData icon;
  final Color color;
  const _TopicStyle(this.icon, this.color);
}
