import { showToast } from '../../common/utils/Toast';
import CollectionService from '../../api/collectionService';
import Collection from '@wfc/client/src/main/ets/wfc/model/collection';
import CollectionEntry from '@wfc/client/src/main/ets/wfc/model/collectionEntry';
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc';
import UserInfo from '@wfc/client/src/main/ets/wfc/model/userInfo';
import promptAction from '@ohos.promptAction';
import { NavigationMenu } from '../../view/BuilderHelper';

@Component
export default struct CollectionDetailPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State collectionId: number = 0;
    @State groupId: string = '';
    @State collection: Collection | null = null;
    @State @Watch('updateSubmitButtonState') myEntryContent: string = '';
    @State creatorInfo: UserInfo | null = null;
    @State displayEntries: CollectionEntry[] = [];
    @State hasJoined: boolean = false;
    @State myEntryIndex: number = -1;
    @State canSubmit: boolean = false;
    @State isCreator: boolean = false;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        if (params && params['collectionId'] && params['groupId']) {
            this.collectionId = params['collectionId'] as number;
            this.groupId = params['groupId'] as string;
            this.fetchCollection();
        } else {
            showToast('参数错误');
            this.mainNavPathStack.pop();
        }
    }

    fetchCollection() {
        CollectionService.getCollection(this.collectionId, this.groupId)
            .then(collection => {
                this.collection = collection;
                this.creatorInfo = wfc.getUserInfo(collection.creatorId, false);
                this.displayEntries = collection.entries.filter(e => e.deleted === 0);

                this.hasJoined = false;
                this.myEntryIndex = -1;
                this.myEntryContent = '';
                this.isCreator = collection.creatorId === wfc.getUserId();

                for (let i = 0; i < this.displayEntries.length; i++) {
                    if (this.displayEntries[i].userId === wfc.getUserId()) {
                        this.hasJoined = true;
                        this.myEntryIndex = i;
                        this.myEntryContent = this.displayEntries[i].content;
                        break;
                    }
                }

                if (!this.hasJoined) {
                    // Pre-fill with user name if not already set or empty
                    let userInfo = wfc.getUserInfo(wfc.getUserId(), false);
                    this.myEntryContent = userInfo.displayName || userInfo.name || '';
                }

                this.updateSubmitButtonState();
            })
            .catch((err: Error) => {
                showToast('获取接龙详情失败: ' + err.message);
            });
    }

    updateSubmitButtonState() {
        if (!this.collection) {
            this.canSubmit = false;
            return;
        }

        let originalContent = '';
        if (this.hasJoined && this.myEntryIndex >= 0 && this.myEntryIndex < this.displayEntries.length) {
            originalContent = this.displayEntries[this.myEntryIndex].content;
        }

        let currentContent = this.myEntryContent.trim();
        let hasChanged = currentContent !== originalContent;

        if (this.hasJoined) {
            this.canSubmit = hasChanged || (currentContent.length === 0 && originalContent.length > 0);
        } else {
            this.canSubmit = currentContent.length > 0;
        }
    }

    build() {
        NavDestination() {
            Column() {
                if (this.collection) {
                    List() {
                        // Header Item
                        ListItem() {
                            Column() {
                                Row() {
                                    Image(this.creatorInfo?.portrait || $r('app.media.avatar_def'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Column() {
                                        Text(`${this.creatorInfo?.displayName || this.collection.creatorId} 发起的接龙`)
                                            .fontSize(14)
                                            .fontColor(Color.Gray)
                                        Text(`已参与 ${this.collection.calculateParticipantCount()} 人`)
                                            .fontSize(12)
                                            .fontColor(Color.Gray)
                                            .margin({ top: 4 })
                                    }
                                    .margin({ left: 12 })
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .width('100%')

                                Text(this.collection.title)
                                    .fontSize(18)
                                    .fontWeight(FontWeight.Bold)
                                    .margin({ top: 16, bottom: 8 })
                                    .width('100%')

                                if (this.collection.desc) {
                                    Text(this.collection.desc)
                                        .fontSize(14)
                                        .fontColor('#333333')
                                        .margin({ bottom: 8 })
                                        .width('100%')
                                }

                                if (this.collection.template) {
                                    Text(`填写格式: ${this.collection.template}`)
                                        .fontSize(12)
                                        .fontColor(Color.Gray)
                                        .margin({ bottom: 8 })
                                        .width('100%')
                                }

                                if (this.collection.expireType === 1) {
                                    Text(`截止时间: ${new Date(this.collection.expireAt).toLocaleString()}`)
                                        .fontSize(12)
                                        .fontColor(Color.Red)
                                        .margin({ bottom: 8 })
                                        .width('100%')
                                }
                            }
                            .padding(16)
                            .backgroundColor(Color.White)
                        }

                        // Entries
                        ForEach(this.displayEntries, (entry: CollectionEntry, index: number) => {
                            ListItem() {
                                if (this.collection?.status === 0 && this.hasJoined && index === this.myEntryIndex) {
                                    // Edit my entry
                                    this.buildEditRow(index + 1)
                                } else {
                                    // Display entry
                                    this.buildEntryRow(index + 1, entry.content)
                                }
                            }
                        })

                        // New Entry Input (if not joined and active)
                        if (this.collection.status === 0 && !this.hasJoined) {
                            ListItem() {
                                this.buildEditRow(this.displayEntries.length + 1)
                            }
                        }
                    }
                    .layoutWeight(1)
                    .backgroundColor('#F5F5F5')
                }
            }
        }
        .hideTitleBar(false)
        .title('接龙详情')
        .menus(NavigationMenu('确定', this.canSubmit, () => {
            this.onSubmit();
        }))
    }

    @Builder
    buildEntryRow(index: number, content: string) {
        Row() {
            Text(`${index}.`)
                .fontSize(14)
                .fontColor(Color.Gray)
                .width(30)
            Text(content)
                .fontSize(16)
                .layoutWeight(1)
        }
        .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 12
        })
        .width('100%')
        .backgroundColor(Color.White)
    }

    @Builder
    buildEditRow(index: number) {
        Row() {
            Text(`${index}.`)
                .fontSize(14)
                .fontColor(Color.Gray)
                .width(30)
            TextInput({
                placeholder: this.collection?.template || '参与接龙',
                text: $$this.myEntryContent
            })
                .width('100%')
                .layoutWeight(1)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#CCCCCC', radius: 4 })
                .height(40)
                .padding({ left: 8, right: 8 })
                .onSubmit(() => {
                    if (this.canSubmit) {
                        this.onSubmit();
                    }
                })
        }
        .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
        })
        .width('100%')
        .backgroundColor(Color.White)
    }

    onSubmit() {
        if (!this.collection) {
            return;
        }

        let content = this.myEntryContent.trim();

        if (this.hasJoined) {
            if (content.length === 0) {
                // Delete entry
                this.confirmDeleteEntry();
            } else {
                // Update entry
                this.joinOrUpdate(content);
            }
        } else {
            // Join
            if (content.length === 0) {
                showToast('请输入内容');
                return;
            }
            this.joinOrUpdate(content);
        }
        this.mainNavPathStack.pop()
    }

    joinOrUpdate(content: string) {
        CollectionService.joinCollection(this.collectionId, this.groupId, content)
            .then(() => {
                showToast(this.hasJoined ? '更新成功' : '参与成功');
                this.fetchCollection();
            })
            .catch((err: Error) => {
                let msg = err.message;
                if (msg == '3003') { // Assuming error code is converted to string message or handled similarly
                    msg = '您不在该群组中';
                }
                showToast('操作失败: ' + msg);
            });
    }

    confirmDeleteEntry() {
        promptAction.showDialog({
            title: '提示',
            message: '确定要删除这条接龙记录吗？',
            buttons: [
                {
                    text: '取消',
                    color: '#000000'
                },
                {
                    text: '删除',
                    color: '#FF0000'
                }
            ]
        }).then((data) => {
            if (data.index === 1) {
                this.doDeleteEntry();
            }
        }).catch((err: Error) => {
            // Cancelled
        });
    }

    doDeleteEntry() {
        CollectionService.deleteCollectionEntry(this.collectionId, this.groupId)
            .then(() => {
                showToast('已退出接龙');
                this.fetchCollection();
            })
            .catch((err: Error) => {
                showToast('操作失败: ' + err.message);
            });
    }
}
