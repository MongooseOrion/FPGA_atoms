import socket
import time
import random
import string

def read_from_socket(host, port):
    
    try:
        # 连接到服务器
        udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udp_socket.bind((host, port))
        while True:
            data, addr = udp_socket.recvfrom(1024)
            print(f"received data: {data}")

    except KeyboardInterrupt:
        print(f"已结束")
    finally:
        # 关闭 socket
        udp_socket.close()
        print("Socket closed")


def send_random_bytes(host, port):
    # 创建一个 UDP socket
    udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    try:
        counter = 0
        while True:
            # 生成按顺序累加的字节数据
            sequential_data = bytes([(counter + i) % 256 for i in range(1024)])
            counter = (counter + 1024) % 256  # 更新计数器

            # 发送数据到指定的主机和端口
            udp_socket.sendto(sequential_data, (host, port))
            #print(f"Sent data: {random_data[:10]}...")  # 仅打印前10个字节以示例
            
            # 发送一次
            time.sleep(0.0005)
    
    except KeyboardInterrupt:
        print("已结束")
    finally:
        # 关闭 socket
        udp_socket.close()
        print("Socket closed")

if __name__ == "__main__":
    host = "192.168.0.2"  # 替换为服务器的主机名或 IP 地址
    port = 8080        # 替换为服务器的端口号
    #read_from_socket(host, port)
    send_random_bytes(host, port)