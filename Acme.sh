#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#添加一些基本函数
function LOGD() {
    echo -e "${yellow}[提示] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[错误] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[信息] $* ${plain}"
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认 $2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

ssl_cert_issue_CF() {
    echo -E ""
    LOGD "******使用说明******"
    LOGI "本 Acme 脚本需要以下数据:"
    LOGI "1.Cloudflare 注册邮箱"
    LOGI "2.Cloudflare 全局 API 密钥"
    LOGI "3.已由 Cloudflare 解析到当前服务器的域名"
    LOGI "4.脚本将申请证书,默认安装路径为 /root/cert"
    confirm "确认继续吗?[y/n]" "y"
    if [ $? -eq 0 ]; then
        # 首先检查 acme.sh
        if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
            echo "未找到 acme.sh, 将进行安装"
            install_acme
            if [ $? -ne 0 ]; then
                LOGE "安装 acme 失败, 请检查日志"
                exit 1
            fi
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        LOGD "请设置域名:"
        read -p "输入域名:" CF_Domain
        LOGD "您设置的域名为:${CF_Domain}"
        LOGD "请设置 API 密钥:"
        read -p "输入 API 密钥:" CF_GlobalKey
        LOGD "您的 API 密钥是:${CF_GlobalKey}"
        LOGD "请设置注册邮箱:"
        read -p "输入邮箱地址:" CF_AccountEmail
        LOGD "您的注册邮箱是:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "设置默认 CA Lets'Encrypt 失败, 脚本退出..."
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "证书签发失败, 脚本退出..."
            exit 1
        else
            LOGI "证书签发成功, 正在安装..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
            --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
            --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "证书安装失败, 脚本退出..."
            exit 1
        else
            LOGI "证书安装成功,正在启用自动更新..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "设置自动更新失败, 脚本退出..."
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            LOGI "证书已安装并启用自动更新, 具体信息如下:"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}

# 运行ssl_cert_issue_CF函数
ssl_cert_issue_CF
