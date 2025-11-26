import cv2
import os
import time
import pandas as pd

df = pd.read_excel('cgi.xlsx')
ip_list = df.iloc[:, 0].tolist()

save_path = 'screens'

if not os.path.exists(save_path):
    os.makedirs(save_path)

username = 'admin'
password = input('Enter password: ')

for ip in ip_list:
    rtsp_url_1 = f'rtsp://{username}:{password}@{ip}/cam/realmonitor?channel=1&subtype=1'
    rtsp_url_2 = f'rtsp://{username}:{password}@{ip}:554/ISAPI/Streaming/Channels/102'

    cap = cv2.VideoCapture(rtsp_url_1)

    if not cap.isOpened():
        print(f'Error: Could not connect to RTSP stream 1 for {ip}. Trying RTSP stream 2.')
        cap = cv2.VideoCapture(rtsp_url_2)

    if not cap.isOpened():
        print(f'Error: Could not connect to RTSP stream 2 for {ip}. Skipping this IP.')
        continue

    ret, frame = cap.read()
    if not ret:
        print(f'Error: Could not retrieve frame for {ip}.')
        cap.release()
        continue

    timestamp = time.strftime('%Y%m%d_%H%M%S')
    filename = os.path.join(save_path, f'{ip}_{timestamp}.jpg')

    cv2.imwrite(filename, frame)
    print(f'Screenshot saved for {ip}: {filename}')

    cap.release()

print('Process completed.')
