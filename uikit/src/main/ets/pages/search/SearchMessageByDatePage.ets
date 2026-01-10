import Conversation from '@wfc/client/src/main/ets/wfc/model/conversation'
import wfc from '@wfc/client/src/main/ets/wfc/client/wfc'
import { uikitNavigationDestinations } from '../uikitNavigationConfig'

@Component
export default struct SearchMessageByDatePage {
    @State conversation: Conversation | undefined = undefined
    @State yearMonths: YearMonth[] = []
    @State messageCounts: Map<string, number> = new Map() // date string (yyyy-MM-dd) -> count
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.conversation = params['conversation'] as Conversation

        this.initData()
    }

    async initData() {
        // Find oldest message
        wfc.getMessagesByTimestampV2(this.conversation!, [], 1000, false, 1, '', (messages) => {
            let oldestTime = new Date().getTime()
            if (messages && messages.length > 0) {
                oldestTime = messages[0].timestamp
            }

            // Generate YearMonth list from oldest to now
            let start = new Date(oldestTime)
            let end = new Date()
            let list: YearMonth[] = []

            let current = new Date(start.getFullYear(), start.getMonth(), 1)
            let endDate = new Date(end.getFullYear(), end.getMonth(), 1)

            while (current <= endDate) {
                list.push(new YearMonth(current.getFullYear(), current.getMonth()))
                current.setMonth(current.getMonth() + 1)
            }

            this.yearMonths = list.reverse()

            this.messageCounts = wfc.getMessageCountByDay(this.conversation!, [], oldestTime / 1000, end.getTime() / 1000)

        }, (err) => {
            // If error or no messages, just show current month
            let now = new Date()
            this.yearMonths = [new YearMonth(now.getFullYear(), now.getMonth())]
            this.messageCounts = wfc.getMessageCountByDay(this.conversation!, [], 0, now.getTime() / 1000)
        })
    }

    build() {
        NavDestination() {
            Column() {
                // Calendar List
                List() {
                    ForEach(this.yearMonths, (ym: YearMonth) => {
                        ListItem() {
                            MonthView({
                                year: ym.year,
                                month: ym.month,
                                messageCounts: this.messageCounts,
                                onDateClick: (year, month, day) => {
                                    this.onDateClick(year, month, day)
                                }
                            })
                        }
                    })
                }
                .width('100%')
                .layoutWeight(1)
                .onAppear(() => {
                })
            }
            .width('100%')
            .height('100%')
            .backgroundColor(Color.White)
        }
        .title('按日期查找')
    }

    onDateClick(year: number, month: number, day: number) {
        // Find the first message of this day
        let dateStr = `${year}-${month + 1 < 10 ? '0' : ''}${month + 1}-${day < 10 ? '0' : ''}${day}`
        let count = this.messageCounts.get(dateStr)
        if (!count || count <= 0) {
            return
        }

        let startOfDay = new Date(year, month, day).getTime()

        wfc.getMessagesByTimestampV2(this.conversation!, [], startOfDay - 1, false, 1, '', (messages) => {
            if (messages && messages.length > 0) {
                let msg = messages[0]
                this.mainNavPathStack.pushPathByName(uikitNavigationDestinations.ConversationPage, {
                    'conversation': this.conversation,
                    'focusMessageId': msg.messageId
                } as Record<string, Object>)
            }
        }, (err) => {
            // error
        })
    }
}

class YearMonth {
    year: number
    month: number // 0-11

    constructor(year: number, month: number) {
        this.year = year
        this.month = month
    }
}

@Component
struct MonthView {
    year: number = 0
    month: number = 0
    @Link messageCounts: Map<string, number>
    onDateClick?: (year: number, month: number, day: number) => void

    build() {
        Column() {
            Text(`${this.year}年${this.month + 1}月`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .padding(10)
                .width('100%')
                .textAlign(TextAlign.Start)
                .backgroundColor('#F5F5F5')

            Grid() {
                // Header (Sun, Mon, ...)
                ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
                    GridItem() {
                        Text(day)
                            .fontSize(14)
                            .fontColor(Color.Gray)
                    }
                    .height(30)
                })

                // Days
                ForEach(this.getDays(), (day: number | null) => {
                    GridItem() {
                        if (day) {
                            Column() {
                                Text(`${day}`)
                                    .fontSize(16)
                                    .fontWeight(this.hasMessage(day) ? FontWeight.Bold : FontWeight.Normal)
                                    .fontColor(this.hasMessage(day) ? Color.Black : Color.Gray)

                                if (this.hasMessage(day)) {
                                    Circle({ width: 4, height: 4 })
                                        .fill(Color.Red) // Or some indicator
                                        .margin({ top: 2 })
                                }
                            }
                            .width('100%')
                            .height('100%')
                            .justifyContent(FlexAlign.Center)
                            .alignItems(HorizontalAlign.Center)
                            // .backgroundColor(this.hasMessage(day) ? '#E0E0E0' : Color.Transparent)
                            // .borderRadius(4)
                            .onClick(() => {
                                if (this.onDateClick) {
                                    this.onDateClick(this.year, this.month, day)
                                }
                            })
                        }
                    }
                    .height(50)
                })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .width('100%')
        }
    }

    getDays(): (number | null)[] {
        let days: (number | null)[] = []
        let firstDay = new Date(this.year, this.month, 1)
        let lastDay = new Date(this.year, this.month + 1, 0)

        // Empty slots before 1st day
        for (let i = 0; i < firstDay.getDay(); i++) {
            days.push(null)
        }

        for (let i = 1; i <= lastDay.getDate(); i++) {
            days.push(i)
        }

        return days
    }

    hasMessage(day: number): boolean {
        let dateStr = `${this.year}-${this.month + 1 < 10 ? '0' : ''}${this.month + 1}-${day < 10 ? '0' : ''}${day}`
        let count = this.messageCounts.get(dateStr)
        return count !== undefined && count > 0
    }
}
