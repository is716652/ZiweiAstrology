import { common } from '@kit.AbilityKit';
import { buffer, JSON as ArkJSON } from '@kit.ArkTS';
import { SolarTermCalculator, SolarTermInfo } from './SolarTermCalculator';

export interface CalendarDayInfo {
  date: string;
  year: number;
  month: number;
  day: number;
  lunar_year: number;
  lunar_month: number;
  lunar_day: number;
  zodiac: string;
  year_gan: string;
  year_zhi: string;
  month_gan: string;
  month_zhi: string;
  day_gan: string;
  day_zhi: string;
  week_day: number;
  week_name: string;
  is_holiday: number;
  holiday_name: string;
  solar_term: string;
  festivals: string;
  // 节气精确时刻（如果是节气当天）
  solar_term_time?: SolarTermInfo;
}

export class CalendarManager {
  private static instance: CalendarManager;
  private context: common.Context | null = null;
  private cachedData: Map<string, Array<CalendarDayInfo>> = new Map();

  private constructor() {}

  public static getInstance(): CalendarManager {
    if (!CalendarManager.instance) {
      CalendarManager.instance = new CalendarManager();
    }
    return CalendarManager.instance;
  }

  public init(context: common.Context): void {
    this.context = context;
  }

  /**
   * 获取指定日期的详细万年历信息
   */
  public async getDayInfo(year: number, month: number, day: number): Promise<CalendarDayInfo | null> {
    if (!this.context) {
      console.error('CalendarManager not initialized with context');
      return null;
    }

    const fileName = this.getFileNameForYear(year);
    if (!fileName) {
      return null;
    }

    let yearData: Array<CalendarDayInfo> | undefined = this.cachedData.get(fileName);
    if (!yearData) {
      const loaded = await this.loadJson(`calendar/${fileName}`);
      if (loaded) {
        yearData = loaded;
        this.cachedData.set(fileName, yearData);
      }
    }

    if (!yearData) {
      return null;
    }

    const dateStr = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
    const dayInfo = yearData.find(item => item.date === dateStr);
    
    if (!dayInfo) {
      return null;
    }
    
    // 如果是节气当天，附加节气精确时刻
    if (dayInfo.solar_term) {
      const date = new Date(year, month - 1, day);
      const termInfo = SolarTermCalculator.getInstance().getSolarTermByDate(date);
      if (termInfo) {
        dayInfo.solar_term_time = termInfo;
      }
    }
    
    return dayInfo;
  }

  private getFileNameForYear(year: number): string | null {
    if (year < 1900 || year > 2060) {
      return null;
    }
    // 根据 calendar_data.md 的规则计算文件名
    // 1900-1909 是 0001
    // 1910-1919 是 0002
    // ...
    // 2050-2059 是 0016
    // 2060-2060 是 0017
    if (year === 2060) {
      return 'calendar_data_0017.json';
    }
    const index = Math.floor((year - 1900) / 10) + 1;
    return `calendar_data_${index.toString().padStart(4, '0')}.json`;
  }

  private async loadJson(path: string): Promise<Array<CalendarDayInfo> | null> {
    if (!this.context) return null;
    try {
      const value = await this.context.resourceManager.getRawFileContent(path);
      const str = buffer.from(value.buffer).toString();
      return ArkJSON.parse(str) as Array<CalendarDayInfo>;
    } catch (err) {
      console.error(`Failed to load calendar data: ${path}`, err);
      return null;
    }
  }
}
