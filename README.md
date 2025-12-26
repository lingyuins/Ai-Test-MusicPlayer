# 本地音乐播放器

基于Python和Flutter开发的跨平台本地音乐播放器。

## 技术栈

- **后端**：Python 3.13 + FastAPI + Mutagen
- **前端**：Flutter 3.10.4

## 功能特性

### 文件识别与导入
- 自动扫描设备本地存储的音频文件（支持MP3、WAV、FLAC、AAC、OGG等）
- 手动添加/移除指定文件夹或文件，支持批量导入

### 基础播放控制
- 播放/暂停、上一曲/下一曲、进度条拖拽调整播放位置
- 顺序播放、单曲循环、随机播放三种播放模式切换

### 音量与音效调节
- 音量增减控制，支持音量渐变
- 基础音效（均衡器预设：摇滚、流行、古典、民谣等）

### 歌曲分类与检索
- 按歌手、专辑、曲风、文件夹自动分类展示
- 关键词搜索（支持搜索歌曲名、歌手名、专辑名）

### 自定义歌单
- 创建/删除/重命名歌单
- 歌曲添加到歌单、从歌单移除，支持拖拽排序

### 播放界面与交互
- 简洁播放页（显示歌曲封面、标题、歌手、专辑、播放进度）
- 后台播放（切换其他应用时音乐不中断）

### 睡眠模式
- 设置定时关闭功能（如10分钟/30分钟/1小时后自动停止播放）

### 歌词显示
- 支持LRC歌词文件同步显示

### 界面设置
- 切换深色/浅色主题
- 调整列表显示样式（列表视图/网格视图）

## 运行说明

### 1. 启动后端服务

```bash
cd backend
pip install -r requirements.txt
python main.py
```

后端服务将运行在 http://0.0.0.0:8000

### 2. 启动前端应用

#### 2.1 安装依赖

```bash
flutter pub get
```

#### 2.2 运行应用

```bash
# 在Windows上运行（需要Visual Studio工具链）
flutter run -d windows

# 在macOS上运行
flutter run -d macos

# 在Linux上运行
flutter run -d linux

# 在Web浏览器中运行
flutter run -d web
```

## 常见问题

### Windows上运行报错："Unable to find suitable Visual Studio toolchain"

**原因**：在Windows上开发Flutter Windows应用需要安装Visual Studio 2022或更高版本，并安装"使用C++的桌面开发"工作负载。

**解决方案**：
1. 安装Visual Studio 2022或更高版本
2. 安装时确保勾选"使用C++的桌面开发"工作负载
3. 安装完成后重启计算机
4. 运行`flutter doctor`验证安装

### Windows上运行报错："Building with plugins requires symlink support"

**原因**：Windows 10/11默认禁用了符号链接支持，而Flutter插件需要此功能。

**解决方案**：
1. 打开"设置" > "更新和安全" > "开发者选项"
2. 启用"开发人员模式"
3. 重启计算机

## 项目结构

```
music_player/
├── backend/              # Python后端服务
│   ├── main.py           # FastAPI主入口
│   └── requirements.txt  # Python依赖
├── lib/                  # Flutter前端代码
│   ├── main.dart         # Flutter主入口
│   ├── models/           # 数据模型
│   ├── providers/        # 状态管理
│   └── screens/          # 界面组件
├── pubspec.yaml          # Flutter依赖配置
└── README.md             # 项目说明
```

## 开发说明

### 后端API

后端提供RESTful API接口，主要包括：
- `/api/config` - 获取/更新配置
- `/api/scan` - 扫描音乐文件
- `/api/add-folder` - 添加音乐文件夹
- `/api/music-files` - 获取音乐文件列表
- `/api/playlists` - 播放列表管理
- `/api/search` - 搜索歌曲

### 前端状态管理

使用Provider进行状态管理，主要状态包括：
- 音乐文件列表
- 当前播放歌曲
- 播放状态
- 音量与音效设置
- 主题与界面配置

## 许可证

MIT License
