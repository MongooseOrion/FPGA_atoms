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
# 将 UDP 传入的音频数据编码播放

def audio_play(RATE = 48000):
    '''
    将 UDP 传输的音频数据编码并播放。

    参数：
    RATE : int
        采样率

    输出：
        NULL
    '''
    import pyaudio
    import socket

    # 初始化PyAudio
    p = pyaudio.PyAudio()

    # 设置音频参数
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    CHUNK = 1024  # 每次读取的音频数据大小

    # 设置 UDP 参数
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080

    # 创建UDP套接字
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    print("接收 UDP 音频数据并播放...")

    # 接收并播放音频数据
    try:
        stream = p.open(format=FORMAT,
                        channels=CHANNELS,
                        rate=RATE,
                        output=True,
                        frames_per_buffer=CHUNK)

        # 持续接收，直到接收到带有起始标识符的数据包
        while True:
            data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据

            stream.write(data)  # 播放音频数据

    except KeyboardInterrupt:
        print("接收停止。")

    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()
        sock.close()


audio_play()