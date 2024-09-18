// 引入包名
import http from '@ohos.net.http';
import data_preferences from '@ohos.data.preferences';
import wfc from 'marswrapper'
import Config from '../config';
import { GlobalContext } from '../globalContext';
import common from '@ohos.app.ability.common';
import url from '@ohos.url';
import GroupAnnouncement from './model/groupAnnouncement';
import AppServerError from './appServerError';
import PCSession from '../wfc/model/pcsession';
import { JSONObject } from '../wfc/type/types';
import Message from '../wfc/messages/message';
import FavItem from '../wfc/model/favItem';
import { stringValue } from '../wfc/util/longUtil';

class AppServer {
    baseUrl = Config.APP_SERVER;
    authToken = '';

    constructor() {
        let context = GlobalContext.getContext().getObject<common.UIAbilityContext>('context');
        let preference = data_preferences.getPreferencesSync(context, {
            name: 'wfcstore'
        })
        let _url = url.URL.parseURL(this.baseUrl)
        this.authToken = preference.getSync(`authToken-${_url.host}-${_url.port}`, '') as string
    }

    requestAuthCode(mobile: string) {
        return this._post('/send_code', { 'mobile': mobile } as Record<string, string>)
    }

    loginWithAuthCode(phone: string, authCode: string) {
        let obj = {
            'mobile': phone,
            'code': authCode,
            'platform': Config.getWFCPlatform(),
            'clientId': wfc.getClientId(),
        } as Record<string, Object>
        return this._post('/login', obj)
    }

    loinWithPassword(phone: string, password: string) {
        let obj = {
            'mobile': phone,
            'password': password,
            'platform': Config.getWFCPlatform(),
            'clientId': wfc.getClientId(),
        } as Record<string, Object>
        return this._post('/login_pwd', obj)
    }

    async getGroupAnnouncement(groupId: string): Promise<GroupAnnouncement> {
        let result = await this._post('/get_group_announcement', { 'groupId': groupId } as Record<string, Object>)
        return result as GroupAnnouncement
    }

    updateGroupAnnouncement(author: string, groupId: string, announcement: string) {
        return this._post('/put_group_announcement', {
            'author': author,
            'groupId': groupId,
            'text': announcement
        } as Record<string, Object>)
    }

    async scanPCLogin(token: string): Promise<PCSession> {
        let result = await this._post(`/scan_pc/${token}`)
        let pcSession = result as PCSession
        if (pcSession.status === 1) {
            return pcSession
        } else {
            throw new AppServerError(-1, pcSession.status + '')
        }
    }

    async confirmPCLogin(token: string, userId: string): Promise<void> {
        let result = await this._post('/confirm_pc', {
            'user_id': userId,
            'token': token,
            'quick_login': 1
        } as JSONObject)
        let pcSession = result as PCSession
        if (pcSession.status === 2) {
            return
        } else {
            throw new AppServerError(-1, pcSession.status + '')
        }
    }

    async cancelPCLogin(token: string): Promise<void> {
        let result = await this._post('/cancel_pc', {
            'token': token,
        } as JSONObject)
        let pcSession = result as PCSession
        if (pcSession.status === 2) {
            return
        } else {
            throw new AppServerError(-1, pcSession.status + '')
        }
    }

    changePassword(oldPassword: string, newPassword: string) {
        return this._post('/change_pwd', {
            'oldPassword': oldPassword,
            'newPassword': newPassword
        } as JSONObject)
    }

    requestResetPasswordAuthCode() {
        return this._post('/send_reset_code')
    }

    resetPassword(resetPasswordAuthCode: string, newPassword: string) {
        return this._post('/reset_pwd', {
            'resetCode': resetPasswordAuthCode,
            'newPassword': newPassword,
        } as JSONObject)
    }

    favMessage(message: Message) {
        let favItem = FavItem.fromMessage(message);
        return this._post('/fav/add', {
            'messageUid': stringValue(favItem.messageUid),
            'type': favItem.favType,
            'convType': favItem.conversation!.type,
            'convTarget': favItem.conversation!.target,
            'convLine': favItem.conversation!.line,
            'origin': favItem.origin,
            'sender': favItem.sender,
            'title': favItem.title,
            'url': favItem.url,
            'thumbUrl': favItem.thumbUrl,
            'data': favItem.data,
        } as JSONObject);
    }

    getFavList(startId: number, count = 20) {
        return this._post('/fav/list', {
            'id': startId,
            'count': count
        } as JSONObject, true)
    }

    delFav(favItemId: number) {
        return this._post('/fav/del/' + favItemId)
    }

    _post(path: string, data?: string | Object, rawResponseData = false): Promise<string | object> {
        return new Promise((resolve, reject) => {
            let httpRequest = http.createHttp();
            // 用于订阅HTTP响应头，此接口会比request请求先返回。可以根据业务需要订阅此消息
            // 从API 8开始，使用on('headersReceive', Callback)替代on('headerReceive', AsyncCallback)。 8+
            // httpRequest.on('headersReceive', (header) => {
            //     console.info('header: ' + JSON.stringify(header));
            // if (header.toString() === 'authToken') {
            //     this.authToken = header.toString();
            //         let context = GlobalContext.getContext().getObject<common.ApplicationContext>('applicationContext');
            //         let preference = data_preferences.getPreferencesSync(context, {
            //             name: 'wfcstore'
            //         })
            //         let _url = url.URL.parseURL(this.baseUrl)
            //         preference.put(`authToken-${_url.host}-${_url.port}`, this.authToken)
            // }
            // });
            console.log('request', path, data)
            httpRequest.request(// 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
                this.baseUrl + path,
                {
                    method: http.RequestMethod.POST, // 可选，默认为http.RequestMethod.GET
                    // 开发者根据自身业务需要添加header字段
                    header: {
                        'Content-Type': 'application/json',
                        'authToken': this.authToken
                    },
                    // 当使用POST请求时此字段用于传递内容
                    extraData: data,
                    expectDataType: rawResponseData ? http.HttpDataType.STRING : http.HttpDataType.OBJECT, // 可选，指定返回数据的类型
                    usingCache: true, // 可选，默认为true
                    priority: 1, // 可选，默认为1
                    connectTimeout: 60000, // 可选，默认为60000ms
                    readTimeout: 60000, // 可选，默认为60000ms
                    usingProtocol: http.HttpProtocol.HTTP1_1, // 可选，协议类型默认值由系统自动指定
                }, (err, data) => {
                if (!err) {
                    // data.result为HTTP响应内容，可根据业务需要进行解析
                    console.info('Result:' + JSON.stringify(data.result));
                    console.info('code:' + JSON.stringify(data.responseCode));
                    // data.header为HTTP响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + JSON.stringify(data.cookies)); // 8+
                    // 取消订阅HTTP响应头事件
                    // httpRequest.off('headersReceive');
                    // 当该请求使用完毕时，调用destroy方法主动销毁
                    httpRequest.destroy();
                    console.log('response', data)
                    if (rawResponseData) {
                        resolve(data.result)
                    } else {
                        let result = data.result as Record<string, Object>
                        if (result.code === 0) {
                            // 30ba6ab2d4d249d4ab9114a02a9850fc
                            let authToken: string = data.header['authtoken']
                            if (!authToken) {
                                authToken = data.header['authToken']
                            }
                            if (authToken) {
                                this.authToken = authToken
                                let context = GlobalContext.getContext()
                                    .getObject<common.ApplicationContext>('context');
                                let preference = data_preferences.getPreferencesSync(context, {
                                    name: 'wfcstore'
                                })
                                let _url = url.URL.parseURL(this.baseUrl)
                                preference.putSync(`authToken-${_url.host}-${_url.port}`, this.authToken)
                            }
                            resolve(result.result)
                        } else {
                            reject(new AppServerError(result.code as number, result.message as string))
                        }
                    }
                } else {
                    console.info('error:' + JSON.stringify(err));
                    // 取消订阅HTTP响应头事件
                    httpRequest.off('headersReceive');
                    // 当该请求使用完毕时，调用destroy方法主动销毁。
                    httpRequest.destroy();
                    console.error('err', err)
                    reject(new AppServerError(-1, err.message))
                }
            }
            )
        })
    }
}

let self = new AppServer();

export default self


