import { showToast } from '../../common/utils/Toast';
import CollectionService from '../../api/collectionService';
import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation';

@Component
export default struct CreateCollectionPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State title: string = '';
    @State desc: string = '';
    @State template: string = ''; // 参与人填写格式，例如：姓名-电话
    @State expireType: number = 0; // 0: 永久有效, 1: 设置过期时间
    @State expireDate: Date = new Date();
    @State conversation: Conversation | null = null;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params && params['conversation']) {
            this.conversation = params['conversation'] as Conversation;
            // 默认截止时间：24小时后
            let now = new Date();
            now.setHours(now.getHours() + 24);
            this.expireDate = now;
        } else {
            showToast('参数错误');
            this.mainNavPathStack.pop();
        }
    }

    build() {
        NavDestination() {
            Column() {
                Scroll() {
                    Column() {
                        // Title
                        Text('接龙主题')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                            .width('100%')
                            .margin({ top: 16, bottom: 8 })
                        TextInput({ placeholder: '请输入接龙主题', text: $$this.title })
                            .backgroundColor(Color.White)
                            .width('100%')
                            .height(48)
                            .borderRadius(4)

                        // Description
                        Text('接龙描述')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                            .width('100%')
                            .margin({ top: 16, bottom: 8 })
                        TextArea({ placeholder: '请输入接龙描述（选填）', text: $$this.desc })
                            .backgroundColor(Color.White)
                            .width('100%')
                            .height(100)
                            .borderRadius(4)

                        // Template
                        Text('填写格式')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                            .width('100%')
                            .margin({ top: 16, bottom: 8 })
                        TextInput({ placeholder: '例如：姓名-电话（选填）', text: $$this.template })
                            .backgroundColor(Color.White)
                            .width('100%')
                            .height(48)
                            .borderRadius(4)

                        // Expire Type
                        Text('截止时间')
                            .fontSize(14)
                            .fontColor(Color.Gray)
                            .width('100%')
                            .margin({ top: 16, bottom: 8 })

                        Row() {
                            Radio({ value: '0', group: 'expireType' })
                                .checked(this.expireType === 0)
                                .onChange((isChecked: boolean) => {
                                    if (isChecked) this.expireType = 0;
                                })
                            Text('永久有效')
                                .fontSize(16)
                                .margin({ left: 8 })
                        }
                        .width('100%')
                        .height(48)
                        .onClick(() => {
                            this.expireType = 0;
                        })

                        Row() {
                            Radio({ value: '1', group: 'expireType' })
                                .checked(this.expireType === 1)
                                .onChange((isChecked: boolean) => {
                                    if (isChecked) this.expireType = 1;
                                })
                            Text('设置截止时间')
                                .fontSize(16)
                                .margin({ left: 8 })
                        }
                        .width('100%')
                        .height(48)
                        .onClick(() => {
                            this.expireType = 1;
                        })

                        if (this.expireType === 1) {
                            Row() {
                                Text(this.formatDate(this.expireDate))
                                    .fontSize(16)
                                Blank()
                                Image($r('app.media.ic_public_arrow_right'))
                                    .width(16)
                                    .height(16)
                            }
                            .width('100%')
                            .height(48)
                            .backgroundColor(Color.White)
                            .padding({ left: 16, right: 16 })
                            .margin({ top: 8 })
                            .borderRadius(4)
                            .onClick(() => {
                                this.showDatePicker();
                            })
                        }

                    }
                    .padding({ left: 16, right: 16, bottom: 32 })
                }
                .align(Alignment.TopStart)
                .layoutWeight(1)
                .backgroundColor('#F5F5F5')
            }
            .width('100%')
            .height('100%')
        }
        .hideTitleBar(false)
        .title('发起接龙')
        .menus(this.NavigationMenus())
    }
    
    @Builder
    NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .margin({ right: 18 })
                .enabled(this.title.trim().length > 0)
                .fontSize(14)
                .borderRadius(4)
                .onClick(() => {
                    this.createCollection();
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }

    showDatePicker() {
        DatePickerDialog.show({
            start: new Date(),
            end: new Date("2100-12-31"),
            selected: this.expireDate,
            onAccept: (value: DatePickerResult) => {
                let newDate = new Date(this.expireDate);
                newDate.setFullYear(value.year, value.month, value.day);

                // Show Time Picker next
                TimePickerDialog.show({
                    selected: this.expireDate,
                    onAccept: (timeValue: TimePickerResult) => {
                         newDate.setHours(timeValue.hour, timeValue.minute);
                         this.expireDate = newDate;
                    }
                })
                this.expireDate = newDate;
            }
        })
    }

    formatDate(date: Date): string {
        return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }

    createCollection() {
        if (!this.conversation) return;

        let expireAt = 0;
        if (this.expireType === 1) {
            expireAt = this.expireDate.getTime();
            if (expireAt <= new Date().getTime()) {
                showToast('截止时间不能早于当前时间');
                return;
            }
        }

        CollectionService.createCollection(
            this.conversation.target,
            this.title,
            this.desc,
            this.template,
            this.expireType,
            expireAt,
            0 // maxParticipants 暂不设置
        ).then(collection => {
            showToast('接龙发布成功');
            this.mainNavPathStack.pop();
        }).catch((err: Error) => {
            showToast('发布失败: ' + err.message);
        });
    }
}
