/**
 * LunarInfoPanel 农历信息面板组件
 * 
 * 功能：
 * - 显示农历日期（农历年月日）
 * - 显示生肖
 * - 显示节气节日信息（包含交节时刻）
 * 
 * 使用示例：
 * LunarInfoPanel({
 *   lunarYear: this.dayInfo.lunar_year,
 *   lunarMonth: this.dayInfo.lunar_month,
 *   lunarDay: this.dayInfo.lunar_day,
 *   zodiac: this.dayInfo.zodiac,
 *   solarTerm: this.dayInfo.solar_term,
 *   solarTermTime: this.dayInfo.solar_term_time,
 *   festivals: this.dayInfo.festivals
 * })
 */

import { SolarTermCalculator, SolarTermInfo } from '../utils/SolarTermCalculator';

@Component
export struct LunarInfoPanel {
  @Prop lunarYear: string = '';
  @Prop lunarMonth: number = 1;
  @Prop lunarDay: number = 1;
  @Prop zodiac: string = '';
  @Prop yearGan: string = '';  // 年干
  @Prop yearZhi: string = '';  // 年支
  @Prop monthGan: string = '';  // 月干
  @Prop monthZhi: string = '';  // 月支
  @Prop dayGan: string = '';  // 日干
  @Prop dayZhi: string = '';  // 日支
  @Prop shiGan: string = '';  // 时干
  @Prop shiZhi: string = '';  // 时支
  @Prop solarTerm: string = '';
  @Prop solarTermTime: SolarTermInfo | null = null;
  @Prop festivals: string = '';

  build() {
    Column({ space: 12 }) {
      // 农历信息
      Column({ space: 8 }) {
        Text('📅 农历信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2416')
          .width('100%')
        
        // 农历日期 - 放大显示
        Text(`${this.lunarYear}年 ${this.getLunarMonth()}${this.getLunarDay()}`)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2C2416')
          .width('100%')
          .margin({ top: 4 })
        
        Text(`生肖：${this.zodiac}`)
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .margin({ top: 4 })
        
        // 四柱八字
        Text(`${this.yearGan}${this.yearZhi}年 ${this.monthGan}${this.monthZhi}月 ${this.dayGan}${this.dayZhi}日 ${this.shiGan}${this.shiZhi}时`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D4A574')
          .width('100%')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .border({ width: 1, color: '#eeeeee' })

      // 节气节日
      if (this.solarTerm || this.festivals) {
        Column({ space: 8 }) {
          Text('🌸 节气节日')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2C2416')
            .width('100%')
          
          // 节日信息
          if (this.festivals) {
            Text(`节日：${this.festivals}`)
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
          }
          
          // 节气信息及精确时刻
          if (this.solarTerm) {
            Column({ space: 4 }) {
              Text(`节气：${this.solarTerm}`)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
              
              // 显示节气精确时刻
              if (this.solarTermTime) {
                Row({ space: 4 }) {
                  Text('⏰ 交节时刻：')
                    .fontSize(13)
                    .fontColor('#999999')
                  Text(SolarTermCalculator.formatSolarTermTime(this.solarTermTime).split(' ')[1])
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#D4A574')
                }
              }
            }
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .border({ width: 1, color: '#eeeeee' })
      }
    }
    .width('100%')
  }

  getLunarMonth(): string {
    const months = ['正月', '二月', '三月', '四月', '五月', '六月', 
                    '七月', '八月', '九月', '十月', '冬月', '腊月'];
    return months[this.lunarMonth - 1] || `${this.lunarMonth}月`;
  }

  getLunarDay(): string {
    const days = ['初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
                  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
                  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'];
    return days[this.lunarDay - 1] || `${this.lunarDay}日`;
  }
}
