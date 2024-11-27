import sys
import requests
from concurrent.futures import ThreadPoolExecutor

# 打印空投摘要
def print_airdrop_summary(wallet_address, data):
    print(f"查询地址: {wallet_address}")
    print("查询结果:")
    for project, info in data.items():
        if project != 'count':  # 排除总计字段
            print(f"  项目: {info['id']}")
            print(f"    积分: {info['points']}")
            print(f"    代币数量: {info['tokens']}")
            print("-------------------------------")
    print(f"总计项目数: {data.get('count', 0)}")
    print("=" * 50)

# 查询空投信息
def check_airdrop(wallet_address):
    url = "https://checkdrop.byzantine.fi/api/getDatas"
    payload = {"address": wallet_address}
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    }

    try:
        response = requests.get(url, params=payload, headers=headers)
        response.raise_for_status()
        data = response.json()
        print_airdrop_summary(wallet_address, data)
    except requests.exceptions.RequestException as e:
        print(f"地址 {wallet_address} 查询失败: {e}")
    except ValueError:
        print(f"地址 {wallet_address} 的返回数据无法解析为 JSON 格式。")
    except Exception as e:
        print(f"地址 {wallet_address} 查询发生意外错误: {e}")

# 主函数
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python check_airdrop.py <钱包地址 | txt 文件路径>")
    else:
        input_arg = sys.argv[1]

        # 如果输入是文件路径
        if input_arg.endswith(".txt"):
            try:
                with open(input_arg, "r") as file:
                    addresses = [line.strip() for line in file if line.strip()]
                if not addresses:
                    print("文件为空或未包含有效的钱包地址。")
                else:
                    print(f"从文件加载了 {len(addresses)} 个地址，开始查询...")
                    # 使用多线程查询多个地址
                    with ThreadPoolExecutor() as executor:
                        executor.map(check_airdrop, addresses)
            except FileNotFoundError:
                print(f"文件 {input_arg} 不存在，请检查路径。")
            except Exception as e:
                print(f"读取文件时发生错误: {e}")
        else:
            # 如果输入是单个地址
            check_airdrop(input_arg)
