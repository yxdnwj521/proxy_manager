#!/bin/bash

# 配置文件路径
CONFIG_FILE="$HOME/.proxy_manager_config"
# 日志文件路径
LOG_FILE="$HOME/.proxy_manager.log"
# 统计文件路径
STATS_FILE="$HOME/.proxy_manager_stats"

# 日志级别
LOG_LEVEL_INFO="INFO"
LOG_LEVEL_WARN="WARN"
LOG_LEVEL_ERROR="ERROR"

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "\033[1;32m已加载上次的代理设置\033[0m"
        show_proxy
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# 代理服务器配置
PROXY_HOST="$PROXY_HOST"
PROXY_PORT="$PROXY_PORT"
EOF
    echo -e "\033[1;32m代理设置已保存\033[0m"
}

# 清理函数
cleanup() {
    echo -e "\n\033[1;33m正在清理代理设置...\033[0m"
    unset_proxy
    save_config
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

# 写入日志
write_log() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 更新统计信息
update_stats() {
    local action=$1
    local current_date=$(date "+%Y-%m-%d")
    
    # 读取现有统计
    if [ -f "$STATS_FILE" ]; then
        source "$STATS_FILE"
    else
        declare -A proxy_usage
        declare -A test_results
        declare -A last_used
    fi
    
    # 更新统计
    case "$action" in
        "start")
            proxy_usage[$current_date]=$((proxy_usage[$current_date] + 1))
            last_used["last_start"]=$(date "+%Y-%m-%d %H:%M:%S")
            ;;
        "stop")
            last_used["last_stop"]=$(date "+%Y-%m-%d %H:%M:%S")
            ;;
        "test_success")
            test_results["success"]=$((test_results["success"] + 1))
            ;;
        "test_fail")
            test_results["fail"]=$((test_results["fail"] + 1))
            ;;
    esac
    
    # 保存统计
    {
        echo "# 代理使用统计"
        echo "declare -A proxy_usage"
        for date in "${!proxy_usage[@]}"; do
            echo "proxy_usage[$date]=${proxy_usage[$date]}"
        done
        echo
        echo "declare -A test_results"
        for result in "${!test_results[@]}"; do
            echo "test_results[$result]=${test_results[$result]}"
        done
        echo
        echo "declare -A last_used"
        for key in "${!last_used[@]}"; do
            echo "last_used[$key]='${last_used[$key]}'"
        done
    } > "$STATS_FILE"
}

# 显示日志
show_logs() {
    local lines=${1:-10}  # 默认显示最后10行
    echo -e "\033[1;36m=== 最近 $lines 条日志 ===\033[0m"
    if [ -f "$LOG_FILE" ]; then
        tail -n "$lines" "$LOG_FILE" | while read -r line; do
            if [[ $line == *"ERROR"* ]]; then
                echo -e "\033[1;31m$line\033[0m"
            elif [[ $line == *"WARN"* ]]; then
                echo -e "\033[1;33m$line\033[0m"
            else
                echo -e "\033[1;32m$line\033[0m"
            fi
        done
    else
        echo "暂无日志记录"
    fi
}

# 显示统计信息
show_stats() {
    echo -e "\033[1;36m=== 代理使用统计 ===\033[0m"
    if [ -f "$STATS_FILE" ]; then
        source "$STATS_FILE"
        
        echo -e "\n\033[1;33m使用频率统计：\033[0m"
        for date in "${!proxy_usage[@]}"; do
            echo "$date: 使用 ${proxy_usage[$date]} 次"
        done
        
        echo -e "\n\033[1;33m连接测试统计：\033[0m"
        echo "成功: ${test_results["success"]:-0} 次"
        echo "失败: ${test_results["fail"]:-0} 次"
        
        echo -e "\n\033[1;33m最近使用记录：\033[0m"
        echo "最后启动: ${last_used["last_start"]:-"无记录"}"
        echo "最后关闭: ${last_used["last_stop"]:-"无记录"}"
    else
        echo "暂无统计信息"
    fi
}

# 清理日志
clean_logs() {
    if [ -f "$LOG_FILE" ]; then
        read -p "确定要清空所有日志记录吗？(y/n) " confirm
        if [ "$confirm" = "y" ]; then
            rm "$LOG_FILE"
            echo -e "\033[1;32m日志已清空\033[0m"
            write_log "$LOG_LEVEL_INFO" "日志文件已清空"
        fi
    fi
}

# 清理统计
clean_stats() {
    if [ -f "$STATS_FILE" ]; then
        read -p "确定要清空所有统计信息吗？(y/n) " confirm
        if [ "$confirm" = "y" ]; then
            rm "$STATS_FILE"
            echo -e "\033[1;32m统计信息已清空\033[0m"
            write_log "$LOG_LEVEL_INFO" "统计信息已清空"
        fi
    fi
}

# 测试代理连接
test_connection() {
    echo -e "\033[1;33m正在测试代理连接...\033[0m"
    write_log "$LOG_LEVEL_INFO" "开始测试代理连接"
    
    # 检查是否设置了代理
    if [ -z "$http_proxy" ]; then
        echo -e "\033[1;31m错误：代理未设置\033[0m"
        write_log "$LOG_LEVEL_ERROR" "测试失败：代理未设置"
        update_stats "test_fail"
        return 1
    fi
    
    # 使用curl测试连接
    echo "测试连接 Google..."
    if curl -s --connect-timeout 5 --proxy "$http_proxy" https://www.google.com > /dev/null; then
        echo -e "\033[1;32m✓ 代理连接测试成功！\033[0m"
        write_log "$LOG_LEVEL_INFO" "代理连接测试成功"
        update_stats "test_success"
        return 0
    else
        echo -e "\033[1;31m✗ 代理连接测试失败\033[0m"
        write_log "$LOG_LEVEL_ERROR" "代理连接测试失败"
        update_stats "test_fail"
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
    write_log "$LOG_LEVEL_INFO" "代理已设置: $PROXY_HOST:$PROXY_PORT"
    update_stats "start"
    show_proxy
    save_config
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
    write_log "$LOG_LEVEL_INFO" "代理已清除"
    update_stats "stop"
    show_proxy
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
            save_config
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
            save_config
            show_proxy
        else
            echo -e "\033[1;31m错误：无效的端口号\033[0m"
            echo "端口号必须是1-65535之间的数字"
        fi
    else
        echo "端口不能为空"
    fi
}

# 重置配置
reset_config() {
    if [ -f "$CONFIG_FILE" ]; then
        rm "$CONFIG_FILE"
        echo -e "\033[1;32m已清除保存的代理设置\033[0m"
    fi
    PROXY_HOST="192.168.1.100"
    PROXY_PORT="8080"
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
    echo "/9 或 /logs - 显示最近日志"
    echo "/10 或 /stats - 显示使用统计"
    echo "/11 或 /clean_logs - 清理日志"
    echo "/12 或 /clean_stats - 清理统计"
    echo "/help 或 /? - 显示此帮助信息"
    echo "/reset - 重置代理设置（清除保存的配置）"
}

# 主循环
show_ftee
echo "欢迎使用代理管理工具"
write_log "$LOG_LEVEL_INFO" "代理管理工具启动"

# 加载上次的配置
load_config

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
            save_config
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
        "/9"|"/logs")
            show_logs
            ;;
        "/10"|"/stats")
            show_stats
            ;;
        "/11"|"/clean_logs")
            clean_logs
            ;;
        "/12"|"/clean_stats")
            clean_stats
            ;;
        "/reset")
            reset_config
            ;;
        "/?"|"/help")
            show_help
            ;;
        *)
            echo "未知命令，输入 /? 查看帮助"
            ;;
    esac
done 