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
# 将 PC 的声音通过 UDP 传输到 FPGA 板卡上
import socket
import time
import pyaudio
import sounddevice as sd

# 创建实例
p = pyaudio.PyAudio()

# 配置参数
sample_rate = 48000
blocksize = 512
ip_addr = '192.168.0.2'
port = 8080
udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def send_system_audio():
    try:
        def callback(indata, frames, time, status):
            if status:
                print(status)
            # 将音频数据发送到指定的主机和端口
            udp_socket.sendto(indata.tobytes(), (ip_addr, port))

        # 使用 sounddevice 捕获系统音频
        with sd.InputStream(samplerate=sample_rate, blocksize=blocksize, channels=1, dtype='int16', callback=callback):
            print("开始捕获系统音频...")
            while True:
                time.sleep(0.1)
    
    except KeyboardInterrupt:
        print("已结束")
    finally:
        # 关闭 socket
        udp_socket.close()
        print("Socket closed")


def send_microphone():
    # 接管电脑麦克风
    stream = p.open(format=pyaudio.paInt16, channels=1, rate=sample_rate, input=True, frames_per_buffer=blocksize)
    # 将数据流发送至 FPGA 板卡
    try:
        while True:
            data = stream.read(blocksize)
            udp_socket.sendto(data, (ip_addr, port))
    except KeyboardInterrupt:
        print("已结束")
    finally:
        # 关闭 socket
        udp_socket.close()
        print("Socket closed")
        stream.stop_stream()
        stream.close()
        p.terminate()
        print("PyAudio terminated")


if __name__ == "__main__":
    #send_system_audio()
    send_microphone()