''' ======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: UTF-8
* ========================================================================
'''
# 将 UDP 传入的音频数据回环发送至开发板
#
'''
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: UTF-8
* ========================================================================
'''
# 将 UDP 传入的音频数据回环发送至开发板
#
import socket
import threading
import time

# 创建锁
lock = threading.Lock()

# 参数设置
sample_rate = 48000
buf_size = 1024
destinate_ip_addr = '192.168.0.2'
source_ip_addr = '192.168.0.3'
port = 8080
udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# 接收数据
def read_from_socket():
    global recv_data
    try:
        # 绑定到源地址和端口
        udp_socket.bind((source_ip_addr, port))
        while True:
            data, addr = udp_socket.recvfrom(buf_size)
            with lock:
                recv_data += data
    except Exception as e:
        print(f"Error receiving data: {e}")

# 发送数据
def send_to_socket():
    global recv_data
    try:
        data_to_send = b''
        while True:
            with lock:
                if len(recv_data) > 1024:
                    data_to_send = recv_data[:1024]  
                    recv_data = recv_data[1024:]     # 移除已发送的数据
            if data_to_send:
                udp_socket.sendto(data_to_send, (destinate_ip_addr, port))
                data_to_send = b''
    except Exception as e:
        print(f"Error sending data: {e}")

if __name__ == "__main__":
    recv_data = b''

    # 创建接收线程
    recv_thread = threading.Thread(target=read_from_socket)
    recv_thread.daemon = True
    recv_thread.start()

    # 创建发送线程
    send_thread = threading.Thread(target=send_to_socket)
    send_thread.daemon = True
    send_thread.start()

    # 保持主线程运行
    try:
        while True:
            time.sleep(0.1)
    except KeyboardInterrupt:
        print("已结束")