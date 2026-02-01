// DunjiaEngine.ets
// 遁甲时空盘核心引擎（基于《遁甲符应经》规则实现）

import { SolarTermCalculator } from './SolarTermCalculator';
import { CalendarManager, CalendarDayInfo } from './CalendarManager';

export enum DunType {
  YANG = 'yang',
  YIN = 'yin'
}

export enum DunjiaSceneType {
  GENERAL_STUDY = 'general_study',       // 普通研习
  STRATEGY_STUDY = 'strategy_study',     // 局势/布局类研习
  TIME_WINDOW_STUDY = 'time_window'      // 时机窗口研习
}

// 宫位编号 0-8 对应九宫：0=一宫坎, 1=二宫坤, 2=三宫震, 3=四宫巽, 4=五宫中, 5=六宫乾, 6=七宫兑, 7=八宫艮, 8=九宫离
export type PalaceIndex = number;

export interface DunjiaInput {
  /** 公历时间，建议使用真太阳时校正后时间 */
  dateTime: Date;
  /** 地理经度，用于真太阳时与节气研习（东经为正） */
  longitude: number;
  /** 研习场景类型 */
  sceneType: DunjiaSceneType;
}

export interface PalaceState {
  palace: PalaceIndex;     // 宫位索引
  palaceName: string;      // 宫名，如"一宫坎"
  palaceElement: string;   // 宫位五行：水、火、木、金、土
  starName?: string;       // 九星名称，如"天蓬"
  doorName?: string;       // 八门名称，如"生门"
  tianGan?: string;        // 天盘天干（暗干）
  diGan?: string;          // 地盘天干（明干）
  deityName?: string;      // 八神名称，如"九天"、"太阴"等
  isZhiFu?: boolean;       // 是否为值符宫
  isZhiShi?: boolean;      // 是否为值使宫
}

export interface RuleHit {
  id: string;              // 规则唯一标识，如"sanqi_deshi"、"qinglong_huishou"
  name: string;            // 规则名称，如"三奇得使"
  level: 'info' | 'hint' | 'focus'; // 提示等级（用于UI呈现权重）
  description: string;     // 面向研习者的结构化说明文案（不做个人预测）
}

export interface EvaluationSummary {
  /** 简短结构特征标签，如"偏向主动推进"、"结构偏稳健" */
  structureTag: string;
  /** 概览说明，用于研习参考 */
  overview: string;
  /** 建议关注的宫位或要素，用于学习提示 */
  focusPoints: string[];
}

export interface DunjiaPanResult {
  /** 阴遁/阳遁 */
  dunType: DunType;
  /** 局数，例如 "阳遁三局" */
  juLabel: string;
  /** 原始输入（便于回显） */
  input: DunjiaInput;
  /** 值符所在宫 */
  zhiFuPalace: PalaceIndex;
  /** 值使所在宫 */
  zhiShiPalace: PalaceIndex;
  /** 九宫详细状态 */
  palaces: PalaceState[];
  /** 命中的结构规则列表（不直接输出吉凶，只说明结构特征） */
  ruleHits: RuleHit[];
  /** 针对当前场景的整体结构评估（研习向描述） */
  summary: EvaluationSummary;
  /** 当日干支信息（包含农历） */
  dayInfo?: CalendarDayInfo;
  /** 时辰干支 */
  hourGanZhi?: string;
  /** 真太阳时偏移量（分钟） */
  solarTimeOffset?: number;
  /** 识别的格局列表 */
  gejuPatterns?: GejuPattern[];
}

/**
 * 格局模式接口
 */
export interface GejuPattern {
  id: string;
  name: string;  // 格局名称，如"三奇得使"、"天遁"
  description: string;  // 格局说明
  palaceIndices: number[];  // 涉及的宫位索引
  level: 'minor' | 'major' | 'special';  // 次要、主要、特殊格局
}

// 核心引擎：负责从时间/地点计算出完整的遁甲盘与结构化分析
export class DunjiaEngine {
  private static instance: DunjiaEngine | null = null;

  private constructor() {}

  static getInstance(): DunjiaEngine {
    if (!DunjiaEngine.instance) {
      DunjiaEngine.instance = new DunjiaEngine();
    }
    return DunjiaEngine.instance;
  }

  /**
   * 从输入参数计算完整的遁甲盘面与结构分析结果。
   */
  public async computePan(input: DunjiaInput): Promise<DunjiaPanResult> {
    const date = input.dateTime;
    
    // 1. 获取干支信息
    const dayInfo = await this.getDayGanZhi(date);
    if (!dayInfo) {
      return this.createEmptyPan(input);
    }

    // 2. 确定阴阳遁与局数
    const ju = this.calculateJu(date, dayInfo);
    
    // 3. 计算当前时轰
    const hour = date.getHours();
    const hourGanZhi = this.getHourGanZhi(dayInfo.day_gan, hour);
    
    // 4. 计算值符值使位置
    const zhiFuZhiShi = this.calculateZhiFuZhiShi(ju, hourGanZhi);
    ju.zhiFuPalace = zhiFuZhiShi.zhiFuPalace;
    ju.zhiShiPalace = zhiFuZhiShi.zhiShiPalace;
    
    // 5. 布九宫（九星、八门、三奇六仪、八神）
    const palaces = this.layoutPalaces(ju, date, dayInfo, hourGanZhi);
    
    // 6. 生成规则命中与结构总结
    const ruleHits: RuleHit[] = [];
    const summary: EvaluationSummary = {
      structureTag: this.generateStructureTag(ju),
      overview: `当前为${ju.dunType === DunType.YANG ? '阳遁' : '阴遁'}${ju.juNumber}局，值符在${palaces[ju.zhiFuPalace].palaceName}，值使在${palaces[ju.zhiShiPalace].palaceName}`,
      focusPoints: [] as string[]
    };
    
    // 8. 识别格局
    const gejuPatterns = this.identifyGejuPatterns(ju, palaces, dayInfo, hourGanZhi);

    return {
      dunType: ju.dunType,
      juLabel: `${ju.dunType === DunType.YANG ? '阳遁' : '阴遁'}${ju.juNumber}局`,
      input,
      zhiFuPalace: ju.zhiFuPalace,
      zhiShiPalace: ju.zhiShiPalace,
      palaces,
      ruleHits,
      summary,
      dayInfo: dayInfo,
      hourGanZhi: `${hourGanZhi.gan}${hourGanZhi.zhi}`,
      solarTimeOffset: this.calculateSolarTimeOffset(input.longitude),
      gejuPatterns: gejuPatterns
    };
  }

  // ========== 内部算法实现 ==========

  /**
   * 计算时轰干支
   */
  private getHourGanZhi(dayGan: string, hour: number): HourGanZhi {
    // 十二时轰对应的地支
    const zhiList = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    
    // 根据小时确定时轰（23-1点为子时，1-3点为丑时...）
    let zhiIndex = 0;
    if (hour >= 23 || hour < 1) {
      zhiIndex = 0; // 子
    } else {
      zhiIndex = Math.floor((hour + 1) / 2);
    }
    
    const hourZhi = zhiList[zhiIndex];
    
    // 根据日干起时法计算时干（甲己起甲子，乙庚起丙子...）
    const ganList = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const dayGanIndex = ganList.indexOf(dayGan);
    
    // 日干起时表：甲己日从甲子起，乙庚日从丙子起...
    const hourGanStart = (dayGanIndex % 5) * 2;
    const hourGanIndex = (hourGanStart + zhiIndex) % 10;
    const hourGan = ganList[hourGanIndex];
    
    return {
      gan: hourGan,
      zhi: hourZhi,
      ganIndex: hourGanIndex,
      zhiIndex: zhiIndex
    };
  }

  /**
   * 计算值符值使位置
   */
  private calculateZhiFuZhiShi(ju: JuInfo, hourGanZhi: HourGanZhi): ZhiFuZhiShiInfo {
    // 根据时干确定值符（六甲时直符移动）
    // 简化：根据局数与时干计算
    const ganList = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    
    // 值符跟随时干：甲在局数宫，乙在下一宫...
    // 简化算法：从局数宫开始，每个时轰移动一步
    const baseGanIndex = ganList.indexOf('甲'); // 0
    const offset = (hourGanZhi.ganIndex - baseGanIndex + 10) % 10;
    
    // 阳遁顺飞，阴遁逆飞
    let zhiFuPalace: number;
    if (ju.dunType === DunType.YANG) {
      zhiFuPalace = (ju.juNumber - 1 + offset) % 9;
    } else {
      zhiFuPalace = (ju.juNumber - 1 - offset + 90) % 9;
    }
    
    // 值使跟随值符（简化：与值符同宫或相邻）
    // 正规算法：值使跟随时支对应的门
    const zhiShiPalace = zhiFuPalace; // 简化：与值符同宫
    
    return {
      zhiFuPalace,
      zhiShiPalace
    };
  }
  private async getDayGanZhi(date: Date): Promise<CalendarDayInfo | null> {
    const manager = CalendarManager.getInstance();
    return await manager.getDayInfo(date.getFullYear(), date.getMonth() + 1, date.getDate());
  }

  /**
   * 计算局数（根据节气与元数）
   */
  private calculateJu(date: Date, dayInfo: CalendarDayInfo): JuInfo {
    // 获取最近节气
    const solarTerm = SolarTermCalculator.getInstance().getSolarTermByDate(date);
    const solarTermName = solarTerm ? solarTerm.name : dayInfo.solar_term;
    
    // 判断阴遁还是阳遁（冬至后阳遁，夏至后阴遁）
    const dunType = this.getDunType(solarTermName);
    
    // 根据节气与元数查局数表
    const juNumber = this.getJuNumber(solarTermName, dayInfo, dunType);
    
    // 计算值符值使位置（简化版：先返回固定位置）
    const zhiFuPalace = 4; // 临时：中宫
    const zhiShiPalace = 4;
    
    return {
      dunType,
      juNumber,
      zhiFuPalace,
      zhiShiPalace
    } as JuInfo;
  }

  /**
   * 判断阴阳遁
   */
  private getDunType(solarTermName: string): DunType {
    const yangTerms = ['冬至', '小寒', '大寒', '立春', '雨水', '惊蛰', '春分', '清明', '谷雨', '立夏', '小满', '芒种'];
    return yangTerms.includes(solarTermName) ? DunType.YANG : DunType.YIN;
  }

  /**
   * 根据节气查局数（简化版）
   */
  private getJuNumber(solarTermName: string, dayInfo: CalendarDayInfo, dunType: DunType): number {
    // 根据《遁甲符应经》的阳遁阴遁局数表
    const yangJuMap: Record<string, number[]> = {
      '冬至': [1, 7, 4], '惊蛰': [1, 7, 4],
      '小寒': [2, 8, 5],
      '大寒': [3, 9, 6], '春分': [3, 9, 6],
      '芒种': [6, 3, 9],
      '谷雨': [5, 2, 8], '小满': [5, 2, 8],
      '立春': [8, 5, 2],
      '清明': [4, 1, 7], '立夏': [4, 1, 7]
    };
    
    const yinJuMap: Record<string, number[]> = {
      '夏至': [9, 3, 6], '白露': [9, 3, 6],
      '小暑': [8, 2, 5],
      '大暑': [7, 1, 4], '秋分': [7, 1, 4],
      '立秋': [2, 5, 8],
      '霜降': [5, 8, 2], '小雪': [5, 8, 2],
      '大雪': [4, 7, 1],
      '处暑': [1, 4, 7],
      '立冬': [6, 9, 3], '寒露': [6, 9, 3]
    };
    
    const juMap = dunType === DunType.YANG ? yangJuMap : yinJuMap;
    const juArray = juMap[solarTermName] || [1, 1, 1];
    
    // 简化：根据日干判断上中下元（甲己日判断仲孟季）
    const yuanIndex = this.getYuanIndex(dayInfo.day_gan);
    return juArray[yuanIndex];
  }

  /**
   * 获取上中下元索引（0=上，1=中，2=下）
   */
  private getYuanIndex(dayGan: string): number {
    // 简化实现：根据日干粗略判断
    const ganIndex = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'].indexOf(dayGan);
    return ganIndex % 3;
  }

  /**
   * 布局九宫（九星、八门、三奇六仪、八神）
   */
  private layoutPalaces(ju: JuInfo, date: Date, dayInfo: CalendarDayInfo, hourGanZhi: HourGanZhi): PalaceState[] {
    const palaceNames: string[] = ['一宫坎', '二宫坤', '三宫震', '四宫巽', '五宫中', '六宫乾', '七宫兑', '八宫艮', '九宫离'];
    const palaceElements: string[] = ['水', '土', '木', '木', '土', '金', '金', '土', '火'];
    
    // 布九星
    const stars = this.layoutStars(ju.juNumber, ju.dunType);
    
    // 布八门
    const doors = this.layoutDoors(ju.juNumber, ju.dunType, hourGanZhi);
    
    // 布三奇六仪（天盘地盘天干）
    const tianPan = this.layoutTianGan(ju, hourGanZhi, true);  // 天盘（暗干）
    const diPan = this.layoutTianGan(ju, hourGanZhi, false);   // 地盘（明干）
    
    // 布八神
    const deities = this.layoutDeities(ju, hourGanZhi);
    
    return palaceNames.map((name: string, index: number): PalaceState => {
      return {
        palace: index as PalaceIndex,
        palaceName: name,
        palaceElement: palaceElements[index],
        starName: stars[index],
        doorName: doors[index],
        tianGan: tianPan[index],
        diGan: diPan[index],
        deityName: deities[index],
        isZhiFu: index === ju.zhiFuPalace,
        isZhiShi: index === ju.zhiShiPalace
      } as PalaceState;
    });
  }

  /**
   * 布九星（简化版：直接按局数顺飞或逆飞）
   */
  private layoutStars(juNumber: number, dunType: DunType): string[] {
    const starNames = ['天蓬', '天芮', '天冲', '天辅', '天禽', '天心', '天柱', '天任', '天英'];
    const result: string[] = new Array(9).fill('');
    
    // 简化：阳遁顺飞，阴遁逆飞
    const startPalace = juNumber - 1; // 局数对应起始宫（简化）
    if (dunType === DunType.YANG) {
      for (let i = 0; i < 9; i++) {
        result[(startPalace + i) % 9] = starNames[i];
      }
    } else {
      for (let i = 0; i < 9; i++) {
        result[(startPalace - i + 9) % 9] = starNames[i];
      }
    }
    
    return result;
  }

  /**
   * 布八门（优化版：值使门根据时支确定，其他门按局数顺飞或逆飞）
   * @param juNumber 局数
   * @param dunType 阴阳遁
   * @param hourGanZhi 时辰干支信息
   */
  private layoutDoors(juNumber: number, dunType: DunType, hourGanZhi: HourGanZhi): string[] {
    const doorNames = ['休门', '死门', '伤门', '杜门', '', '开门', '惊门', '生门', '景门'];
    const result: string[] = new Array(9).fill('');
    
    // 首先确定值使门：根据时支确定对应八门
    const zhiList = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    const doorIndexMap: Record<string, number> = {
      '子': 0, // 休门
      '丑': 1, // 死门
      '寅': 2, // 伤门
      '卯': 3, // 杜门
      '辰': 5, // 开门（辰时归于开门）
      '巳': 6, // 惊门
      '午': 8, // 景门（午时在离宫）
      '未': 7, // 生门（未时在艮宫）
      '申': 6, // 惊门
      '酉': 5, // 开门
      '戌': 1, // 死门（戌时归于死门）
      '亥': 0  // 休门
    };
    
    const zhiIndex = zhiList.indexOf(hourGanZhi.zhi);
    const zhiShiDoorIndex = doorIndexMap[hourGanZhi.zhi] || 0;
    const zhiShiDoor = doorNames[zhiShiDoorIndex];
    
    // 根据《遁甲符应经》规则：值使门在值使宫
    // 计算值使宫位（已在calculateZhiFuZhiShi中计算）
    // 简化：这里我们先模拟值使宫，实际使用传入的ju.zhiShiPalace
    const zhiShiPalace = this.calculateZhiShiPalace(juNumber, dunType, hourGanZhi);
    
    // 将值使门放在值使宫
    result[zhiShiPalace] = zhiShiDoor;
    
    // 布置其余七门：根据阴阳遁顺飞或逆飞
    const remainingDoors = [...doorNames.filter(d => d !== '' && d !== zhiShiDoor)];
    
    // 从值使宫开始，按阴阳遁方向依次布置其他门
    if (dunType === DunType.YANG) {
      // 阳遁顺飞
      let placementIndex = (zhiShiPalace + 1) % 9;
      for (const door of remainingDoors) {
        // 跳过中宫，最多循环9次避免死循环
        let attempts = 0;
        while (placementIndex === 4 && attempts < 9) {
          placementIndex = (placementIndex + 1) % 9;
          attempts++;
        }
        
        if (attempts < 9 && placementIndex !== zhiShiPalace && result[placementIndex] === '') {
          result[placementIndex] = door;
        }
        
        placementIndex = (placementIndex + 1) % 9;
      }
    } else {
      // 阴遁逆飞
      let placementIndex = (zhiShiPalace - 1 + 9) % 9;
      for (const door of remainingDoors) {
        // 跳过中宫，最多循环9次避免死循环
        let attempts = 0;
        while (placementIndex === 4 && attempts < 9) {
          placementIndex = (placementIndex - 1 + 9) % 9;
          attempts++;
        }
        
        if (attempts < 9 && placementIndex !== zhiShiPalace && result[placementIndex] === '') {
          result[placementIndex] = door;
        }
        
        placementIndex = (placementIndex - 1 + 9) % 9;
      }
    }
    
    return result;
  }
  
  /**
   * 计算值使宫位
   * @param juNumber 局数
   * @param dunType 阴阳遁
   * @param hourGanZhi 时辰干支信息
   */
  private calculateZhiShiPalace(juNumber: number, dunType: DunType, hourGanZhi: HourGanZhi): PalaceIndex {
    // 简化：值使宫与值符宫有一定关联，根据时支确定
    // 根据《遁甲符应经》：值使门随值符移动，但固定在时支所对应的宫位
    
    // 基础宫位：根据局数确定
    let basePalace = (juNumber - 1) % 9;
    
    // 根据时支修正值使宫位
    const zhiToPalaceAdjustment: Record<string, number> = {
      '子': 0, // 休门在坎宫
      '丑': 1, // 死门在坤宫
      '寅': 2, // 伤门在震宫
      '卯': 3, // 杜门在巽宫
      '辰': 5, // 开门在乾宫
      '巳': 6, // 惊门在兑宫
      '午': 8, // 景门在离宫
      '未': 7, // 生门在艮宫
      '申': 6, // 惊门在兑宫
      '酉': 5, // 开门在乾宫
      '戌': 1, // 死门在坤宫
      '亥': 0  // 休门在坎宫
    };
    
    const adjustment = zhiToPalaceAdjustment[hourGanZhi.zhi] || 0;
    
    // 阴阳遁不同算法
    if (dunType === DunType.YANG) {
      return (basePalace + adjustment) % 9 as PalaceIndex;
    } else {
      return (basePalace - adjustment + 9) % 9 as PalaceIndex;
    }
  }

  /**
   * 布三奇六仪（天干）
   * @param isTianPan true=天盘（暗干），false=地盘（明干）
   * @param ju 局信息
   * @param hourGanZhi 时辰干支信息
   */
  private layoutTianGan(ju: JuInfo, hourGanZhi: HourGanZhi, isTianPan: boolean): string[] {
    const ganList = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const result: string[] = new Array(9).fill('');
    
    if (isTianPan) {
      // 天盘：根据《遁甲符应经》规则精确布局三奇六仪
      // 三奇（乙丙丁）和六仪（戊己庚辛壬癸）的布局遵循特定规则
      
      // 首先确定值符的位置
      const zhiFuPalace = ju.zhiFuPalace;
      
      // 根据《遁甲符应经》：三奇六仪随天盘运行
      // 甲在值符宫，其他干支按阴阳遁顺飞或逆飞
      result[zhiFuPalace] = '甲';
      
      // 其余天干的布局
      const remainingGans = ['乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
      
      if (ju.dunType === DunType.YANG) {
        // 阳遁顺飞
        let placementIndex = (zhiFuPalace + 1) % 9;
        for (const gan of remainingGans) {
          // 跳过中宫和已有天干的宫位，最多循环9次避免死循环
          let attempts = 0;
          while ((placementIndex === 4 || result[placementIndex] !== '') && attempts < 9) {
            placementIndex = (placementIndex + 1) % 9;
            attempts++;
          }
          
          if (attempts < 9 && placementIndex !== zhiFuPalace && result[placementIndex] === '') {
            result[placementIndex] = gan;
          }
          
          placementIndex = (placementIndex + 1) % 9;
        }
      } else {
        // 阴遁逆飞
        let placementIndex = (zhiFuPalace - 1 + 9) % 9;
        for (const gan of remainingGans) {
          // 跳过中宫和已有天干的宫位，最多循环9次避免死循环
          let attempts = 0;
          while ((placementIndex === 4 || result[placementIndex] !== '') && attempts < 9) {
            placementIndex = (placementIndex - 1 + 9) % 9;
            attempts++;
          }
          
          if (attempts < 9 && placementIndex !== zhiFuPalace && result[placementIndex] === '') {
            result[placementIndex] = gan;
          }
          
          placementIndex = (placementIndex - 1 + 9) % 9;
        }
      }
    } else {
      // 地盘：固定布局（与九宫固定对应）
      // 地盘排列：戊己庚辛甲壬癸乙丙
      const diPanGans = ['戊', '己', '庚', '辛', '甲', '壬', '癸', '乙', '丙'];
      for (let i = 0; i < 9; i++) {
        result[i] = diPanGans[i];
      }
    }
    
    return result;
  }

  /**
   * 布八神（九天、九地、太阴、六合、白虎、玄武、朱雀、腾蛇）
   */
  private layoutDeities(ju: JuInfo, hourGanZhi: HourGanZhi): string[] {
    const deityNames = ['值符', '腾蛇', '太阴', '六合', '白虎', '玄武', '九地', '九天'];
    const result: string[] = new Array(9).fill('');
    
    // 根据《遁甲符应经》：九天九地太阴六合的定位规则
    // 冬至后阳遁：值符后一为九天，后二为九地，前二为太阴，前三为六合
    // 夏至后阴遁：值符前一为九天，前二为九地，后二为太阴，后三为六合
    
    const zhiFuPalace = ju.zhiFuPalace;
    
    if (ju.dunType === DunType.YANG) {
      // 阳遁：后一九天，后二九地，前二太阴，前三六合
      result[zhiFuPalace] = '值符';
      result[(zhiFuPalace + 1) % 9] = '九天';
      result[(zhiFuPalace + 2) % 9] = '九地';
      result[(zhiFuPalace - 2 + 9) % 9] = '太阴';
      result[(zhiFuPalace - 3 + 9) % 9] = '六合';
      // 其余四位填充其他神煤
      result[(zhiFuPalace + 3) % 9] = '白虎';
      result[(zhiFuPalace + 4) % 9] = '玄武';
      result[(zhiFuPalace - 1 + 9) % 9] = '腾蛇';
    } else {
      // 阴遁：前一九天，前二九地，后二太阴，后三六合
      result[zhiFuPalace] = '值符';
      result[(zhiFuPalace - 1 + 9) % 9] = '九天';
      result[(zhiFuPalace - 2 + 9) % 9] = '九地';
      result[(zhiFuPalace + 2) % 9] = '太阴';
      result[(zhiFuPalace + 3) % 9] = '六合';
      // 其余四位填充其他神煤
      result[(zhiFuPalace - 3 + 9) % 9] = '白虎';
      result[(zhiFuPalace - 4 + 9) % 9] = '玄武';
      result[(zhiFuPalace + 1) % 9] = '腾蛇';
    }
    
    // 中宫特殊处理
    if (result[4] === '') {
      result[4] = '天禽'; // 中宫固定为天禽
    }
    
    return result;
  }

  /**
   * 生成结构标签
   */
  private generateStructureTag(ju: JuInfo): string {
    return `${ju.dunType === DunType.YANG ? '阳遁' : '阴遁'}${ju.juNumber}局研习`;
  }

  /**
   * 创建空盘（当无法获取干支信息时）
   */
  private createEmptyPan(input: DunjiaInput): DunjiaPanResult {
    const palaceNames: string[] = ['一宫坎', '二宫坤', '三宫震', '四宫巽', '五宫中', '六宫乾', '七宫兑', '八宫艮', '九宫离'];
    const palaceElements: string[] = ['水', '土', '木', '木', '土', '金', '金', '土', '火'];

    const palaces: PalaceState[] = palaceNames.map((name: string, index: number): PalaceState => {
      return {
        palace: index as PalaceIndex,
        palaceName: name,
        palaceElement: palaceElements[index]
      } as PalaceState;
    });

    return {
      dunType: DunType.YANG,
      juLabel: '数据加载中',
      input,
      zhiFuPalace: 4,
      zhiShiPalace: 4,
      palaces,
      ruleHits: [],
      summary: {
        structureTag: '',
        overview: '',
        focusPoints: [] as string[]
      }
    };
  }

  /**
   * 便捷方法：从当前时间生成默认输入（可用于"从当前日期进入时空盘"的场景）。
   * longitude 由调用方决定，可使用城市经度或用户自定义经度。
   */
  public createDefaultInput(dateTime: Date, longitude: number): DunjiaInput {
    return {
      dateTime,
      longitude,
      sceneType: DunjiaSceneType.GENERAL_STUDY
    };
  }

  /**
   * 计算真太阳时偏移量
   * @param longitude 经度
   * @returns 偏移量（分钟）
   */
  private calculateSolarTimeOffset(longitude: number): number {
    // 真太阳时偏移量计算公式：(经度 - 120) × 4分钟
    return (longitude - 120) * 4;
  }

  /**
   * 识别奇门遁甲格局
   * @param ju 局信息
   * @param palaces 九宫状态
   * @param dayInfo 当日信息
   * @param hourGanZhi 时辰干支
   */

  /**
   * 识别奇门遁甲格局
   * @param ju 局信息
   * @param palaces 九宫状态
   * @param dayInfo 当日信息
   * @param hourGanZhi 时辰干支
   */
  private identifyGejuPatterns(ju: JuInfo, palaces: PalaceState[], dayInfo: CalendarDayInfo, hourGanZhi: HourGanZhi): GejuPattern[] {
    const patterns: GejuPattern[] = [];
    
    // 1. 识别三奇得使格局
    // 三奇（乙丙丁）临八门之一，且该门为值使门
    const sanQiGan = ['乙', '丙', '丁'];
    for (const gan of sanQiGan) {
      const ganPalaceIndex = palaces.findIndex(p => p.tianGan === gan);
      if (ganPalaceIndex !== -1 && ganPalaceIndex === ju.zhiShiPalace) {
        patterns.push({
          id: `sanqi_deshi_${gan}`,
          name: `三奇得使(${gan})`,
          description: `${gan}奇临值使门，为三奇得使格局，主贵人扶助，事半功倍`,
          palaceIndices: [ganPalaceIndex],
          level: 'major'
        });
      }
    }
    
    // 2. 识别三奇合格局
    // 三奇（乙丙丁）同在一宫
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      // 检查一个宫位中是否同时有乙丙丁三个天干
      const allGanInPalace: string[] = [];
      if (palace.tianGan) allGanInPalace.push(palace.tianGan);
      if (palace.diGan) allGanInPalace.push(palace.diGan);
      if (sanQiGan.every(qi => allGanInPalace.includes(qi))) {
        patterns.push({
          id: `sanqi_he_${i}`,
          name: `三奇合局`,
          description: `乙丙丁三奇同聚${palace.palaceName}，为三奇合局，主大吉昌隆`,
          palaceIndices: [i],
          level: 'major'
        });
      }
    }
    
    // 3. 识别天遁格局
    // 丙奇临开、休、生三吉门，且临天上六甲
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      if (palace.tianGan === '丙' && ['开门', '休门', '生门'].includes(palace.doorName || '') &&
          (palace.diGan === '甲' || palace.diGan === '戊' || palace.diGan === '己')) {
        patterns.push({
          id: `tian_dun_${i}`,
          name: `天遁`,
          description: `丙奇临${palace.doorName}，得天时之利，宜争讼、陈诉、上书、献策等`,
          palaceIndices: [i],
          level: 'major'
        });
      }
    }
    
    // 4. 识别地遁格局
    // 乙奇临开门或杜门，且临地下六己
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      if (palace.tianGan === '乙' && ['开门', '杜门'].includes(palace.doorName || '') &&
          (palace.diGan === '己')) {
        patterns.push({
          id: `di_dun_${i}`,
          name: `地遁`,
          description: `乙奇临${palace.doorName}，得地利之便，宜埋葬、修造、建厂、藏兵等`,
          palaceIndices: [i],
          level: 'major'
        });
      }
    }
    
    // 5. 识别人遁格局
    // 丁奇临杜门
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      if (palace.tianGan === '丁' && palace.doorName === '杜门') {
        patterns.push({
          id: `ren_dun_${i}`,
          name: `人遁`,
          description: `丁奇临杜门，得人和之助，宜潜藏、匿形、和谈、密谋等`,
          palaceIndices: [i],
          level: 'major'
        });
      }
    }
    
    // 6. 识别伏吟格局
    // 天盘地盘相同
    for (let i = 0; i < 9; i++) {
      if (palaces[i].tianGan && palaces[i].diGan && palaces[i].tianGan === palaces[i].diGan) {
        patterns.push({
          id: `fu_yin_${i}`,
          name: `伏吟`,
          description: `${palaces[i].tianGan}干在${palaces[i].palaceName}伏吟，主静守为宜，不宜轻举妄动`,
          palaceIndices: [i],
          level: 'minor'
        });
      }
    }
    
    // 7. 识别反吹格局
    // 甲子与甲午、甲戌与甲辰、甲申与甲寅相对
    const oppositePairs = [
      ['甲子', '甲午'],
      ['甲戌', '甲辰'],
      ['甲申', '甲寅']
    ];
    for (let i = 0; i < 9; i++) {
      for (let j = i + 1; j < 9; j++) {
        const tianGan1 = palaces[i].tianGan || '';
        const tianGan2 = palaces[j].tianGan || '';
        const diGan1 = palaces[i].diGan || '';
        const diGan2 = palaces[j].diGan || '';
        const hasOpposite = oppositePairs.some(pair => 
          (pair.includes(tianGan1) && pair.includes(diGan2)) || 
          (pair.includes(diGan1) && pair.includes(tianGan2))
        );
        if (hasOpposite) {
          patterns.push({
            id: `fan_yin_${i}_${j}`,
            name: `反吹`,
            description: `${tianGan1}与${tianGan2}在宫位间反吹，主变动、反复，宜谨慎行事`,
            palaceIndices: [i, j],
            level: 'minor'
          });
        }
      }
    }
        
    // 8. 识别青龙返首格局（中卷）
    // 六甲加六丙：天盘甲（或戊己代甲）加地盘丙
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      const tianGan = palace.tianGan || '';
      const diGan = palace.diGan || '';
          
      // 天盘为甲或戊己（代甲），地盘为丙
      if (['甲', '戊', '己'].includes(tianGan) && diGan === '丙') {
        patterns.push({
          id: `qinglong_huishou_${i}`,
          name: `青龙返首`,
          description: `六甲加六丙于${palace.palaceName}，龙回首之象，造举百事皆吉`,
          palaceIndices: [i],
          level: 'special'
        });
      }
    }
        
    // 9. 识别飞鸟跌穴格局（中卷）
    // 六丙加六甲：天盘丙加地盘甲（或戊己）
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      const tianGan = palace.tianGan || '';
      const diGan = palace.diGan || '';
          
      // 天盘为丙，地盘为甲或戊己（代甲）
      if (tianGan === '丙' && ['甲', '戊', '己'].includes(diGan)) {
        patterns.push({
          id: `feiniao_diexue_${i}`,
          name: `飞鸟跌穴`,
          description: `六丙加六甲于${palace.palaceName}，鸟归巢之象，百事皆吉`,
          palaceIndices: [i],
          level: 'special'
        });
      }
    }
        
    // 10. 识别三奇入墓格局（中卷）
    // 乙奇入辰宫（木墓），丙丁奇入戌宫（火墓）
    const muMuGong = 3;  // 巽宫（辰位）
    const huoMuGong = 5; // 乾宫（戌位）
        
    // 乙奇入辰宫
    if (palaces[muMuGong].tianGan === '乙') {
      patterns.push({
        id: `sanqi_rumu_yi`,
        name: `三奇入墓`,
        description: `乙奇入辰宫木墓，精华被掩，吉力大减`,
        palaceIndices: [muMuGong],
        level: 'major'
      });
    }
        
    // 丙丁奇入戌宫
    if (palaces[huoMuGong].tianGan === '丙' || palaces[huoMuGong].tianGan === '丁') {
      const qiName = palaces[huoMuGong].tianGan;
      patterns.push({
        id: `sanqi_rumu_${qiName}`,
        name: `三奇入墓`,
        description: `${qiName}奇入戌宫火墓，精华被掩，吉力大减`,
        palaceIndices: [huoMuGong],
        level: 'major'
      });
    }
        
    // 11. 识别六仪击刑格局(中卷)
    // 三刑之时:寅巳申三刑、丑戌未三刑、子卯相刑
    const shiZhi = hourGanZhi.zhi;
    const sanXing1 = ['寅', '巳', '申'];  // 寅巳申三刑
    const sanXing2 = ['丑', '戌', '未'];  // 丑戌未三刑
    const sanXing3 = ['子', '卯'];          // 子卯相刑
        
    if (sanXing1.includes(shiZhi)) {
      patterns.push({
        id: `liuyi_jixing_1`,
        name: `六仪击刑`,
        description: `寅巳申三刑之时,天地不顺,百事不宜`,
        palaceIndices: [],
        level: 'major'
      });
    } else if (sanXing2.includes(shiZhi)) {
      patterns.push({
        id: `liuyi_jixing_2`,
        name: `六仪击刑`,
        description: `丑戌未三刑之时,天地不顺,百事不宜`,
        palaceIndices: [],
        level: 'major'
      });
    } else if (sanXing3.includes(shiZhi)) {
      patterns.push({
        id: `liuyi_jixing_3`,
        name: `六仪击刑`,
        description: `子卯相刑之时,天地不顺,百事不宜`,
        palaceIndices: [],
        level: 'major'
      });
    }
        
    // 12. 识别太白入荧惑格局（中卷）
    // 天盘庚加地盘丙
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      if (palace.tianGan === '庚' && palace.diGan === '丙') {
        patterns.push({
          id: `taibai_ru_yinghuo_${i}`,
          name: `太白入荧惑`,
          description: `庚加丙于${palace.palaceName}，白虎入赤地，利反击、利突袭`,
          palaceIndices: [i],
          level: 'major'
        });
      }
    }
        
    // 13. 识别荧惑入太白格局（中卷）
    // 天盘丙加地盘庚
    for (let i = 0; i < 9; i++) {
      const palace = palaces[i];
      if (palace.tianGan === '丙' && palace.diGan === '庚') {
        patterns.push({
          id: `yinghuo_ru_taibai_${i}`,
          name: `荧惑入太白`,
          description: `丙加庚于${palace.palaceName}，赤炎遇刚金，敌方退却之象`,
          palaceIndices: [i],
          level: 'minor'
        });
      }
    }
        
    // 14. 识别天网四张格局(中卷)
    // 四季尾月(辰戌丑未月)戊己日
    const sijiYue = ['辰', '戌', '丑', '未'];  // 辰戌丑未月
    const monthZhi: string = dayInfo.month_zhi || '';  // 使用月支信息
    const dayGan: string = dayInfo.day_gan;
        
    if (sijiYue.includes(monthZhi) && ['戊', '己'].includes(dayGan)) {
      patterns.push({
        id: `tianwang_sizhang`,
        name: `天网四张`,
        description: `四季尾月戊己日,天罗地网,诸事不宜`,
        palaceIndices: [],
        level: 'major'
      });
    }
    
    return patterns;
  }
}



// 内部类型定义
interface JuInfo {
  dunType: DunType;
  juNumber: number;
  zhiFuPalace: PalaceIndex;
  zhiShiPalace: PalaceIndex;
}

interface HourGanZhi {
  gan: string;          // 时干
  zhi: string;          // 时支
  ganIndex: number;     // 干索引 0-9
  zhiIndex: number;     // 支索引 0-11
}

interface ZhiFuZhiShiInfo {
  zhiFuPalace: PalaceIndex;
  zhiShiPalace: PalaceIndex;
}
