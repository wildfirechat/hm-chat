import { FontSize, Radius } from '../common/design/Tokens'
@Builder
export function NavigationMenu(title:string, enable: boolean, onClick: (event: ClickEvent) => void) {
    Row() {
        Button(title)
            .type(ButtonType.Normal)
            .height(32)
            .width(60)
            .margin({ right: 20 })
            .enabled(enable)
            .fontSize(FontSize.sm)
            .borderRadius(Radius.sm)
            .onClick((e) => {
                onClick(e);
            })
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
}