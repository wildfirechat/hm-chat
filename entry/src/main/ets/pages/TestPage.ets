import { pinyin4js } from '@ohos/pinyin4js';

@Entry
@Component
struct TestPage {
    private arrayA: string[] = ['安']
    private arrayB: string[] = ['卜', '白', '包', '毕', '丙']
    private arrayC: string[] = ['曹', '成', '陈', '催']
    private arrayL: string[] = ['刘', '李', '楼', '梁', '雷', '吕', '柳', '卢']
    private value: string[] = ['#', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
        'H', 'I', 'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S', 'T', 'U',
        'V', 'W', 'X', 'Y', 'Z']

    onPageShow(){
        console.info("00773-" + pinyin4js.convertToPinyinString('厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER));
        console.info("00773-" + pinyin4js.convertToPinyinString('1厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER));
        console.info("00773-" + pinyin4js.convertToPinyinString('2厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER));
        console.info("00773-" + pinyin4js.convertToPinyinString('a厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER));
        console.info("00773-" + pinyin4js.convertToPinyinString('A厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER));
    }

    build() {
        Row() {
            List({ space: 20, initialIndex: 0 }) {
                ForEach(this.arrayA, (item) => {
                    ListItem() {
                        Text(item)
                            .width('80%')
                            .height('5%')
                            .fontSize(30)
                            .textAlign(TextAlign.Center)
                    }
                }, item => item)

                ForEach(this.arrayB, (item) => {
                    ListItem() {
                        Text(item)
                            .width('80%')
                            .height('5%')
                            .fontSize(30)
                            .textAlign(TextAlign.Center)
                    }
                    .selectable(false)
                }, item => item)

                ForEach(this.arrayC, (item) => {
                    ListItem() {
                        Text(item)
                            .width('80%')
                            .height('5%')
                            .fontSize(30)
                            .textAlign(TextAlign.Center)
                    }.selectable(true)
                }, item => item)

                ForEach(this.arrayL, (item) => {
                    ListItem() {
                        Text(item)
                            .width('80%')
                            .height('5%')
                            .fontSize(30)
                            .textAlign(TextAlign.Center)
                    }.editable(true)
                }, item => item)
            }
            .layoutWeight(1)
            // .width('50%')
            .height('100%')

            AlphabetIndexer({ arrayValue: this.value, selected: 0 })
                .selectedColor(0xFFFFFF) // 选中项文本颜色
                .popupColor(0xFFFAF0) // 弹出框文本颜色
                .selectedBackgroundColor(0xCCCCCC) // 选中项背景颜色
                .popupBackground(0xD2B48C) // 弹出框背景颜色
                .usingPopup(true) // 是否显示弹出框
                .selectedFont({ size: 16, weight: FontWeight.Bolder }) // 选中项字体样式
                .popupFont({ size: 30, weight: FontWeight.Bolder }) // 弹出框内容的字体样式
                .itemSize(28) // 每一项的尺寸大小
                .alignStyle(IndexerAlign.Left) // 弹出框在索引条右侧弹出
                .onSelect((index: number) => {
                    console.info(this.value[index] + ' Selected!')
                })
                .popupPosition({ x: -100, y: 100 })
                .onRequestPopupData((index: number) => {
                    if (this.value[index] == 'A') {
                        return this.arrayA // 当选中A时，弹出框里面的提示文本列表显示A对应的列表arrayA，选中B、C、L时也同样
                    } else if (this.value[index] == 'B') {
                        return this.arrayB
                    } else if (this.value[index] == 'C') {
                        return this.arrayC
                    } else if (this.value[index] == 'L') {
                        return this.arrayL
                    } else {
                        return [] // 选中其余子母项时，提示文本列表为空
                    }
                })
                .onPopupSelect((index: number) => {
                    console.info('onPopupSelected:' + index)
                })
        }
    }
}