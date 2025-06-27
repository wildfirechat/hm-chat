import ArticlesMessageContent, { Article } from "@wfc/client/src/main/ets/wfc/messages/articlesMessageContent";
import Message from "@wfc/client/src/main/ets/wfc/messages/message";
import { navigationDestinations } from "../../navigationConfig";

@Component
export default struct ArticleMessageContentView {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @Link message: Message;

    hasSubArticles() {
        let articleMessageContent = this.message.messageContent as ArticlesMessageContent
        return articleMessageContent.subArticles.length > 0
    }

    articlesMessageContent() {
        let articleMessageContent = this.message.messageContent as ArticlesMessageContent
        return articleMessageContent;
    }

    build() {
        Column() {
            Column() {
                Image(this.articlesMessageContent().topArticle!.cover)
                    .enabled(false)
                    .width('100%')
                    .objectFit(ImageFit.CENTER)
                Text(this.articlesMessageContent().topArticle?.title)
                    .maxLines(2)
                    .padding(10)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .onClick(() => {
                this.mainNavPathStack.pushPathByName(navigationDestinations.WebViewPage, {
                    'url': this.articlesMessageContent().topArticle?.url,
                    'title': this.articlesMessageContent().topArticle?.title
                } as Record<string, Object>)
            })

            if (this.articlesMessageContent().subArticles.length > 0) {
                ForEach(this.articlesMessageContent().subArticles, (item: Article, index) => {
                    Row() {
                        Text(this.articlesMessageContent().topArticle?.title)
                            .maxLines(2)
                            .layoutWeight(1)
                            .padding(10)
                        Image(this.articlesMessageContent().topArticle!.cover)
                            .enabled(false)
                            .height(60)
                            .width(60)
                            .objectFit(ImageFit.CENTER)
                            .borderRadius({
                                topLeft: 5,
                                topRight: 5
                            })
                    }
                }, (item: Article, index) => index + '')
            }
        }
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .padding(10)
        .width('100%')
        .borderRadius(5)
    }
}