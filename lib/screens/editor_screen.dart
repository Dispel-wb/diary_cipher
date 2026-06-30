import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../widgets/date_picker.dart';
import '../services/encryption_service.dart';
import '../services/file_service.dart';

class EditorScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? existingCipher;

  const EditorScreen({this.initialDate, this.existingCipher, super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late DateTime _selectedDate;
  final _passwordController = TextEditingController();
  final _hintController = TextEditingController();   // 新增：口令提示
  final _textController = TextEditingController();
  bool _isEncryptMode = true;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.existingCipher != null) {
      _isEncryptMode = false;
      _textController.text = widget.existingCipher!;
    }
  }

  String _formatDate() =>
      '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _process() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showSnack('请输入加密口令');
      return;
    }

    final dateStr = _formatDate();

    try {
      if (_isEncryptMode) {
        final plain = _textController.text;
        if (plain.isEmpty) {
          _showSnack('日记内容不能为空');
          return;
        }
        final cipher = EncryptionService.encrypt(plain, dateStr, password);
        await FileService.save(cipher, dateStr);
        // 保存口令提示（仅桌面端有效）
        final hint = _hintController.text.trim();
        if (hint.isNotEmpty) {
          await FileService.saveHint(dateStr, hint);
        }
        setState(() => _resultText = cipher);
        _showSnack(kIsWeb ? '加密成功，已触发下载' : '加密并保存成功');
      } else {
        final cipher = _textController.text;
        if (cipher.isEmpty) {
          _showSnack('请先输入密文或上传文件');
          return;
        }
        final plain = EncryptionService.decrypt(cipher, password);
        setState(() => _resultText = plain);
        _showSnack('解密成功');
      }
    } catch (e) {
      _showSnack('操作失败: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _textController.text = String.fromCharCodes(result.files.single.bytes!);
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEncryptMode ? '写日记' : '读日记'),
        centerTitle: true,
        elevation: 1,
        actions: [
          if (widget.existingCipher == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(_isEncryptMode ? Icons.lock_open : Icons.lock),
                onPressed: () {
                  setState(() {
                    _isEncryptMode = !_isEncryptMode;
                    _resultText = null;
                  });
                },
                tooltip: '切换到${_isEncryptMode ? "解密" : "加密"}',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日期卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: DatePicker(
                  initialDate: _selectedDate,
                  onDateChanged: (dt) => setState(() => _selectedDate = dt),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 口令卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '口令',
                        hintText: '输入你的私人加密口令（任意字符）',
                        helperText: '✨ 口令越复杂越安全，请务必牢记或使用密码管理器',
                        prefixIcon: Icon(Icons.vpn_key, color: colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_isEncryptMode) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _hintController,
                        decoration: InputDecoration(
                          labelText: '口令提示（可选）',
                          hintText: '例如：常用密码+生日、宠物名字',
                          helperText: '提示词将单独保存，忘记口令时可查看',
                          prefixIcon: Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 内容卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: _isEncryptMode ? 10 : 8,
                      decoration: InputDecoration(
                        labelText: _isEncryptMode ? '日记内容' : '密文',
                        hintText: _isEncryptMode ? '今天发生了……' : '粘贴密文或上传文件',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (!_isEncryptMode && kIsWeb) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('上传密文文件 (.txt)'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 操作按钮
            FilledButton.icon(
              onPressed: _process,
              icon: Icon(_isEncryptMode ? Icons.lock : Icons.lock_open),
              label: Text(_isEncryptMode ? '加密并保存' : '解密查看'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            // 输出结果动画
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _resultText != null
                  ? Card(
                      key: ValueKey(_resultText),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEncryptMode ? '🔐 加密结果' : '📄 解密结果',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SelectableText(
                                _resultText!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _hintController.dispose();
    _textController.dispose();
    super.dispose();
  }
}