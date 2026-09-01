import http from '@ohos.net.http';
import data_preferences from '@ohos.data.preferences';
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config';
import common from '@ohos.app.ability.common';
import url from '@ohos.url';
import GroupAnnouncement from './model/groupAnnouncement';
import AppServerError from './appServerError';
import PCSession from '@wfc/client/src/main/ets/wfc/model/pcsession';
import { JSONObject } from '@wfc/client/src/main/ets/wfc/type/types';
import Message from '@wfc/client/src/main/ets/wfc/messages/message';
import FavItem from '@wfc/client/src/main/ets/wfc/model/favItem';
import { stringValue } from '@wfc/client/src/main/ets/wfc/util/longUtil';
import { parseHostAndPort } from './Util';
import ConferenceInfo from '@wfc/avenginekit/src/main/ets/wfc/av/model/conferenceInfo';
import QRLoginSession from './model/qrLoginSession';

class AppServer {
    authToken = '';
    private isInitialized = false
    private currentHostPort = '';

    constructor() {
    }

    private baseUrl(): string {
        let address = Config.getAppServer();
        if (!address) {
            console.error('AppServer address not configured');
            return '';
        }
        return address;
    }

    requestAuthCode(mobile: string, slideVerifyToken?: string) {
        let params = { 'mobile': mobile } as Record<string, Object>
        if (slideVerifyToken) {
            params['slideVerifyToken'] = slideVerifyToken
        }
        return this._post('/send_code', params)
    }

    requestDestroyAuthCode(slideVerifyToken?: string) {
        let params = {} as Record<string, Object>
        if (slideVerifyToken) {
            params['slideVerifyToken'] = slideVerifyToken
        }
        return this._post('/send_destroy_code', params)
    }

    loginWithAuthCode(phone: string, authCode: string, slideVerifyToken?: string) {
        let obj = {
            'mobile': phone,
            'code': authCode,
            'platform': Config.getWFCPlatform(),
            'clientId': wfc.getClientId(),
        } as Record<string, Object>
        if (slideVerifyToken) {
            obj['slideVerifyToken'] = slideVerifyToken
        }
        return this._post('/login', obj)
    }

    loinWithPassword(phone: string, password: string, slideVerifyToken?: string) {
        let obj = {
            'mobile': phone,
            'password': password,
            'platform': Config.getWFCPlatform(),
            'clientId': wfc.getClientId(),
        } as Record<string, Object>
        if (slideVerifyToken) {
            obj['slideVerifyToken'] = slideVerifyToken
        }
        return this._post('/login_pwd', obj)
    }

    destroy(authCode: string) {
        let obj = {
            'code': authCode,
        } as Record<string, Object>
        return this._post('/destroy', obj)
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

    /**
     * 创建 PC 登录会话（本端为被扫码端）：token 拼成二维码内容 wildfirechat://pcsession/<token> 供手机端扫描。
     * 与 Android/iOS 端 createPCLoginSession 保持一致（POST /pc_session）。
     * @param deviceName 设备名，平板扫码登录传 'pad'
     */
    async createPCLoginSession(deviceName: string = 'pad'): Promise<QRLoginSession> {
        let params = {
            'flag': 1,
            'device_name': deviceName,
            'clientId': wfc.getClientId(),
            'platform': Config.getWFCPlatform()
        } as Record<string, Object>
        console.log('[PadQR] createPCLoginSession url=' + this.baseUrl() + '/pc_session' + ', params=' + JSON.stringify(params))
        let result = await this._post('/pc_session', params)
        console.log('[PadQR] createPCLoginSession response=' + JSON.stringify(result))
        return result as object as QRLoginSession
    }

    /**
     * 二维码登录，创建二维码登录 session
     * @param userId
     * @returns
     */
    createQRLoginSession(userId: string, deviceName: string = 'wearable') {
        let params = {
            'flag': 1,
            'device_name': deviceName,
            'clientId': wfc.getClientId(),
            'platform': Config.getWFCPlatform()
        } as Record<string, Object>
        if (userId) {
            params['userId'] = userId
        }
        let result = this._post('/pc_session', params)
        return result as object as QRLoginSession
    }

    /**
     * 二维码登录
     * UI 层的具体实现，可以参考 vue-pc-chat
     * @param token
     * @returns
     */
    async loginWithQRSession(token: string) {
        // 注意：extraData 不能传空字符串 ''（Content-Type: application/json 下会被 http 模块
        // 判为参数错误 401），传空对象 {}（序列化为 {}，服务端不解析该 body，等价 Android 的 null body）
        let data = await this._post(`/session_login/${token}`, {} as Record<string, Object>, true) as http.HttpResponse
        console.log('[PadQR] loginWithQRSession raw body=' + String(data.result))
        if (!data || data.result === undefined || data.result === null || String(data.result).length === 0) {
            // 空响应体：抛错让轮询走异常分支，避免解析空值
            throw new AppServerError(-1, '返回数据为空')
        }
        // rawResponseData=true 时 expectDataType 为 STRING，data.result 是 JSON 字符串，
        // 需要自行解析（code 9 需携带 result 里的扫码用户信息，走 ResultWrapper 会丢失）
        let restResult: Record<string, Object>
        try {
            restResult = JSON.parse(data.result as string) as Record<string, Object>
        } catch (e) {
            console.error('[PadQR] loginWithQRSession JSON.parse failed, fallback to object', JSON.stringify(e))
            restResult = data.result as Record<string, Object>
        }
        let code = restResult['code'] as number
        console.log('[PadQR] loginWithQRSession parsed code=' + code + ', result=' + JSON.stringify(restResult['result']))
        if (code === 0) {
            this._interceptResponseAuthToken(data)
            return restResult
        } else if ([9, 18].indexOf(code) >= 0) {
            return restResult
        } else {
            throw new AppServerError(code, restResult['message'] as string)
        }
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

    changePassword(oldPassword: string, newPassword: string, slideVerifyToken?: string) {
        let params = {
            'oldPassword': oldPassword,
            'newPassword': newPassword
        } as JSONObject
        if (slideVerifyToken) {
            params['slideVerifyToken'] = slideVerifyToken
        }
        return this._post('/change_pwd', params)
    }

    // 滑动验证相关 API
    getSlideVerify() {
        return this._post('/slide_verify/generate', {} as JSONObject, false)
    }

    verifySlide(token: string, x: number) {
        return this._post('/slide_verify/verify', {
            'token': token,
            'x': x
        } as JSONObject)
    }

    requestResetPasswordAuthCode(phone: string) {
        return this._post('/send_reset_code', {
            "mobile": phone
        } as JSONObject)
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

    getMyPrivateConferenceId(): Promise<string> {
        return this._post('/conference/get_my_id') as Promise<string>
    }

    createConference(conferenceInfo: ConferenceInfo): Promise<string> {
        return this._post('/conference/create', conferenceInfo) as Promise<string>
    }

    async queryConferenceInfo(conferenceId: string, password: string): Promise<ConferenceInfo> {
        let result = await this._post('/conference/info', { 'conferenceId': conferenceId, 'password': password } as Record<string, Object>)
        return result as ConferenceInfo
    }

    destroyConference(conferenceId: string) {
        return this._post(`/conference/destroy/${conferenceId}`);
    }

    favConference(conferenceId: string) {
        return this._post('/conference/fav/' + conferenceId);
    }

    unfavConference(conferenceId: string) {
        return this._post('/conference/unfav/' + conferenceId);
    }

    isFavConference(conferenceId: string) {
        return this._post('/conference/is_fav/' + conferenceId);
    }

    async getFavConferences() {
        let result = await this._post('/conference/fav_conferences');
        return result as ConferenceInfo[]
    }

    updateConference(conferenceInfo: ConferenceInfo) {
        return this._post('/conference/put_info', conferenceInfo);
    }

    recordConference(conferenceId: string, record: boolean) {
        return this._post('/conference/recording/' + conferenceId, { 'recording': record } as JSONObject);
    }

    setConferenceFocusUserId(conferenceId: string, userId: string) {
        return this._post('/conference/focus/' + conferenceId, { 'userId': userId ? userId : '' } as JSONObject);
    }

    async checkVersion(currentVersion: string, buildNumber: number): Promise<Record<string, Object> | null> {
        let url = this.baseUrl + '/version/check?platform=' + Config.getWFCPlatform() + '&currentVersion=' + currentVersion + '&buildNumber=' + buildNumber
        try {
            let result = await this._get(url)
            if (result && result.code === 0) {
                return result.result as Record<string, Object>
            }
        } catch (e) {
            console.error('checkVersion error', e)
        }
        return null
    }

    _init() {
        let context = AppStorage.get<common.UIAbilityContext>('context');
        let preference = data_preferences.getPreferencesSync(context?.getApplicationContext(), {
            name: 'wfcstore'
        })
        // 兼容 Android 端迁移过来的数据
        let hostPort = parseHostAndPort(this.baseUrl())
        this.currentHostPort = `${hostPort.host}-${hostPort.port}`;
        this.authToken = preference.getSync(`authToken:${this.currentHostPort}`, '') as string
    }

    _get(url: string): Promise<Record<string, Object>> {
        this._ensureInitialized()
        return new Promise((resolve, reject) => {
            let httpRequest = http.createHttp();
            httpRequest.request(url, {
                method: http.RequestMethod.GET,
                header: {
                    'Content-Type': 'application/json',
                    'authToken': this.authToken
                },
                expectDataType: http.HttpDataType.OBJECT,
                connectTimeout: 30000,
                readTimeout: 30000,
            }, (err, data) => {
                if (!err && data.responseCode == 200) {
                    httpRequest.destroy();
                    let result = data.result as Record<string, Object>
                    resolve(result)
                } else {
                    httpRequest.destroy();
                    reject(new AppServerError(-1, err?.message || '请求失败'))
                }
            })
        })
    }

    private _ensureInitialized() {
        let hostPort = parseHostAndPort(this.baseUrl())
        let newHostPort = `${hostPort.host}-${hostPort.port}`;
        if (!this.isInitialized || this.currentHostPort !== newHostPort) {
            this._init()
            this.isInitialized = true
        }
    }

    _post(path: string, data?: string | Object, rawResponseData = false): Promise<string | object | http.HttpResponse> {
        this._ensureInitialized()
        return new Promise((resolve, reject) => {
            let httpRequest = http.createHttp();

            console.log('request', path, data)
            httpRequest.request(// 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
                this.baseUrl() + path,
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
                if (!err && data && data.responseCode == 200) {
                    httpRequest.destroy();
                    console.log('response', data)
                    if (rawResponseData) {
                        resolve(data)
                    } else {
                        let result = data.result as Record<string, Object>
                        if (result && result.code === 0) {
                            this._interceptResponseAuthToken(data)
                            resolve(result.result)
                        } else if (result) {
                            reject(new AppServerError(result.code as number, result.message as string))
                        } else {
                            // 200 但响应体为空/非 JSON：不能抛异常挂起 promise，按失败处理
                            console.error('_post empty/invalid response body, path=' + path)
                            reject(new AppServerError(-1, '返回数据为空'))
                        }
                    }
                } else {
                    httpRequest.destroy();
                    console.error('[PadQR] _post request failed, path=' + path + ', responseCode=' + (data ? data.responseCode : -1) + ', err=' + JSON.stringify(err))
                    reject(new AppServerError(-1, err?.message || '请求失败'))
                }
            }
            )
        })
    }

    _interceptResponseAuthToken(data: http.HttpResponse) {
        let header = data.header as Record<string, Object>
        let authToken: string = header['authtoken'] as string
        if (!authToken) {
            authToken = header['authToken'] as string
        }
        if (authToken) {
            this.authToken = authToken
            let context = AppStorage.get<common.ApplicationContext>('context');
            let preference = data_preferences.getPreferencesSync(context?.getApplicationContext(), {
                name: 'wfcstore'
            })
            preference.putSync(`authToken:${this.currentHostPort}`, this.authToken)
        }
    }
}

let self = new AppServer();

export default self


