/**
 * 时辰工具类：处理时辰相关计算
 */

export interface ShichenInfo {
  name: string;        // 子时
  range: string;       // 23:00-01:00
  zhi: string;         // 子
  wuxing: string;      // 水
  index: number;       // 0-11
  gan?: string;        // 时干（需根据日干计算）
}

export class ShichenHelper {
  // 十二时辰基础信息
  private static readonly SHICHEN_LIST: ShichenInfo[] = [
    { name: '子时', range: '23:00-01:00', zhi: '子', wuxing: '水', index: 0 },
    { name: '丑时', range: '01:00-03:00', zhi: '丑', wuxing: '土', index: 1 },
    { name: '寅时', range: '03:00-05:00', zhi: '寅', wuxing: '木', index: 2 },
    { name: '卯时', range: '05:00-07:00', zhi: '卯', wuxing: '木', index: 3 },
    { name: '辰时', range: '07:00-09:00', zhi: '辰', wuxing: '土', index: 4 },
    { name: '巳时', range: '09:00-11:00', zhi: '巳', wuxing: '火', index: 5 },
    { name: '午时', range: '11:00-13:00', zhi: '午', wuxing: '火', index: 6 },
    { name: '未时', range: '13:00-15:00', zhi: '未', wuxing: '土', index: 7 },
    { name: '申时', range: '15:00-17:00', zhi: '申', wuxing: '金', index: 8 },
    { name: '酉时', range: '17:00-19:00', zhi: '酉', wuxing: '金', index: 9 },
    { name: '戌时', range: '19:00-21:00', zhi: '戌', wuxing: '土', index: 10 },
    { name: '亥时', range: '21:00-23:00', zhi: '亥', wuxing: '水', index: 11 },
  ];

  // 天干列表
  private static readonly TIAN_GAN = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

  /**
   * 获取所有时辰列表
   */
  public static getAllShichen(): ShichenInfo[] {
    return [...ShichenHelper.SHICHEN_LIST];
  }

  /**
   * 根据当前时间自动获取时辰索引
   */
  public static getCurrentShichenIndex(): number {
    const now = new Date();
    const hour = now.getHours();
    
    // 23:00-00:59 算子时
    if (hour === 23) return 0;
    // 其他时间按 (hour+1)/2 计算
    return Math.floor((hour + 1) / 2) % 12;
  }

  /**
   * 计算时干（五鼠遁法）
   * 根据日干推算时干
   * 口诀：甲己还加甲，乙庚丙作初，丙辛从戊起，丁壬庚子居，戊癸何方发，壬子是真途
   */
  public static calculateShiGan(dayGan: string, shichenIndex: number): string {
    const ganIndex = ShichenHelper.TIAN_GAN.indexOf(dayGan);
    if (ganIndex === -1) return '甲'; // 默认值

    // 五鼠遁起始天干索引
    let startGanIndex = 0;
    switch (ganIndex) {
      case 0: // 甲
      case 5: // 己
        startGanIndex = 0; // 甲
        break;
      case 1: // 乙
      case 6: // 庚
        startGanIndex = 2; // 丙
        break;
      case 2: // 丙
      case 7: // 辛
        startGanIndex = 4; // 戊
        break;
      case 3: // 丁
      case 8: // 壬
        startGanIndex = 6; // 庚
        break;
      case 4: // 戊
      case 9: // 癸
        startGanIndex = 8; // 壬
        break;
    }

    // 从子时开始，每个时辰天干顺推
    const shiGanIndex = (startGanIndex + shichenIndex) % 10;
    return ShichenHelper.TIAN_GAN[shiGanIndex];
  }

  /**
   * 获取完整的时柱信息（干支+五行）
   */
  public static getShizhuInfo(dayGan: string, shichenIndex: number): string {
    const shichen = ShichenHelper.SHICHEN_LIST[shichenIndex];
    const shiGan = ShichenHelper.calculateShiGan(dayGan, shichenIndex);
    return `${shiGan}${shichen.zhi}`;
  }

  /**
   * 获取时辰显示文本（用于选择器）
   */
  public static getShichenDisplayText(shichenIndex: number, dayGan?: string): string {
    const shichen = ShichenHelper.SHICHEN_LIST[shichenIndex];
    if (dayGan) {
      const shiGan = ShichenHelper.calculateShiGan(dayGan, shichenIndex);
      return `${shichen.name}（${shichen.range}）${shiGan}${shichen.zhi}时 ${shichen.wuxing}`;
    }
    return `${shichen.name}（${shichen.range}）`;
  }
}
