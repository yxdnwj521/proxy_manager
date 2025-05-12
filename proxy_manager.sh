#!/bin/bash

# 清理函数
cleanup() {
    echo -e "\n\033[1;33m正在清理代理设置...\033[0m"
    unset_proxy
    echo -e "\033[1;32m代理已安全关闭\033[0m"
    exit 0
}

# 注册信号处理
trap cleanup SIGINT SIGTERM SIGHUP

# 显示FTEE标志
show_ftee() {
    clear
    echo -e "\033[1;36m"  # 设置青色
    cat << "EOF"
███████╗████████╗███████╗███████╗
██╔════╝╚══██╔══╝██╔════╝██╔════╝
█████╗     ██║   █████╗  █████╗  
██╔══╝     ██║   ██╔══╝  ██╔══╝  
██║        ██║   ███████╗███████╗
╚═╝        ╚═╝   ╚══════╝╚══════╝
EOF
    echo -e "\033[0m"  # 重置颜色
}

# 代理服务器配置
PROXY_HOST="192.168.1.100"  # 默认代理服务器地址
PROXY_PORT="8080"           # 默认代理端口

# 显示当前代理设置
show_proxy() {
    echo "当前系统代理设置："
    echo "HTTP_PROXY: $HTTP_PROXY"
    echo "HTTPS_PROXY: $HTTPS_PROXY"
    echo "http_proxy: $http_proxy"
    echo "https_proxy: $https_proxy"
    echo "当前代理地址: $PROXY_HOST:$PROXY_PORT"
}

# 测试代理连接
test_connection() {
    echo -e "\033[1;33m正在测试代理连接...\033[0m"
    
    # 检查是否设置了代理
    if [ -z "$http_proxy" ]; then
        echo -e "\033[1;31m错误：代理未设置\033[0m"
        return 1
    fi
    
    # 使用curl测试连接
    echo "测试连接 Google..."
    if curl -s --connect-timeout 5 --proxy "$http_proxy" https://www.google.com > /dev/null; then
        echo -e "\033[1;32m✓ 代理连接测试成功！\033[0m"
        return 0
    else
        echo -e "\033[1;31m✗ 代理连接测试失败\033[0m"
        return 1
    fi
}

# 设置代理
set_proxy() {
    echo "设置代理"
    export http_proxy="http://$PROXY_HOST:$PROXY_PORT"
    export https_proxy="http://$PROXY_HOST:$PROXY_PORT"
    export HTTP_PROXY="http://$PROXY_HOST:$PROXY_PORT"
    export HTTPS_PROXY="http://$PROXY_HOST:$PROXY_PORT"
    
    # 设置系统代理
    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings set org.gnome.system.proxy.http host "$PROXY_HOST"
    gsettings set org.gnome.system.proxy.http port "$PROXY_PORT"
    gsettings set org.gnome.system.proxy.https host "$PROXY_HOST"
    gsettings set org.gnome.system.proxy.https port "$PROXY_PORT"
    
    echo "代理已设置"
    show_proxy
    test_connection
}

# 清除代理
unset_proxy() {
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    
    # 清除系统代理
    gsettings set org.gnome.system.proxy mode 'none'
    
    echo "代理已清除"
    show_proxy
}

# 显示帮助信息
show_help() {
    echo "代理管理工具使用说明："
    echo "/1 或 /start - 开启代理"
    echo "/2 或 /close - 关闭代理"
    echo "/3 或 /change_http - 更换代理地址"
    echo "/4 或 /change_port - 更换代理端口"
    echo "/5 或 /show - 显示当前代理设置"
    echo "/6 或 /clear - 清除屏幕并重新显示"
    echo "/7 或 /test - 测试代理连接"
    echo "/8 或 /exit - 退出程序"
    echo "/help 或 /? - 显示此帮助信息"
}

# 验证和格式化代理地址
validate_and_format_host() {
    local input=$1
    local formatted_host=""
    
    # 移除协议前缀（如果存在）
    input=$(echo "$input" | sed -E 's/^(https?:\/\/)?(.*)/\2/')
    
    # 移除末尾的斜杠（如果存在）
    input=$(echo "$input" | sed 's/\/$//')
    
    # 检查是否是有效的IP地址
    if [[ $input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # 验证IP地址的每个部分是否在有效范围内
        IFS='.' read -r -a ip_parts <<< "$input"
        local valid_ip=1
        for part in "${ip_parts[@]}"; do
            if [ "$part" -gt 255 ] || [ "$part" -lt 0 ]; then
                valid_ip=0
                break
            fi
        done
        if [ $valid_ip -eq 1 ]; then
            formatted_host=$input
        fi
    # 检查是否是有效的域名或URL
    elif [[ $input =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*(\.[a-zA-Z0-9][a-zA-Z0-9-]*)*$ ]]; then
        formatted_host=$input
    fi
    
    echo "$formatted_host"
}

# 更换代理地址
change_http() {
    read -p "请输入新的代理地址 (支持IP、域名或URL): " new_host
    if [ ! -z "$new_host" ]; then
        local formatted_host=$(validate_and_format_host "$new_host")
        if [ ! -z "$formatted_host" ]; then
            PROXY_HOST=$formatted_host
            echo "代理地址已更新为: $PROXY_HOST"
            show_proxy
        else
            echo -e "\033[1;31m错误：无效的地址格式\033[0m"
            echo "支持的格式："
            echo "- IP地址 (例如: 192.168.1.100)"
            echo "- 域名 (例如: proxy.example.com)"
            echo "- URL (例如: http://proxy.example.com)"
        fi
    else
        echo "地址不能为空"
    fi
}

# 更换代理端口
change_port() {
    read -p "请输入新的代理端口: " new_port
    if [ ! -z "$new_port" ]; then
        # 验证端口号是否有效
        if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -ge 1 ] && [ $new_port -le 65535 ]; then
            PROXY_PORT=$new_port
            echo "代理端口已更新为: $PROXY_PORT"
            show_proxy
        else
            echo -e "\033[1;31m错误：无效的端口号\033[0m"
            echo "端口号必须是1-65535之间的数字"
        fi
    else
        echo "端口不能为空"
    fi
}

# 主循环
show_ftee
echo "欢迎使用代理管理工具"

# 启用命令历史记录
HISTFILE=~/.proxy_manager_history
HISTSIZE=1000
HISTFILESIZE=2000
set -o history

while true; do
    echo -e "\n请输入命令:"
    read -e -p "> " cmd

    case "$cmd" in
        "/1"|"/start")
            set_proxy
            ;;
        "/2"|"/close")
            unset_proxy
            ;;
        "/3"|"/change_http")
            change_http
            ;;
        "/4"|"/change_port")
            change_port
            ;;
        "/5"|"/show")
            show_proxy
            ;;
        "/6"|"/clear")
            show_ftee
            ;;
        "/7"|"/test")
            test_connection
            ;;
        "/8"|"/exit")
            cleanup
            ;;
        "/?"|"/help")
            show_help
            ;;
        *)
            echo "未知命令，输入 /? 查看帮助"
            ;;
    esac
done 