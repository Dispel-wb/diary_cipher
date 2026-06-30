class DiaryEntry {
  final String date;      // YYYYMMDD
  final String cipherText; // 完整密文（含日期头）

  DiaryEntry({required this.date, required this.cipherText});

  /// 去掉日期头后的预览（前20字符）
  String get preview {
    String pure = cipherText.length > 9 ? cipherText.substring(9) : cipherText;
    return pure.length > 20 ? '${pure.substring(0, 20)}...' : pure;
  }
}