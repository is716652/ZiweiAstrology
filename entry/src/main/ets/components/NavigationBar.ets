import router from '@ohos.router'

/**
 * 通用顶部导航栏组件
 * 
 * 功能：
 * - 统一的导航栏样式和布局
 * - 支持自定义标题
 * - 支持自定义返回行为
 * - 支持右侧操作按钮（可选）
 * 
 * 使用方式：
 * ```typescript
 * NavigationBar({
 *   title: '页面标题',
 *   onBack: () => { router.back() },
 *   rightActionText: '保存',
 *   onRightAction: () => { // 保存逻辑 }
 * })
 * ```
 */
@Component
export struct NavigationBar {
  @Prop title: string = ''
  @Prop showBackButton: boolean = true
  @Prop showBack: boolean = true  // 支持showBack参数（与showBackButton同义）
  @Prop backButtonText: string = '← 返回'
  @Prop rightActionText: string = ''
  @Prop navBarBackgroundColor: string = '#ffffff'
  @Prop titleColor: string = '#2C2416'
  @Prop buttonColor: string = '#666666'
  
  onBack?: () => void
  onRightAction?: () => void

  build() {
    Column({ space: 0 }) {
      Row() {
        // 左侧返回按钮
        if (this.showBackButton || this.showBack) {
          Text(this.backButtonText)
            .fontSize(16)
            .fontColor(this.buttonColor)
            .onClick(() => {
              if (this.onBack) {
                this.onBack()
              } else {
                router.back()
              }
            })
        } else {
          Text(' ')
            .fontSize(16)
        }

        // 中间标题
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧操作按钮
        if (this.rightActionText) {
          Text(this.rightActionText)
            .fontSize(16)
            .fontColor(this.buttonColor)
            .onClick(() => {
              if (this.onRightAction) {
                this.onRightAction()
              }
            })
        } else {
          Text(' ')
            .fontSize(16)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.navBarBackgroundColor)

      Divider().color('#eeeeee')
    }
  }
}
