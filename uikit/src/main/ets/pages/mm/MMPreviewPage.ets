import { MediaEntry } from '../../common/Types';

@Component
export default struct MMPreviewPage {
    @State mediaEntries: MediaEntry[] = []
    @State index: number = 0
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params) {
            this.mediaEntries = params['mediaEntries'] as MediaEntry[] || [];
            this.index = params['index'] as number || 0;
        }
    }

    build() {
        NavDestination() {
            Stack() {
                Swiper() {
                    ForEach(this.mediaEntries, (entry: MediaEntry) => {
                        if (entry.type === 'image') {
                            Image(entry.url)
                                .alt(entry.thumbnail)
                                .objectFit(ImageFit.Contain)
                                .width('100%')
                                .height('100%')
                        } else {
                            Video({
                                previewUri: entry.thumbnail,
                                src: entry.url
                            })
                                .objectFit(ImageFit.Contain)
                                .width('100%')
                                .height('100%')
                        }
                    }, (entry: MediaEntry) => entry.url)
                }
                .index(this.index)
                .indicator(false)
                .vertical(false)
                .loop(false)
            }
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Black)
        }
        .hideTitleBar(true)
    }
}

