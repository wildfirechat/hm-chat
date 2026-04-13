import { Profile } from '@wfc/moment_client';
import wfc from '@wfc/client';
import { MomentConstants } from '../utils/MomentConstants';

@Component
export struct FeedHeaderComponent {
    @Prop profile: Profile | undefined;
    @Prop userId: string;

    private safeAreaHeight: number = px2vp(AppStorage.get<number>('SafeAreaTopHeight') || 0);

    @Builder
    build() {
        Stack({ alignContent: Alignment.BottomEnd }) {
            // 背景图
            Image(this.profile?.backgroundUrl || $r('app.media.background'))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor($r('app.color.wf_tertiary_text'))

            Row() {
                // 用户名
                Text(wfc.getUserInfo(this.userId).displayName)
                    .fontSize(20)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold)
                    .margin({ right: 12, bottom: 20 })

                // 头像
                Image(wfc.getUserInfo(this.userId).portrait || $r('app.media.icon'))
                    .width(MomentConstants.AVATAR_SIZE_LARGE)
                    .height(MomentConstants.AVATAR_SIZE_LARGE)
                    .borderRadius(8)
                    .borderWidth(2)
                    .borderColor($r('app.color.wf_background'))
                    .backgroundColor($r('app.color.wf_background'))
            }
            .margin({ right: 20, bottom: -20 })
        }
        .width('100%')
        .height(MomentConstants.COVER_HEIGHT + 40 + this.safeAreaHeight)
        .margin({ bottom: 40 })
    }
}

