/**
 * 万年历页面 - 月份切换头部组件
 *
 * 功能：
 * - 显示当前年份与月份
 * - 提供上一月 / 下一月切换按钮
 * - 可在任意使用万年历的页面复用
 *
 * 使用方式：
 * ```typescript
 * CalendarHeader({
 *   year: this.currentYear,
 *   month: this.currentMonth,
 *   onPrevMonth: () => {
 *     this.changeMonth(-1);
 *   },
 *   onNextMonth: () => {
 *     this.changeMonth(1);
 *   }
 * })
 * ```
 */
@Component
export struct CalendarHeader {
  @Prop year: number = 2024;
  @Prop month: number = 1;

  onPrevMonth?: () => void;
  onNextMonth?: () => void;
  onToday?: () => void;
  onYearClick?: () => void;
  onMonthClick?: () => void;

  build() {
    Row() {
      // 上一月
      Text('◀')
        .fontSize(24)
        .fontColor('#D4A574')
        .padding(8)
        .onClick(() => {
          if (this.onPrevMonth) {
            this.onPrevMonth();
          }
        });

      // 当前年月
      Row({ space: 4 }) {
        Text(`${this.year}年`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D4A574')
          .onClick(() => {
            if (this.onYearClick) {
              this.onYearClick();
            }
          });
        Text(`${this.month}月`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D4A574')
          .onClick(() => {
            if (this.onMonthClick) {
              this.onMonthClick();
            }
          });
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
      
      // 返回今天
      Text('今')
        .fontSize(14)
        .fontColor('#4A90E2')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#E8F4FD')
        .borderRadius(4)
        .margin({ right: 8 })
        .onClick(() => {
          if (this.onToday) {
            this.onToday();
          }
        });

      // 下一月
      Text('▶')
        .fontSize(24)
        .fontColor('#D4A574')
        .padding(8)
        .onClick(() => {
          if (this.onNextMonth) {
            this.onNextMonth();
          }
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }
}
