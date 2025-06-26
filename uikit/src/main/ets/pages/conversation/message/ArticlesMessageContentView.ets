import ArticlesMessageContent, { Article } from "@wfc/client/src/main/ets/wfc/messages/articlesMessageContent";
import Message from "@wfc/client/src/main/ets/wfc/messages/message";

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
            Image(this.articlesMessageContent().topArticle!.cover)
                .height(160)
                .objectFit(ImageFit.CENTER)
                .borderRadius({
                    topLeft: 5,
                    topRight: 5
                })
            Text(this.articlesMessageContent().topArticle?.title)
                .maxLines(2)
                .padding(10)
            if (this.articlesMessageContent().subArticles.length > 0) {
                ForEach(this.articlesMessageContent().subArticles, (item: Article, index) => {
                    Column() {
                        Image(this.articlesMessageContent().topArticle!.cover)
                            .height(160)
                            .objectFit(ImageFit.CENTER)
                            .borderRadius({
                                topLeft: 5,
                                topRight: 5
                            })
                        Text(this.articlesMessageContent().topArticle?.title)
                            .maxLines(2)
                            .padding(10)
                    }
                }, (item: Article, index) => index + '')
            }
        }
    }
}