#!/bin/bash

# 更新软件包列表并安装 certbot
apt update -y && apt install -y certbot

# 获取域名
read -p "请输入需要申请证书的域名（多个域名用空格分隔）：" domains

# 检查域名是否为空
if [ -z "$domains" ]; then
  echo "请输入域名！"
  exit 1
fi

# 循环处理每个域名
for domain in $domains; do
  # 去除域名两端的空格
  domain=$(echo $domain | sed 's/^\s+|\s+$//g')

  # 申请证书
  certbot certonly --standalone -d $domain --email you@email.com --agree-tos --no-eff-email --force-renewal

  # 检查证书是否申请成功
  if [ $? -ne 0 ]; then
    echo "申请证书失败：$domain"
    continue
  fi

  # 输出证书存放目录
  echo "证书存放目录：/etc/letsencrypt/live/$domain"

  # 复制证书文件到 /root/cert/ 目录
  mkdir -p /root/cert/
  cp /etc/letsencrypt/live/$domain/*.pem /root/cert/
done

# 下载自动续签脚本
if [ ! -f "auto_cert_renewal.sh" ]; then
  curl -O https://raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal-1.sh
fi

# 赋予自动续签脚本可执行权限
chmod +x auto_cert_renewal-1.sh

# 执行自动续签脚本
./auto_cert_renewal-1.sh

# 定时执行脚本
echo "0 0 * * * cd ~ && ./auto_cert_renewal.sh-1" | crontab -
