/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import { showToast } from '../../common/utils/Toast';
import pollService from '../../api/pollService';
import Poll from './model/poll';
import { uikitNavigationDestinations } from '../uikitNavigationConfig';

interface OptionItem {
    id: number;
    value: string;
}

interface PollCallback {
    onSuccess: (poll: Poll) => void;
    onError: (errorCode: number, message: string) => void;
}

@Component
export default struct CreatePollPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private groupId: string = '';

    @State title: string = '';
    @State desc: string = '';
    @State options: OptionItem[] = [
        { id: 1, value: '' },
        { id: 2, value: '' }
    ];
    @State pollType: number = 1;        // 1=单选, 2=多选
    @State anonymous: boolean = false;
    @State showResult: boolean = false;
    @State endTime: number = 0;
    @State pollVisibility: number = 1;      // 1=仅群内, 2=公开
    @State isLoading: boolean = false;

    private nextOptionId: number = 3;
    private readonly MIN_OPTIONS = 2;
    private readonly MAX_OPTIONS = 10;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByName(uikitNavigationDestinations.CreatePollPage) as Record<string, Object>[];
        if (params && params.length > 0) {
            this.groupId = params[0]['groupId'] as string || '';
        }

        if (!this.groupId) {
            showToast('投票功能仅支持群组');
            this.mainNavPathStack.pop();
            return;
        }
    }

    private addOption() {
        if (this.options.length >= this.MAX_OPTIONS) {
            showToast(`最多${this.MAX_OPTIONS}个选项`);
            return;
        }
        this.options.push({ id: this.nextOptionId++, value: '' });
    }

    private removeOption(index: number) {
        if (this.options.length <= this.MIN_OPTIONS) {
            showToast(`至少保留${this.MIN_OPTIONS}个选项`);
            return;
        }
        this.options.splice(index, 1);
    }

    private updateOption(index: number, value: string) {
        this.options[index].value = value;
    }

    private getEndTimeText(): string {
        if (this.endTime === 0) {
            return '无截止时间';
        }
        let date = new Date(this.endTime);
        return `${date.getMonth() + 1}-${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }

    private showEndTimePicker() {
        // 使用默认的24小时后
        let defaultTime = new Date().getTime() + 24 * 60 * 60 * 1000;
        if (this.endTime > 0) {
            defaultTime = this.endTime;
        }

        DatePickerDialog.show({
            start: new Date(),
            selected: new Date(defaultTime),
            onDateAccept: (date: Date) => {
                // 选择时间后，设置当天的时间
                let selectedTime = new Date(date);
                let now = new Date();
                selectedTime.setHours(now.getHours() + 24);
                selectedTime.setMinutes(0);
                selectedTime.setSeconds(0);

                if (selectedTime.getTime() <= now.getTime()) {
                    showToast('截止时间必须大于当前时间');
                    return;
                }
                this.endTime = selectedTime.getTime();
            },
            onCancel: () => {
                // 清除截止时间
                this.endTime = 0;
            }
        });
    }

    private showPollTypeDialog() {
        AlertDialog.show({
            title: '选择投票类型',
            message: '',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            buttons: [
                {
                    value: '单选',
                    action: () => {
                        this.pollType = 1;
                    }
                },
                {
                    value: '多选',
                    action: () => {
                        this.pollType = 2;
                    }
                }
            ]
        });
    }

    private showVisibilityDialog() {
        AlertDialog.show({
            title: '选择可见性',
            message: '',
            autoCancel: true,
            alignment: DialogAlignment.Center,
            gridCount: 4,
            buttons: [
                {
                    value: '仅群内',
                    action: () => {
                        this.pollVisibility = 1;
                    }
                },
                {
                    value: '公开',
                    action: () => {
                        this.pollVisibility = 2;
                    }
                }
            ]
        });
    }

    private getPollTypeText(): string {
        return this.pollType === 1 ? '单选' : '多选';
    }

    private getVisibilityText(): string {
        return this.pollVisibility === 1 ? '仅群内' : '公开';
    }

    private createPoll() {
        // 验证标题
        let title = this.title.trim();
        if (!title) {
            showToast('请输入投票标题');
            return;
        }

        // 过滤空选项
        let validOptions = this.options
            .map(opt => opt.value.trim())
            .filter(value => value.length > 0);

        if (validOptions.length < this.MIN_OPTIONS) {
            showToast(`至少需要${this.MIN_OPTIONS}个有效选项`);
            return;
        }

        if (!pollService.baseUrl) {
            showToast('投票服务未配置');
            return;
        }

        this.isLoading = true;

        let description = this.desc.trim();
        let maxSelect = this.pollType === 1 ? 1 : validOptions.length;
        let anonymousValue = this.anonymous ? 1 : 0;
        let showResultValue = this.showResult ? 1 : 0;

        pollService.createPoll(
            this.groupId,
            title,
            description,
            validOptions,
            this.pollVisibility,
            this.pollType,
            maxSelect,
            anonymousValue,
            this.endTime,
            showResultValue,
            {
                onSuccess: (poll: Poll): void => {
                    this.isLoading = false;
                    showToast('投票创建成功');
                    this.mainNavPathStack.pop();
                },
                onError: (errorCode: number, message: string): void => {
                    this.isLoading = false;
                    showToast('创建失败: ' + message);
                }
            } as PollCallback
        );
    }

    build() {
        NavDestination() {
            Scroll() {
                Column({ space: 16 }) {
                    // 标题输入
                    Column({ space: 8 }) {
                        Text('投票标题')
                            .fontSize(14)
                            .fontColor('#666666')
                            .width('100%')

                        TextInput({ placeholder: '请输入投票标题（必填）', text: $$this.title })
                            .height(44)
                            .backgroundColor('#F5F5F5')
                            .borderRadius(8)
                    }
                    .width('100%')

                    // 描述输入
                    Column({ space: 8 }) {
                        Text('投票描述')
                            .fontSize(14)
                            .fontColor('#666666')
                            .width('100%')

                        TextArea({ placeholder: '请输入投票描述（可选）', text: $$this.desc })
                            .height(80)
                            .backgroundColor('#F5F5F5')
                            .borderRadius(8)
                    }
                    .width('100%')

                    // 选项列表
                    Column({ space: 8 }) {
                        Text('投票选项')
                            .fontSize(14)
                            .fontColor('#666666')
                            .width('100%')

                        ForEach(this.options, (item: OptionItem, index: number) => {
                            Row({ space: 8 }) {
                                TextInput({ placeholder: `选项 ${index + 1}`, text: item.value })
                                    .layoutWeight(1)
                                    .height(44)
                                    .backgroundColor('#F5F5F5')
                                    .borderRadius(8)
                                    .onChange((value: string) => {
                                        this.updateOption(index, value);
                                    })

                                if (this.options.length > this.MIN_OPTIONS) {
                                    Button('删除')
                                        .fontSize(12)
                                        .fontColor('#FF3B30')
                                        .backgroundColor(Color.Transparent)
                                        .onClick(() => {
                                            this.removeOption(index);
                                        })
                                }
                            }
                            .width('100%')
                        }, (item: OptionItem) => item.id.toString())

                        // 添加选项按钮
                        if (this.options.length < this.MAX_OPTIONS) {
                            Button('+ 添加选项')
                                .width('100%')
                                .height(44)
                                .fontSize(14)
                                .fontColor('#007AFF')
                                .backgroundColor('#F5F5F5')
                                .borderRadius(8)
                                .onClick(() => {
                                    this.addOption();
                                })
                        }

                        Text(`至少${this.MIN_OPTIONS}个选项，最多${this.MAX_OPTIONS}个选项`)
                            .fontSize(12)
                            .fontColor('#999999')
                            .width('100%')
                    }
                    .width('100%')

                    // 设置项
                    Column({ space: 8 }) {
                        Text('投票设置')
                            .fontSize(14)
                            .fontColor('#666666')
                            .width('100%')

                        Column({ space: 1 }) {
                            // 投票类型
                            Row() {
                                Text('投票类型')
                                    .fontSize(16)
                                    .fontColor('#333333')

                                Row({ space: 4 }) {
                                    Text(this.getPollTypeText())
                                        .fontSize(14)
                                        .fontColor('#666666')
                                    Image($r('app.media.ic_public_arrow_right'))
                                        .width(16)
                                        .height(16)
                                }
                            }
                            .width('100%')
                            .height(48)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .justifyContent(FlexAlign.SpaceBetween)
                            .onClick(() => {
                                this.showPollTypeDialog();
                            })

                            Divider()
                                .strokeWidth(0.5)
                                .color('#E5E5E5')
                                .margin({ left: 16 })

                            // 匿名投票
                            Row() {
                                Text('匿名投票')
                                    .fontSize(16)
                                    .fontColor('#333333')

                                Toggle({ type: ToggleType.Switch, isOn: $$this.anonymous })
                                    .selectedColor('#007AFF')
                            }
                            .width('100%')
                            .height(48)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .justifyContent(FlexAlign.SpaceBetween)

                            Divider()
                                .strokeWidth(0.5)
                                .color('#E5E5E5')
                                .margin({ left: 16 })

                            // 始终显示结果
                            Row() {
                                Text('始终显示结果')
                                    .fontSize(16)
                                    .fontColor('#333333')

                                Toggle({ type: ToggleType.Switch, isOn: $$this.showResult })
                                    .selectedColor('#007AFF')
                            }
                            .width('100%')
                            .height(48)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .justifyContent(FlexAlign.SpaceBetween)

                            Divider()
                                .strokeWidth(0.5)
                                .color('#E5E5E5')
                                .margin({ left: 16 })

                            // 截止时间
                            Row() {
                                Text('截止时间')
                                    .fontSize(16)
                                    .fontColor('#333333')

                                Row({ space: 4 }) {
                                    Text(this.getEndTimeText())
                                        .fontSize(14)
                                        .fontColor('#666666')
                                    Image($r('app.media.ic_public_arrow_right'))
                                        .width(16)
                                        .height(16)
                                }
                            }
                            .width('100%')
                            .height(48)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .justifyContent(FlexAlign.SpaceBetween)
                            .onClick(() => {
                                this.showEndTimePicker();
                            })

                            Divider()
                                .strokeWidth(0.5)
                                .color('#E5E5E5')
                                .margin({ left: 16 })

                            // 可见性
                            Row() {
                                Text('可见性')
                                    .fontSize(16)
                                    .fontColor('#333333')

                                Row({ space: 4 }) {
                                    Text(this.getVisibilityText())
                                        .fontSize(14)
                                        .fontColor('#666666')
                                    Image($r('app.media.ic_public_arrow_right'))
                                        .width(16)
                                        .height(16)
                                }
                            }
                            .width('100%')
                            .height(48)
                            .padding({ left: 16, right: 16 })
                            .backgroundColor(Color.White)
                            .justifyContent(FlexAlign.SpaceBetween)
                            .onClick(() => {
                                this.showVisibilityDialog();
                            })
                        }
                        .width('100%')
                        .borderRadius(8)
                        .clip(true)
                    }
                    .width('100%')

                    // 发布按钮
                    Button('发布投票')
                        .width('100%')
                        .height(48)
                        .fontSize(16)
                        .fontColor(Color.White)
                        .backgroundColor('#007AFF')
                        .borderRadius(8)
                        .margin({ top: 16 })
                        .enabled(!this.isLoading)
                        .onClick(() => {
                            this.createPoll();
                        })
                }
                .width('100%')
                .padding(16)
            }
            .width('100%')
            .height('100%')
        }
        .title('创建投票')
        .backgroundColor('#F2F2F7')
        .hideBackButton(false)
    }
}
