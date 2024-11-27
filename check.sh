#!/bin/bash

# 打印空投摘要
print_airdrop_summary() {
    wallet_address="$1"
    data="$2"

    echo "查询地址: $wallet_address"
    echo "查询结果:"

    # 输出每个项目的详细信息
    echo "$data" | jq -c '. | to_entries[] | .value' | while read -r project; do
        # 判断数据类型，如果是对象类型则处理
        if echo "$project" | jq -e 'type == "object"' >/dev/null 2>&1; then
            # 如果是对象，处理它
            project_id=$(echo "$project" | jq -r '.id // "-"')
            points=$(echo "$project" | jq -r '.points // "-"')
            tokens=$(echo "$project" | jq -r '.tokens // "-"')
            isClaimed=$(echo "$project" | jq -r '.isClaimed // "null"')

            # 输出积分和代币数量
            echo "  项目: $project_id"
            echo "    积分: $points"
            echo "    代币数量: $tokens"
            echo "    是否已领取: $isClaimed"
            echo "-------------------------------"
        fi
        # 如果不是对象类型，什么也不做（即跳过）
    done

    # 计算并输出总项目数
    total_count=$(echo "$data" | jq -r '.count // 0')
    echo "总计项目数: $total_count"
    echo "=================================================="
}

# 查询空投信息
check_airdrop() {
    wallet_address="$1"
    url="https://checkdrop.byzantine.fi/api/getDatas"

    response=$(curl -s -G --data-urlencode "address=$wallet_address" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$url")

    if [ $? -ne 0 ]; then
        echo "地址 $wallet_address 查询失败: 网络请求失败"
        return
    fi

    # 直接获取原始 JSON 数据
    data="$response"

    # 验证返回是否是合法 JSON 数据
    if ! echo "$data" | jq . >/dev/null 2>&1; then
        echo "地址 $wallet_address 查询失败: 返回数据不是合法 JSON 格式"
        return
    fi

    # 输出查询结果，但不打印原始JSON数据
    print_airdrop_summary "$wallet_address" "$data"
}

# 主函数
main() {
    echo "输入查询的EVM地址，多个地址请隔行分开！（按两次ENTER确认）:"

    # 使用数组来存储地址
    addresses=()
    while read -r address; do
        [[ -z "$address" ]] && break  # 空行结束输入
        addresses+=("$address")
    done

    if [ ${#addresses[@]} -eq 0 ]; then
        echo "未输入任何地址，请重新运行脚本。"
        exit 1
    fi

    echo "共输入了 ${#addresses[@]} 个地址，开始查询..."

    # 为每个地址分别查询空投数据并将结果保存到一个变量
    for address in "${addresses[@]}"; do
        check_airdrop "$address"
    done
}

# 调用主函数
main
