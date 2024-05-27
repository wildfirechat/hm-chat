import { numberValue } from '../wfc/util/longUtil'

export const humanSize = (size: number): string => {
    let value = (size / 1024).toFixed(1);

    if (size > (1024 << 10)) {
        value = (Number.parseInt(value) / 1024).toFixed(1);
        return `${value} M`;
    } else {
        return `${value} KB`;
    }
}

export const getFiletypeIcon = (extension: string) => {
    let filename = 'unknown';

    if (extension && extension.indexOf('.')) {
        extension = extension.substring(extension.lastIndexOf('.') + 1)
    }

    extension = (extension || '').toLowerCase().replace(/^\./, '');

    switch (true) {
        case ['mp3', 'flac', 'aac', 'm4a', 'wma'].includes(extension):
            filename = 'audio';
            break;

        case ['mp4', 'mkv', 'avi', 'flv'].includes(extension):
            filename = 'audio';
            break;

        case ['zip', 'rar', 'tar', 'tar.gz'].includes(extension):
            filename = 'zip';
            break;

        case ['doc', 'docx'].includes(extension):
            filename = 'word';
            break;

        case ['xls', 'xlsx'].includes(extension):
            filename = 'excel';
            break;

        case ['ai', 'apk', 'exe', 'ipa', 'pdf', 'ppt', 'psd'].includes(extension):
            filename = extension;
            break;
        default:
            break;
    }

    return $r(`app.media.ic_file_type_${filename}`);
}


// decodeHTML: (text = '') => {
//     return text.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
// },
// escapeHtml: (text) => {
//     return text.replace(/&/g, '&amp;')
//         .replace(/</g, '&lt;')
//         .replace(/>/g, '&gt;')
//             // /(^| ) /g 会匹配开头的空格或者前面是空格的空格，并将其替换为前一个匹配到的内容 $1 加上 &nbsp;。
//             // 这样可以确保前一个字符不是空格的空格保持不变，其他情况下的空格都会被替换为 &nbsp;
//         .replace(/(^| ) /g, "$1&nbsp;")
//         .replace(/<script/gi, "&lt;script")
//         .replace(/<iframe/gi, "&lt;iframe");
// },

export const isImage = (ext: string) => {
    return ['bmp', 'gif', 'jpeg', 'jpg', 'png'].includes(ext);
}

export const isVideo = (ext: string) => {
    return ['mp4'].includes(ext);
}

// 3 types supported: pic, video, doc
export const getMediaType = (ext = '') => {
    ext = ext.toLowerCase();

    switch (true) {
        case isImage(ext):
            return 'pic';

        case ['mp4'].includes(ext):
            return 'video';

        default:
            return 'doc';
    }
}


// md5: (file) => {
//     return new Promise((resolve, reject) => {
//         new MD5().md5(file, (err, md5) => {
//             resolve(err ? false : md5);
//         });
//     });
// },

export const weekFormat = (num: number): string => {
    let str: string
    switch (num) {
        case 1:
            str = '星期一'
            break
        case 2:
            str = '星期二'
            break
        case 3:
            str = '星期三'
            break
        case 4:
            str = '星期四'
            break
        case 5:
            str = '星期五'
            break
        case 6:
            str = '星期六'
            break
        default:
            str = '星期天'
    }
    return str
}

/**
 * 会话时间显示
 */
export const dateFormat = (date: number): string => {
    if (!date) return ''
    let today = new Date().setHours(0, 0, 0, 0);
    let that = new Date(date).setHours(0, 0, 0, 0);
    if (today === that) {
        return timeFormat(date);
    } else {
        let thatDate = new Date(date);
        return thatDate.getFullYear() + '/' + (thatDate.getMonth() + 1) + '/' + thatDate.getDate();
    }
}

/**
 * 消息会话时间显示
 */
export const timeFormat = (time: number): string => {
    if (!time) return ''
    let newtime: string;
    let nowtime = new Date()
    // if (date.constructor !== Date) {
    //     date = new Date(date.replace(/\-/g, '/')) // 解决ios日期显示NAN问题
    //  }
    let date = new Date(time)
    // 获取消息发送时间
    let Y = date.getFullYear()
    let M = date.getMonth() + 1 < 10 ? +(date.getMonth() + 1) : date.getMonth() + 1
    let D = date.getDate() < 10 ? date.getDate() : date.getDate()
    let W = date.getDay()
    let H = date.getHours() < 10 ? '0' + date.getHours() : date.getHours()
    let Min = date.getMinutes() < 10 ? '0' + date.getMinutes() : date.getMinutes()
    // 获取当前时间
    let nowY = nowtime.getFullYear()
    let nowM = nowtime.getMonth() + 1 < 10 ? (nowtime.getMonth() + 1) : nowtime.getMonth() + 1
    let nowD = nowtime.getDate() < 10 ? nowtime.getDate() : nowtime.getDate()
    let isWeek = Math.abs(time - nowtime.getTime()) < 7 * 24 * 3600 * 1000
    if (Y < nowY) {
        // 去年
        newtime = Y + '-' + M + '-' + D + ' ' + H + ':' + Min
    } else {
        if (Y === nowY && M === nowM && (nowD - D <= 7)) {
            // 昨天
            if ((nowD - D) === 1) {
                newtime = '昨天' + ' ' + H + ':' + Min
            } else if (nowD === D) {
                // 当天
                newtime = H + ':' + Min
            } else {
                // 一周内
                newtime = weekFormat(W) + ' ' + H + ':' + Min
            }
        } else {
            // 一年内
            newtime = M + '-' + D + ' ' + H + ':' + Min
        }
    }
    return newtime
}

