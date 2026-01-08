import http from '@ohos.net.http';
import image from '@ohos.multimedia.image';
// Import at module level to avoid circular dependency
import appServer from '../api/appServer';

export interface SlideVerifyViewDelegate {
  slideVerifyViewDidVerifySuccess(token: string): void;
  slideVerifyViewDidVerifyFailed(): void;
  slideVerifyViewDidLoadFailed(): void;
}

@Component
export struct SlideVerifyView {
  @State token: string = ''
  @State sliderY: number = 0
  @State bgImageData: string = ''
  @State sliderImageData: string = ''
  @State sliderImageTop: number = 0

  @State currentX: number = 0
  @State isVerified: boolean = false
  @State hintOpacity: number = 1
  @State isLoading: boolean = false

  @State scaleX: number = 1
  @State scaleY: number = 1
  @State imageOffsetX: number = 0

  private controller: SlideVerifyController = new SlideVerifyController()
  delegate?: SlideVerifyViewDelegate

  aboutToAppear() {
    this.loadVerifyCode()
  }

  build() {
    Column() {
      // 标题
      Text('安全验证')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      // 图片容器
      Stack() {
        // 背景图
        Image(this.bgImageData)
          .width('100%')
          .height(150)
          .objectFit(ImageFit.Contain)
          .onComplete(() => {
            this.calculateScale()
          })

        // 滑块图
        Image(this.sliderImageData)
          .width(50)
          .height(50)
          .position({ x: this.imageOffsetX + this.currentX, y: this.sliderImageTop })
      }
      .width('100%')
      .height(150)
      .backgroundColor('#f5f5f5')
      .borderRadius(4)
      .margin({ bottom: 15 })

      // 滑块轨道
      Stack() {
        // 提示文字
        Text('向右滑动完成验证')
          .fontSize(14)
          .fontColor('#999999')
          .opacity(this.hintOpacity)

        // 滑块按钮
        Circle()
          .width(40)
          .height(40)
          .fill(this.isVerified ? '#4CAF50' : Color.White)
          .position({ x: this.currentX, y: 0 })
          .shadow({ radius: this.isVerified ? 0 : 5, color: '#80000000', offsetX: 0, offsetY: 2 })
          .gesture(
            PanGesture({ direction: PanDirection.Horizontal })
              .onActionStart((event: GestureEvent) => {
                if (this.isVerified || this.isLoading) {
                  return
                }
              })
              .onActionUpdate((event: GestureEvent) => {
                if (this.isVerified || this.isLoading) {
                  return
                }
                let newX = event.offsetX
                let maxDistance = 280 // 轨道宽度 - 按钮宽度
                newX = Math.max(0, Math.min(newX, maxDistance))
                this.currentX = newX
                this.hintOpacity = 1 - (newX / maxDistance)
              })
              .onActionEnd((event: GestureEvent) => {
                if (this.isVerified || this.isLoading) {
                  return
                }
                // 只要滑动超过 10px，就触发验证
                if (this.currentX >= 10) {
                  this.verifySlidePosition(this.currentX)
                } else {
                  // 回弹
                  this.currentX = 0
                  this.hintOpacity = 1
                }
              })
          )
      }
      .width('100%')
      .height(40)
      .backgroundColor('#f0f0f0')
      .borderRadius(20)
      .margin({ bottom: 10 })

      // 刷新按钮
      Row() {
        Text('🔄')
          .fontSize(20)
          .onClick(() => {
            this.refreshVerify()
          })
      }
      .width(32)
      .height(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(4)
      .shadow({ radius: 8, color: '#80000000', offsetX: 0, offsetY: 2 })
      .position({ x: 290, y: 10 })

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(0x317aff)
      }
    }
    .width(320)
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 20, color: '#80000000', offsetX: 0, offsetY: 4 })
  }

  private async loadVerifyCode() {
    this.isLoading = true
    try {
      console.info('[SlideVerify] 开始加载验证码...')
      const response = await appServer.getSlideVerify() as Record<string, Object>
      console.info('[SlideVerify] 服务器响应:', JSON.stringify(response))
      this.isLoading = false

      if (response && response['token'] && response['backgroundImage'] && response['sliderImage']) {
        this.token = response['token'] as string
        this.sliderY = response['y'] as number
        console.info('[SlideVerify] Token:', this.token, 'Y:', this.sliderY)

        // 设置图片（后端已返回带前缀的 data URI）
        this.bgImageData = response['backgroundImage'] as string
        this.sliderImageData = response['sliderImage'] as string
        console.info('[SlideVerify] 验证码图片加载成功')
      } else {
        console.error('[SlideVerify] 响应数据不完整:', JSON.stringify(response))
        if (this.delegate) {
          this.delegate.slideVerifyViewDidLoadFailed()
        }
      }
    } catch (error) {
      this.isLoading = false
      console.error('[SlideVerify] 加载验证码失败:', error)
      if (this.delegate) {
        this.delegate.slideVerifyViewDidLoadFailed()
      }
    }
  }

  private calculateScale() {
    // 背景图原始尺寸：300 x 150
    const naturalWidth = 300
    const naturalHeight = 150
    const containerWidth = 280 // 320 - 20*2
    const containerHeight = 150

    // 计算容器的宽高比和图片的宽高比
    const containerRatio = containerWidth / containerHeight
    const imageRatio = naturalWidth / naturalHeight

    // 根据 object-fit: contain 的逻辑计算实际渲染尺寸
    let renderWidth: number
    let renderHeight: number

    if (imageRatio > containerRatio) {
      // 图片更宽，按宽度适配，上下留白
      renderWidth = containerWidth
      renderHeight = containerWidth / imageRatio
    } else {
      // 图片更高，按高度适配，左右留白
      renderHeight = containerHeight
      renderWidth = containerHeight * imageRatio
    }

    // 计算缩放比例
    this.scaleX = renderWidth / naturalWidth
    this.scaleY = renderHeight / naturalHeight

    // 计算图片在容器中的偏移量
    const offsetX = (containerWidth - renderWidth) / 2
    const offsetY = (containerHeight - renderHeight) / 2

    this.imageOffsetX = offsetX

    // 计算滑块的 Y 坐标
    this.sliderImageTop = offsetY + (this.sliderY * this.scaleY)

    console.info('[SlideVerify] 图片计算:')
    console.info('  原始尺寸:', naturalWidth, 'x', naturalHeight)
    console.info('  容器尺寸:', containerWidth, 'x', containerHeight)
    console.info('  实际渲染:', renderWidth.toFixed(1), 'x', renderHeight.toFixed(1))
    console.info('  偏移量: offsetX=', offsetX.toFixed(1), ', offsetY=', offsetY.toFixed(1))
    console.info('  缩放比例: scaleX=', this.scaleX.toFixed(3), ', scaleY=', this.scaleY.toFixed(3))
    console.info('  滑块位置: 原始Y=', this.sliderY, ', 显示Y=', this.sliderImageTop.toFixed(1))
  }

  private refreshVerify() {
    this.loadVerifyCode()
  }

  private reset() {
    this.currentX = 0
    this.isVerified = false
    this.hintOpacity = 1
  }

  private async verifySlidePosition(x: number) {
    try {
      console.info('[SlideVerify] ========== 验证开始 ==========')
      console.info('[SlideVerify] 滑块按钮在轨道上的位置:', x, 'px')
      console.info('[SlideVerify] 背景图偏移 imageOffsetX:', this.imageOffsetX.toFixed(2), 'px')
      console.info('[SlideVerify] 缩放比例 scaleX:', this.scaleX.toFixed(3))

      // 转换为原图坐标
      const originalX = Math.round(x / this.scaleX)
      console.info('[SlideVerify] 转换到原图(300x150)的X坐标:', originalX)
      console.info('[SlideVerify] 原图有效X坐标范围: 50 ~ 200')
      console.info('[SlideVerify] ==================================')

      // 模仿 iOS，检查 code === 0 判断成功
      const responseStr: string = await appServer.verifySlide(this.token, originalX) as string
      const response = JSON.parse(responseStr) as Record<string, Object>

      console.info('[SlideVerify] API 响应:', JSON.stringify(response))
      console.info('[SlideVerify] response.code:', response['code'])
      console.info('[SlideVerify] response.code === 0:', response['code'] === 0)

      if (response['code'] === 0) {
        console.info('[SlideVerify] 验证成功！')
        this.isVerified = true

        // 延迟关闭
        setTimeout(() => {
          if (this.delegate) {
            this.delegate.slideVerifyViewDidVerifySuccess(this.token)
          }
        }, 500)
      } else {
        console.info('[SlideVerify] 验证失败！code =', response['code'])
        // 验证失败
        this.reset()
        if (this.delegate) {
          this.delegate.slideVerifyViewDidVerifyFailed()
        }

        // 1秒后自动刷新
        setTimeout(() => {
          this.refreshVerify()
        }, 1000)
      }
    } catch (error) {
      console.error('[SlideVerify] 验证失败:', error)
      this.reset()
      if (this.delegate) {
        this.delegate.slideVerifyViewDidVerifyFailed()
      }

      // 1秒后自动刷新
      setTimeout(() => {
        this.refreshVerify()
      }, 1000)
    }
  }
}

export class SlideVerifyController {
  show() {
    // 由外部控制显示
  }

  hide() {
    // 由外部控制隐藏
  }
}
