<p align='center'>
<img src='https://raw.githubusercontent.com/daryl5/iScheme/master/images/logo.png' width=100 />
</p>

# iScheme
[GIF showcase(6MB)](https://github.com/daryl5/iScheme/blob/master/images/showcase.gif?raw=true)

[中文介绍](https://github.com/daryl5/iScheme#中文介绍)  
iScheme is a Mac menu bar app for iOS/Android/FE developers to open specific [URL scheme](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html) in iOS/Android simulator/real device with **JUST 1 CLICK**.  
If you are working on several pages in a giant app, and you always click through pages to navigate to your page for debugging, iScheme will save a lot of time for you.

## Feature
- Open URL scheme in:
   - iOS simulator
   - iOS device (need to integrate iScheme client in your app)
   - Android simulator (adb required)
   - Android device (adb required)
- Generate QR code
- Open iOS app sandbox
- Scan QR code on screen

## Tips
- iScheme works in QR code mode by default, remember to change working mode to iOS/Android in Preferences.
- `⌘+⇧+E` open the **FIRST** URL scheme. **Always use this hotkey**. You can customize hotkey in Preferences.
- `⌘+⇧+\`` show a 「Quick Jump」/「Search」 window. You can paste and press Enter to jump, or type a keyword to search.
- Click a scheme while holding `⌘` will show QR code of this scheme. This works in main menu and search result.
- You can find all schemes in `Documents/Schemes.json` if you want to share with others.

## Build the app
Building the app requires Carthage to be installed. Then run `carthage update` to build dependencies.

## Author
[@程序员小方](https://weibo.com/wuyunpeng) at Weibo

## License
iScheme is released under the MIT license. See LICENSE for details.

# 中文介绍

[GIF 演示(6MB)](https://github.com/daryl5/iScheme/blob/master/images/showcase.gif?raw=true)

iScheme 是一个给 iOS/Android/移动前端开发者使用的 Mac 菜单栏 App，用于一键跳转一个 [URL scheme](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html)，支持 iOS 模拟器和真机、Android 模拟器和真机。  
如果你在一个业务繁多的 App 中负责几个页面，并且经常需要在 App 中点点点去到你负责的页面来进行调试，那 iScheme 会帮你节省掉这些点点点的时间。

## 功能
- 跳转 URL scheme，支持:
   - iOS 模拟器
   - iOS 真机 (需要在你的 app 中集成 iScheme client)
   - Android 模拟器 (需要安装 adb)
   - Android 真机 (需要安装 adb)
- 显示 scheme 对应的二维码
- 打开 iOS 模拟器中 app 的沙盒目录
- 扫描屏幕上的二维码

## Tips
- iScheme 默认是二维码模式，你需要在偏好设置中更改为 iOS 或安卓模式。
- `⌘+⇧+E` 会跳转 **第一个** scheme，记得使用这个快捷键来提高效率。在偏好设置中可以自定义按键。
- ``⌘+⇧+` `` 会显示「快速跳转」/「搜索」窗口，可以粘贴 scheme 按下回车直接跳转或进行搜索。
- 在任何界面按着 `⌘` 点击 scheme 会生成其二维码。
- 你可以在 `Documents/Schemes.json` 找到你添加的所有 scheme，直接分享这个文件即可将所有 scheme 分享给他人。

## 运行
在终端运行 `carthage update` 安装项目依赖，然后打开工程文件运行即可。

## 作者
微博：[@程序员小方](https://weibo.com/wuyunpeng)