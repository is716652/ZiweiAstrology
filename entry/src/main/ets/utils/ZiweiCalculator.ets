import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';

/**
 * 紫微斗数排盘引擎
 * 基于传统紫微斗数理论实现完整排盘算法
 */

// 星曜规则数据结构
interface StarInfo {
  name: string;
  offset: number;
}

interface StarSystem {
  description: string;
  stars: StarInfo[];
}

interface TianfuSystem {
  description: string;
  tianfu_offset: number;
  stars: StarInfo[];
}

interface LucunRule {
  name: string;
  rule: string;
  positions: Record<string, number>;
}

interface AuxiliaryStarsRule {
  name: string;
  rule: string;
}

interface AuxiliaryStars {
  description: string;
  left_fu: AuxiliaryStarsRule;
  right_bi: AuxiliaryStarsRule;
  lucun: LucunRule;
}

interface FourTransform {
  lu: string;
  quan: string;
  ke: string;
  ji: string;
}

interface StarRulesData {
  description: string;
  ziwei_system: StarSystem;
  tianfu_system: TianfuSystem;
  auxiliary_stars: AuxiliaryStars;
  four_transforms: Record<string, FourTransform>;
}

// 出生信息
export interface BirthInfo {
  solarDate: Date;           // 公历日期
  lunarYear: number;         // 农历年
  lunarMonth: number;        // 农历月
  lunarDay: number;          // 农历日
  shichenIndex: number;      // 时辰索引（0-11）
  yearGan: string;           // 年干
  yearZhi: string;           // 年支
  monthGan: string;          // 月干
  monthZhi: string;          // 月支
  dayGan: string;            // 日干
  dayZhi: string;            // 日支
  shiGan: string;            // 时干
  shiZhi: string;            // 时支
}

// 五行局信息
export interface WuxingJuInfo {
  nayin: string;             // 纳音
  ju: number;                // 局数（2/3/4/5/6）
}

// 五行局数据结构
interface WuxingJuData {
  description: string;
  data: Record<string, WuxingJuInfo>;
}

// 宫位信息
export interface PalaceInfo {
  index: number;             // 宫位索引（0-11）
  name: string;              // 宫位名称
  zhi: string;               // 地支
  gan: string;               // 天干
  mainStars: string[];       // 主星列表
  auxiliaryStars: string[];  // 辅星列表
  transforms: string[];      // 四化
}

// 命盘结果
export interface ZiweiChart {
  birthInfo: BirthInfo;      // 出生信息
  mingGongIndex: number;     // 命宫索引
  shenGongIndex: number;     // 身宫索引
  wuxingJu: WuxingJuInfo;    // 五行局
  ziweiPosition: number;     // 紫微位置
  tianfuPosition: number;    // 天府位置
  palaces: PalaceInfo[];     // 12宫信息
}

/**
 * 紫微斗数排盘计算器
 */
export class ZiweiCalculator {
  private static instance: ZiweiCalculator;
  private wuxingJuTable: Map<string, WuxingJuInfo> = new Map();
  private starRules: StarRulesData | null = null;
  private context: Context | null = null;

  // 十二地支顺序
  private readonly ZHI_ORDER = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  
  // 十天干顺序
  private readonly GAN_ORDER = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

  // 十二宫位名称（从命宫开始逆时针）
  private readonly PALACE_NAMES = [
    '命宫', '兄弟宫', '夫妻宫', '子女宫', '财帛宫', '疾厄宫',
    '迁移宫', '仆役宫', '官禄宫', '田宅宫', '福德宫', '父母宫'
  ];

  private constructor() {}

  static getInstance(): ZiweiCalculator {
    if (!ZiweiCalculator.instance) {
      ZiweiCalculator.instance = new ZiweiCalculator();
    }
    return ZiweiCalculator.instance;
  }

  /**
   * 初始化（加载JSON配置）
   */
  async init(context: Context): Promise<void> {
    this.context = context;
    await this.loadWuxingJuTable();
    await this.loadStarRules();
  }

  /**
   * 加载五行局纳音表
   */
  private async loadWuxingJuTable(): Promise<void> {
    try {
      const mgr = this.context!.resourceManager;
      const content = await mgr.getRawFileContent('ziwei/wuxing_ju_table.json');
      const decoder = util.TextDecoder.create('utf-8');
      const jsonStr = decoder.decodeToString(content);
      const data = JSON.parse(jsonStr) as WuxingJuData;

      const entries = Object.entries(data.data);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        this.wuxingJuTable.set(entry[0], entry[1]);
      }
    } catch (error) {
      console.error('加载五行局表失败:', error);
    }
  }

  /**
   * 加载安星规则
   */
  private async loadStarRules(): Promise<void> {
    try {
      const mgr = this.context!.resourceManager;
      const content = await mgr.getRawFileContent('ziwei/star_rules.json');
      const decoder = util.TextDecoder.create('utf-8');
      const jsonStr = decoder.decodeToString(content);
      this.starRules = JSON.parse(jsonStr) as StarRulesData;
    } catch (error) {
      console.error('加载安星规则失败:', error);
    }
  }

  /**
   * 主排盘方法
   */
  calculate(birthInfo: BirthInfo): ZiweiChart {
    // 第一步：定命宫
    const mingGongIndex = this.calculateMingGong(birthInfo.lunarMonth, birthInfo.shichenIndex);

    // 第二步：定身宫
    const shenGongIndex = this.calculateShenGong(birthInfo.lunarMonth, birthInfo.shichenIndex);

    // 第三步：起寅首天干（五虎遁）
    const yinGan = this.getYinGan(birthInfo.yearGan);

    // 第四步：定五行局
    const mingGongGan = this.getGanByPosition(yinGan, mingGongIndex);
    const mingGongZhi = this.ZHI_ORDER[mingGongIndex];
    const wuxingJu = this.getWuxingJu(mingGongGan, mingGongZhi);

    // 第五步：定紫微星位置
    const ziweiPosition = this.calculateZiweiPosition(birthInfo.lunarDay, wuxingJu.ju);

    // 第六步：定天府位置（紫微三合宫）
    const tianfuPosition = (ziweiPosition + 4) % 12;

    // 第七步：初始化12宫
    const palaces = this.initializePalaces(mingGongIndex, yinGan);

    // 第八步：安主星
    this.arrangeMainStars(palaces, ziweiPosition, tianfuPosition);

    // 第九步：安辅星
    this.arrangeAuxiliaryStars(palaces, birthInfo);

    // 第十步：安四化
    this.arrangeFourTransforms(palaces, birthInfo.yearGan);

    // 标记命宫和身宫
    palaces[mingGongIndex].name = '命宫 ★';
    if (shenGongIndex !== mingGongIndex) {
      palaces[shenGongIndex].name += ' (身)';
    }

    return {
      birthInfo,
      mingGongIndex,
      shenGongIndex,
      wuxingJu,
      ziweiPosition,
      tianfuPosition,
      palaces
    };
  }

  /**
   * 计算命宫位置
   * 口诀：顺数生月，逆数生时
   */
  private calculateMingGong(lunarMonth: number, shichenIndex: number): number {
    // 从寅宫(2)开始顺数月份
    let position = (2 + lunarMonth - 1) % 12;

    // 从该位置逆数时辰
    position = (position - shichenIndex + 12) % 12;

    return position;
  }

  /**
   * 计算身宫位置
   * 口诀：顺数生月，顺数生时
   */
  private calculateShenGong(lunarMonth: number, shichenIndex: number): number {
    // 从寅宫(2)开始顺数月份
    let position = (2 + lunarMonth - 1) % 12;

    // 从该位置顺数时辰
    position = (position + shichenIndex) % 12;

    return position;
  }

  /**
   * 五虎遁：根据年干确定寅宫天干
   */
  private getYinGan(yearGan: string): string {
    const map: Record<string, string> = {
      '甲': '丙', '己': '丙',
      '乙': '戊', '庚': '戊',
      '丙': '庚', '辛': '庚',
      '丁': '壬', '壬': '壬',
      '戊': '甲', '癸': '甲'
    };
    return map[yearGan] || '丙';
  }

  /**
   * 根据寅宫天干和宫位索引获取该宫天干
   */
  private getGanByPosition(yinGan: string, zhiIndex: number): string {
    const yinIndex = 2; // 寅在地支中的索引
    const ganStartIndex = this.GAN_ORDER.indexOf(yinGan);
    const offset = (zhiIndex - yinIndex + 12) % 12;
    return this.GAN_ORDER[(ganStartIndex + offset) % 10];
  }

  /**
   * 查询五行局
   */
  private getWuxingJu(gan: string, zhi: string): WuxingJuInfo {
    const key = gan + zhi;
    return this.wuxingJuTable.get(key) || { nayin: '未知', ju: 5 };
  }

  /**
   * 计算紫微星位置
   */
  private calculateZiweiPosition(lunarDay: number, ju: number): number {
    let remainder = lunarDay % ju;
    if (remainder === 0) remainder = ju;

    // 从子宫(0)开始顺数
    return (remainder - 1) % 12;
  }

  /**
   * 初始化12宫基本信息
   */
  private initializePalaces(mingGongIndex: number, yinGan: string): PalaceInfo[] {
    const palaces: PalaceInfo[] = [];

    for (let i = 0; i < 12; i++) {
      // 宫位索引（从命宫开始逆时针）
      const palaceIndex = (mingGongIndex - i + 12) % 12;
      
      const palaceInfo: PalaceInfo = {
        index: palaceIndex,
        name: this.PALACE_NAMES[i],
        zhi: this.ZHI_ORDER[palaceIndex],
        gan: this.getGanByPosition(yinGan, palaceIndex),
        mainStars: [],
        auxiliaryStars: [],
        transforms: []
      };
      
      palaces.push(palaceInfo);
      
      console.info(`初始化宬位[${i}]: ${palaceInfo.name}, 地支索引=${palaceInfo.index}, ${palaceInfo.gan}${palaceInfo.zhi}宫`);
    }
    
    console.info(`共创建${palaces.length}个宫位`);

    return palaces;
  }

  /**
   * 安排主星（紫微星系+天府星系）
   */
  private arrangeMainStars(palaces: PalaceInfo[], ziweiPos: number, tianfuPos: number): void {
    if (!this.starRules) return;

    // 安紫微星系（逆时针）
    const ziweiStars = this.starRules.ziwei_system.stars;
    for (let i = 0; i < ziweiStars.length; i++) {
      const star = ziweiStars[i];
      const pos = (ziweiPos + star.offset + 12) % 12;
      const palace = palaces.find(p => p.index === pos);
      if (palace) {
        palace.mainStars.push(star.name);
      }
    }

    // 安天府星系（顺时针）
    const tianfuStars = this.starRules.tianfu_system.stars;
    for (let i = 0; i < tianfuStars.length; i++) {
      const star = tianfuStars[i];
      const pos = (tianfuPos + star.offset) % 12;
      const palace = palaces.find(p => p.index === pos);
      if (palace) {
        palace.mainStars.push(star.name);
      }
    }
  }

  /**
   * 安排辅星（左辅、右弼、禄存等）
   */
  private arrangeAuxiliaryStars(palaces: PalaceInfo[], birthInfo: BirthInfo): void {
    if (!this.starRules) return;

    // 左辅：从辰宫(4)起正月，顺数生月
    const leftFuPos = (4 + birthInfo.lunarMonth - 1) % 12;
    const leftFuPalace = palaces.find(p => p.index === leftFuPos);
    if (leftFuPalace) {
      leftFuPalace.auxiliaryStars.push('左辅');
    }

    // 右弼：从戌宫(10)起正月，逆数生月
    const rightBiPos = (10 - (birthInfo.lunarMonth - 1) + 12) % 12;
    const rightBiPalace = palaces.find(p => p.index === rightBiPos);
    if (rightBiPalace) {
      rightBiPalace.auxiliaryStars.push('右弼');
    }

    // 禄存：根据年干定位
    const lucunPositions = this.starRules.auxiliary_stars.lucun.positions;
    const lucunPos = lucunPositions[birthInfo.yearGan];
    if (lucunPos !== undefined) {
      const lucunPalace = palaces.find(p => p.index === lucunPos);
      if (lucunPalace) {
        lucunPalace.auxiliaryStars.push('禄存');
      }
    }
  }

  /**
   * 安排四化星
   */
  private arrangeFourTransforms(palaces: PalaceInfo[], yearGan: string): void {
    if (!this.starRules) return;

    const transforms = this.starRules.four_transforms[yearGan];
    if (!transforms) return;

    // 遍历所有宫位，找到四化星所在位置
    for (let i = 0; i < palaces.length; i++) {
      const palace = palaces[i];
      for (let j = 0; j < palace.mainStars.length; j++) {
        const star = palace.mainStars[j];
        if (star === transforms.lu) {
          palace.transforms.push('化禄');
        }
        if (star === transforms.quan) {
          palace.transforms.push('化权');
        }
        if (star === transforms.ke) {
          palace.transforms.push('化科');
        }
        if (star === transforms.ji) {
          palace.transforms.push('化忌');
        }
      }
    }
  }
}
