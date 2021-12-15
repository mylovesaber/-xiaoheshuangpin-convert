# xiaoheshuangpin-convert
一款 MacOS/Linux 平台针对小鹤双拼安卓百度挂接码表的输入法词库转换脚本

该工具针对小鹤双拼官网网盘中为安卓百度输入法定制的 ini 后缀的码表文件进行定向转换，以便全平台的搜狗输入法都能正常挂接使用
(写此脚本的时候 MacOS Monterey 系统下，鼠须管输入法无法正常切换使用，搜狗成了唯一合适的输入法了)
该工具未对其他码表做任何适配，其他码表用户切勿尝试

## 创建脚本原因

其实已经有一个通用性比较强的码表转换工具了：
深蓝词库转换： https://github.com/studyzy/imewlconverter

>MacOS 下安装完 .Net 包后需要将 dotnet 加入环境变量否则无法工作：
>
>`echo "PATH=\"/usr/local/share/dotnet:\$PATH\"" >> ~/.zshrc && source ~/.zshrc`

但我在 MacOS 中尝试了各种组合，好像都无法转换老鹤制作的安卓百度的挂接码表

同时 Mac 下的 office/WPS 打开码表不分列没法继续编辑，所以只能自己写一个自用了
脚本转换所需文件获取方式如下：

>小鹤双拼官网网盘链接：http://flypy.ys168.com/
>
>下载途径: **<网盘>** - **<____3.2.挂接——辅助码>** - **<for安卓百度个性短语.ini>**

## 帮助菜单

可以直接 `bash convert.sh -h` 查看帮助菜单：

<details>
  <summary>点击此行展开帮助信息</summary>

```shell
MacOS/Linux 小鹤双拼码表转换工具
该工具针对以下码表文件进行定向转换，
以便全平台的搜狗输入法都能正常挂接使用
该工具未对其他码表做任何适配，其他码表用户切勿尝试
小鹤双拼官网网盘链接：http://flypy.ys168.com/
网盘 - ____3.2.挂接——辅助码 - for安卓百度个性短语.ini

已适配系统：MacOS/Ubuntu/Debian

可选选项及用法：
-u | --username                 (MacOS 必填)该选项用于指定当前桌面登录的用户名，
                                并与终端中脚本运行时的用户进行比对，
                                防止出现权限错误、环境变量注入错误等问题
                                仅限 MacOS 必填，Linux 无此功能
                                举例：
                                    -u "测试 yes"
                                    --username "Mike"

-s | --speedlink                (MacOS 选填)利用国内github镜像站加速依赖环境的下载
                                内置国内加速源：
                                tsinghua (清华源) <- 推荐
                                ghproxy (公共github加速)
                                仅限 MacOS 有效，Linux 无此功能
                                举例：
                                    -s tsinghua

输入输出文件有两种方案：绝对路径组合 或 文件名组合，每一种组合都包括了对应的输入输出方式，只能二选一
绝对路径组合：
-i | --inputfile                (二选一必填)该选项用于指定需要转换的文件对应的绝对路径
                                如果文件名或路径存在中文路径，请用英文双引号括起来
                                建议选择纯英文路径！
                                一旦使用，则必须且只能和 --outputfile 搭配使用
                                举例：
                                    -i /Users/"做个人吧"/data/"for安卓百度个性短语.ini"
                                    --inputfile /Users/Mike/need_converted.ini

-o | --outputfile               (二选一必填)该选项用于指定转换后的文件对应的绝对路径
                                注意事项和举例等同于 --inputfile
                                一旦使用，则必须且只能和 --inputfile 搭配使用

文件名组合：
-I | --inputfilename            (二选一必填)该选项的参数必须是单纯的文件名
                                利用 MacOS 独有的 Spotslight 或 linux 的 locate
                                实现快速定位需转换的码表文件，当出现重复文件时会停止运行并警告
                                该选项一旦使用，则必须且只能和 --outputfilename 搭配使用
                                建议改成英文名再使用，最好用英文双引号括起来
                                举例：
                                    -I "for安卓百度个性短语.ini"
                                    --inputfilename "test.ini"

-O | --outputfilename           (二选一必填)该选项用于指定生成的码表文件名，默认和需转换文件同路径
                                用法和注意事项等同于 --inputfilename

--check                         (选填)该选项无后续参数，会自动检查转换所需依赖并给出结果以供检查
-c | --clean                    (选填)该选项无后续参数，会删掉原始未转换的码表文件
-h | --help                     该选项无后续参数，使用后将打印帮助信息并退出脚本
```

</details>

## 教程前提

对于路径和用户名推荐全部用英文双引号括起来防止读取错误

假设有以下情况:
- 当前系统登录的用户名为：Mike
- 全新的 MacOS 系统未安装 homebrew，网络环境无法打开 github，首次安装和日常使用的镜像源选择清华源
- 需要转换的码表文件所在的绝对路径是： "/Users/Mike/need_convert.ini"
- 想要输出到的路径以及自定义码表文件输出名： "/Users/Mike/output/converted.ini"
- 希望一键转换后只保留转换后的码表文件并删掉原始文件

为了实现以上条件，以下提供了两种解决办法，以下所有命令的选项参数均参考以上介绍和对应帮助信息

## 分系统使用教程

<details>
  <summary>**MacOS 使用方法点击此行展开**</summary>

### 0. MacOS 全程在非 root 环境下操作

### 1. 下载项目

根据网络情况二选一：

```bash
# github 使用请确定你的网络能打开 github
git clone https://github.com/mylovesaber/xiaoheshuangpin-convert.git && cd xiaoheshuangpin-convert

# 国内用户请使用以下命令运行
git clone https://gitee.com/mylovesaber/xiaoheshuangpin-convert.git && cd xiaoheshuangpin-convert
```

### 2. 检查环境

事先进行测试，看看环境依赖是否满足、输入输出路径是否正确(**具体参数请自行更改**)：

```bash
# 绝对路径方案：
bash ./convert.sh -u "Mike" -s tsinghua -i "/Users/Mike/need_convert.ini" -o "/Users/Mike/output/converted.ini" --check

# 文件名方案：
bash ./convert.sh -u "Mike" -s tsinghua -I "need_convert.ini" -O "converted.ini" --check
```

### 3. 转换码表
#### 3.1 绝对路径方案

```bash
bash ./convert.sh -u "Mike" -s tsinghua -i "/Users/Mike/need_convert.ini" -o "/Users/Mike/output/converted.ini" -c
```

#### 3.2 文件名方案

 MacOS 下利用 Spotslight 的专用工具 mdfind 实现瞬间精准定位，所以如果你不了解绝对路径如何获取的话，可以直接使用文件名作为输入源，脚本会自动查找对应绝对路径并完成转换，如果存在重名情况会自动报错并退出，届时则需要你手动删掉其他同名文件再运行脚本，所以请确保输入名和转换后的文件名都是独一无二的，由于没有指定路径所以默认生成的文件和需要转换的源文件在同一个目录下：

 ```bash
bash ./convert.sh -u "Mike" -s tsinghua -I "need_convert.ini" -O "converted.ini" -c
 ```

</details>

<details>
  <summary>**Linux 使用方法点击此行展开**</summary>

### 0. Linux 全程在 root 环境下操作

提权三种方式：
1. `su` 前提是曾经切换到 root 下并设置了密码，否则无法登录
2. `sudo -i` 当前用户的登录密码
3. 在后文所有命令前面加上 `sudo` 字样，首次运行命令的时候会提示输入密码并回车即可

以下所有命令默认已执行第一第二种提权方式进入 root 权限了

### 1. 下载项目

根据网络情况二选一：

```bash
# github 使用请确定你的网络能打开 github
git clone https://github.com/mylovesaber/xiaoheshuangpin-convert.git && cd xiaoheshuangpin-convert

# 国内用户请使用以下命令运行
git clone https://gitee.com/mylovesaber/xiaoheshuangpin-convert.git && cd xiaoheshuangpin-convert
```

### 2. 检查环境

事先进行测试，看看环境依赖是否满足、输入输出路径是否正确(**具体参数请自行更改**)：

```bash
# 绝对路径方案：
bash ./convert.sh -i "/Users/Mike/need_convert.ini" -o "/Users/Mike/output/converted.ini" --check

# 文件名方案：
bash ./convert.sh -I "need_convert.ini" -O "converted.ini" --check
```

### 3. 转换码表
#### 3.1 绝对路径方案

```bash
bash ./convert.sh -i "/Users/Mike/need_convert.ini" -o "/Users/Mike/output/converted.ini" -c
```

#### 3.2 文件名方案

Linux 下使用 locate 命令实现瞬间精准定位，但之前会创建或更新数据库，所以会有一段时间形似无响应，切勿手动停止脚本运行。如果你不了解绝对路径如何获取的话，可以直接使用文件名作为输入源，脚本会自动查找对应绝对路径并完成转换，如果存在重名情况会自动报错并退出，届时则需要你手动删掉其他同名文件再运行脚本，所以请确保输入名和转换后的文件名都是独一无二的，由于没有指定路径所以默认生成的文件和需要转换的源文件在同一个目录下：

 ```bash
bash ./convert.sh -I "need_convert.ini" -O "converted.ini" -c
 ```

</details>
