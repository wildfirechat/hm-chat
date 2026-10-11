import { FeedEntry } from '../model/MomentModel';
import { MomentConstants } from '../utils/MomentConstants';
import { FontSize } from '@wfc/uikit/src/main/ets/common/design/Tokens'
import { trustedMediaSrc } from '@wfc/uikit/src/main/ets/util/trustedMedia'

/**
 * 九宫格图片布局（微信朋友圈规则）：
 * - 1 张：按原始宽高比（mediaWidth/mediaHeight），宽=容器 60%，原图宽 < 200vp 时 50%，
 *   高上限 1.2×宽；无尺寸信息时退回方形
 * - 4 张：2×2
 * - 其余：三列
 * cell 用 thumbUrl 兜底 mediaUrl；视频叠播放图标
 */
@Component
export struct NineGridView {
    @Prop medias: FeedEntry[] = [];
    @Prop isVideo: boolean = false;
    // 内容区可用宽度，由父组件按屏幕宽度计算后传入
    @Prop contentWidth: number = 260;
    onItemClick: (index: number) => void = () => {};

    // 单张媒体的展示尺寸
    private singleSize(): SingleSize {
        const entry = this.medias[0];
        const w = entry?.mediaWidth ?? 0;
        const h = entry?.mediaHeight ?? 0;
        let width: number;
        let height: number;
        if (w > 0 && h > 0) {
            width = this.contentWidth * 0.6;
            if (w < 200) {
                width = this.contentWidth * 0.5;
            }
            height = width * h / w;
            const maxHeight = width * 1.2;
            if (height > maxHeight) {
                height = maxHeight;
            }
        } else {
            // 无尺寸信息退回方形
            width = this.contentWidth * 0.6;
            height = width;
        }
        return { width: width, height: height };
    }

    private gridHeight(): number {
        const count = this.medias.length;
        const cols = count === 4 ? 2 : 3;
        const rows = Math.ceil(count / cols);
        const size = this.cellSize();
        return rows * size + (rows - 1) * MomentConstants.IMAGE_GRID_GAP;
    }

    private cellSize(): number {
        const cols = this.medias.length === 4 ? 2 : 3;
        return (this.contentWidth - (cols - 1) * MomentConstants.IMAGE_GRID_GAP) / cols;
    }

    build() {
        if (this.medias.length === 1) {
            this.buildSingleCell()
        } else if (this.medias.length > 1) {
            Grid() {
                ForEach(this.medias.slice(0, 9), (entry: FeedEntry, index: number) => {
                    GridItem() {
                        this.buildCell(entry, index)
                    }
                }, (entry: FeedEntry, index: number) => `img_${index}_${entry.mediaUrl}`)
            }
            .columnsTemplate(this.medias.length === 4 ? '1fr 1fr' : '1fr 1fr 1fr')
            .columnsGap(MomentConstants.IMAGE_GRID_GAP)
            .rowsGap(MomentConstants.IMAGE_GRID_GAP)
            .width('100%')
            .height(this.gridHeight())
        }
    }

    @Builder
    private buildSingleCell() {
        Stack({ alignContent: Alignment.Center }) {
            Image(trustedMediaSrc(this.medias[0].thumbUrl || this.medias[0].mediaUrl))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

            if (this.isVideo) {
                this.buildPlayIcon()
            }
        }
        .width(this.singleSize().width)
        .height(this.singleSize().height)
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .clip(true)
        .onClick(() => this.onItemClick(0))
    }

    @Builder
    private buildCell(entry: FeedEntry, index: number) {
        Stack({ alignContent: Alignment.Center }) {
            Image(trustedMediaSrc(entry.thumbUrl || entry.mediaUrl))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

            if (this.isVideo) {
                this.buildPlayIcon()
            }
        }
        .width('100%')
        .height('100%')
        .borderRadius(MomentConstants.BORDER_RADIUS_SMALL)
        .clip(true)
        .onClick(() => this.onItemClick(index))
    }

    @Builder
    private buildPlayIcon() {
        Column() {
            SymbolGlyph($r('sys.symbol.play_fill'))
                .fontSize(FontSize.d3)
                .fontColor([Color.White])
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor($r('app.color.mask_medium'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }
}

interface SingleSize {
    width: number;
    height: number;
}
