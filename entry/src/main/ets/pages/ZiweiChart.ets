import { router } from '@kit.ArkUI';
import { ZiweiCalculator, ZiweiChart, BirthInfo, PalaceInfo } from '../utils/ZiweiCalculator';
import { ZiweiPalaceGrid } from '../components/ZiweiPalaceGrid';
import { NavigationBar } from '../components/NavigationBar';

/**
 * 紫微斗数排盘页面
 */

@Entry
@Component
struct ZiweiChartPage {
  @State chart: ZiweiChart | null = null;
  @State palaces: PalaceInfo[] = [];
  @State mingGongIndex: number = 0;
  @State shenGongIndex: number = 0;
  @State selectedPalace: PalaceInfo | null = null;
  @State showPalaceDetail: boolean = false;
  @State isCalculating: boolean = true;

  private birthInfo: BirthInfo | null = null;

  async aboutToAppear() {
    // 从路由参数获取出生信息
    const params = router.getParams() as Record<string, Object>;
    
    if (!params || !params['lunarYear']) {
      // 参数不完整，返回上一页
      router.back();
      return;
    }

    this.birthInfo = {
      solarDate: new Date(params['solarDate'] as string),
      lunarYear: params['lunarYear'] as number,
      lunarMonth: params['lunarMonth'] as number,
      lunarDay: params['lunarDay'] as number,
      shichenIndex: params['shichenIndex'] as number,
      yearGan: params['yearGan'] as string,
      yearZhi: params['yearZhi'] as string,
      monthGan: params['monthGan'] as string,
      monthZhi: params['monthZhi'] as string,
      dayGan: params['dayGan'] as string,
      dayZhi: params['dayZhi'] as string,
      shiGan: params['shiGan'] as string,
      shiZhi: params['shiZhi'] as string
    };

    // 初始化计算器
    const calculator = ZiweiCalculator.getInstance();
    await calculator.init(getContext(this));

    // 执行排盘
    this.chart = calculator.calculate(this.birthInfo);
    this.palaces = this.chart.palaces;
    this.mingGongIndex = this.chart.mingGongIndex;
    this.shenGongIndex = this.chart.shenGongIndex;

    // 调试：检查所有宫位数据
    console.info(`===== 排盘完成 =====`);
    console.info(`命宫索引: ${this.mingGongIndex}, 身宫索引: ${this.shenGongIndex}`);
    console.info(`palaces数组长度: ${this.palaces.length}`);
    
    // 按数组顺序输出
    console.info('\n按数组顺序:');
    for (let i = 0; i < this.palaces.length; i++) {
      const p = this.palaces[i];
      console.info(`[${i}] ${p.name} | 地支索引=${p.index} | ${p.gan}${p.zhi} | 主星=${p.mainStars.join(',')||'无'}`);
    }
    
    // 按地支索引顺序输出
    console.info('\n按地支索引(0-11):');
    for (let zhiIndex = 0; zhiIndex < 12; zhiIndex++) {
      const p = this.palaces.find(palace => palace.index === zhiIndex);
      if (p) {
        console.info(`[地支${zhiIndex}=${p.zhi}] ${p.name} | ${p.gan}${p.zhi} | 主星=${p.mainStars.join(',')||'无'}`);
      } else {
        console.error(`!!! 缺失地支索引${zhiIndex}的宫位数据 !!!`);
      }
    }

    this.isCalculating = false;
  }

  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      NavigationBar({
        title: '紫微斗数命盘',
        showBack: true,
        onBack: () => {
          router.back();
        }
      });

      if (this.isCalculating) {
        // 加载动画
        Column({ space: 16 }) {
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#D4A574')
          
          Text('正在排盘...')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FAFAFA')
      } else if (this.chart) {
        Scroll() {
          Column({ space: 16 }) {
            // 出生信息卡片
            this.buildBirthInfoCard()
        
            // 命盘核心信息
            this.buildChartInfoCard()

            // 紫微命盘网格
            Column() {
              ZiweiPalaceGrid({
                palaces: $palaces,
                mingGongIndex: $mingGongIndex,
                shenGongIndex: $shenGongIndex,
                onPalaceClick: (palace: PalaceInfo) => {
                  this.selectedPalace = palace;
                  this.showPalaceDetail = true;
                }
              })
            }
            .width('95%')
            .padding(8)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({
              radius: 8,
              color: 'rgba(0, 0, 0, 0.1)',
              offsetX: 0,
              offsetY: 2
            })

            // 使用说明
            Column({ space: 8 }) {
              Text('💡 使用说明')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666666')
              
              Text('• 点击任意宫位查看详细星曜信息')
                .fontSize(12)
                .fontColor('#999999')
              
              Text('• 命宫标记为 ★，身宫标记为 身')
                .fontSize(12)
                .fontColor('#999999')
              
              Text('• 主星为褐色，辅星为蓝色，四化为红色')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('90%')
            .padding(12)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 20 })
          }
          .width('100%')
          .padding({ top: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .backgroundColor('#FAFAFA')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .bindSheet(this.showPalaceDetail, this.buildPalaceDetailSheet(), {
      height: 500,
      backgroundColor: '#FFFFFF',
      onDisappear: () => {
        this.showPalaceDetail = false;
      }
    })
  }

  /**
   * 出生信息卡片
   */
  @Builder
  buildBirthInfoCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('📅')
          .fontSize(20)
        Text('出生信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2416')
      }
      .width('100%')

      Divider()
        .strokeWidth(1)
        .color('#EEEEEE')

      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text('公历')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.formatDate(this.birthInfo!.solarDate))
            .fontSize(14)
            .fontColor('#2C2416')
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('农历')
            .fontSize(12)
            .fontColor('#999999')
          Text(`${this.birthInfo!.lunarYear}年${this.birthInfo!.lunarMonth}月${this.birthInfo!.lunarDay}日`)
            .fontSize(14)
            .fontColor('#2C2416')
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('时辰')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.getShichenName(this.birthInfo!.shichenIndex))
            .fontSize(14)
            .fontColor('#2C2416')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      Row({ space: 8 }) {
        Text('四柱八字：')
          .fontSize(12)
          .fontColor('#999999')
        Text(`${this.birthInfo!.yearGan}${this.birthInfo!.yearZhi}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D4A574')
        Text(`${this.birthInfo!.monthGan}${this.birthInfo!.monthZhi}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D4A574')
        Text(`${this.birthInfo!.dayGan}${this.birthInfo!.dayZhi}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D4A574')
        Text(`${this.birthInfo!.shiGan}${this.birthInfo!.shiZhi}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D4A574')
      }
      .width('100%')
    }
    .width('90%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 命盘核心信息卡片
   */
  @Builder
  buildChartInfoCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('⭐')
          .fontSize(20)
        Text('命盘信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2416')
      }
      .width('100%')

      Divider()
        .strokeWidth(1)
        .color('#EEEEEE')

      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text('命宫')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.palaces.find(p => p.index === this.mingGongIndex)?.zhi + '宫')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#D4A574')
        }

        Column({ space: 4 }) {
          Text('身宫')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.palaces.find(p => p.index === this.shenGongIndex)?.zhi + '宫')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9370DB')
        }

        Column({ space: 4 }) {
          Text('五行局')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.chart!.wuxingJu.nayin)
            .fontSize(14)
            .fontColor('#2C2416')
          Text(`${this.getJuName(this.chart!.wuxingJu.ju)}`)
            .fontSize(12)
            .fontColor('#666666')
        }

        Column({ space: 4 }) {
          Text('紫微位置')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.palaces.find(p => p.index === this.chart!.ziweiPosition)?.zhi + '宫')
            .fontSize(14)
            .fontColor('#8B008B')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('90%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 宫位详情弹窗
   */
  @Builder
  buildPalaceDetailSheet() {
    Column({ space: 16 }) {
      if (this.selectedPalace) {
      // 标题栏
      Row({ space: 8 }) {
        Text(this.selectedPalace!.name.replace(' ★', '').replace(' (身)', ''))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2416')
        
        Text(`${this.selectedPalace!.gan}${this.selectedPalace!.zhi}`)
          .fontSize(16)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20 })

      Divider()
        .strokeWidth(1)
        .color('#EEEEEE')

      Scroll() {
        Column({ space: 12 }) {
          // 主星
          if (this.selectedPalace!.mainStars.length > 0) {
            Column({ space: 6 }) {
              Text('主星')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666666')
              
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.selectedPalace!.mainStars, (star: string) => {
                  Text(star)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#8B4513')
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .margin({ right: 8, bottom: 8 })
                })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          // 辅星
          if (this.selectedPalace!.auxiliaryStars.length > 0) {
            Column({ space: 6 }) {
              Text('辅星')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666666')
              
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.selectedPalace!.auxiliaryStars, (star: string) => {
                  Text(star)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#4682B4')
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .margin({ right: 8, bottom: 8 })
                })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          // 四化
          if (this.selectedPalace!.transforms.length > 0) {
            Column({ space: 6 }) {
              Text('四化')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#666666')
              
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.selectedPalace!.transforms, (transform: string) => {
                  Text(transform)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#DC143C')
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .margin({ right: 8, bottom: 8 })
                })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          // 空宫提示
          if (this.selectedPalace!.mainStars.length === 0 && 
              this.selectedPalace!.auxiliaryStars.length === 0) {
            Text('此宫无主星，需参考对宫星曜')
              .fontSize(14)
              .fontColor('#999999')
              .fontStyle(FontStyle.Italic)
          }
        }
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)

      Button('关闭')
        .width('90%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .fontColor('#666666')
        .onClick(() => {
          this.showPalaceDetail = false;
        })
        .margin({ bottom: 20 })
      }
    }
    .width('100%')
    .height(500)
  }

  // 辅助方法
  private formatDate(date: Date): string {
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private getShichenName(index: number): string {
    const names = ['子时', '丑时', '寅时', '卯时', '辰时', '巳时', 
                   '午时', '未时', '申时', '酉时', '戌时', '亥时'];
    return names[index] || '未知';
  }

  private getJuName(ju: number): string {
    const names: Record<number, string> = {
      2: '水二局',
      3: '木三局',
      4: '金四局',
      5: '土五局',
      6: '火六局'
    };
    return names[ju] || '未知';
  }
}
