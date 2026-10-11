import { Profile } from '../model/MomentModel';
import wfc from '@wfc/client';
import { MomentConstants } from '../utils/MomentConstants';
import { FontSize } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

@Component
export struct FeedHeaderComponent {
    @Prop profile: Profile | undefined;
    @Prop userId: string;
    // 点击封面回调（仅自己的朋友圈首页传入，用于「更新背景」）
    onBackgroundClick?: () => void;
    // 长按封面回调（仅自己的朋友圈首页传入，用于「更新背景」）
    onBackgroundLongPress?: () => void;

    private safeAreaHeight: number = px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0);

    build() {
        Stack({ alignContent: Alignment.Bottom }) {
            // 背景封面图
            Image(trustedMediaSrc(this.profile?.backgroundUrl) || $r('app.media.background'))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor($r('app.color.wf_tertiary_text'))

            // 渐变遮罩层：从透明到半黑，覆盖下半区（不拦截触摸，手势统一由外层 Stack 处理）
            Column()
                .width('100%')
                .height('60%')
                .linearGradient({
                    angle: 180,
                    colors: [
                        [$r('app.color.gradient_transparent'), 0.0],
                        [$r('app.color.gradient_mid'), 0.6],
                        [$r('app.color.gradient_end'), 1.0]
                    ]
                })
                .hitTestBehavior(HitTestMode.None)

            // 底部：用户名 + 头像（不拦截触摸，手势统一由外层 Stack 处理）
            Row() {
                // 用户名
                Text(wfc.getUserInfo(this.userId).displayName)
                    .fontSize(FontSize.lg)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .textShadow({ radius: 4, color: $r('app.color.mask_light'), offsetX: 0, offsetY: 1 })
                    .margin({ right: 16, bottom: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: '60%' })

                // 头像（带阴影）
                Image(trustedMediaSrc(wfc.getUserInfo(this.userId).portrait) || $r('app.media.icon'))
                    .width(MomentConstants.AVATAR_SIZE_LARGE)
                    .height(MomentConstants.AVATAR_SIZE_LARGE)
                    .borderRadius(MomentConstants.BORDER_RADIUS)
                    .borderWidth(2)
                    .borderColor(Color.White)
                    .backgroundColor($r('app.color.comment_background'))
                    .shadow({ radius: 8, color: $r('app.color.mask_light'), offsetX: 0, offsetY: 2 })
            }
            .width('100%')
            .padding({ right: 16, bottom: 16 })
            .justifyContent(FlexAlign.End)
            .alignItems(VerticalAlign.Bottom)
            .hitTestBehavior(HitTestMode.None)
        }
        .width('100%')
        .height(MomentConstants.COVER_HEIGHT + this.safeAreaHeight + MomentConstants.AVATAR_SIZE_LARGE / 2)
        .margin({ bottom: MomentConstants.AVATAR_SIZE_LARGE / 2 })
        .clip(true)
        // 手势挂在最外层 Stack：整个封面区域（含渐变层/底部信息区）都能点击/长按
        .onClick(() => this.onBackgroundClick?.())
        .gesture(
            LongPressGesture()
                .onAction(() => this.onBackgroundLongPress?.())
        )
    }
}
