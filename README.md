# 密日记 · Cipher Diary

跨平台本地日记加密工具，安全、离线、无需网络。  
使用 AES-256-CBC + PBKDF2 密钥派生，守护你的每一份秘密。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Static Badge](https://img.shields.io/badge/Windows_Release.zip-Download-blue)]()


---

## ✨ 功能特性

- 🔐 **军事级加密**：AES-256-CBC 加密，PBKDF2 密钥派生，每篇日记独立随机 IV。
- 📅 **日期绑定**：密文与日记日期绑定，配合口令生成唯一密钥。
- 💻 **多平台支持**：同一套代码运行于 **Windows 桌面**、**Web 浏览器**，Linux 桌面可额外构建。
- 🖱️ **右键菜单管理**：桌面端日记列表支持右键查看口令提示、删除日记。
- 💡 **口令提示**：加密时可填写提示词，遗忘口令时帮助回忆（不暴露真实口令）。
- 🎨 **Material 3 界面**：圆润卡片、动感切换、滚轮日期选择器，美观直观。
- 📁 **本地文件存储**：桌面端保存为 `.txt` 文件，Web 端加密后下载或上传解密，纯离线操作。
- 🌐 **全中文支持**：UTF-8 编码，完美处理任意语言字符。

---

## 🔒 加密原理

1. **密钥派生**：用户口令 + 日期作为盐，经 PBKDF2（HMAC-SHA256，10,000 轮迭代）生成 256 位 AES 密钥。
2. **加密**：使用 AES-256-CBC 模式，随机 128 位 IV，对明文进行加密。
3. **密文格式**：`日期|Base64(IV + 密文)`，解码后可分离日期、IV 和密文。
4. **安全性**：每个日记不同 IV，即使相同明文亦产生不同密文；口令强度无限制，暴力破解几乎不可能。

---

## 📦 技术栈

- **框架**：Flutter 3.x (Dart)
- **加密库**：pointycastle (AES, PBKDF2, HMAC-SHA256)
- **文件操作**：path_provider (桌面路径) / universal_html (Web 下载)
- **文件选择**：file_picker (Web 上传)
- **图标字体**：Material Icons (内建于 Flutter)

---

## 🚀 快速开始

### 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.0
- **桌面版**：Visual Studio 2022（包含“使用 C++ 的桌面开发”工作负载）
- **Web 版**：Chrome 浏览器

### 获取项目

```bash
git clone https://github.com/yourname/diary_cipher.git
cd diary_cipher
flutter pub get
运行
bash
# Windows 桌面端
flutter run -d windows

# Web 端 (浏览器)
flutter run -d chrome
打包发布
bash
# Windows 可执行程序
flutter build windows --release
# 输出在 build/windows/runner/Release/

# Web 静态站点
flutter build web --release
# 输出在 build/web/
Linux 打包需在 Linux 环境（或 WSL）下运行 flutter build linux --release。
```

## 📂 项目结构

```md
diary_cipher/
├── pubspec.yaml # 依赖配置
├── README.md
└── lib/
├── main.dart # 应用入口
├── models/
│ └── diary_entry.dart # 日记数据模型
├── services/
│ ├── encryption_service.dart # 加解密核心
│ └── file_service.dart # 文件存取抽象
├── screens/
│ ├── home_screen.dart # 首页列表
│ └── editor_screen.dart # 加解密编辑页
└── widgets/
│└── date_picker.dart # 滚轮日期选择器
└── diary_cipher.zip #Windows应用程序（解压可用）
```
## 📝 使用指南

1. **新建日记**  
   点击右下角 + 按钮 → 选择日期 → 输入加密口令（越复杂越安全）→ 可选填“口令提示”→ 输入日记内容 → 点击“加密并保存”。

2. **查看日记**  
   桌面端列表左键点击条目；输入正确口令 → 点击“解密查看”。

3. **管理日记**  
   在日记条目上 **右键**，可选择：
   - **查看口令提示**：帮助回忆口令
   - **删除日记**：彻底删除日记与提示文件

4. **Web 端使用**  
   加密后自动下载 `.txt` 文件；解密时粘贴密文或上传该文件。

---

## ⚠️ 重要提醒

- **口令是唯一凭证**：遗忘口令将导致日记永久无法解密，请务必使用密码管理器或安全记录。
- **提示词不包含真实口令**：提示仅作为记忆辅助，不应直接写出口令。
- **本地备份**：建议定期备份 `文档/diary_cipher/` 文件夹到安全位置。

---

## 🧩 依赖说明

| 包名 | 用途 |
|------|------|
| `crypto` | SHA-256 哈希 |
| `path_provider` | 桌面端文档路径 |
| `file_picker` | Web 端文件上传 |
| `universal_html` | Web 端触发下载 |
| `pointycastle` | AES、PBKDF2、HMAC 密码学实现 |
| `intl` | 日期格式化（备用） |

所有依赖均无网络请求，完全离线可用。

---

## 📄 开源协议

本项目采用 [MIT 许可证](LICENSE)。  
你可以自由使用、修改和分发，但请保留原作者声明。

---

**愿你笔下的秘密，永远安全。** 🔏