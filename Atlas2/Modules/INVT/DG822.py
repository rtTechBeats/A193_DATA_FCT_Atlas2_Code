#!/usr/bin/env python3
"""
DG822 信号发生器控制脚本
基于 PyVISA 库控制信号发生器输出方波和正弦波
"""

import sys
import argparse
import pyvisa
from typing import Optional, Tuple

class DG822Controller:
    """DG822 信号发生器控制器类"""
    
    def __init__(self, resource_name: Optional[str] = None):
        """
        初始化控制器
        
        Args:
            resource_name: VISA 资源名，如果为 None 则自动搜索
        """
        self.rm = pyvisa.ResourceManager()
        self.instr = None
        
        if resource_name:
            self.resource_name = resource_name
        else:
            # 尝试自动搜索 DG822
            resources = self.rm.list_resources()
            dg822_resources = [r for r in resources if 'DG8' in r.upper()]
            
            if not dg822_resources:
                raise ConnectionError("未找到 DG822 设备，请检查连接")
            
            self.resource_name = dg822_resources[0]
    
    def connect(self) -> bool:
        """连接到仪器"""
        try:
            self.instr = self.rm.open_resource(self.resource_name)
            self.instr.timeout = 5000  # 5秒超时
            self.instr.read_termination = '\n'
            self.instr.write_termination = '\n'
            
            # 查询设备ID验证连接
            idn = self.instr.query('*IDN?')
            print(f"已连接到设备: {idn.strip()}")
            return True
        except Exception as e:
            print(f"连接失败: {e}")
            return False
    
    def disconnect(self):
        """断开连接"""
        if self.instr:
            self.instr.close()
            print("已断开连接")
    
    def setup_waveform(self, 
                      wavemode: str,  # 'SINE' 或 'SQUARE'
                      channel: int,   # 通道号 (1或2)
                      frequency: float,  # 频率 (Hz)
                      voltage: float,    # 电压值
                      unit: str,         # 电压单位: 'VPP', 'VRMS', 'DBM'
                      offset_volt: float,  # 偏置电压 (V)
                      phase: float,      # 相位 (度)
                      duty_cycle: float  # 占空比 (%)
                     ) -> bool:
        """
        设置波形参数
        
        Args:
            wavemode: 波形模式 ('SINE' 或 'SQUARE')
            channel: 通道 (1 或 2)
            frequency: 频率 (Hz)
            voltage: 电压幅度
            unit: 电压单位 ('VPP', 'VRMS', 'DBM')
            offset_volt: 偏置电压 (V)
            phase: 相位 (度)
            duty_cycle: 占空比 (%)
        
        Returns:
            bool: 设置是否成功
        """
        if not self.instr:
            print("错误: 未连接到设备")
            return False
        
        if channel not in [1, 2]:
            print("错误: 通道号必须是 1 或 2")
            return False
        
        if wavemode.upper() not in ['SINE', 'SQUARE']:
            print("错误: 波形模式必须是 'SINE' 或 'SQUARE'")
            return False
        
        try:
            # 选择通道
            self.instr.write(f':OUTPut{channel}:STATe OFF')
            
            # 设置波形模式
            if wavemode.upper() == 'SINE':
                self.instr.write(f':SOURce{channel}:FUNCtion SINusoid')
            else:  # SQUARE
                self.instr.write(f':SOURce{channel}:FUNCtion SQUare')
            
            # 设置频率
            self.instr.write(f':SOURce{channel}:FREQuency {frequency}')
            
            # 设置幅度和单位
            if unit.upper() == 'VPP':
                self.instr.write(f':SOURce{channel}:VOLTage:UNIT VPP')
                self.instr.write(f':SOURce{channel}:VOLTage {voltage}')
            elif unit.upper() == 'VRMS':
                self.instr.write(f':SOURce{channel}:VOLTage:UNIT VRMS')
                self.instr.write(f':SOURce{channel}:VOLTage {voltage}')
            elif unit.upper() == 'DBM':
                self.instr.write(f':SOURce{channel}:VOLTage:UNIT DBM')
                self.instr.write(f':SOURce{channel}:VOLTage {voltage}')
            else:
                print(f"警告: 单位 '{unit}' 可能不受支持，使用 VPP")
                self.instr.write(f':SOURce{channel}:VOLTage:UNIT VPP')
                self.instr.write(f':SOURce{channel}:VOLTage {voltage}')
            
            # 设置偏置电压
            self.instr.write(f':SOURce{channel}:VOLTage:OFFSet {offset_volt}')
            
            # 设置相位
            self.instr.write(f':SOURce{channel}:PHASe {phase}')
            
            # 如果是方波，设置占空比
            if wavemode.upper() == 'SQUARE':
                if 0 <= duty_cycle <= 100:
                    self.instr.write(f':SOURce{channel}:FUNCtion:SQUare:DCYCle {duty_cycle}')
                else:
                    print(f"警告: 占空比 {duty_cycle}% 超出范围，使用 50%")
                    self.instr.write(f':SOURce{channel}:FUNCtion:SQUare:DCYCle 50')
            
            # 开启输出
            self.instr.write(f':OUTPut{channel}:STATe ON')
            
            print(f"通道 {channel} 设置完成:")
            print(f"  波形: {wavemode}")
            print(f"  频率: {frequency} Hz")
            print(f"  电压: {voltage} {unit}")
            print(f"  偏置: {offset_volt} V")
            print(f"  相位: {phase} 度")
            if wavemode.upper() == 'SQUARE':
                print(f"  占空比: {duty_cycle}%")
            
            return True
            
        except Exception as e:
            print(f"设置波形时出错: {e}")
            return False
    
    def query_status(self, channel: int) -> str:
        """查询通道状态"""
        if not self.instr:
            return "未连接"
        
        try:
            # 查询输出状态
            output_state = self.instr.query(f':OUTPut{channel}:STATe?').strip()
            # 查询波形类型
            waveform = self.instr.query(f':SOURce{channel}:FUNCtion?').strip()
            # 查询频率
            freq = self.instr.query(f':SOURce{channel}:FREQuency?').strip()
            # 查询幅度
            volt = self.instr.query(f':SOURce{channel}:VOLTage?').strip()
            # 查询单位
            unit = self.instr.query(f':SOURce{channel}:VOLTage:UNIT?').strip()
            
            return (f"通道 {channel}: 输出 {'开启' if output_state == '1' else '关闭'}, "
                   f"波形: {waveform}, 频率: {freq} Hz, 幅度: {volt} {unit}")
        except Exception as e:
            return f"查询状态失败: {e}"


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description='控制 DG822 信号发生器输出波形',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 输出 1kHz, 2Vpp, 0V偏置的正弦波到通道1
  python dg822_control.py SINE 1 1000 2 VPP 0 0 50
  
  # 输出 10kHz, 5Vpp, 1V偏置, 30%占空比的方波到通道2
  python dg822_control.py SQUARE 2 10000 5 VPP 1 0 30
        """
    )
    
    parser.add_argument('wavemode', type=str, choices=['SINE', 'SQUARE'], 
                       help='波形模式: SINE(正弦波) 或 SQUARE(方波)')
    parser.add_argument('channel', type=int, choices=[1, 2], 
                       help='通道号: 1 或 2')
    parser.add_argument('frequency', type=float, 
                       help='频率 (Hz)，例如: 1000 表示 1kHz')
    parser.add_argument('voltage', type=float, 
                       help='电压幅度值')
    parser.add_argument('unit', type=str, choices=['VPP', 'VRMS', 'DBM'], 
                       help="电压单位: VPP(峰峰值), VRMS(有效值), DBM(功率)")
    parser.add_argument('offsetVolt', type=float, 
                       help='偏置电压 (V)')
    parser.add_argument('phase', type=float, 
                       help='相位 (度)')
    parser.add_argument('duty_cycle', type=float, 
                       help='占空比 (%%，仅对方波有效)')
    
    parser.add_argument('--resource', '-r', type=str, 
                       help='VISA资源名 (例如: TCPIP0::192.168.1.100::inst0::INSTR)')

    parser.add_argument('--disable', '-d', type=int, 
                       help='disable output([0, 1])')
    
    return parser.parse_args()


def main():
    """主函数"""
    args = parse_arguments()
    
    print("DG822 信号发生器控制脚本")
    print("=" * 50)
    
    # 创建控制器实例
    try:
        controller = DG822Controller(args.resource)
    except ConnectionError as e:
        print(f"初始化失败: {e}")
        print("请检查:")
        print("1. DG822 是否已通过 USB/GPIB/LAN 连接到计算机")
        print("2. 是否安装了 NI-VISA 或 R&S VISA")
        print("3. 可以尝试指定资源名: --resource 'VISA资源名'")
        return 1
    
    # 连接到设备
    if not controller.connect():
        print("无法连接到设备，请检查连接和VISA安装")
        return 1

    if args.disable == 1:
        if controller.instr:
            controller.instr.write(f':OUTPut{args.channel}:STATe OFF')
        controller.disconnect()
    else: 

        try:
            # 设置波形
            success = controller.setup_waveform(
                wavemode=args.wavemode,
                channel=args.channel,
                frequency=args.frequency,
                voltage=args.voltage,
                unit=args.unit,
                offset_volt=args.offsetVolt,
                phase=args.phase,
                duty_cycle=args.duty_cycle
            )
            
            # if success:
            #     # print("\n波形设置成功!")
                
            #     # 查询并显示状态
            #     # print("\n当前状态:")
            #     # print(controller.query_status(args.channel))
                
            #     # print("\n按 Enter 键停止输出并退出...")
            #     # input()
                
            #     # 停止输出
            #     # controller.instr.write(f':OUTPut{args.channel}:STATe OFF')
            #     # print(f"通道 {args.channel} 输出已关闭")
            # else:
            #     print("波形设置失败")
            #     return 1
                
        except KeyboardInterrupt:
            print("\n\n用户中断，停止输出...")
            if controller.instr:
                controller.instr.write(f':OUTPut{args.channel}:STATe OFF')
        except Exception as e:
            print(f"运行过程中出错: {e}")
            return 1
        finally:
            controller.disconnect()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
