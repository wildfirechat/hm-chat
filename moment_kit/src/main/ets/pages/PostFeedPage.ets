import { momentClient, FeedEntry, FeedContentType } from '@wfc/moment_client';
import { MomentConstants } from '../utils/MomentConstants';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { showToast } from '@wfc/uikit/src/main/ets/common/utils/Toast';

const MAX_TEXT_LENGTH = 2000;
const MAX_IMAGES = 9;

interface PostFeedState {
    text: string;
    selectedImages: string[];
    isPosting: boolean;
    uploadingCount: number;
    totalCount: number;
}

@Component
export struct PostFeedPage {
    @State postState: PostFeedState = {
        text: '',
        selectedImages: [],
        isPosting: false,
        uploadingCount: 0,
        totalCount: 0
    };
    // TextArea 高度跟随内容动态扩展
    @State textAreaHeight: number = 130;

    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    private async publishFeed() {
        if (this.postState.isPosting) return;
        if (!this.postState.text.trim() && this.postState.selectedImages.length === 0) {
            showToast('请输入内容或选择图片');
            return;
        }

        this.postState.isPosting = true;
        this.postState.totalCount = this.postState.selectedImages.length;
        this.postState.uploadingCount = 0;

        try {
            const uploadedMedias: FeedEntry[] = [];
            for (const imagePath of this.postState.selectedImages) {
                const url = await this.uploadImage(imagePath);
                if (url) {
                    uploadedMedias.push(new FeedEntry(url, '', 0, 0));
                }
                this.postState.uploadingCount++;
            }

            const feedType = uploadedMedias.length > 0
                ? FeedContentType.Content_Image_Type
                : FeedContentType.Content_Text_Type;

            momentClient.postFeed(
                feedType,
                this.postState.text.trim(),
                uploadedMedias,
                [], [], [], '',
                () => {
                    this.postState.isPosting = false;
                    showToast('发布成功');
                    this.goBack();
                },
                (errorCode: number) => {
                    this.postState.isPosting = false;
                    showToast(`发布失败 (${errorCode})`);
                }
            );
        } catch (e) {
            this.postState.isPosting = false;
            showToast('发布失败，请重试');
        }
    }

    private uploadImage(path: string): Promise<string> {
        return new Promise((resolve) => {
            momentClient.uploadMedia('', path, (url: string) => {
                resolve(url);
            }, () => {
                resolve('');
            });
        });
    }

    private async selectImages() {
        try {
            const remain = MAX_IMAGES - this.postState.selectedImages.length;
            if (remain <= 0) return;

            const options = new photoAccessHelper.PhotoSelectOptions();
            options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
            options.maxSelectNumber = remain;

            const photoPicker = new photoAccessHelper.PhotoViewPicker();
            const photoUris = (await photoPicker.select(options)).photoUris;

            if (photoUris?.length > 0) {
                const newImages = [...this.postState.selectedImages, ...photoUris];
                this.postState.selectedImages = newImages.slice(0, MAX_IMAGES);
            }
        } catch (e) {
            // 用户取消选择，忽略
        }
    }

    private removeImage(index: number) {
        const newImages = [...this.postState.selectedImages];
        newImages.splice(index, 1);
        this.postState.selectedImages = newImages;
    }

    private goBack() {
        this.mainNavPathStack.pop();
    }

    private canPublish(): boolean {
        return !this.postState.isPosting &&
            (this.postState.text.trim().length > 0 || this.postState.selectedImages.length > 0);
    }

    // 根据字符数估算 TextArea 高度（约每行 20 字，行高 22vp）
    private estimateTextAreaHeight(text: string): number {
        const lineCount = Math.max(1, Math.ceil(text.length / 22));
        const estimated = lineCount * 22 + 36;
        return Math.min(Math.max(estimated, 120), 300);
    }

    build() {
        NavDestination() {
            Column() {
                // 文本输入区
                this.buildTextInput()

                // 图片选择区
                this.buildImageSelector()

                // 上传进度
                if (this.postState.isPosting && this.postState.totalCount > 0) {
                    this.buildUploadProgress()
                }

                Blank()
            }
            .width('100%')
            .height('100%')
            .padding({ left: 16, right: 16, top: 0 })
            .backgroundColor(MomentConstants.BACKGROUND_COLOR)
        }
        .title('发表朋友圈')
        .menus(this.buildPostMenu)
        .backgroundColor(MomentConstants.BACKGROUND_COLOR)
    }

    @Builder
    private buildPostMenu() {
        if (this.postState.isPosting) {
            LoadingProgress()
                .width(22)
                .height(22)
                .color(MomentConstants.PRIMARY_COLOR)
                .margin({ right: 16 })
        } else {
            Button('发表')
                .backgroundColor(this.canPublish() ? MomentConstants.PRIMARY_COLOR : $r('app.color.button_disabled'))
                .fontColor(this.canPublish() ? Color.White : $r('app.color.text_disabled'))
                .fontSize(15)
                .height(34)
                .padding({ left: 18, right: 18 })
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .margin({ right: 16 })
                .onClick(() => {
                    if (this.canPublish()) this.publishFeed();
                })
        }
    }

    @Builder
    private buildTextInput() {
        Column() {
            TextArea({
                placeholder: '这一刻的想法...',
                text: this.postState.text
            })
                .width('100%')
                .height(this.textAreaHeight)
                .fontSize(MomentConstants.FONT_SIZE_CONTENT)
                .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
                .fontColor(MomentConstants.TEXT_PRIMARY_COLOR)
                .placeholderColor(MomentConstants.TEXT_SECONDARY_COLOR)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                .maxLength(MAX_TEXT_LENGTH)
                .onChange((value: string) => {
                    this.postState.text = value;
                    this.textAreaHeight = this.estimateTextAreaHeight(value);
                })

            // 字数提示（接近上限时显示）
            if (this.postState.text.length > MAX_TEXT_LENGTH * 0.8) {
                Row() {
                    Blank()
                    Text(`${this.postState.text.length}/${MAX_TEXT_LENGTH}`)
                        .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                        .fontColor(this.postState.text.length >= MAX_TEXT_LENGTH
                            ? MomentConstants.ERROR_COLOR
                            : MomentConstants.TEXT_SECONDARY_COLOR)
                }
                .width('100%')
                .padding({ right: 4, top: 4 })
            }
        }
        .width('100%')
        .margin({ top: 12, bottom: 12 })
    }

    @Builder
    private buildImageSelector() {
        Column() {
            Grid() {
                // 已选图片
                ForEach(this.postState.selectedImages, (imagePath: string, index: number) => {
                    GridItem() {
                        this.buildImageItem(imagePath, index)
                    }
                }, (imagePath: string, index: number) => `img_${index}`)

                // 添加按钮
                if (this.postState.selectedImages.length < MAX_IMAGES) {
                    GridItem() {
                        this.buildAddImageButton()
                    }
                }
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsGap(MomentConstants.IMAGE_GRID_GAP + 2)
            .columnsGap(MomentConstants.IMAGE_GRID_GAP + 2)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    private buildImageItem(imagePath: string, index: number) {
        Stack({ alignContent: Alignment.TopEnd }) {
            Image(imagePath)
                .width('100%')
                .aspectRatio(1)
                .borderRadius(MomentConstants.BORDER_RADIUS)
                .objectFit(ImageFit.Cover)
                .backgroundColor(MomentConstants.COMMENT_BACKGROUND_COLOR)

            // 删除按钮
            Button() {
                SymbolGlyph($r('sys.symbol.xmark'))
                    .fontSize(11)
                    .fontColor([Color.White])
            }
            .width(22)
            .height(22)
            .type(ButtonType.Circle)
            .backgroundColor('rgba(0,0,0,0.55)')
            .margin({ top: 4, right: 4 })
            .onClick(() => this.removeImage(index))
        }
        .width('100%')
    }

    @Builder
    private buildAddImageButton() {
        Column({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(28)
                .fontColor([MomentConstants.TEXT_SECONDARY_COLOR])
        }
        .width('100%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(MomentConstants.CARD_BACKGROUND_COLOR)
        .borderRadius(MomentConstants.BORDER_RADIUS)
        .border({
            width: 1,
            color: MomentConstants.DIVIDER_COLOR,
            style: BorderStyle.Dashed
        })
        .onClick(() => this.selectImages())
    }

    @Builder
    private buildUploadProgress() {
        Column({ space: 8 }) {
            Progress({
                value: this.postState.uploadingCount,
                total: this.postState.totalCount,
                type: ProgressType.Linear
            })
                .width('100%')
                .height(4)
                .color(MomentConstants.PRIMARY_COLOR)
                .backgroundColor(MomentConstants.DIVIDER_COLOR)
                .borderRadius(2)

            Text(`上传中 ${this.postState.uploadingCount}/${this.postState.totalCount}`)
                .fontSize(MomentConstants.FONT_SIZE_CAPTION)
                .fontColor(MomentConstants.TEXT_SECONDARY_COLOR)
        }
        .width('100%')
        .padding({ top: 12, bottom: 4 })
    }
}
