import cv2
import time

# 打开虚拟摄像头
cap = cv2.VideoCapture('/dev/video0')

# 检查摄像头是否打开成功
if not cap.isOpened():
    print("无法打开摄像头")
    exit()

# 初始化计数器
frame_count = 0
fps = 0
start_time = time.time()

while True:
    # 读取一帧图像
    ret, frame = cap.read()
    
    if not ret:
        print("无法接收帧 (流结束？)")
        break
    
    frame_count += 1

    # 每60帧计算一次FPS
    if frame_count % 60 == 0:
        elapsed_time = time.time() - start_time
        fps = 60 / elapsed_time
        start_time = time.time()  # 重置时间计数器

    # 在帧上显示帧率
    cv2.putText(frame, f'FPS: {fps:.2f}', (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # 显示图像
    cv2.imshow('Frame', frame)

    # 按下 'q' 键退出
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# 释放摄像头和关闭窗口
cap.release()
cv2.destroyAllWindows()
