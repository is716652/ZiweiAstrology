/**
 * CalendarGrid 日历网格组件
 * 
 * 功能：
 * - 显示星期标题行（周一～周日）
 * - 显示6×7日期网格（包含上月尾部、当月、下月开头）
 * - 支持日期选中状态高亮
 * - 日期点击事件回调
 * 
 * 使用示例：
 * CalendarGrid({
 *   calendarDays: this.calendarDays,
 *   selectedDate: this.selectedDate,
 *   onDaySelected: (dayCell: DayCell) => {
 *     this.onDaySelected(dayCell);
 *   }
 * })
 */

export interface DayCell {
  day: number;          // 公历日期数字
  isCurrentMonth: boolean;  // 是否当月
  date: Date;           // 完整日期对象
  lunarDay?: string;    // 农历日期（如“初一”、“十五”）
  solarTerm?: string;   // 节气（如“立春”、“春分”）
  hasFestival?: boolean; // 是否有节日
}

@Component
export struct CalendarGrid {
  @Prop calendarDays: DayCell[] = [];
  @Prop selectedDate: Date = new Date();
  
  onDaySelected?: (dayCell: DayCell) => void;
  onDayDoubleClick?: (dayCell: DayCell) => void;
  
  private weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  private lastClickTime: number = 0;
  private lastClickDay: DayCell | null = null;
  private DOUBLE_CLICK_DELAY: number = 300; // 双击间隔300ms

  // 判断是否为选中日期
  isSelectedDate(dayCell: DayCell): boolean {
    return dayCell.date.getFullYear() === this.selectedDate.getFullYear() &&
           dayCell.date.getMonth() === this.selectedDate.getMonth() &&
           dayCell.date.getDate() === this.selectedDate.getDate();
  }

  // 判断是否为今天
  isToday(dayCell: DayCell): boolean {
    const today = new Date();
    return dayCell.date.getFullYear() === today.getFullYear() &&
           dayCell.date.getMonth() === today.getMonth() &&
           dayCell.date.getDate() === today.getDate();
  }

  build() {
    Column({ space: 0 }) {
      // 星期标题行
      Row() {
        ForEach(this.weekDays, (weekDay: string) => {
          Text(weekDay)
            .fontSize(14)
            .fontColor('#999999')
            .width(`${100/7}%`)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')
      .height(36)
      .backgroundColor('#F5F1E8')

      // 日期网格 (6周 x 7天)
      Column({ space: 0 }) {
        ForEach([0, 1, 2, 3, 4, 5], (weekIndex: number) => {
          Row({ space: 0 }) {
            ForEach(this.calendarDays.slice(weekIndex * 7, (weekIndex + 1) * 7), (dayCell: DayCell) => {
              this.buildDayCell(dayCell)
            })
          }
          .width('100%')
        })
      }
      .width('100%')
    }
    .width('90%')
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .border({ width: 1, color: '#eeeeee' })
  }

  @Builder buildDayCell(dayCell: DayCell) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 2 }) {
        // 公历日期
        Text(dayCell.day.toString())
          .fontSize(16)
          .fontColor(
            this.isToday(dayCell) ? '#FF6B35' : // 今天用橙色
            (dayCell.isCurrentMonth ? '#2C2416' : '#cccccc')
          )
          .fontWeight(
            this.isSelectedDate(dayCell) || this.isToday(dayCell) ? FontWeight.Bold : FontWeight.Normal
          )
        
        // 农历日期/节气
        if (dayCell.solarTerm && dayCell.isCurrentMonth) {
          // 优先显示节气
          Text(dayCell.solarTerm)
            .fontSize(10)
            .fontColor('#E74C3C')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
        } else if (dayCell.lunarDay) {
          // 其次显示农历
          Text(dayCell.lunarDay)
            .fontSize(10)
            .fontColor(
              this.isToday(dayCell) ? '#FF6B35' : // 今天用橙色
              (dayCell.isCurrentMonth ? '#999999' : '#dddddd')
            )
            .maxLines(1)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      // 节日标记（右上角小圆点）
      if (dayCell.hasFestival && dayCell.isCurrentMonth) {
        Circle({ width: 6, height: 6 })
          .fill('#FF6B35')
          .margin({ top: 4, right: 4 })
      }
    }
    .width(`${100/7}%`)
    .height(60)
    .backgroundColor(this.isSelectedDate(dayCell) ? '#E8F4FD' : '#ffffff')
    .border({
      width: this.isSelectedDate(dayCell) ? 2 : (this.isToday(dayCell) ? 1 : 0),
      color: this.isSelectedDate(dayCell) ? '#4A90E2' : (this.isToday(dayCell) ? '#FF6B35' : '#ffffff')
    })
    .borderRadius(6)
    .onClick(() => {
      const currentTime = Date.now();
      const isSameDay = this.lastClickDay?.date.getTime() === dayCell.date.getTime();
      const isDoubleClick = isSameDay && (currentTime - this.lastClickTime) < this.DOUBLE_CLICK_DELAY;
      
      if (isDoubleClick) {
        // 双击事件
        if (this.onDayDoubleClick) {
          this.onDayDoubleClick(dayCell);
        }
        this.lastClickTime = 0;
        this.lastClickDay = null;
      } else {
        // 单击事件
        this.lastClickTime = currentTime;
        this.lastClickDay = dayCell;
        if (this.onDaySelected) {
          this.onDaySelected(dayCell);
        }
      }
    })
  }
}
