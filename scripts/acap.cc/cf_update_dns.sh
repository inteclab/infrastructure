#!/usr/bin/env bash

# 检查必要的环境变量
if [ -z "$CLOUDFLARE_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ] || [ -z "$DOMAIN" ]; then
    echo "错误: 必须设置环境变量 CLOUDFLARE_TOKEN, CLOUDFLARE_ZONE_ID, DOMAIN"
    echo "请使用以下命令设置环境变量："
    echo "export CLOUDFLARE_TOKEN='your_api_token'"
    echo "export CLOUDFLARE_ZONE_ID='your_zone_id'"
    echo "export DOMAIN='xxxx.com'"
    exit 1
fi

# 配置参数
RECORDS="ui,hub,gcr,ghcr,k8sgcr,k8s,quay,mcr,elastic,nvcr,uptime,v"
AUTO_INSTALL=true
TTL="1"
PROXY="false"


# 更新单个DNS记录的函数
update_dns_record() {
    local subdomain=$1
    local record_name="${subdomain}.${DOMAIN}"

    # 获取当前公网 IP
    CURRENT_IP=$(curl -s http://ipv4.icanhazip.com)

    # 获取已存在的 DNS 记录
    RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?type=A&name=$record_name" \
         -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
         -H "Content-Type: application/json")

    # 提取记录 ID 和已存在的 IP
    RECORD_ID=$(echo $RECORD | jq -r '.result[0].id')
    EXISTING_IP=$(echo $RECORD | jq -r '.result[0].content')

    # 如果记录不存在，创建新记录
    if [ "$RECORD_ID" = "null" ]; then
        echo "创建新记录: $record_name"
        CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
             -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
             -H "Content-Type: application/json" \
             --data "{\"content\":\"${CURRENT_IP}\",\"name\":\"${record_name}\",\"proxied\":${PROXY},\"type\":\"A\",\"ttl\":${TTL}}")

        if [ "$(echo $CREATE_RESPONSE | jq -r '.success')" = "true" ]; then
            echo "DNS 记录创建成功: $record_name -> $CURRENT_IP"
        else
            echo "DNS 记录创建失败: $record_name"
            echo $CREATE_RESPONSE
        fi
        return
    fi

    # 如果 IP 没有变化，跳过更新
    if [ "$CURRENT_IP" = "$EXISTING_IP" ]; then
        echo "IP 没有变化，跳过更新: $record_name"
        return
    fi

    # 更新现有记录
    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
         -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
         -H "Content-Type: application/json" \
         --data "{\"content\":\"${CURRENT_IP}\",\"name\":\"${record_name}\",\"proxied\":${PROXY},\"type\":\"A\",\"ttl\":${TTL}}")

    if [ "$(echo $UPDATE_RESPONSE | jq -r '.success')" = "true" ]; then
        echo "DNS 记录更新成功: $record_name -> $CURRENT_IP"
    else
        echo "DNS 记录更新失败: $record_name"
        echo $UPDATE_RESPONSE
    fi
}

# 更新所有DNS记录的函数
update_all_dns_records() {
    echo "开始更新 DNS 记录..."
    RECORDS="git,$RECORDS"
    IFS=',' read -ra SUBDOMAIN_ARRAY <<< "$RECORDS"
    for subdomain in "${SUBDOMAIN_ARRAY[@]}"; do
        update_dns_record "$subdomain"
    done
    echo "DNS 记录更新完成"
}


# 主函数
main() {

    echo "开始配置 Cloudflare DNS..."
    update_all_dns_records

}

# 执行主函数
main "$@"