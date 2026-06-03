# 茶歇 Chaxie 🍵

一个待在 macOS 菜单栏里的极简番茄钟，不占 Dock。专注结束自动进入茶歇（休息），茶歇结束自动回到专注，切换时只弹一条静音的系统通知（右上角横幅，不出声）。

菜单栏专注时显示 `🍃 25:00`，茶歇时显示 `🍵 05:00`。

## 安装（一行命令）

打开「终端」，粘贴运行：

```bash
curl -fsSL https://github.com/leoian611/chaxie-pomodoro/releases/latest/download/Chaxie.zip -o /tmp/chaxie.zip \
  && ditto -x -k /tmp/chaxie.zip /Applications \
  && xattr -dr com.apple.quarantine /Applications/Chaxie.app \
  && open /Applications/Chaxie.app
```

它会自动下载、解压到「应用程序」、去掉隔离属性（绕过 Gatekeeper），然后打开。首次启动会请求通知权限，点允许即可。之后在启动台或应用程序文件夹里双击就能用。

## 用法

菜单栏会显示当前阶段和剩余时间。点开后：

- 开始 / 暂停（⌘S）
- 跳到下一阶段（⌘N）
- 重置当前阶段（⌘R）
- 专注时长 / 休息时长：预设 + 自定义（1–180 分钟），你的设置会被记住
- 退出（⌘Q）

想让它开机自启：系统设置 → 通用 → 登录项 → 加号选中「茶歇」。

## 从源码构建

需要 Xcode Command Line Tools（`xcode-select --install`）。

```bash
git clone https://github.com/leoian611/chaxie-pomodoro.git
cd chaxie-pomodoro
bash build.sh
open Chaxie.app          # 或 cp -r Chaxie.app /Applications
```

## 图标（可选）

把一张 `AppIcon.icns` 放到项目根目录，`build.sh` 会自动拷进 app 并写入 `Info.plist`。没有也能正常用，只是用系统默认图标（菜单栏始终是 🍃 / 🍵 文字图标，不受影响）。

## 说明

应用是本地 ad-hoc 签名、未做公证，所以下载后需要去掉隔离属性（安装命令里的 `xattr` 那步已经帮你做了）。如果你是手动下载解压的，首次打开被 Gatekeeper 拦，可以右键点 app 选「打开」，或运行 `xattr -dr com.apple.quarantine /Applications/Chaxie.app`。
