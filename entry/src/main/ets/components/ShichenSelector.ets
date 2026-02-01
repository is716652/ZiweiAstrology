/**
 * ShichenSelector 时辰选择器组件
 * 
 * 功能：
 * - 显示当前选中时辰
 * - 点击展开网格选择器（4行 x 3列）
 * - 高亮显示当前选中时辰
 * 
 * 使用示例：
 * ShichenSelector({
 *   shichenTexts: this.shichenTexts,
 *   selectedIndex: this.selectedShichenIndex,
 *   onShichenChanged: (index: number) => {
 *     this.selectedShichenIndex = index;
 *   }
 * })
 */

interface ShichenInfo {
  name: string;
  range: string;
  ganZhi: string;
}

@Component
export struct ShichenSelector {
  @Prop shichenTexts: string[] = [];
  @Prop selectedIndex: number = 0;
  
  @State showGrid: boolean = false;
  
  onShichenChanged?: (index: number) => void;

  build() {
    Column({ space: 12 }) {
      // 当前选中时辰显示区域
      Row({ space: 8 }) {
        Text('🕐')
          .fontSize(18)
        Text(this.shichenTexts[this.selectedIndex] || '请选择时辰')
          .fontSize(15)
          .fontColor('#2C2416')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(this.showGrid ? '▲' : '▼')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: '#E5E5E5' })
      .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
      .onClick(() => {
        this.showGrid = !this.showGrid;
      })
      
      // 网格选择器（展开时显示）
      if (this.showGrid) {
        Column({ space: 10 }) {
          ForEach([0, 1, 2, 3], (rowIndex: number) => {
            Row({ space: 10 }) {
              ForEach([0, 1, 2], (colIndex: number) => {
                this.buildShichenCell(rowIndex * 3 + colIndex)
              })
            }
            .width('100%')
          })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FAFAFA')
        .borderRadius(12)
      }
    }
    .width('100%')
  }

  // 解析时辰文本
  private parseShichenText(text: string): ShichenInfo {
    const match = text.match(/(\S+时)（([^)]+)）(\S+时)?/);
    return {
      name: match ? match[1] : text,
      range: match ? match[2] : '',
      ganZhi: match ? (match[3] || '') : ''
    };
  }

  @Builder buildShichenCell(index: number) {
    Column({ space: 4 }) {
      // 时辰名称
      Text(this.parseShichenText(this.shichenTexts[index] || '').name)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedIndex === index ? '#FFFFFF' : '#333333')
      
      // 干支
      Text(this.parseShichenText(this.shichenTexts[index] || '').ganZhi)
        .fontSize(12)
        .fontColor(this.selectedIndex === index ? '#FFFFFF' : '#666666')
        .visibility(this.parseShichenText(this.shichenTexts[index] || '').ganZhi ? Visibility.Visible : Visibility.None)
      
      // 时间范围
      Text(this.parseShichenText(this.shichenTexts[index] || '').range)
        .fontSize(10)
        .fontColor(this.selectedIndex === index ? 'rgba(255,255,255,0.8)' : '#999999')
        .visibility(this.parseShichenText(this.shichenTexts[index] || '').range ? Visibility.Visible : Visibility.None)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(70)
    .padding({ top: 8, bottom: 8, left: 4, right: 4 })
    .backgroundColor(this.selectedIndex === index ? '#D4A574' : '#FFFFFF')
    .borderRadius(10)
    .border({
      width: this.selectedIndex === index ? 0 : 1,
      color: '#E5E5E5'
    })
    .shadow({
      radius: this.selectedIndex === index ? 8 : 2,
      color: this.selectedIndex === index ? '#40D4A574' : '#10000000',
      offsetY: this.selectedIndex === index ? 4 : 1
    })
    .onClick(() => {
      if (this.onShichenChanged) {
        this.onShichenChanged(index);
      }
      this.showGrid = false;  // 选择后自动收起
    })
  }
}
