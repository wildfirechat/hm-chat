import router from '@ohos.router';
import { MediaEntry } from '../../common/Types';

@Entry
@Component
export default struct MMPreviewPage {
    @State mediaEntries: MediaEntry[] = []

    aboutToAppear() {
        const params = router.getParams() as Record<string, Object>;
        this.mediaEntries = params['mediaEntries'] as MediaEntry[]
    }

    build() {
        Navigation() {
            Swiper() {
                ForEach(this.mediaEntries, (entry: MediaEntry) => {
                    if (entry.type === 'image') {
                        Image(entry.url)
                            .alt(entry.thumbnail)
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#EDEDED')
                    } else {
                        Video({
                            previewUri: entry.thumbnail,
                            src: entry.url
                        })
                            .objectFit(ImageFit.Contain)
                            .width('100%')
                            .height('100%')
                            .backgroundColor('#EDEDED')
                    }
                }, (entry: MediaEntry) => entry.url)
            }
            .indicator(false)
            .vertical(false)
        }
        .title('媒体文件预览')
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .navBarPosition(NavBarPosition.Start)
    }
}