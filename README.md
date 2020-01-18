## 西电睿思手机客户端(iOS)

[![Build Status](https://travis-ci.org/freedom10086/Ruisi_Ios.svg?branch=master)](https://travis-ci.org/freedom10086/Ruisi_Ios)

西安电子科技大学校园睿思论坛客户端。    
本客户端在校园网和校外网环境下均可使用。如有bug,建议等欢迎反馈。    

**Android版本** [Ruisi](https://github.com/freedom10086/Ruisi)


### 下载
- App Store [西电睿思](https://apps.apple.com/us/app/西电睿思/id1322805454)

### 编译
- 安装Cocoapods: `sudo gem install cocoapods`
- 克隆本项目: `git clone https://github.com/freedom10086/Ruisi_Ios.git`
- 在项目文件夹中运行:  `pod install`
- 使用xcode(需要10.x及以上版本)打开生成的`.xcworkspace`文件，构建并运行.

### 移植到你的论坛
> 理论上支持任何Discuz 3.x版本
1. 到你discuz管理后台`全局` -> `手机版设置` -> `开启手机版` ，目前不支持新触屏版，关闭此选项
2. `全局` -> `防采集设置` -> `不进行防采集的内容` 勾选`文章`，或者关闭防采集
3. 修改代码文件`Constant.swift`，设置里的论坛地址，修改`baseUrl`指向你的论坛地址（由于我们学校论坛有2个地址所以这儿我填了2个根地址，按需删除）
```
//校园网地址
public static let BASE_URL_EDU = "http://rs.xidian.edu.cn/"
//校外网地址
public static let BASE_URL_ME = "http://rsbbs.xidian.edu.cn/"

public static var baseUrl: String {
    return App.isSchoolNet ? BASE_URL_EDU : BASE_URL_ME
}
```
4. 修改配置文件`forums.json`，按照默认模版填上你论坛板块信息
5. 板块图标放到`forumlogo`目录，文件名`common_2_icon.gif`，中间的数字替换为板块`fid`
6. 设置表情    
修改`smiley.json`，表情显示在发帖回复键盘底下，参考默认模版修改为你的论坛支持的表情，支持文字(`isImage:false`)，与图片表情(`path`：表情在smiley目录位置，`value`：表情转义文字)，把图片表情放在`smiley`目录，后缀`.png`。
查询你论坛支持的表情(需要开启 【应用 -> 掌上论坛 】)：根路径 + api/mobile/index.php?version=4&module=smiley，[示例](http://184.170.213.188/api/mobile/index.php?version=4&module=smiley)

### 软件截图
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/1.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/2.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/3.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/4.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/5.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/6.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/7.png)
![image](https://github.com/freedom10086/Ruisi_Ios/blob/master/screenshots/8.png)

### 意见和反馈
- freedom10086 <2351386755@qq.com>

### 参考和使用的开源库和软件：

[Kingfisher](https://github.com/onevcat/Kingfisher)

[Kanna](https://github.com/tid-kijyun/Kanna)

[Ruisi](https://github.com/freedom10086/Ruisi)

[MailOnline/ImageViewer](https://github.com/MailOnline/ImageViewer)

[SwiftGif](https://github.com/bahlo/SwiftGif)


### License

    Copyright 2017-2018 freedom10086

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
