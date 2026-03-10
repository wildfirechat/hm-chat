import { uikitNavigationDestinations } from './pages/uikitNavigationConfig';
import wfc from '@wfc/client';
import url from '@ohos.url';
import { showToast } from './common/utils/Toast';

export default class WfcScheme {
    static QR_CODE_PREFIX_PC_SESSION = "wildfirechat://pcsession/";
    static QR_CODE_PREFIX_USER = "wildfirechat://user/";
    static QR_CODE_PREFIX_GROUP = "wildfirechat://group/";
    static QR_CODE_PREFIX_CHANNEL = "wildfirechat://channel/";
    static QR_CODE_PREFIX_CONFERENCE = "wildfirechat://conference/";

    static buildConferenceLink(conferenceId: string, password: string) {
        let link = WfcScheme.QR_CODE_PREFIX_CONFERENCE + conferenceId;
        if (password) {
            link += '/?pwd=' + password
        }
        return link;
    }

    static handleQRCodeResult(navPathStack: NavPathStack, qrCodeText: string) {
        let prefix = '';
        let value = '';

        try {
            let lastSlashIndex = qrCodeText.lastIndexOf('/');
            if (lastSlashIndex <= 0) {
                showToast('不支持的二维码格式')
                return;
            }

            prefix = qrCodeText.substring(0, lastSlashIndex + 1);
            let qIndex = qrCodeText.indexOf('?');
            value = qrCodeText.substring(lastSlashIndex + 1, qIndex > 0 ? qIndex : qrCodeText.length);

            let params: url.URLParams | undefined;
            try {
                let _url = url.URL.parseURL(qrCodeText);
                params = _url.params;
            } catch (e) {
            }

            switch (prefix) {
                case WfcScheme.QR_CODE_PREFIX_PC_SESSION:
                    navPathStack.pushPathByName(uikitNavigationDestinations.PCLoginPage, {
                        'token': value,
                        'isConfirmPCLogin': false,
                        'platform': 0
                    } as Record<string, Object>)
                    break;
                case WfcScheme.QR_CODE_PREFIX_USER:
                    let userInfo = wfc.getUserInfo(value, true);
                    if (userInfo) {
                        navPathStack.pushPathByName(uikitNavigationDestinations.UserInfoPage, {
                            'userInfo': userInfo
                        } as Record<string, Object>)
                    }
                    break;
                case WfcScheme.QR_CODE_PREFIX_GROUP:
                    navPathStack.pushPathByName(uikitNavigationDestinations.GroupInfoPage, {
                        'groupId': value,
                        'from': params?.get('from') || ''
                    } as Record<string, Object>)
                    break;
                case WfcScheme.QR_CODE_PREFIX_CHANNEL:
                    // navPathStack.pushPathByName(uikitNavigationDestinations.ChannelInfoPage, {
                    //     'channelId': value
                    // } as Record<string, Object>)
                    showToast('TODO')
                    break;
                case WfcScheme.QR_CODE_PREFIX_CONFERENCE:
                    navPathStack.pushPathByName(uikitNavigationDestinations.ConferenceInfoPage, {
                        'conferenceId': value,
                        'password': params?.get('pwd') || ''
                    } as Record<string, Object>)
                    break;
                default:
                    if (qrCodeText.startsWith('http')) {
                        navPathStack.pushPathByName(uikitNavigationDestinations.WebViewPage, {
                            'url': qrCodeText,
                            'title': ''
                        } as Record<string, Object>)
                    } else {
                        showToast('qrcode: ' + qrCodeText);
                    }
                    break;
            }

        } catch (e) {
            console.error('handleQRCodeResult error', e);
        }
    }
}
