#!/usr/bin/python3

import numpy as np
import serial
from simple_pid import PID
import time

serial_port = '/dev/ttyUSB0'
baud_rate = 115200
serial_connection = serial.Serial(serial_port, baud_rate)

TOUCHSCREEN_WIDTH = 225.0
TOUCHSCREEN_HEIGHT = 171.5
ball_x = 0.0
ball_y = 0.0

BASE_ANGLES = np.array([-50.0, -70.0, -170.0, -190.0, -290.0, -310.0])
PLATFORM_ANGLES = np.array([-54.0, -66.0, -174.0, -186.0, -294.0, -306.0])
BETA = np.array([np.pi / 6, -5 * np.pi / 6, -np.pi / 2, np.pi / 2, 5 * np.pi / 6, -np.pi / 6])
BASE_RADIUS = 76.0
PLATFORM_RADIUS = 60.0
HORN_LENGTH = 40.0
ROD_LENGTH = 130.0
INITIAL_HEIGHT = 120.28183632
  
b = np.array([[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]])
p = np.array([[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]])
q = np.array([[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]])
l = np.array([[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]])
alpha = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        
T = np.array([0.0, 0.0, 0.0])
R = np.array([0.0, 0.0, 0.0])
initial_height = np.array([0.0, 0.0, INITIAL_HEIGHT])

def initialize_platform():
    for i in range(6):
        xb = BASE_RADIUS * np.cos(np.radians(BASE_ANGLES[i]))
        yb = BASE_RADIUS * np.sin(np.radians(BASE_ANGLES[i]))
        b[i] = [xb, yb, 0]
        px = PLATFORM_RADIUS * np.cos(np.radians(PLATFORM_ANGLES[i]))
        py = PLATFORM_RADIUS * np.sin(np.radians(PLATFORM_ANGLES[i]))
        p[i] = [px, py, 0]

def calculate_angle_alpha():
    for i in range(6):
        q[i][0] = np.cos(R[2]) * np.cos(R[1]) * p[i][0] + (-np.sin(R[2]) * np.cos(R[0]) + np.cos(R[2]) * np.sin(R[1]) * np.sin(R[0])) * p[i][1] + (np.sin(R[2]) * np.sin(R[0]) + np.cos(R[2]) * np.sin(R[1]) * np.cos(R[0])) * p[i][2]
        q[i][1] = np.sin(R[2]) * np.cos(R[1]) * p[i][0] + (np.cos(R[2]) * np.cos(R[0]) + np.sin(R[2]) * np.sin(R[1]) * np.sin(R[0])) * p[i][1] + (-np.cos(R[2]) * np.sin(R[0]) + np.sin(R[2]) * np.sin(R[1]) * np.cos(R[0])) * p[i][2]
        q[i][2] = -np.sin(R[1]) * p[i][0] + np.cos(R[1]) * np.sin(R[0]) * p[i][1] + np.cos(R[1]) * np.cos(R[0]) * p[i][2]
        q[i] += T + initial_height
        l[i] = q[i] - b[i]
    for i in range(6):
        L = np.linalg.norm(l[i]) ** 2 - ((ROD_LENGTH ** 2) - (HORN_LENGTH ** 2))
        M = 2 * HORN_LENGTH * (q[i][2] - b[i][2])
        N = 2 * HORN_LENGTH * (np.cos(BETA[i]) * (q[i][0] - b[i][0]) + np.sin(BETA[i]) * (q[i][1] - b[i][1]))
        alpha[i] = np.arcsin(L / np.sqrt(M ** 2 + N ** 2)) - np.arctan2(N, M)
        if np.isnan(alpha[i]):
            alpha[i] = 0
             
def send_angles_to_serial(alpha):
    data = 'j' + 'j' + ','.join([str(int(np.degrees(alpha_i) * 100)) for alpha_i in alpha]) + '\n'
    serial_connection.write(data.encode())
    
def read_serial_event():
    if serial_connection.in_waiting >= 6:
        header = serial_connection.read(2)
        if header == b'kk':
            global ball_x, ball_y
            ball_x = int.from_bytes(serial_connection.read(2), byteorder='little', signed=True)
            ball_y = int.from_bytes(serial_connection.read(2), byteorder='little', signed=True)
            
if __name__ == "__main__":   
    initialize_platform()
    
    pid_x = PID(0.001, 0.000, 0.00042, setpoint=0, output_limits=(-0.6, 0.6))
    pid_y = PID(0.001, 0.000, 0.00042, setpoint=0, output_limits=(-0.6, 0.6))
    
    last_time = time.time()
    
    while True:
        read_serial_event()
        
        current_time = time.time()
        elapsed = current_time - last_time
        
        if elapsed >= 0.02:
            T = [0, 0, 0]
            R = [pid_y(ball_y), pid_x(ball_x), 0]
    
            calculate_angle_alpha()
            send_angles_to_serial(alpha)
        
            print("ball: ", ball_x, " ",ball_y, " alpha: ", np.degrees(alpha))        
            last_time = current_time
    
