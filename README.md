# 茶歇 Chaxie 🍵

一个待在 macOS 菜单栏里的番茄钟，不占 Dock。专注结束自动进入茶歇（休息），茶歇结束自动回到专注，切换时只弹一条静音的系统通知（右上角横幅，不出声）。

菜单栏专注时显示 `🍃 25:00`，茶歇时显示 `🍵 05:00`。

## 一行命令安装（给别人用）

> 需要先发过一次 Release（见下文）。把 `<USER>` 换成你的 GitHub 用户名。

```bash
curl -fsSL https://github.com/<USER>/chaxie/releases/latest/download/Chaxie.zip -o /tmp/chaxie.zip \
  && ditto -x -k /tmp/chaxie.zip /Applications \
  && xattr -dr com.apple.quarantine /Applications/Chaxie.app \
  && open /Applications/Chaxie.app
```

下载 → 解压到「应用程序」→ 去掉隔离属性（绕过 Gatekeeper 拦截）→ 打开。之后在启动台/应用程序里双击即用。首次启动会请求通知权限，点允许。

## 自己从源码构建

需要 Xcode Command Line Tools（`xcode-select --install`）。

```bash
git clone https://github.com/<USER>/chaxie.git
cd chaxie
bash build.sh
open Chaxie.app          # 或 cp -r Chaxie.app /Applications
```

## 用法

菜单栏会显示当前阶段和剩余时间。点开后：

- 开始 / 暂停（⌘S）
- 跳到下一阶段（⌘N）
- 重置当前阶段（⌘R）
- 专注时长 / 休息时长：预设 + 自定义（1–180 分钟），设置会被记住
- 退出（⌘Q）

## 图标（可选）

把一张 `AppIcon.icns` 放到项目根目录，`build.sh` 会自动拷进 app 并写入 `Info.plist`。没有也能正常用，只是用系统默认图标（菜单栏始终是 🍃 / 🍵 文字图标，不受影响）。

## 推到 GitHub 并自动出包

在 GitHub 建一个空仓库 `chaxie`，然后：

```bash
git init
git add .
git commit -m "feat: 菜单栏番茄钟 茶歇"
git branch -M main
git remote add origin git@github.com:<USER>/chaxie.git
git push -u origin main

# 打 tag 触发 CI，在 macOS runner 上编译并发布 Release
git tag v1.0
git push origin v1.0
```

`.github/workflows/release.yml` 会在收到 `v*` tag 时，在真机 macOS 上构建、打包成 `Chaxie.zip` 并挂到 Release。之后别人就能用上面那条一行命令安装。

## 说明

应用是本地 ad-hoc 签名、未做公证，所以别人下载后必须去掉隔离属性（上面命令里的 `xattr` 那步），否则 Gatekeeper 会拦。自用/小范围分发这是正常做法。
