import { Profile } from '@wfc/moment_client';
import wfc from '@wfc/client';
import { MomentConstants } from '../utils/MomentConstants';

@Component
export struct FeedHeaderComponent {
    @Prop profile: Profile | undefined;
    @Prop userId: string;

    private safeAreaHeight: number = px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0);

    build() {
        Stack({ alignContent: Alignment.Bottom }) {
            // 背景封面图
            Image(this.profile?.backgroundUrl || $r('app.media.background'))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor($r('app.color.wf_tertiary_text'))

            // 渐变遮罩层：从透明到半黑，覆盖下半区
            Column()
                .width('100%')
                .height('60%')
                .linearGradient({
                    angle: 180,
                    colors: [
                        ['#00000000', 0.0],
                        ['#55000000', 0.6],
                        ['#88000000', 1.0]
                    ]
                })

            // 底部：用户名 + 头像
            Row() {
                // 用户名
                Text(wfc.getUserInfo(this.userId).displayName)
                    .fontSize(18)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .textShadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 1 })
                    .margin({ right: 14, bottom: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: '60%' })

                // 头像（带阴影）
                Image(wfc.getUserInfo(this.userId).portrait || $r('app.media.icon'))
                    .width(MomentConstants.AVATAR_SIZE_LARGE)
                    .height(MomentConstants.AVATAR_SIZE_LARGE)
                    .borderRadius(MomentConstants.BORDER_RADIUS)
                    .borderWidth(2)
                    .borderColor(Color.White)
                    .backgroundColor($r('app.color.comment_background'))
                    .shadow({ radius: 8, color: '#40000000', offsetX: 0, offsetY: 2 })
            }
            .width('100%')
            .padding({ right: 16, bottom: 16 })
            .justifyContent(FlexAlign.End)
            .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .height(MomentConstants.COVER_HEIGHT + this.safeAreaHeight + MomentConstants.AVATAR_SIZE_LARGE / 2)
        .margin({ bottom: MomentConstants.AVATAR_SIZE_LARGE / 2 })
        .clip(true)
    }
}
