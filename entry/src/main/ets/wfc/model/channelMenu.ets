export default class ChannelMenu {
    menuId: string;
    type: string;
    name: string;
    key: string;
    url: string;
    mediaId: string;
    articleId: string;
    appId: string;
    appPage: string;
    extra: string;
    subMenus: ChannelMenu[];

    constructor(menuId: string = '', type: string = '', name: string ='', key: string ='', url: string = '', mediaId: string = '', articleId: string = '', appId: string = '', appPage: string = '', extra: string = '', subMenus: ChannelMenu[] = []) {
        this.menuId = menuId;
        this.type = type;
        this.name = name;
        this.key = key;
        this.url = url;
        this.mediaId = mediaId;
        this.articleId = articleId;
        this.appId = appId;
        this.appPage = appPage;
        this.extra = extra;
        this.subMenus = subMenus;
    }


}
