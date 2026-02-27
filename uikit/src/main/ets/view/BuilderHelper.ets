@Builder
export function NavigationMenu(title:string, enable: boolean, onClick: (event: ClickEvent) => void) {
    Row() {
        Button(title)
            .type(ButtonType.Normal)
            .height(30)
            .width(60)
            .margin({ right: 18 })
            .enabled(enable)
            .fontSize(14)
            .borderRadius(4)
            .onClick((e) => {
                onClick(e);
            })
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
}