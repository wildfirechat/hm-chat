import { momentClient } from '@wfc/moment_client';
import { MomentConstants } from '../utils/MomentConstants';
import { picker } from '@kit.CoreFileKit';

interface PostFeedState {
    text: string;
    selectedImages: string[];
    isPosting: boolean;
    error?: string;
}

@Component
export struct PostFeedPage {
    // 状态管理
    @State postState: PostFeedState = {
        text: '',
        selectedImages: [],
        isPosting: false
    };
    // 最大图片数量
    private readonly MAX_IMAGES = 9;

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        // 页面初始化
    }

    /**
     * 选择图片
     */
    private async selectImages() {
        try {
            const documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.defaultFilePathUri = '';
            documentSelectOptions.fileSuffixFilters = ['.jpg', '.jpeg', '.png', '.gif'];
            documentSelectOptions.maxSelectNumber = this.MAX_IMAGES - this.postState.selectedImages.length;

            const documentViewPicker = new picker.DocumentViewPicker();
            const documentSelectResult = await documentViewPicker.select(documentSelectOptions);

            if (documentSelectResult && documentSelectResult.length > 0) {
                const newImages = [...this.postState.selectedImages, ...documentSelectResult];
                this.postState.selectedImages = newImages.slice(0, this.MAX_IMAGES);
            }
        } catch (error) {
            console.error('Select images failed:', error);
        }
    }

    /**
     * 移除图片
     */
    private removeImage(index: number) {
        const newImages = [...this.postState.selectedImages];
        newImages.splice(index, 1);
        this.postState.selectedImages = newImages;
    }

    /**
     * 发布朋友圈
     */
    private publishFeed() {
        if (this.postState.isPosting) {
            return;
        }

        if (!this.postState.text.trim() && this.postState.selectedImages.length === 0) {
            this.postState.error = '请输入文字或选择图片';
            return;
        }

        this.postState.isPosting = true;
        this.postState.error = undefined;

        // 构建朋友圈内容
        const feedType = this.postState.selectedImages.length > 0 ? 1 : 0; // 1: 图片，0: 文字
        const text = this.postState.text.trim();
        // TODO
        // const medias = this.postState.selectedImages.map((imagePath, index) => ({
        //   url: imagePath,
        //   thumbUrl: imagePath, // TODO: 生成缩略图
        //   type: 'image',
        //   width: 0,
        //   height: 0
        // }));

        momentClient.postFeed(
            feedType,
            text,
            //medias,
            [],
            [],
            [],
            [],
            '',
            (feedId: bigint, timestamp: number) => {
                console.log('Feed posted successfully:', feedId);
                this.postState.isPosting = false;

                // 发布成功，返回上一页
                this.goBack();
            },
            (errorCode: number) => {
                console.error('Post feed failed:', errorCode);
                this.postState.isPosting = false;
                this.postState.error = `发布失败: ${errorCode}`;
            }
        );
    }

    /**
     * 返回上一页
     */
    private goBack() {
        this.mainNavPathStack.pop()
    }

    /**
     * 检查是否可以发布
     */
    private canPublish(): boolean {
        return !this.postState.isPosting &&
            (this.postState.text.trim().length > 0 || this.postState.selectedImages.length > 0);
    }

    build() {
        NavDestination() {
            Column() {
                // 文本输入区域
                this.buildTextInput()

                // 图片选择区域
                this.buildImageSelector()

                Blank()

                // 错误提示
                if (this.postState.error) {
                    this.buildErrorTip()
                }

                // 发布按钮
                this.buildPublishButton()
            }
            .width('100%')
            .height('100%')
            .padding(MomentConstants.CARD_PADDING)
            .backgroundColor(MomentConstants.BACKGROUND_COLOR)
        }
        .title('发表朋友圈')
        .backgroundColor(MomentConstants.BACKGROUND_COLOR)
        .toolbarConfiguration([
            {
                value: '取消',
                action: () => {
                    this.goBack();
                }
            },
            {
                value: '发布',
                action: () => {
                    this.publishFeed();
                }
            }
        ])
    }

    @Builder
    private buildTextInput() {
        Column() {
            TextArea({
                placeholder: '这一刻的想法...',
                text: this.postState.text
            })
                .width('100%')
                .height(120)
                .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .padding(12)
                .onChange((value: string) => {
                    this.postState.text = value;
                    this.postState.error = undefined;
                })
        }
        .width('100%')
        .margin({ bottom: 16 })
    }

    @Builder
    private buildImageSelector() {
        Column() {
            // 图片网格
            if (this.postState.selectedImages.length > 0 || this.postState.selectedImages.length < this.MAX_IMAGES) {
                Grid() {
                    // 已选择的图片
                    ForEach(this.postState.selectedImages, (imagePath: string, index: number) => {
                        GridItem() {
                            this.buildImageItem(imagePath, index)
                        }
                    }, (imagePath: string, index: number) => `image_${index}`)

                    // 添加图片按钮
                    if (this.postState.selectedImages.length < this.MAX_IMAGES) {
                        GridItem() {
                            this.buildAddImageButton()
                        }
                    }
                }
                .columnsTemplate('1fr 1fr 1fr')
                .rowsGap(MomentConstants.IMAGE_GRID_GAP)
                .columnsGap(MomentConstants.IMAGE_GRID_GAP)
                .width('100%')
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private buildImageItem(imagePath: string, index: number) {
        Stack({ alignContent: Alignment.TopEnd }) {
            // 图片
            Image(imagePath)
                .width('100%')
                .height(100)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#F0F0F0')

            // 删除按钮
            Button() {
                Image($r('app.media.icon')) // TODO: 使用关闭图标
                    .width(16)
                    .height(16)
                    .fillColor('#FFFFFF')
            }
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor('rgba(0,0,0,0.6)')
            .margin({ top: 4, right: 4 })
            .onClick(() => {
                this.removeImage(index);
            })
        }
        .width('100%')
    }

    @Builder
    private buildAddImageButton() {
        Column() {
            Image($r('app.media.icon')) // TODO: 使用添加图标
                .width(24)
                .height(24)
                .fillColor(MomentConstants.TEXT_SECONDARY_COLOR)

            Text('添加图片')
                .fontSize(MomentConstants.FONT_SIZE_SMALL)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .margin({ top: 4 })
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .border({
            width: 1,
            color: MomentConstants.DIVIDER_COLOR,
            style: BorderStyle.Dashed
        })
        .onClick(() => {
            this.selectImages();
        })
    }

    @Builder
    private buildErrorTip() {
        Row() {
            Image($r('app.media.icon')) // TODO: 使用警告图标
                .width(16)
                .height(16)
                .fillColor(MomentConstants.ERROR_COLOR)
                .margin({ right: 6 })

            Text(this.postState.error!)
                .fontSize(MomentConstants.FONT_SIZE_SMALL)
                .fontColor(MomentConstants.ERROR_COLOR)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3F3')
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .margin({ bottom: 16 })
    }

    @Builder
    private buildPublishButton() {
        Button(this.postState.isPosting ? '发布中...' : '发布')
            .width('100%')
            .height(44)
            .fontSize(MomentConstants.FONT_SIZE_MEDIUM)
            .fontColor('#FFFFFF')
            .backgroundColor(this.canPublish() ? MomentConstants.PRIMARY_COLOR : '#CCCCCC')
            .borderRadius(MomentConstants.BORDER_RADIUS)
            .enabled(this.canPublish())
            .margin({ bottom: 20 })
            .onClick(() => {
                this.publishFeed();
            })

        if (this.postState.isPosting) {
            LoadingProgress()
                .width(20)
                .height(20)
                .color(MomentConstants.PRIMARY_COLOR)
                .position({ x: '50%', y: '50%' })
                .translate({ x: '-50%', y: '-50%' })
        }
    }
}