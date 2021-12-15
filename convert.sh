#!/bin/bash
########################################################################
# 颜色设置
_norm=$(tput sgr0)
_red=$(tput setaf 1)
_green=$(tput setaf 2)
_tan=$(tput setaf 3)
_cyan=$(tput setaf 6)

function _print() {
	printf "${_norm}%s${_norm}\n" "$@"
}
function _info() {
	printf "${_cyan}➜ %s${_norm}\n" "$@"
}
function _success() {
	printf "${_green}✓ %s${_norm}\n" "$@"
}
function _warning() {
	printf "${_tan}⚠ %s${_norm}\n" "$@"
}
function _error() {
	printf "${_red}✗ %s${_norm}\n" "$@"
}

########################################################################
# 变量初始化
username=
speedlink=
INPUT_PATH_NAME=
OUTPUT_PATH_NAME=
INPUT_NAME=
OUTPUT_NAME=
FINAL_INPUT_INFO=
FINAL_OUTPUT_INFO=
FINAL_PATH=
SYSTEM_TYPE=
clean=0
check=0

########################################################################

function _help(){
echo -e "
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
"
}

function _checksys(){
# 检查系统信息
_info "正在检查系统环境兼容性..."
if [ -f /usr/bin/sw_vers ]; then
    SYSTEM_TYPE="MacOS"
elif [ -f /usr/bin/lsb_release ]; then
    system_name=$(lsb_release -i 2>/dev/null)
    if [[ ${system_name} =~ "Debian" ]]; then
        SYSTEM_TYPE="Debian"
    elif [[ ${system_name} =~ "Ubuntu" ]]; then
        SYSTEM_TYPE="Ubuntu"
    fi
else
    _error "暂未适配该系统，退出..."
    exit 1
fi
_success "此脚本支持该系统！"
_info "继续检测中..."
}

function _check(){
# 检查 root
if [[ "${SYSTEM_TYPE}" == "MacOS" ]]; then
    if [[ $EUID == 0 ]]; then
        _error "当前在 root 模式下，请回退到系统当前登录的用户下再运行此脚本以防权限出错"
        exit 1
    elif [[ ! "${username}" == "$(whoami)" ]]; then
        _error "系统当前登录的用户与指定的用户名不同，请设置成当前桌面登录用户名再运行此脚本以防权限出错"
        exit 1
    fi
fi
if [[ "${SYSTEM_TYPE}" =~ "Debian"|"Ubuntu" ]]; then
    if [[ $EUID != 0 ]]; then
        _error "当前在普通用户模式下，请提权到 root 下再运行此脚本，或在运行命令前加上 sudo 以防部分系统级功能无法使用"
        exit 1
    fi
fi

# 必备软件包检查
if [[ ${SYSTEM_TYPE} =~ "MacOS" ]]; then
    _mac_check_devpack
    _mac_check_homebrew
elif [[ ${SYSTEM_TYPE} =~ "Debian"|"Ubuntu" ]]; then
    _check_aptdep
fi
_check_convert_file
}

function _check_aptdep(){
if ! which basename > /dev/null 2>&1; then
    _warning "缺少 basename，正在安装依赖..."
    apt install -y coreutils
else
    _success "basename 已安装"
fi
if ! which dos2unix > /dev/null 2>&1; then
    _warning "缺少 dos2unix，正在安装依赖..."
    apt install -y dos2unix
else
    _success "dos2unix 已安装"
fi
if ! which locate > /dev/null 2>&1; then
    _warning "缺少 locate，正在安装依赖..."
    apt install -y locate
else
    _success "locate 已安装"
fi
}

function _mac_check_devpack(){
if ! which xcode-select > /dev/null 2>&1; then
    xcode-select --install
    _info "未发现开发者工具包，即将开始下载..."
    _info "下载完成会弹出安装包安装界面，请手动安装完成后重新运行此脚本"
    echo ""
    _warning "根据不同网络情况，该工具包可能会下载很久，也有可能失败"
    _warning "如果失败请打开浏览器搜索关键词：Command Line Tools下载"
    _warning "并根据搜到的教程去苹果官网下载安装，完成后重新运行此脚本"
    exit 0
fi
}

function _mac_check_homebrew(){
# brew, homebrew-core, homebrew-cask, homebrew-cask-fonts, homebrew-cask-drivers, homebrew-cask-versions, homebrew-command-not-found, install
if ! which brew > /dev/null 2>&1; then
    _info "未发现 HomeBrew，开始安装..."
    if [[ -z ${speedlink} ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    elif [[ ${speedlink} =~ "tsinghua" ]]; then
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
        cd ~ || _error "进入路径错误" && exit 1
        git clone --depth=1 https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.git brew-install
        /bin/bash brew-install/install.sh
        rm -rf brew-install
        brew update
        for tap in core cask{,-fonts,-drivers,-versions} command-not-found; do
            brew tap --custom-remote --force-auto-update "homebrew/${tap}" "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git"
        done
        ARCH=$(uname -m)
        if [[ "${ARCH}" == "x86_64" ]]; then
            {
                echo 'export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"'
                echo 'export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"'
                echo 'export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"'
            } >> /Users/"${username}"/.zprofile
            export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
            export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
            export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
        elif [[ "${ARCH}" == "arm64" ]]; then
            test -r /Users/"${username}"/.bash_profile && echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/"${username}"/.bash_profile
            test -r /Users/"${username}"/.zprofile && echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/"${username}"/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    elif [[ ${speedlink} =~ "ghproxy" ]]; then
        export HOMEBREW_BREW_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/homebrew-core.git"
        /bin/bash -c "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew update
        for tap in core cask{,-fonts,-drivers,-versions} command-not-found; do
            brew tap --custom-remote --force-auto-update "homebrew/${tap}" "https://ghproxy.com/https://github.com/Homebrew/homebrew-${tap}.git"
        done
        {
            echo 'export HOMEBREW_BREW_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/brew.git"'
            echo 'export HOMEBREW_CORE_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/homebrew-core.git"'
        } >> /Users/"${username}"/.zprofile
        export HOMEBREW_BREW_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://ghproxy.com/https://github.com/Homebrew/homebrew-core.git"
    fi
fi
if which brew > /dev/null 2>&1; then
    if ! brew list gnu-sed > /dev/null 2>&1; then
        _warning "缺少依赖: gnu-sed，正在安装 gnu-sed..."
        brew install gnu-sed
        echo 'export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"' >> ~/.zshrc
    fi
    if ! brew list gnu-getopt > /dev/null 2>&1; then
        _warning "缺少依赖: gnu-getopt，正在安装 gnu-getopt..."
        brew install gnu-getopt
        echo 'export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"' >> ~/.zshrc
    fi
    if ! brew list dos2unix > /dev/null 2>&1; then
        _warning "缺少依赖: dos2unix，正在安装 dos2unix..."
        brew install dos2unix
    fi
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"
fi
}

function _check_convert_file(){
# 检查输入输出文件名或绝对路径情况
# INPUT_PATH_NAME=
# OUTPUT_PATH_NAME=
# INPUT_NAME=
# OUTPUT_NAME=
# FINAL_INPUT_INFO=
# FINAL_OUTPUT_INFO=
# FINAL_PATH=
# FINAL_PATH=
if [[ -z "${INPUT_PATH_NAME}" && -z "${OUTPUT_PATH_NAME}" && -z "${INPUT_NAME}" && -z "${OUTPUT_NAME}" ]]; then
    _error "必须同时指定要转换文件转换前后的 <绝对路径> 或 <文件名>"
    exit 1
elif [[ -n "${INPUT_PATH_NAME}" && -n "${OUTPUT_PATH_NAME}" ]]; then
    FINAL_INPUT_INFO="${INPUT_PATH_NAME}"
    FINAL_OUTPUT_INFO="${OUTPUT_PATH_NAME}"
    FINAL_PATH=$(dirname "${FINAL_OUTPUT_INFO}")
elif [[ -n "${INPUT_NAME}" && -n "${OUTPUT_NAME}" ]]; then
    if [[ "${SYSTEM_TYPE}" == "MacOS" ]]; then
        FIXED_PATH=$(mdfind -name "${INPUT_NAME}")
    elif [[ "${SYSTEM_TYPE}" =~ "Debian"|"Ubuntu" ]]; then
        _warning "开始创建或更新全局文件数据库，耗时可能会很长"
        _warning "并不是程序无响应，请耐心等待且不要强制退出"
        updatedb 2>/dev/null
        FIXED_PATH=$(locate "${INPUT_NAME}")
    fi
    count=0
    for i in "${FIXED_PATH}"; do
        count=$(expr $count + 1)
    done
    if [[ ${count} != 1 ]]; then
        _error "同名文件有多个，请确认以下路径的文件均为你自行下载的码表文件"
        _error "如果存在非自行下载的码表文件，请将你需要保留的码表文件名改名"
        _error "请只保留一个码表文件用于转换，之后重新运行此脚本"
        _error "以下是所有同名文件列表:"
        echo -e "${FIXED_PATH}"
        exit 1
    fi
    FINAL_PATH=$(dirname "${FIXED_PATH}")
    FINAL_INPUT_INFO="${FIXED_PATH}"
    FINAL_OUTPUT_INFO="${FINAL_PATH}/${OUTPUT_NAME}"
else
    _error "输入了多余选项参数！只能同时存在要转换文件转换前后的 <绝对路径> 或 <文件名>"
    exit 1
fi
${FIXED_PATH}
${FINAL_PATH}
${FINAL_INPUT_INFO}
${FINAL_OUTPUT_INFO}
#检查属主权限、输入文件、输出路径是否存在
if [[ ! -f "${FINAL_INPUT_INFO}" ]]; then
    _error "需转换的文件不存在，请确认需转换文件的路径完全正确"
    exit 1
fi

if [[ "${SYSTEM_TYPE}" == "MacOS" ]]; then
    belong_to_owner=$(ls -l "${FINAL_INPUT_INFO}" | awk '{print $3}')
    if [[ "${username}" != "${belong_to_owner}" ]]; then
        _error "需转换文件的属主和当前登录桌面的用户名不同，请手动将属主改成当前登录名后再试"
        exit 1
    fi
    if [[ ! -d "${FINAL_PATH}" ]]; then
        _warning "指定的输出目录路径不存在，将尝试创建对应文件夹路径..."
        mkdir -p "${FINAL_PATH}"
        if [[ "$?" != 0 ]]; then
            _error "输出目录创建失败，请确认指定的输出路径是否存在权限冲突"
            exit 1
        fi
    fi
elif [[ "${SYSTEM_TYPE}" =~ "Debian"|"Ubuntu" ]]; then
    if [[ ! -d "${FINAL_PATH}" ]]; then
        _warning "指定的输出目录路径不存在，将尝试创建对应文件夹路径..."
        mkdir -p "${FINAL_PATH}"
    fi
fi
}

function _check_result(){
if [[ ${SYSTEM_TYPE} == "MacOS" ]]; then
    _info "系统信息: "
    _print "$(sw_vers 2>/dev/null)"
    if ! which xcode-select > /dev/null 2>&1; then
        _error "xcode-select 未安装，请重新运行脚本进行安装"
    else
        _success "开发者工具包已安装"
    fi
    if ! which brew > /dev/null 2>&1; then
        _error "HomeBrew 未安装，请重新运行脚本进行安装"
    else
        _success "HomeBrew 已安装"
    fi
    if ! brew list gnu-sed > /dev/null 2>&1; then
        _error "gnu-sed 未安装，请重新运行脚本进行安装"
    else
        _success "gnu-sed 已安装"
    fi
    if ! brew list gnu-getopt > /dev/null 2>&1; then
        _error "gnu-getopt 未安装，请重新运行脚本进行安装"
    else
        _success "gnu-getopt 已安装"
    fi
    if ! brew list dos2unix > /dev/null 2>&1; then
        _error "dos2unix 未安装，请重新运行脚本进行安装"
    else
        _success "dos2unix 已安装"
    fi
elif [[ ${SYSTEM_TYPE} =~ "Debian"|"Ubuntu" ]]; then
    _info "系统信息: "
    _print "$(lsb_release -a 2>/dev/null)"
    _check_aptdep
fi
_info "最终输入文件路径信息: "$(_print "${FINAL_INPUT_INFO}")
_info "最终输出文件路径信息: "$(_print "${FINAL_OUTPUT_INFO}")
_info "临时文件路径信息: "$(_print "${FINAL_PATH}")
}

function _convert(){
dos2unix -b -n "${FINAL_INPUT_INFO}" "${FINAL_PATH}"/tmp.ini
sed -i 's/=/-/g' "${FINAL_PATH}"/tmp.ini
sed -i 's/,/=/g' "${FINAL_PATH}"/tmp.ini
sed -i 's/-/,/g' "${FINAL_PATH}"/tmp.ini
unix2dos < "${FINAL_PATH}"/tmp.ini | iconv -f UTF-8 -t UTF-16LE > "${FINAL_OUTPUT_INFO}"
rm -rf "${FINAL_PATH}"/tmp.ini
[[ $? != 0 ]] && _error "转换出现错误，退出中..." && exit 1
_success "已完成转换!"
_info "输出文件路径: "$(_print "${FINAL_OUTPUT_INFO}")
if [[ ${clean} == 0 ]]; then
    _info "原始文件路径: "$(_print "${FINAL_INPUT_INFO}")
    _info "原始文件可自行删除"
elif [[ ${clean} == 1 ]]; then
    rm -rf "${FINAL_INPUT_INFO}"
    _success "原始文件已删除"
fi
_info "之后请将转换后的码表文件内容自行导入搜狗输入法的 <自定义短语设置>"
}

_checksys
if [[ ${SYSTEM_TYPE} == "MacOS" ]]; then
    GETOPT="${PWD}/macgetopt"
else
    GETOPT="getopt"
fi
if ! ARGS=$("${GETOPT}" -a -o u:i:o:I:O:s:hc -l username:,speedlink:,inputfile:,outputfile:,inputfilename:,outputfilename:,help,clean,check -- "$@")
then
    _error "无效的参数，请查看帮助信息"
    _help
    exit 1
fi
eval set -- "${ARGS}"
while true; do
    case "$1" in
    -u | --username)
        username="$2"
        shift
        ;;
    -s | --speedlink)
        speedlink="$2"
        shift
        ;;
    -i | --inputfile)
        INPUT_PATH_NAME="$2"
        shift
        ;;
    -o | --outputfile)
        OUTPUT_PATH_NAME="$2"
        shift
        ;;
    -I | --inputfilename)
        INPUT_NAME="$2"
        shift
        ;;
    -O | --outputfilename)
        OUTPUT_NAME="$2"
        shift
        ;;
    -h | --help)
        _help
        exit 0
        ;;
    -c | --clean)
        clean=1
        ;;
    --check)
        check=1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

_check
[[ ${check} == 1 ]] && _check_result && exit 0
_convert