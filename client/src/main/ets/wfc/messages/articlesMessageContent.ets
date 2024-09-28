import MessageContent from "./messageContent";
import MessageContentType from "./messageContentType";
import wfc from "../client/wfc";
import LinkMessageContent from "./linkMessageContent";
import Message from './message';
import MessagePayload from './messagePayload';

export default class ArticlesMessageContent extends MessageContent {
    topArticle?: Article;
    subArticles = [] as Article[];

    constructor() {
        super(MessageContentType.Articles);
    }

    digest(message: Message) {
        return this.topArticle ? this.topArticle.title : 'no top article';
    }

    encode() {
        let payload = super.encode();
        let obj = {
            top: this.topArticle!.toJson(),
        } as Data
        if (this.subArticles) {
            obj.subArticles = this.subArticles.map(article => article.toJson());
        }
        payload.binaryContent = wfc.utf8_to_b64(JSON.stringify(obj));

        return payload;
    }

    decode(payload: MessagePayload) {
        super.decode(payload);
        let obj = JSON.parse(wfc.b64_to_utf8(payload.binaryContent)) as Data;
        this.topArticle = new Article();
        this.topArticle.fromJson(obj.top!);
        if (obj.subArticles) {
            this.subArticles = [];
            obj.subArticles.forEach(article => {
                let tmp = new Article();
                tmp.fromJson(article);
                this.subArticles.push(tmp);
            })
        }
    }

    toLinkMessageContent() {
        let contents = [] as LinkMessageContent[];
        contents.push(this.topArticle!.toLinkMessageContent())
        if (this.subArticles) {
            this.subArticles.forEach(article => {
                contents.push(article.toLinkMessageContent())
            })
        }
        return contents;
    }
}

class Article {
    articleId = '';
    cover = '';
    title = '';
    digest = '';
    url = '';
    readReport = false;

    toJson(): ArticleData {
        let obj = {
            id: this.articleId,
            cover: this.cover,
            title: this.title,
            url: this.url,
            digest: this.digest,
            rr: this.readReport
        } as ArticleData
        return obj;
    }

    fromJson(obj: ArticleData) {
        this.articleId = obj.id;
        this.cover = obj.cover;
        this.title = obj.title;
        this.digest = obj.digest;
        this.url = obj.url;
        this.readReport = obj.rr;
    }

    toLinkMessageContent() {
        let content = new LinkMessageContent();
        content.url = this.url;
        content.title = this.title;
        content.contentDigest = this.digest;
        content.thumbnail = this.cover;

        return content;
    }
}

class ArticleData {
    id = ''
    cover = ''
    title = ''
    url = ''
    digest = ''
    rr = false
}

class Data {
    top?: ArticleData
    subArticles = [] as ArticleData[]
}
