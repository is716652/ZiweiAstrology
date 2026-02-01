/**
 * 真太阳时计算工具类
 * 
 * 功能：
 * - 计算真太阳时（True Solar Time）
 * - 计算均时差（Equation of Time）
 * - 计算经度时差修正
 * 
 * 算法来源：
 * - 基于天文算法，参考《Astronomical Algorithms》Jean Meeus
 * - 均时差计算精度：±1分钟
 * 
 * 使用示例：
 * ```typescript
 * const helper = new SolarTimeHelper(116.4074); // 北京经度
 * const trueSolarTime = helper.getTrueSolarTime(new Date());
 * console.log(trueSolarTime.format()); // "14:23:15"
 * ```
 */

export interface TrueSolarTimeResult {
  localTime: Date;           // 当地平太阳时
  trueSolarTime: Date;       // 真太阳时
  equationOfTime: number;    // 均时差（分钟）
  longitudeOffset: number;   // 经度时差（分钟）
  totalOffset: number;       // 总偏差（分钟）
}

export class SolarTimeHelper {
  private longitude: number;  // 当地经度（东经为正）
  private standardLongitude: number = 120;  // 标准经度（东八区）

  /**
   * 构造函数
   * @param longitude 当地经度（东经为正，西经为负）。默认120度（北京时间标准经度）
   */
  constructor(longitude: number = 120) {
    this.longitude = longitude;
  }

  /**
   * 设置当地经度
   * @param longitude 经度值
   */
  setLongitude(longitude: number): void {
    this.longitude = longitude;
  }

  /**
   * 获取真太阳时
   * @param date 当地平太阳时（本地时间）
   * @returns 真太阳时结果对象
   */
  getTrueSolarTime(date: Date): TrueSolarTimeResult {
    // 1. 计算儒略日
    const JD = this.dateToJulianDay(date);

    // 2. 计算均时差
    const equationOfTime = this.calculateEquationOfTime(JD);

    // 3. 计算经度时差
    const longitudeOffset = this.calculateLongitudeOffset();

    // 4. 计算总偏差
    const totalOffset = equationOfTime + longitudeOffset;

    // 5. 计算真太阳时
    const trueSolarTime = new Date(date.getTime() + totalOffset * 60 * 1000);

    return {
      localTime: date,
      trueSolarTime: trueSolarTime,
      equationOfTime: equationOfTime,
      longitudeOffset: longitudeOffset,
      totalOffset: totalOffset
    };
  }

  /**
   * 格式化显示真太阳时
   * @param date 本地时间
   * @returns 格式化字符串，如 "14:23"
   */
  formatTrueSolarTime(date: Date): string {
    const result = this.getTrueSolarTime(date);
    const time = result.trueSolarTime;
    const hours = time.getHours().toString().padStart(2, '0');
    const minutes = time.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 获取真太阳时与本地时间的时差描述
   * @param date 本地时间
   * @returns 时差描述，如 "快2分钟" 或 "慢5分钟"
   */
  getTimeDifferenceDescription(date: Date): string {
    const result = this.getTrueSolarTime(date);
    const offset = Math.round(result.totalOffset);
    
    if (offset === 0) {
      return "与本地时间一致";
    } else if (offset > 0) {
      return `快${offset}分钟`;
    } else {
      return `慢${Math.abs(offset)}分钟`;
    }
  }

  /**
   * 计算日期对应的儒略日（Julian Day）
   * @param date 日期对象
   * @returns 儒略日数值
   */
  private dateToJulianDay(date: Date): number {
    const year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();
    const second = date.getSeconds();

    // 1月和2月视为前一年的13月和14月
    if (month <= 2) {
      month += 12;
    }

    const a = Math.floor(year / 100);
    const b = 2 - a + Math.floor(a / 4);

    const dayFraction = (hour + minute / 60 + second / 3600) / 24;

    const JD = Math.floor(365.25 * (year + 4716)) +
               Math.floor(30.6001 * (month + 1)) +
               day + dayFraction + b - 1524.5;

    return JD;
  }

  /**
   * 计算均时差（Equation of Time）
   * 
   * 均时差是真太阳时与平太阳时之差，由以下两个因素造成：
   * 1. 地球公转轨道是椭圆而非正圆
   * 2. 地球自转轴相对于公转轨道面有倾角
   * 
   * @param JD 儒略日
   * @returns 均时差（分钟），正值表示真太阳时快于平太阳时
   */
  private calculateEquationOfTime(JD: number): number {
    // 计算儒略世纪数（从J2000.0起算）
    const T = (JD - 2451545.0) / 36525.0;

    // 太阳平黄经（度）
    const L0 = this.normalizeAngle(280.46646 + 36000.76983 * T + 0.0003032 * T * T);

    // 太阳平近点角（度）
    const M = this.normalizeAngle(357.52911 + 35999.05029 * T - 0.0001537 * T * T);

    // 地球轨道偏心率
    const e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T;

    // 黄赤交角（度）
    const epsilon = 23.439291 - 0.0130042 * T;

    // 转换为弧度
    const L0_rad = L0 * Math.PI / 180;
    const M_rad = M * Math.PI / 180;
    const epsilon_rad = epsilon * Math.PI / 180;

    // 计算均时差（使用更精确的公式）
    const y = Math.tan(epsilon_rad / 2);
    const y2 = y * y;

    // 均时差（弧度）
    const E = y2 * Math.sin(2 * L0_rad) -
              2 * e * Math.sin(M_rad) +
              4 * e * y2 * Math.sin(M_rad) * Math.cos(2 * L0_rad) -
              0.5 * y2 * y2 * Math.sin(4 * L0_rad) -
              1.25 * e * e * Math.sin(2 * M_rad);

    // 转换为分钟（1度 = 4分钟）
    const E_minutes = E * 180 / Math.PI * 4;

    return E_minutes;
  }

  /**
   * 计算经度时差修正
   * 
   * 由于地球自西向东自转，东经地区的地方时会早于标准时
   * 每相差1度经度，时间相差4分钟
   * 
   * @returns 经度时差（分钟），正值表示当地时间早于标准时
   */
  private calculateLongitudeOffset(): number {
    // 经度差（当地经度 - 标准经度）
    const longitudeDiff = this.longitude - this.standardLongitude;

    // 转换为时间差（每度4分钟）
    return longitudeDiff * 4;
  }

  /**
   * 将角度标准化到 0-360 度范围
   * @param angle 角度
   * @returns 标准化后的角度
   */
  private normalizeAngle(angle: number): number {
    let normalized = angle % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    return normalized;
  }

  /**
   * 获取详细的真太阳时信息（用于调试）
   * @param date 本地时间
   * @returns 详细信息字符串
   */
  getDetailedInfo(date: Date): string {
    const result = this.getTrueSolarTime(date);
    const localTimeStr = this.formatTime(result.localTime);
    const trueSolarTimeStr = this.formatTime(result.trueSolarTime);

    return `本地时间：${localTimeStr}\n` +
           `真太阳时：${trueSolarTimeStr}\n` +
           `均时差：${result.equationOfTime.toFixed(2)}分钟\n` +
           `经度偏差：${result.longitudeOffset.toFixed(2)}分钟\n` +
           `总偏差：${result.totalOffset.toFixed(2)}分钟`;
  }

  /**
   * 格式化时间
   * @param date 日期对象
   * @returns 格式化字符串 "HH:mm:ss"
   */
  private formatTime(date: Date): string {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }
}

/**
 * 预定义的中国主要城市经度
 */
export class ChinaCityLongitudes {
  static readonly BEIJING: number = 116.4074;      // 北京
  static readonly SHANGHAI: number = 121.4737;     // 上海
  static readonly GUANGZHOU: number = 113.2644;    // 广州
  static readonly SHENZHEN: number = 114.0579;     // 深圳
  static readonly CHENGDU: number = 104.0668;      // 成都
  static readonly HANGZHOU: number = 120.1551;     // 杭州
  static readonly XIAN: number = 108.9398;         // 西安
  static readonly WUHAN: number = 114.3055;        // 武汉
  static readonly CHONGQING: number = 106.5516;    // 重庆
  static readonly TIANJIN: number = 117.2010;      // 天津
  static readonly NANJING: number = 118.7969;      // 南京
  static readonly SHENYANG: number = 123.4328;     // 沈阳
  static readonly HARBIN: number = 126.6433;       // 哈尔滨
  static readonly KUNMING: number = 102.8329;      // 昆明
  static readonly URUMQI: number = 87.6177;        // 乌鲁木齐
  static readonly LHASA: number = 91.1145;         // 拉萨
}

export const CHINA_CITY_LONGITUDES = ChinaCityLongitudes;
