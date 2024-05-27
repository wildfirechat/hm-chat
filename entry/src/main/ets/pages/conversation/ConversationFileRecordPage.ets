import BasicDataSource from '../../common/BasicDataSource'
import { showToast } from '../../common/utils/Toast'
import Config from '../../config'
import { getFiletypeIcon, humanSize } from '../../util/helper'
import OptionItemView from '../../view/OptionItemView'
import wfc from '../../wfc/client/wfc'
import Conversation from '../../wfc/model/conversation'
import ConversationType from '../../wfc/model/conversationType'
import FileRecord from '../../wfc/model/fileRecord'
import GroupInfo from '../../wfc/model/groupInfo'
import Long from '../../wfc/util/long'
import { eq, stringValue } from '../../wfc/util/longUtil'
import { navigationDestinations } from '../navigationConfig'

@Entry
@Component
export default struct ConversationFileRecordPage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    private fileRecordDataSource: FileRecordDataSource = new FileRecordDataSource()
    private conversation?: Conversation
    private isLoading: boolean = false

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversation = params['conversation'] as Conversation;
        this.loadConversationFileRecords(Long.ZERO)
    }

    loadConversationFileRecords(beforeMessageUid: Long) {
        this.isLoading = true
        let fileRecords = wfc.getConversationFileRecords(this.conversation!, '', beforeMessageUid, 0, 200, fileRecords => {
            if (eq(beforeMessageUid, 0)) {
                this.fileRecordDataSource.setFileRecords(fileRecords)
            } else {
                this.fileRecordDataSource.appendFileRecords(fileRecords)
            }
            this.isLoading = false
        }, err => {
            showToast('加载文件记录失败: ' + err)
            this.isLoading = false
        })
    }

    fileRecordIcon(fileRecord: FileRecord): ResourceStr {
        return Config.DEFAULT_PORTRAIT_URL
    }

    fileSenderDisplayName(fileRecord: FileRecord) {
        let sender = fileRecord.userId;
        let displayName = wfc.getUserDisplayName(sender)
        return displayName
    }

    build() {
        NavDestination() {
            Column() {
                Text('文件记录')
                    .backgroundColor('#e5e5e5')
                    .fontColor('#989898')
                    .fontSize(13)
                    .padding({ left: 10 })
                    .width('100%')
                    .height(23)
                if (this.fileRecordDataSource.totalCount() === 0) {
                    Text('没有文件记录')
                        .width('100%')
                        .height('100%')
                        .textAlign(TextAlign.Center)
                } else {
                    List() {
                        LazyForEach(this.fileRecordDataSource, (fileRecord: FileRecord) => {
                            ListItem() {
                                Row() {
                                    Image(getFiletypeIcon(fileRecord.name))
                                        .width(50)
                                        .height(50)
                                        .margin(10)
                                    Column() {
                                        Text(fileRecord.name)
                                            .fontSize(1)
                                            .maxLines(1)
                                        Row() {
                                            Text(fileRecord.name)
                                                .maxLines(1)
                                            Text(this.fileSenderDisplayName(fileRecord))
                                                .maxLines(1)
                                                .margin({ left: 10 })
                                            Text(humanSize(fileRecord.size))
                                                .maxLines(1)
                                                .margin({ left: 10 })
                                        }
                                        .justifyContent(FlexAlign.Start)
                                    }
                                    .justifyContent(FlexAlign.Center)
                                    .alignItems(HorizontalAlign.Start)
                                }
                                .justifyContent(FlexAlign.Start)
                            }
                        }, (fileRecord: FileRecord) => stringValue(fileRecord.messageUid)
                        )
                    }
                    .onScrollIndex((start, end) => {
                        if (end === this.fileRecordDataSource.totalCount() - 1 && !this.isLoading) {
                            this.loadConversationFileRecords(this.fileRecordDataSource.getData(this.fileRecordDataSource.totalCount() - 1)
                                .messageUid)
                        }
                    })
                    .width('100%')
                    // .height(0)
                    .layoutWeight(1)
                    .divider({
                        strokeWidth: 1,
                        startMargin: 70
                    })
                }
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Start)
        }
        .title('文件记录')
        .height('100%')
        .width('100%')
        .backgroundColor('#EDEDED')
    }
}

class FileRecordDataSource
extends BasicDataSource
<FileRecord> {
    private fileRecords: FileRecord[] = []

    setFileRecords(fileRecords: FileRecord[]): void {
        this.fileRecords = fileRecords
        this.notifyDataReload()
    }

    appendFileRecords(fileRecords: FileRecord[]) {
        this.fileRecords = this.fileRecords.concat(fileRecords)
        this.notifyDataReload()
    }

    public totalCount(): number {
        return this.fileRecords.length
    }

    public getData(index: number): FileRecord {
        return this.fileRecords[index]
    }
}
