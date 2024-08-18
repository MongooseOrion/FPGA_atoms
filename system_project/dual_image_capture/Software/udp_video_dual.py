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
# UDP 将双目摄像头数据按前后帧编码传输，该文件解析为双目数据

import threading
import socket
import numpy as np
import cv2
import time


received_data = bytearray()
lock = threading.Lock()
exit_event = threading.Event()


# 接收数据
def udp_receive_data():
    global received_data
    UDP_IP = "192.168.0.3"  # 监听所有可用的网络接口
    UDP_PORT = 8080
    BUFFER_SIZE = 50000
    # 创建UDP套接字
    udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_socket.bind((UDP_IP, UDP_PORT))
    while not exit_event.is_set():
        # 接收数据 在使用共享数据之前先获取锁
        data, _ = udp_socket.recvfrom(BUFFER_SIZE)
        with lock:
            received_data += data
        if exit_event.is_set():
            break


# 显示图像
def cv_imshow():
    global received_data
    cmos1_marker = b"\xff\xa1\xff\xa1"
    cmos2_marker = b"\xff\xa2\xff\xa2"
    start_marker = b"\xff\xd8"
    end_marker = b"\xff\xd9"
    while not exit_event.is_set():
        time.sleep(0.0001)
        # 检查 cmos 通道标识符
        with lock: 
            cmos1_pos = received_data.find(cmos1_marker)
            cmos2_pos = received_data.find(cmos2_marker)
        
        if(cmos1_pos != -1):
            # 摄像头 1
            with lock:
                # 检查起始标识符
                start_pos_1 = received_data.find(start_marker, cmos1_pos + len(cmos1_marker))
            if start_pos_1 != -1:
                #time.sleep(0.0001)    #当检查到起始符后，要过一段时间结束符才会到来，暂停一小会防止程序卡死
                # 检查结束标识符
                with lock:
                    end_pos_1 = received_data.find(end_marker, start_pos_1 + len(start_marker))
                if end_pos_1 != -1:
                    with lock:
                        image_data_cam1 = received_data[start_pos_1 : end_pos_1+len(end_marker)]
                        received_data = received_data[end_pos_1 + len(end_marker):]  #清除已经显示信息
                    image_cam1 = np.frombuffer(image_data_cam1, dtype=np.uint8)
                    image_cam1 = cv2.imdecode(image_cam1, cv2.IMREAD_COLOR)
                    cv2.imshow("CMOS 1", image_cam1)
                    cv2.waitKey(1)
                    cmos1_pos = -1
                    start_pos_1 = -1
                    end_pos_1 = -1
        
        if(cmos2_pos != -1):
            # 摄像头 2
            with lock:
                start_pos_2 = received_data.find(start_marker, cmos2_pos + len(cmos2_marker))
            if start_pos_2 != -1:
                #time.sleep(0.0001)    #当检查到起始符后，要过一段时间结束符才会到来，暂停一小会防止程序卡死
                # 检查结束标识符
                with lock:
                    end_pos_2 = received_data.find(end_marker, start_pos_2 + len(start_marker))
                if end_pos_2 != -1:
                    with lock:
                        image_data_cam2 = received_data[start_pos_2 : end_pos_2+len(end_marker)]
                        received_data = received_data[end_pos_2 + len(end_marker):]  #清除已经显示信息
                    image_cam2 = np.frombuffer(image_data_cam2, dtype=np.uint8)
                    image_cam2 = cv2.imdecode(image_cam2, cv2.IMREAD_COLOR)
                    cv2.imshow("CMOS 2", image_cam2)
                    cv2.waitKey(1)  
                    cmos2_pos = -1
                    start_pos_2 = -1
                    end_pos_2 = -1

        if exit_event.is_set():
            break


# 创建
thread1 = threading.Thread(target=udp_receive_data)
thread2 = threading.Thread(target=cv_imshow)

# 启动线程
thread1.start()
thread2.start()

try:
    while not exit_event.is_set():
        time.sleep(0.1)
except KeyboardInterrupt:
    exit_event.set()
    print("Exit event set by KeyboardInterrupt")

# 等待两个线程执行完毕
thread1.join()
thread2.join()

print("Main thread exiting.")
