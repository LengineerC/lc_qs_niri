# 自用Quickshell配置
~~vide coding产物~~

## 1. 运行环境

### 必需组件

| 组件 | 用途 |
| --- | --- |
| Niri | Wayland 合成器、工作区/窗口同步、显示器控制和电源菜单注销 |
| Quickshell | 加载整个 QML Shell，并提供通知、托盘、MPRIS、PipeWire、UPower、PAM、Bluetooth 和 IPC 接口 |
| Qt 6 QML | `QtQuick`、Controls、Layouts、Effects、Shapes、Dialogs 等界面模块 |
| qml-niri | 提供 `import Niri`，同步 Niri 工作区、窗口和 Overview 状态 |
| D-Bus | 通知、托盘、蓝牙、MPRIS、UPower 和电源策略等服务的通信基础 |
| Nerd Fonts | 正确显示 Bar、按钮和天气等模块中的 Nerd Font 图标 |

需要保证 Quickshell 运行于 Niri 会话中，并且环境变量 `NIRI_SOCKET`
可用。可以这样检查：

```bash
test -n "$NIRI_SOCKET" && printf '%s\n' "$NIRI_SOCKET"
qs --version
niri --version
```

qml-niri 必须位于 Qt 6 的 QML 导入路径中，例如：

```text
/usr/lib/qt6/qml/Niri/qmldir
```

若启动时出现 `module "Niri" is not installed`，请按照
[qml-niri](https://github.com/imiric/qml-niri) 的安装说明安装插件，或者设置
`QML_IMPORT_PATH` 指向包含 `Niri` 目录的上级目录。

### 外部命令与服务

| 命令或服务 | 对应功能 | 缺失时的影响 |
| --- | --- | --- |
| `niri` | 显示器调整、注销 | 显示器管理和注销不可用 |
| `python3` | 剪切板历史、壁纸缩略图脚本 | 剪切板历史和壁纸总览不可用 |
| `wl-copy`、`wl-paste` | 监听、恢复、清空剪切板 | 剪切板模块不可用 |
| `magick` | 生成壁纸总览缩略图 | 原壁纸仍可显示，但总览没有缩略图 |
| `matugen` | 从壁纸或颜色生成 Material 3 主题 | 自动主题取色不可用 |
| `nmcli`、NetworkManager | Wi-Fi 扫描、开关和连接 | 网络面板中的 Wi-Fi 功能不可用 |
| BlueZ | 蓝牙扫描、配对、连接和开关 | 蓝牙功能不可用 |
| PipeWire、WirePlumber | 音量、麦克风和音频设备选择 | 音频模块不可用 |
| UPower | 电池、电源状态和健康信息 | 电池模块无法读取电源信息 |
| power-profiles-daemon | 省电、平衡、性能模式 | 电池面板无法切换性能策略 |
| `sensors` | CPU 温度 | 系统监视器仍可用，但温度显示为不可用 |
| `ps`、`kill` | 进程列表和结束进程 | 系统监视器的进程管理不可用 |
| `cava` | 媒体面板波形可视化 | 播放控制仍可用，但没有动态波形 |
| `curl` | Open-Meteo 天气与地点查询 | 天气模块无法刷新 |
| `fastfetch` | 获取系统信息 | 侧边栏和锁屏无法显示小组件 |
| PAM | 锁屏密码验证 | 锁屏无法验证系统密码 |
| `systemctl` | 关机、重启、挂起 | 相应电源操作不可用 |
| `id`、`getent` | 用户名、UID 和用户资料 | 用户信息与用户进程分类不完整 |
| AccountsService | 可选的系统头像来源 | 可以继续使用设置中的自定义头像 |

天气功能还需要访问以下 HTTPS 服务：

```text
https://api.open-meteo.com
https://geocoding-api.open-meteo.com
```

### 字体

默认界面字体和图标字体分别为：

```text
JetBrainsMono Nerd Font
Symbols Nerd Font
```

缺少图标字体时，界面会出现方框或空白字符。界面正文字体可以在设置窗口中
修改，但 `Symbols Nerd Font` 仍建议安装。

### Caelestia Blob 原生插件

> 模块已经存在，不需要重新构建，如需自己构建需自行修改路径并下拉Caelestia仓库

`Caelestia/Blobs/` 已包含 x86-64 原生插件，因此普通 x86-64 Arch 环境通常
不需要额外构建。若架构或 Qt ABI 不一致，需要准备：

```text
cmake、ninja、C++20 编译器、Qt 6 Core/Qml/Quick/ShaderTools
```

然后依据 `native/caelestia-blobs/CMakeLists.txt` 重新编译。该构建文件还会
读取工作区中的 `caelestiashell/plugin/src/Caelestia/Blobs` 源码。

## 2. 独立界面

Launcher IPC 会在当前显示器打开全屏 layer-shell 启动台，支持模糊壁纸、
应用网格、搜索和键盘选择；Bar 左侧系统图标仍打开原来的小型面板。
剪切板和系统监视器仍是由 Niri 管理的普通独立窗口。

### `launcher`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call launcher open` | 在当前显示器打开全屏启动台 |
| `qs ipc call launcher close` | 关闭全屏启动台 |
| `qs ipc call launcher toggle` | 切换全屏启动台显示状态 |
| `qs ipc call launcher visible` | 返回当前是否显示 |

### `clipboard`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call clipboard open` | 打开剪切板历史 |
| `qs ipc call clipboard close` | 关闭剪切板历史 |
| `qs ipc call clipboard toggle` | 切换剪切板窗口显示状态 |
| `qs ipc call clipboard visible` | 返回当前是否显示 |

### `systemMonitor`

目标名称区分大小写。

| 命令 | 说明 |
| --- | --- |
| `qs ipc call systemMonitor open` | 打开系统监视器 |
| `qs ipc call systemMonitor close` | 关闭系统监视器 |
| `qs ipc call systemMonitor toggle` | 切换系统监视器显示状态 |
| `qs ipc call systemMonitor visible` | 返回当前是否显示 |

### `settingsWindow`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call settingsWindow open` | 打开设置窗口 |
| `qs ipc call settingsWindow close` | 关闭设置窗口 |
| `qs ipc call settingsWindow toggle` | 切换设置窗口显示状态 |
| `qs ipc call settingsWindow visible` | 返回当前是否显示 |
| `qs ipc call settingsWindow quickSettings` | 打开快速设置页面 |
| `qs ipc call settingsWindow system` | 打开网络、蓝牙和音频页面 |
| `qs ipc call settingsWindow style` | 打开 Style 页面 |
| `qs ipc call settingsWindow displays` | 打开显示器页面 |

## 5. 锁屏

### `lock`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call lock open` | 锁定会话 |
| `qs ipc call lock isLocked` | 返回当前是否处于锁屏状态 |

## 6. 媒体控制

### `media`

命令作用于当前活动的 MPRIS 播放器。

| 命令 | 说明 |
| --- | --- |
| `qs ipc call media playPause` | 播放或暂停 |
| `qs ipc call media previous` | 上一首 |
| `qs ipc call media next` | 下一首 |
| `qs ipc call media pauseAll` | 暂停所有支持暂停的播放器 |

## 7. 通知

### `notifications`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call notifications open` | 在当前聚焦的显示器上打开通知面板 |
| `qs ipc call notifications close` | 关闭通知面板 |
| `qs ipc call notifications toggle` | 在当前聚焦的显示器上切换通知面板 |
| `qs ipc call notifications visible` | 返回通知面板是否显示 |
| `qs ipc call notifications status` | 返回未读数、弹出数、历史数和勿扰状态 JSON |
| `qs ipc call notifications markAllRead` | 将所有通知标记为已读 |
| `qs ipc call notifications clearHistory` | 清空通知历史 |
| `qs ipc call notifications setDoNotDisturb true` | 开启勿扰模式 |
| `qs ipc call notifications setDoNotDisturb false` | 关闭勿扰模式 |

Quickshell 会注册 `org.freedesktop.Notifications`。同时运行其他通知守护进程
可能导致注册失败，需要保证同一会话中只有一个通知服务端。

## 8. 壁纸

### `wallpaper`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call wallpaper set "/path/image.jpg"` | 设置指定壁纸 |
| `qs ipc call wallpaper next` | 下一张壁纸 |
| `qs ipc call wallpaper previous` | 上一张壁纸 |
| `qs ipc call wallpaper random` | 随机壁纸 |
| `qs ipc call wallpaper setDirectory "/path/wallpapers"` | 修改壁纸目录 |
| `qs ipc call wallpaper status` | 返回当前路径、目录、数量和自动取色状态 JSON |

壁纸总览扫描以下扩展名：

```text
jpg、jpeg、png、webp
```

## 9. 主题

### `theme`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call theme toggle` | 切换深色/浅色模式 |
| `qs ipc call theme setMode dark` | 切换为深色模式 |
| `qs ipc call theme setMode light` | 切换为浅色模式 |
| `qs ipc call theme setAccent "#89b4fa"` | 从指定十六进制颜色生成主题 |
| `qs ipc call theme fromWallpaper "/path/image.jpg"` | 从指定壁纸生成主题并设置壁纸 |
| `qs ipc call theme setScheme scheme-tonal-spot` | 修改 Matugen 配色方案 |
| `qs ipc call theme status` | 返回模式、scheme、壁纸和生成状态 JSON |

`setScheme` 支持：

```text
scheme-content
scheme-expressive
scheme-fidelity
scheme-fruit-salad
scheme-monochrome
scheme-neutral
scheme-rainbow
scheme-tonal-spot
scheme-vibrant
```

## 10. 通用设置

### `settings`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call settings status` | 返回当前主要设置的 JSON |
| `qs ipc call settings setLanguage zh_CN` | 切换为简体中文 |
| `qs ipc call settings setLanguage en_US` | 切换为英语 |
| `qs ipc call settings setTimeFormat "HH:mm:ss"` | 设置 Qt 时间格式 |
| `qs ipc call settings setDateFormat "yyyy-MM-dd ddd"` | 设置 Qt 日期格式 |
| `qs ipc call settings setWallpaperFillMode PreserveAspectCrop` | 设置壁纸显示形式 |
| `qs ipc call settings reset` | 将全部 Shell 设置恢复默认值 |

`setWallpaperFillMode` 支持：

```text
Stretch
PreserveAspectFit
PreserveAspectCrop
Tile
TileVertically
TileHorizontally
Pad
```

注意：`settings reset` 会立即恢复所有设置默认值，包括语言、字体、缩放、
壁纸选项、天气位置和剪切板限制。

## 11. 显示器持久化

### `outputs`

| 命令 | 说明 |
| --- | --- |
| `qs ipc call outputs saveCurrent` | 将当前显示器状态写入持久化文件 |
| `qs ipc call outputs configPath` | 返回生成的 Niri `outputs.kdl` 路径 |
| `qs ipc call outputs statePath` | 返回内部显示器状态 JSON 路径 |
| `qs ipc call outputs persistentCount` | 返回已保存的显示器记录数量 |

显示器分辨率、刷新率、缩放、方向、位置、VRR 和启用状态的具体修改在设置
窗口中完成；IPC 当前只暴露保存与状态查询。

## 12. 侧边栏

### `leftsidebar`
| 命令 | 说明 |
| --- | --- |
| `qs ipc call leftsidebar open` | 打开左侧侧边栏 |
| `qs ipc call leftsidebar close` | 关闭左侧侧边栏 |
| `qs ipc call leftsidebar toggle` | 切换左侧侧边栏显示状态 |
| `qs ipc call leftsidebar isShown` | 返回左侧侧边栏的显示状态 |
