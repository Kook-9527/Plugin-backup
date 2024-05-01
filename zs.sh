#!/bin/bash

# 安装 acme.sh
curl https://get.acme.sh | sh

# 输入你的域名
read -p "请输入你的域名: " domain

# 输入你的邮箱
read -p "请输入你的邮箱: " email

# 安装证书
/root/.acme.sh/acme.sh --issue --dns dns_cf -d $domain -d *.$domain --yes-I-know-dns-manual-mode-enough-go-ahead-please --force --debug 2

# 安装证书到指定位置
/root/.acme.sh/acme.sh --install-cert -d $domain \
    --key-file /root/cert/key.pem \
    --fullchain-file /root/cert/fullchain.pem \
    --force

# 赋予证书文件权限
chmod 600 /root/cert/*.pem

# 设置定时任务
crontab -l | { cat; echo "17 21 * * * \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" > /dev/null"; } | crontab -

# 重启你的服务
# systemctl restart your_service