// import Config from "../config";
// // import FavItem from "../wfc/model/favItem";
// // import {stringValue} from "../wfc/util/longUtil";
// import AppServerError from "./appServerError";
// import wfc from 'marswrapper'
// import data_preferences from '@ohos.data.preferences';
// import http from '@ohos.net.http';
//
// export class AppServerApi {
//     constructor() {
//     }
//
//     requestAuthCode(mobile) {
//         return this._post('/send_code', {mobile})
//     }
//
//     loinWithPassword(mobile, password) {
//         return new Promise((resolve, reject) => {
//             let responsePromise = this._post('/login_pwd', {
//                 mobile,
//                 password,
//                 platform: Config.getWFCPlatform(),
//                 clientId: wfc.getClientId()
//             }, true)
//             this._interceptLoginResponse(responsePromise, resolve, reject)
//         })
//     }
//
//     loginWithAuthCode(mobile, authCode) {
//         return new Promise((resolve, reject) => {
//             let responsePromise = this._post('/login', {
//                 mobile,
//                 code: authCode,
//                 platform: Config.getWFCPlatform(),
//                 clientId: wfc.getClientId()
//             }, true);
//             this._interceptLoginResponse(responsePromise, resolve, reject)
//         })
//     }
//
//
//     createPCSession(userId) {
//         return this._post('/pc_session', {
//             flag: 1,
//             device_name: 'pc',
//             userId: userId,
//             clientId: wfc.getClientId(),
//             platform: Config.getWFCPlatform()
//         })
//     }
//
//     // 扫码登录
//     loginWithPCSession(appToken) {
//         const _interceptPCSessionLoginResponse = (responsePromise, resolve, reject) => {
//             responsePromise
//                 .then(response => {
//                     if (response.data.code === 0) {
//                         let appAuthToken = response.headers['authtoken'];
//                         if (!appAuthToken) {
//                             appAuthToken = response.headers['authToken'];
//                         }
//
//                         if (appAuthToken) {
//                             setItem('authToken-' + new URL(response.config.url).host, appAuthToken);
//                         }
//                         resolve(response.data);
//                     } else if ([9, 18].indexOf(response.data.code) > -1) {
//                         resolve(response.data);
//                     } else {
//                         reject(new AppServerError(response.data.code, response.data.message));
//                     }
//                 })
//                 .catch(err => {
//                     reject(err);
//                 })
//         }
//
//         return new Promise((resolve, reject) => {
//             let responsePromise = this._post(`/session_login/${appToken}`, null, true);
//             _interceptPCSessionLoginResponse(responsePromise, resolve, reject)
//         })
//     }
//
//     changePassword(oldPassword, newPassword) {
//         return this._post('/change_pwd', {
//             oldPassword,
//             newPassword
//         })
//     }
//
//     requestResetPasswordAuthCode() {
//         return this._post('/send_reset_code')
//     }
//
//     resetPassword(resetPasswordAuthCode, newPassword) {
//         return this._post('/reset_pwd', {
//             resetCode: resetPasswordAuthCode,
//             newPassword: newPassword,
//         })
//     }
//
//     getGroupAnnouncement(groupId) {
//         return this._post('/get_group_announcement', {groupId: groupId})
//     }
//
//     updateGroupAnnouncement(author, groupId, announcement) {
//         return this._post('/put_group_announcement', {
//             author,
//             groupId,
//             text: announcement
//         })
//     }
//
//     favMessage(message) {
//         let favItem = FavItem.fromMessage(message);
//         return this._post('/fav/add', {
//             messageUid: stringValue(favItem.messageUid),
//             type: favItem.favType,
//             convType: favItem.conversation.type,
//             convTarget: favItem.conversation.target,
//             convLine: favItem.conversation.line,
//             origin: favItem.origin,
//             sender: favItem.sender,
//             title: favItem.title,
//             url: favItem.url,
//             thumbUrl: favItem.thumbUrl,
//             data: favItem.data,
//         });
//     }
//
//     getFavList(startId, count = 20) {
//         return this._post('/fav/list', {id: startId, count: count}, false, true)
//     }
//
//     delFav(favItemId) {
//         return this._post('/fav/del/' + favItemId, '')
//     }
//
//     _interceptLoginResponse(responsePromise, resolve, reject) {
//         responsePromise
//             .then(response => {
//                 if (response.data.code === 0) {
//                     let appAuthToken = response.headers['authtoken'];
//                     if (!appAuthToken) {
//                         appAuthToken = response.headers['authToken'];
//                     }
//
//                     if (appAuthToken) {
//                         setItem('authToken-' + new URL(response.config.url).host, appAuthToken);
//                     }
//                     resolve(response.data.result);
//                 } else {
//                     reject(new AppServerError(response.data.code, response.data.message));
//                 }
//             })
//             .catch(err => {
//                 reject(err);
//             })
//     }
//
//     /**
//      *
//      * @param path
//      * @param data
//      * @param rawResponse
//      * @param rawResponseData
//      * @return {Promise<string | AxiosResponse<any>|*|T>}
//      * @private
//      */
//     // async _post(path, data = {}, rawResponse = false, rawResponseData = false) {
//     //     let response;
//     //     path = Config.APP_SERVER + path;
//     //     response = await axios.post(path, data, {
//     //         transformResponse: rawResponseData ? [data => data] : axios.defaults.transformResponse,
//     //         headers: {
//     //             'authToken': getItem('authToken-' + new URL(path).host),
//     //         },
//     //         withCredentials: true,
//     //     })
//     //     if (rawResponse) {
//     //         return response;
//     //     }
//     //     if (response.data) {
//     //         if (rawResponseData) {
//     //             return response.data;
//     //         }
//     //         if (response.data.code === 0) {
//     //             return response.data.result
//     //         } else {
//     //             throw new AppServerError(response.data.code, response.data.message)
//     //         }
//     //     } else {
//     //         throw new Error('request error, status code: ' + response.status)
//     //     }
//     // }
//     _post(path: string, data: string | object) {
//         return new Promise((resolve, reject) => {
//             let httpRequest = http.createHttp();
//             // 用于订阅HTTP响应头，此接口会比request请求先返回。可以根据业务需要订阅此消息
//             // 从API 8开始，使用on('headersReceive', Callback)替代on('headerReceive', AsyncCallback)。 8+
//             httpRequest.on('headersReceive', (header) => {
//                 console.info('header: ' + JSON.stringify(header));
//                 // if (header.toString() === 'authToken') {
//                 //     this.authToken = header.toString();
//                 // }
//             });
//             console.log('request', path, data)
//             httpRequest.request(
//                 // 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
//                 path,
//                 {
//                     method: http.RequestMethod.POST, // 可选，默认为http.RequestMethod.GET
//                     // 开发者根据自身业务需要添加header字段
//                     header: {
//                         'Content-Type': 'application/json'
//                     },
//                     // 当使用POST请求时此字段用于传递内容
//                     extraData: data,
//                     expectDataType: http.HttpDataType.OBJECT, // 可选，指定返回数据的类型
//                     usingCache: true, // 可选，默认为true
//                     priority: 1, // 可选，默认为1
//                     connectTimeout: 60000, // 可选，默认为60000ms
//                     readTimeout: 60000, // 可选，默认为60000ms
//                     usingProtocol: http.HttpProtocol.HTTP1_1, // 可选，协议类型默认值由系统自动指定
//                 }, (err, data) => {
//                 if (!err) {
//                     // data.result为HTTP响应内容，可根据业务需要进行解析
//                     console.info('Result:' + JSON.stringify(data.result));
//                     console.info('code:' + JSON.stringify(data.responseCode));
//                     // data.header为HTTP响应头，可根据业务需要进行解析
//                     console.info('header:' + JSON.stringify(data.header));
//                     console.info('cookies:' + JSON.stringify(data.cookies)); // 8+
//                     // 取消订阅HTTP响应头事件
//                     httpRequest.off('headersReceive');
//                     // 当该请求使用完毕时，调用destroy方法主动销毁
//                     httpRequest.destroy();
//                     console.log('response', data)
//                     if (data.result.code === 0) {
//                         resolve(data.result.data)
//                     } else {
//                         reject(data.result.code)
//                     }
//                 } else {
//                     console.info('error:' + JSON.stringify(err));
//                     // 取消订阅HTTP响应头事件
//                     httpRequest.off('headersReceive');
//                     // 当该请求使用完毕时，调用destroy方法主动销毁。
//                     httpRequest.destroy();
//                     console.error('err', err)
//                     reject(err)
//                 }
//             }
//             )
//         })
//     }
// }
//
// const appServerApi = new AppServerApi();
// export default appServerApi;
