import { PalaceInfo } from '../utils/ZiweiCalculator';

interface GridPosition {
  row: number;
  col: number;
}

@Component
export struct ZiweiPalaceGrid {
  @Link palaces: PalaceInfo[];
  @Link mingGongIndex: number;
  @Link shenGongIndex: number;
  onPalaceClick?: (palace: PalaceInfo) => void;

  private readonly ZHI_ORDER = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  /**
   * 获取地支在Grid中的位置（符合八卦方位）
   * 子（坎）在北，午（离）在南，寅（震）在东，酉（兑）在西
   */
  getGridPosition(zhiIndex: number): GridPosition {
    const positions: GridPosition[] = [
      { row: 3, col: 2 }, // 子(0) - 下方中右（坎宫=正北）
      { row: 3, col: 3 }, // 丑(1) - 下方右
      { row: 2, col: 0 }, // 寅(2) - 左侧中下（震宫辅助）
      { row: 1, col: 0 }, // 卯(3) - 左侧中上（震宫=正东）
      { row: 0, col: 0 }, // 辰(4) - 上方左
      { row: 0, col: 1 }, // 巳(5) - 上方中左
      { row: 0, col: 2 }, // 午(6) - 上方中右（离宫=正南）
      { row: 0, col: 3 }, // 未(7) - 上方右
      { row: 1, col: 3 }, // 申(8) - 右侧中上
      { row: 2, col: 3 }, // 酉(9) - 右侧中下（兑宫=正西）
      { row: 3, col: 0 }, // 戌(10) - 下方左
      { row: 3, col: 1 }  // 亥(11) - 下方中左
    ];
    return positions[zhiIndex] || { row: 0, col: 0 };
  }

  isCenterCell(row: number, col: number): boolean {
    return (row === 1 || row === 2) && (col === 1 || col === 2);
  }

  findZhiIndex(row: number, col: number): number {
    for (let i = 0; i < 12; i++) {
      const pos = this.getGridPosition(i)
      if (pos.row === row && pos.col === col) return i
    }
    return -1
  }

  /**
   * 根据行列查找宫位
   */
  findPalaceByPosition(row: number, col: number): PalaceInfo | null {
    // 数据未加载完成
    if (this.palaces.length === 0) {
      return null
    }
      
    const zhiIndex = this.findZhiIndex(row, col)
    if (zhiIndex === -1) {
      return null
    }
      
    const palace = this.palaces.find(p => p.index === zhiIndex)
    return palace || null
  }

  /**
   * 获取宫位背景色
   */
  getPalaceBackground(palace: PalaceInfo): ResourceStr {
    if (palace.index === this.mingGongIndex) {
      return '#FFE5B4'; // 命宫金色
    }
    if (palace.index === this.shenGongIndex) {
      return '#E6E6FA'; // 身宫紫色
    }
    return '#F0F8FF'; // 普通宫位淡蓝
  }

  /**
   * 获取宫位边框色
   */
  getPalaceBorder(palace: PalaceInfo): ResourceStr {
    if (palace.index === this.mingGongIndex) {
      return '#D4A574'; // 命宫金色边框
    }
    if (palace.index === this.shenGongIndex) {
      return '#9370DB'; // 身宫紫色边框
    }
    return '#B0C4DE'; // 普通边框
  }

  build() {
    Stack() {
      Grid() {
        ForEach([0, 1, 2, 3], (row: number) => {
          ForEach([0, 1, 2, 3], (col: number) => {
            // 跳过中央2x2区域的右下角3个格子
            if (!((row === 1 && col === 2) || (row === 2 && col === 1) || (row === 2 && col === 2))) {
              GridItem() {
                if (this.isCenterCell(row, col)) {
                  this.buildCenterInfo()
                } else {
                  this.buildPalaceCell(row, col)
                }
              }
              .rowStart(row)
              .rowEnd(this.isCenterCell(row, col) ? row + 1 : row)
              .columnStart(col)
              .columnEnd(this.isCenterCell(row, col) ? col + 1 : col)
            }
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .width('100%')
      .height('100%')
      .columnsGap(2)
      .rowsGap(2)
      .backgroundColor('#D0D0D0')
    }
    .width('100%')
    .aspectRatio(1)
  }

  @Builder
  buildPalaceCell(row: number, col: number) {
    Stack() {
      if (this.findPalaceByPosition(row, col) !== null) {
        this.buildPalaceContent(this.findPalaceByPosition(row, col)!)
      }
      
      if (this.findPalaceByPosition(row, col) === null) {
        Column() {
          Text('宫位')
            .fontSize(10)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F0F8FF')
        .borderRadius(4)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildPalaceContent(palace: PalaceInfo) {
    Column({ space: 2 }) {
      // 宫位名称 + 地支
      Row({ space: 4 }) {
        Text(palace.name.replace(' ★', '').replace(' (身)', ''))
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2416')
        
        if (palace.index === this.mingGongIndex) {
          Text('★')
            .fontSize(12)
            .fontColor('#D4A574')
        }
        
        if (palace.index === this.shenGongIndex) {
          Text('身')
            .fontSize(9)
            .fontColor('#9370DB')
            .border({ width: 1, color: '#9370DB' })
            .borderRadius(2)
            .padding({ left: 2, right: 2 })
        }
      }

      Text(`${palace.zhi}宫`)
        .fontSize(8)
        .fontColor('#666666')

      Divider()
        .strokeWidth(0.5)
        .color('#CCCCCC')

      // 主星（最多显示2个）
      if (palace.mainStars.length > 0) {
        Column({ space: 1 }) {
          ForEach(palace.mainStars.slice(0, 2), (star: string) => {
            Text(star)
              .fontSize(9)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8B4513')
          })
        }
        .alignItems(HorizontalAlign.Start)
      }

      // 辅星（最多显示1个）
      if (palace.auxiliaryStars.length > 0) {
        Text(palace.auxiliaryStars[0])
          .fontSize(8)
          .fontColor('#4682B4')
      }

      // 四化
      if (palace.transforms.length > 0) {
        Text(palace.transforms.join(' '))
          .fontSize(7)
          .fontColor('#DC143C')
      }

      // 空宫提示
      if (palace.mainStars.length === 0 && palace.auxiliaryStars.length === 0) {
        Text('空宫')
          .fontSize(8)
          .fontColor('#999999')
          .fontStyle(FontStyle.Italic)
      }
    }
    .width('100%')
    .height('100%')
    .padding(4)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.getPalaceBackground(palace))
    .border({
      width: palace.index === this.mingGongIndex ? 2 : 1,
      color: this.getPalaceBorder(palace)
    })
    .borderRadius(4)
    .onClick(() => {
      if (this.onPalaceClick) {
        this.onPalaceClick(palace)
      }
    })
  }

  @Builder
  buildCenterInfo() {
    Column({ space: 4 }) {
      Text('紫微').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#8B008B')
      Text('斗数').fontSize(14).fontColor('#8B008B')
      Text('命盘').fontSize(12).fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FAFAFA')
  }
}
