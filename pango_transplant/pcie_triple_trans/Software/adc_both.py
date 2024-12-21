import os
import struct
import threading
import numpy as np
import pyaudio
import queue
import time

FIFO_PATH = "adc_fifo"  # 替换为你的 FIFO 路径
audio_queue = queue.Queue(maxsize=10)  # 设置最大队列大小
stop_event = threading.Event()

def read_audio_data():
    with open(FIFO_PATH, "rb") as fifo:
        print("Reading from FIFO...")
        while not stop_event.is_set():
            data = fifo.read(16384)  # 逐步读取数据
            if data:
                num_samples = len(data) // 4  # 每个样本4字节（2字节右声道 + 2字节左声道）
                audio_samples = struct.unpack('<' + 'hh' * num_samples, data)  # 每个样本包含左右声道
                print(audio_samples[:10])
                if not stop_event.is_set():
                    try:
                        audio_queue.put(audio_samples, timeout=1)  # 将音频数据放入队列
                    except queue.Full:
                        continue  # 如果队列满，继续循环

def play_audio():
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16, channels=2, rate=48000, output=True)

    while not stop_event.is_set():
        try:
            audio_samples = audio_queue.get(timeout=1)
            audio_array = np.array(audio_samples, dtype=np.int16)
            stream.write(audio_array.tobytes())  # 将音频数据写入流
            audio_queue.task_done()
        except queue.Empty:
            continue

    stream.stop_stream()
    stream.close()
    p.terminate()

def main():
    reader_thread = threading.Thread(target=read_audio_data)
    player_thread = threading.Thread(target=play_audio)

    reader_thread.start()
    player_thread.start()

    try:
        while True:
            time.sleep(1)  # 主线程可以做其他事情
    except KeyboardInterrupt:
        stop_event.set()
        reader_thread.join()
        audio_queue.join()  # 确保队列中的数据处理完成
        player_thread.join()
        print("Stopped playback.")

if __name__ == "__main__":
    main()
