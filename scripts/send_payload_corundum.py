import struct
from scapy.all import *
import socket
import time
import argparse

# def create_frame(payload, recon, index, func_type=0, size=0, address=0):
#     #eth = Ether(src='74:86:e2:29:f5:80', dst='08:96:ad:f6:5d:80')
#     ip = IP(src='172.20.1.11', dst='172.20.1.2')
#     id = 0
#     udp = UDP(sport=8000, dport=8000)
#     if recon == True:
#         if func_type == 0:
#             if index == 0:
#                 upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
#                 lwr_hdr = size >> 19
#                 pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
#             else:
#                 upr_hdr = func_type | 0 << 2
#                 pkt_hdr = struct.pack('<HHB', 0xF0E1, 0x0001, upr_hdr)
#             frame = (pkt_hdr + payload)
#         elif func_type == 1:
#             upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
#             lwr_hdr = size >> 19
#             pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
#             frame = pkt_hdr
#     else:
#         frame = payload
#     return frame


# def create_frame(payload, recon, index, func_type=0, size=0, address=0):
#     eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')
#     ip = IP(src='192.168.1.100', dst='192.168.1.101')
#     id = 0
#     udp = UDP(sport=1, dport=2)
#     if recon == True:
#         if func_type == 0:
#             if index == 0:
#                 upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
#                 lwr_hdr = size >> 19
#                 pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
#                 frame = pkt_hdr
#             else:
#                 upr_hdr = func_type | 0 << 2
#                 pkt_hdr = struct.pack('<HHB', 0xF0E1, 0x0001, upr_hdr)
#                 frame = (pkt_hdr + payload)
#         elif func_type == 1:
#             upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
#             lwr_hdr = size >> 19
#             pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
#             frame = pkt_hdr
#     else:
#         frame = payload
#     return frame

class recon:
    def __init__(self, ip, port, packet_count=64, packet_size=64):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.ip = ip
        self.port = port
        self.packet_count = packet_count
        self.packet_size = packet_size 
        self.pkts = [bytearray([(x + k) % 256 for x in range(packet_size)]) for k in range(packet_count)]
        self.framed_pkts = [self.create_frame(pkt, True, 1) for index, pkt in enumerate(self.pkts)]
        
    def create_frame(self, payload, recon, index, func_type=0, size=0, address=0):
        id = 0
        if recon == True:
            if func_type == 0:
                if index == 0:
                    upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
                    lwr_hdr = size >> 19
                    pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
                    frame = pkt_hdr
                else:
                    upr_hdr = func_type | 0 << 2
                    pkt_hdr = struct.pack('<HHB', 0xF0E1, 0x0001, upr_hdr)
                    frame = (pkt_hdr + payload)
            elif func_type == 1:
                upr_hdr = func_type | 1 << 2 | address << 3 | id << 37 | (size & 0x7ffff) << 45
                lwr_hdr = size >> 19
                pkt_hdr = struct.pack('<HHQH', 0xF0E1, 0x0001, upr_hdr, lwr_hdr)
                frame = pkt_hdr
            else:
                frame = payload
        return frame

    def send_read_dma(self, address, size):
        config_pkt = bytes(self.create_frame(0, True, 0, func_type=1, size=size, address=address))
        self.sock.sendto(config_pkt, (self.ip, self.port))
        
    def send_write_dma(self, address, size):
        config_pkt = bytes(self.create_frame(0, True, 0, func_type=0, size=size, address=address))
        self.sock.sendto(config_pkt, (self.ip, self.port))

    def send_data(self, packet_count):
        for idx in range(packet_count):
            self.sock.sendto(self.framed_pkts[idx], (self.ip, self.port))

    def __del__(self):
        self.sock.close()

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="Reconfiguration testing script")
    parser.add_argument('--ip', type=str, help="IP Address", required=True)
    parser.add_argument('--port', type=int, help="Port", required=True, default=8000)
    parser.add_argument('--cmd', type=str, help="CMD for testing", required=True)
    
    args = parser.parse_args()
    
    recon_obj = recon(args.ip, args.port)

    address = 0x100
    packet = 8
    size = 8*64
    
    if args.cmd == "dma_write":
        recon_obj.send_write_dma(address, size)
        recon_obj.send_data(packet)
    elif args.cmd == "dma_read":
        recon_obj.send_read_dma(address, size)
