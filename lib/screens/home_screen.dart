import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/file_service.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _dates = [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadDates();
  }

  Future<void> _loadDates() async {
    final dates = await FileService.listDates();
    setState(() => _dates = dates);
  }

  Future<void> _openDiary(String dateStr) async {
    final cipher = await FileService.read(dateStr);
    if (cipher != null) {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(
            initialDate: DateTime(year, month, day),
            existingCipher: cipher,
          ),
        ),
      );
      _loadDates();
    }
  }

  /// 右键菜单
  Future<void> _showContextMenu(
      BuildContext context, Offset position, String dateStr) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'hint',
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('查看口令提示'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('删除日记', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
    if (result == 'delete') {
      await _deleteDiary(dateStr);
    } else if (result == 'hint') {
      await _viewHint(dateStr);
    }
  }

  Future<void> _viewHint(String dateStr) async {
    final hint = await FileService.readHint(dateStr);
    if (!mounted) return;
    if (hint == null || hint.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('无提示'),
          content: const Text('这篇日记没有设置口令提示。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'))
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('口令提示'),
          content: SelectableText(hint),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'))
          ],
        ),
      );
    }
  }

  Future<void> _deleteDiary(String dateStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除日记'),
        content: Text('确定删除 $dateStr 的日记吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await FileService.delete(dateStr); // 同时会删除提示文件
      _loadDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('密日记'),
        centerTitle: true,
        elevation: 2,
      ),
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '欢迎使用密日记 Web 版\n点击右下角开始加密日记',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : _dates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book,
                          size: 64,
                          color:
                              theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('还没有日记',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('点击下方按钮开始记录秘密',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    final display =
                        '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6)}';
                    return GestureDetector(
                      onSecondaryTapDown: (details) {
                        _showContextMenu(
                            context, details.globalPosition, date);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(Icons.lock,
                                color:
                                    theme.colorScheme.onPrimaryContainer),
                          ),
                          title: Text(display),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openDiary(date),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditorScreen(initialDate: null),
            ),
          ).then((_) {
            if (!kIsWeb) _loadDates();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('新日记'),
      ),
    );
  }
}