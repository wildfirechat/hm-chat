import { showToast } from '../../common/utils/Toast';
import wfc from '../../wfc/client/wfc';
import url from '@ohos.url';
import UserInfo from '../../wfc/model/userInfo';
import { navigationDestinations } from '../navigationConfig';

export default class DSBridge {
    private webUrl: string;
    private webviewController: WebviewController
    private ready = false;
    private callId = 0;
    private asyncJsCallbacks: Record<number, string> = {}
    private mainNavPathStack: NavPathStack

    constructor(webUrl: string, webviewController: WebviewController, mainNavPathStack: NavPathStack) {
        this.webUrl = webUrl;
        this.webviewController = webviewController;
        this.mainNavPathStack = mainNavPathStack
    }

    private _callbackJs = (cbMethodName: string, code: number, data?: Object | string, complete = true) => {
        let ret: Record<string, Object> = {
            'code': code,
            'data': data ? data : ''
        }

        let script = `${cbMethodName}(${JSON.stringify(ret, null, '')});`
        if (complete) {
            script += `delete window.${cbMethodName}`
        }
        console.log('callbackjs', script)
        this.webviewController.runJavaScript(script)

    }
    private _callJs = (method: string, args?: Object[]) => {
        this.callId++;
        let obj: Record<string, Object> = {
            'method': method,
            'callbackId': this.callId,
            'data': args ? args : '[]'
        }

        let script = `window._handleMessageFromNative(${JSON.stringify(obj, null, '')})`
        this.webviewController.runJavaScript(script).then(value => {
            console.log('xxxxxxx', value)
        }).catch((r: Error) => {
            console.log('xxxxxxx ', r)
        })
    }
    private toast = (arg: string) => {
        showToast(arg)
    }
    private getAuthCode = (arg: string) => {
        let args = JSON.parse(arg) as Record<string, Object>
        let data = args.data as Record<string, Object>
        wfc.getAuthCode(data.appId as string, data.appType as number, url.URL.parseURL(this.webUrl)
            .host, (authCode: string) => {
            let cb = args._dscbstub as string;
            this._callbackJs(cb, 0, authCode)
        }, err => {
            let cb = args._dscbstub as string;
            this._callbackJs(cb, err)

        })
    }
    private config = (arg: string) => {
        let args = JSON.parse(arg) as Record<string, Object>
        let data = args.data as Record<string, Object>

        let appId = data.appId as string;
        let appType = data.appType as number;
        let timestamp = data.timestamp as number;
        let nonce = data.nonceStr as string;
        let signature = data.signature as string;

        wfc.configApplication(appId, appType, timestamp, nonce, signature, () => {
            this.ready = true;
            this._callJs('ready')

        }, err => {
            this._callJs('error', [err + ''])
        })
    }
    private openUrl = (arg: string) => {
        let args = JSON.parse(arg) as Record<string, Object>
        let url = args.data

        this.mainNavPathStack.pushPathByName(navigationDestinations.WebViewPage, {
            'url': url
        } as Record<string, Object>)
    }
    private close = (arg: string) => {
        this.mainNavPathStack.pop(true)
        let args = JSON.parse(arg) as Record<string, Object>
        let cb = args._dscbstub as string;
        this._callbackJs(cb, 0)
    }
    private chooseContacts = (arg: string) => {
        let args = JSON.parse(arg) as Record<string, Object>
        let cb = args._dscbstub as string;
        this.mainNavPathStack.pushPathByName(navigationDestinations.PickContactPage, {} as Record<string, Object>)
        this.asyncJsCallbacks[0] = cb;

    }
    private methods: Record<string, Function> = {
        'toast': this.toast,
        'getAuthCode': this.getAuthCode,
        'config': this.config,
        'openUrl': this.openUrl,
        'close': this.close,
        'chooseContacts': this.chooseContacts
    }
    private call = (method: string, arg: string) => {
        console.log('xxx call', method, arg)

        let argObj = JSON.parse(arg) as Record<string, Object>;

        let func = this.methods[method];
        if (func) {
            func(arg)
        } else {
            console.error('no method found', method)
        }
    }
    public onPickContact = (users: UserInfo[]) => {
        let method = this.asyncJsCallbacks[0];
        this._callbackJs(method, 0, users)
    }
}

interface AsyncJSCallback {
    reqId: number,
    method: string
}
