#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly CONFIG_NAME="lc_qs_niri"
readonly REPOSITORY_URL="https://github.com/LengineerC/lc_qs_niri.git"
readonly QML_NIRI_VERSION="0.2.1"
readonly QML_NIRI_URL="https://github.com/imiric/qml-niri/archive/refs/tags/v${QML_NIRI_VERSION}.tar.gz"
readonly QML_NIRI_SHA256="98c5ae261922a3945f93a2ea2aec92ab883b29041a5c0412c2e8b63803f9fdb0"

install_packages=true
install_qml_niri=true
configure_autostart=true
start_shell=true
source_override=""
source_dir=""
work_dir=""
staging_dir=""

if [[ -t 1 ]]; then
    readonly c_blue=$'\033[1;34m'
    readonly c_green=$'\033[1;32m'
    readonly c_yellow=$'\033[1;33m'
    readonly c_red=$'\033[1;31m'
    readonly c_reset=$'\033[0m'
else
    readonly c_blue=""
    readonly c_green=""
    readonly c_yellow=""
    readonly c_red=""
    readonly c_reset=""
fi

info() {
    printf '%s==>%s %s\n' "$c_blue" "$c_reset" "$*"
}

success() {
    printf '%s==>%s %s\n' "$c_green" "$c_reset" "$*"
}

warn() {
    printf '%s警告:%s %s\n' "$c_yellow" "$c_reset" "$*" >&2
}

die() {
    printf '%s错误:%s %s\n' "$c_red" "$c_reset" "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
lc_qs_niri 一键安装器（Arch Linux x86-64）

用法：
  ./install.sh [选项]

选项：
  --no-packages    不安装或升级系统软件包
  --no-qml-niri    不构建和安装 qml-niri v0.2.1
  --no-autostart   不向 Niri 添加自动启动片段
  --no-start       安装后不立即启动 Quickshell
  --source DIR     从指定的配置源码目录安装
  -h, --help       显示本帮助

默认行为：同步并完整升级 Arch 软件包数据库、安装全部依赖，将配置安装到
$XDG_CONFIG_HOME/quickshell/lc_qs_niri（未设置时使用 ~/.config），安装固定版本
qml-niri，并在可用的 Niri 会话中启动配置。旧配置会先被移动到带时间戳的备份。
EOF
}

cleanup() {
    if [[ -n "$work_dir" && "$work_dir" == /tmp/lc-qs-niri.* && -d "$work_dir" ]]; then
        rm -rf -- "$work_dir"
    fi

    if [[ -n "$staging_dir" && -d "$staging_dir" ]]; then
        case "$staging_dir" in
            */.lc_qs_niri.install.*) rm -rf -- "$staging_dir" ;;
        esac
    fi
}

trap cleanup EXIT

while (($#)); do
    case "$1" in
        --no-packages)
            install_packages=false
            ;;
        --no-qml-niri)
            install_qml_niri=false
            ;;
        --no-autostart)
            configure_autostart=false
            ;;
        --no-start)
            start_shell=false
            ;;
        --source)
            (($# >= 2)) || die "--source 需要一个目录参数"
            source_override=$2
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "未知参数：$1（使用 --help 查看帮助）"
            ;;
    esac
    shift
done

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "请以普通用户运行本脚本；需要系统权限时脚本会调用 sudo。"
[[ $(uname -m) == "x86_64" ]] || die \
    "当前配置内置的 Caelestia.Blobs 插件仅支持 x86-64，当前架构为 $(uname -m)。"

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
[[ "$config_home" == /* ]] || die "XDG_CONFIG_HOME 必须是绝对路径：$config_home"
target_dir="$config_home/quickshell/$CONFIG_NAME"

detect_arch_linux() {
    [[ -r /etc/os-release ]] || die "无法读取 /etc/os-release。"

    # shellcheck disable=SC1091
    source /etc/os-release
    local distro_id=${ID:-}
    local distro_like=" ${ID_LIKE:-} "
    if [[ "$distro_id" != "arch" && "$distro_like" != *" arch "* ]]; then
        die "目前的一键依赖安装仅支持 Arch Linux 及其衍生版；检测到 ${PRETTY_NAME:-未知发行版}。"
    fi
}

install_arch_dependencies() {
    local packages=(
        accountsservice
        base-devel
        bluez
        bluez-utils
        brightnessctl
        ca-certificates
        cava
        cmake
        curl
        ddcutil
        dbus
        fastfetch
        git
        glib2
        imagemagick
        libnotify
        lm_sensors
        matugen
        networkmanager
        ninja
        niri
        pam
        pipewire
        pipewire-audio
        power-profiles-daemon
        procps-ng
        python
        qt6-base
        qt6-declarative
        qt6-imageformats
        qt6-shadertools
        qt6-svg
        qt6-tools
        qt6-wayland
        quickshell
        ttf-jetbrains-mono-nerd
        ttf-nerd-fonts-symbols
        upower
        wireplumber
        wl-clipboard
        xdg-utils
    )

    command -v pacman >/dev/null 2>&1 || die "未找到 pacman。"
    command -v sudo >/dev/null 2>&1 || die "未找到 sudo。"

    info "请求 sudo 权限"
    sudo -v
    info "同步系统并安装 lc_qs_niri 依赖"
    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

make_work_dir() {
    if [[ -z "$work_dir" ]]; then
        work_dir=$(mktemp -d /tmp/lc-qs-niri.XXXXXX)
    fi
}

find_qt_qml_path() {
    local candidate=""
    local result=""
    local candidates=(
        /usr/lib/qt6/bin/qtpaths
        /usr/bin/qtpaths6
        /usr/bin/qtpaths
    )

    if command -v qtpaths6 >/dev/null 2>&1; then
        candidates+=("$(command -v qtpaths6)")
    fi
    if command -v qtpaths >/dev/null 2>&1; then
        candidates+=("$(command -v qtpaths)")
    fi

    for candidate in "${candidates[@]}"; do
        [[ -x "$candidate" ]] || continue
        result=$("$candidate" --qt-query QT_INSTALL_QML 2>/dev/null || true)
        if [[ -n "$result" && "$result" == /* ]]; then
            printf '%s\n' "$result"
            return 0
        fi
    done

    return 1
}

install_qml_niri_release() {
    local archive=""
    local source_dir=""
    local build_dir=""
    local qml_path=""

    command -v curl >/dev/null 2>&1 || die "安装 qml-niri 需要 curl。"
    command -v cmake >/dev/null 2>&1 || die "安装 qml-niri 需要 cmake。"
    command -v ninja >/dev/null 2>&1 || die "安装 qml-niri 需要 ninja。"
    command -v sha256sum >/dev/null 2>&1 || die "安装 qml-niri 需要 sha256sum。"
    command -v sudo >/dev/null 2>&1 || die "安装 qml-niri 需要 sudo。"

    qml_path=$(find_qt_qml_path) || die "无法查询 Qt 6 的 QML 导入目录。"
    make_work_dir
    archive="$work_dir/qml-niri-v${QML_NIRI_VERSION}.tar.gz"
    source_dir="$work_dir/qml-niri-${QML_NIRI_VERSION}"
    build_dir="$work_dir/qml-niri-build"

    info "下载 qml-niri v${QML_NIRI_VERSION}"
    curl --fail --location --retry 3 --output "$archive" "$QML_NIRI_URL"
    if ! printf '%s  %s\n' "$QML_NIRI_SHA256" "$archive" | sha256sum --check --status; then
        die "qml-niri 源码校验失败，已停止安装。"
    fi

    tar -xzf "$archive" -C "$work_dir"
    info "构建 qml-niri v${QML_NIRI_VERSION}"
    cmake -S "$source_dir" -B "$build_dir" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQML_INSTALL_DIR="$qml_path"
    cmake --build "$build_dir" --parallel

    info "安装 qml-niri 到 $qml_path/Niri"
    sudo cmake --install "$build_dir"
    [[ -f "$qml_path/Niri/qmldir" ]] || die "qml-niri 安装后验证失败。"
}

resolve_source_dir() {
    local script_dir=""

    if [[ -n "$source_override" ]]; then
        [[ -d "$source_override" ]] || die "源码目录不存在：$source_override"
        source_dir=$(realpath "$source_override")
    else
        script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)
        if [[ -n "$script_dir" && -f "$script_dir/shell.qml" ]]; then
            source_dir=$script_dir
        else
            command -v git >/dev/null 2>&1 || die "下载安装配置需要 git。"
            make_work_dir
            source_dir="$work_dir/config-source"
            info "下载 lc_qs_niri 配置"
            git clone --depth 1 "$REPOSITORY_URL" "$source_dir"
        fi
    fi

    [[ -f "$source_dir/shell.qml" ]] || die "源码目录中没有 shell.qml：$source_dir"
    [[ -f "$source_dir/Caelestia/Blobs/qmldir" ]] || die \
        "源码目录缺少 Caelestia.Blobs 原生模块。"
}

install_configuration() {
    local target_parent=""
    local backup_dir=""
    local timestamp=""
    local source_real=""
    local target_real=""

    target_parent=$(dirname "$target_dir")
    mkdir -p "$target_parent"
    source_real=$(realpath "$source_dir")
    target_real=$(realpath -m "$target_dir")

    if [[ "$source_real" == "$target_real" ]]; then
        info "配置已经位于 $target_dir，保留当前文件"
        return 0
    fi

    staging_dir=$(mktemp -d "$target_parent/.lc_qs_niri.install.XXXXXX")
    info "复制配置到临时目录"
    (
        cd "$source_dir"
        tar \
            --exclude='./.git' \
            --exclude='./.vscode' \
            --exclude='./.qmlls.ini' \
            -cf - .
    ) | tar -xf - -C "$staging_dir"

    if [[ -e "$target_dir" || -L "$target_dir" ]]; then
        timestamp=$(date +%Y%m%d-%H%M%S)
        backup_dir="${target_dir}.backup-${timestamp}-$$"
        info "备份原配置到 $backup_dir"
        mv -- "$target_dir" "$backup_dir"
    fi

    if ! mv -- "$staging_dir" "$target_dir"; then
        if [[ -n "$backup_dir" && -e "$backup_dir" ]]; then
            mv -- "$backup_dir" "$target_dir"
        fi
        die "安装配置失败，原配置已恢复。"
    fi
    staging_dir=""
    success "配置已安装到 $target_dir"
}

configure_niri() {
    local niri_dir="$config_home/niri"
    local niri_config="$niri_dir/config.kdl"
    local fragment_dir="$niri_dir/lc_qs_niri"
    local fragment="$fragment_dir/quickshell.kdl"
    local include_line='include "lc_qs_niri/quickshell.kdl"'
    local timestamp=""
    local config_backup=""
    local existing_spawn=""

    if [[ ! -f "$niri_config" ]]; then
        warn "没有找到 $niri_config，跳过 Niri 自动启动配置。"
        return 0
    fi

    existing_spawn=$(grep -RhsE --include='*.kdl' \
        '^[[:space:]]*spawn-at-startup[[:space:]].*"(qs|quickshell)".*lc_qs_niri' \
        "$niri_dir" 2>/dev/null || true)
    if [[ -n "$existing_spawn" ]]; then
        info "Niri 已存在 lc_qs_niri 自动启动项，跳过修改"
        return 0
    fi

    if ! niri validate --config "$niri_config" >/dev/null; then
        warn "现有 Niri 配置未通过验证，跳过自动启动设置。"
        return 0
    fi

    mkdir -p "$fragment_dir"
    if [[ -e "$fragment" ]]; then
        warn "$fragment 已存在且不是本安装器生成的启动项，跳过自动启动设置。"
        return 0
    fi

    cat >"$fragment" <<'EOF'
// lc_qs_niri autostart; managed by the lc_qs_niri installer.
spawn-at-startup "qs" "-c" "lc_qs_niri"
EOF

    if ! grep -Eq \
            '^[[:space:]]*include[[:space:]]+"lc_qs_niri/quickshell\.kdl"[[:space:]]*$' \
            "$niri_config"; then
        timestamp=$(date +%Y%m%d-%H%M%S)
        config_backup="${niri_config}.backup-${timestamp}-$$"
        cp -a -- "$niri_config" "$config_backup"
        printf '\n// lc_qs_niri\n%s\n' "$include_line" >>"$niri_config"
    fi

    if ! niri validate --config "$niri_config" >/dev/null; then
        if [[ -n "$config_backup" ]]; then
            cp -a -- "$config_backup" "$niri_config"
        fi
        mv -- "$fragment" "${fragment}.invalid"
        warn "自动启动片段未通过 Niri 验证，已还原 config.kdl。"
        return 0
    fi

    success "已通过独立 include 添加 Niri 自动启动项"
}

verify_installation() {
    local blob_ldd=""
    local qml_path=""
    local missing=()
    local command_name=""
    local required_commands=(
        cava
        curl
        fastfetch
        magick
        matugen
        niri
        nmcli
        notify-send
        python3
        qs
        sensors
        systemctl
        wl-copy
        wl-paste
        xdg-open
    )

    for command_name in "${required_commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            missing+=("$command_name")
        fi
    done

    ((${#missing[@]} == 0)) || die "以下必需命令不可用：${missing[*]}"
    [[ -f "$target_dir/shell.qml" ]] || die "目标目录缺少 shell.qml。"
    [[ -f "$target_dir/Caelestia/Blobs/libtest-caelestia-blobsplugin.so" ]] \
        || die "目标目录缺少 Caelestia.Blobs 插件。"

    if $install_qml_niri; then
        qml_path=$(find_qt_qml_path) || die "无法重新查询 Qt QML 路径。"
        [[ -f "$qml_path/Niri/qmldir" ]] || die "Qt QML 路径中没有 Niri 模块。"
    fi

    if ! blob_ldd=$(ldd \
            "$target_dir/Caelestia/Blobs/libtest-caelestia-blobsplugin.so" \
            2>/dev/null); then
        die "无法检查 Caelestia.Blobs 的动态库依赖。"
    fi
    if grep -q 'not found' <<<"$blob_ldd"; then
        die "Caelestia.Blobs 存在未满足的动态库依赖。"
    fi

    for service in NetworkManager bluetooth power-profiles-daemon; do
        if ! systemctl is-active --quiet "$service.service" 2>/dev/null; then
            warn "$service.service 未运行，对应功能将不可用；请按系统环境决定是否启用。"
        fi
    done
}

start_quickshell() {
    if [[ -z ${NIRI_SOCKET:-} ]]; then
        warn "当前不在可识别的 Niri 会话中；下次登录后会自动启动。"
        return 0
    fi

    if [[ -n $(qs -c "$CONFIG_NAME" list 2>/dev/null || true) ]]; then
        info "lc_qs_niri 已在运行；没有强制重启现有进程"
        return 0
    fi

    info "启动 lc_qs_niri"
    if qs --daemonize --config "$CONFIG_NAME"; then
        success "lc_qs_niri 已启动"
    else
        warn "自动启动失败，请运行：qs -c $CONFIG_NAME"
    fi
}

main() {
    detect_arch_linux

    if $install_packages; then
        install_arch_dependencies
    else
        info "已跳过系统依赖安装"
    fi

    if $install_qml_niri; then
        install_qml_niri_release
    else
        info "已跳过 qml-niri 安装"
    fi

    resolve_source_dir
    install_configuration

    if $configure_autostart; then
        configure_niri
    else
        info "已跳过 Niri 自动启动设置"
    fi

    verify_installation

    if $start_shell; then
        start_quickshell
    fi

    success "安装完成"
    printf '配置目录：%s\n' "$target_dir"
    printf '手动启动：qs -c %s\n' "$CONFIG_NAME"
}

main
