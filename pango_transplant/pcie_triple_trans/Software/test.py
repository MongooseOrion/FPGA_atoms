import os
import struct
import threading
import numpy as np
import wave
import time

FIFO_PATH = "adc_fifo"  # 替换为你的 FIFO 路径
WAV_FILE = "output.wav"         # 保存的 WAV 文件名
stop_event = threading.Event()

def read_audio_data():
    with open(FIFO_PATH, "rb") as fifo, wave.open(WAV_FILE, 'wb') as wf:
        wf.setnchannels(1)  # 单声道
        wf.setsampwidth(2)  # 16 位
        wf.setframerate(48000)  # 采样率 48000 Hz
        
        print("Reading from FIFO and writing to WAV...")
        while not stop_event.is_set():
            data = fifo.read(16384)  # 每次读取 16384 字节
            if data:
                num_samples = len(data) // 2  # 每个样本 2 字节
                audio_samples = struct.unpack('<' + 'h' * num_samples, data)
                
                # 写入 WAV 文件
                wf.writeframes(data)

def main():
    reader_thread = threading.Thread(target=read_audio_data)
    reader_thread.start()

    try:
        while True:
            time.sleep(1)  # 主线程可以做其他事情
    except KeyboardInterrupt:
        stop_event.set()
        reader_thread.join()
        print("Stopped saving audio.")

if __name__ == "__main__":
    main()
