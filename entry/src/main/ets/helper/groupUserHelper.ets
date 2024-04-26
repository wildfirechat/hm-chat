import { pinyin4js } from '@ohos/pinyin4js';
import { UIUserInfo } from '../common/Types';
import wfc from '../wfc/client/wfc';
import UserInfo from '../wfc/model/userInfo';
import taskpool from '@ohos.taskpool';


export function loadAndGroupContactUserInfos(): Promise<UIUserInfo[]> {
    return new Promise((resolve, reject) => {
        taskpool.execute(loadContactAndGroupTask).then((ret: Object) => {
            let uiUserInfos = ret as UIUserInfo[]
            resolve(uiUserInfos)
        })
    })
}

export function groupUserInfos(userIds: string[], groupId = ''): Promise<UIUserInfo[]> {
    return new Promise((resolve, reject) => {
        try {
            taskpool.execute(groupUserInfoTask, userIds, groupId).then((ret: Object) => {
                let uiUserInfos = ret as UIUserInfo[]
                resolve(uiUserInfos)
            }).catch((e: Error) => {
            })
        } catch (e) {
        }
    })
}


@Concurrent
function loadContactAndGroupTask(): UIUserInfo[] {
    let friendUserIds = wfc.getMyFriendList()
    let userInfos = wfc.getUserInfos(friendUserIds, '')
    let groupedUsers: UIUserInfo[] = []
    let lastCategory: string = '';

    userInfos.forEach(user => {
        let category: string = pinyin4js.getShortPinyin(user.displayName.substring(0, 1)).toUpperCase() as string
        if (category < 'A' || category > 'Z') {
            category = '#'
        }
        if (!lastCategory || lastCategory !== category) {
            groupedUsers.push({
                showCategory: false,
                category: category,
                userInfo: user
            });
        } else {
            groupedUsers.push({
                showCategory: false,
                category: category,
                userInfo: user
            });
        }
        lastCategory = category
    })

    groupedUsers.sort((a, b) => {
        if (a.category !== '#' && b.category !== '#') {
            return a.category > b.category ? 1 : 0
        } else {
            if (a.category === '#' && b.category !== '#') {
                return 1
            } else if (a.category !== '#' && b.category === '#') {
                return -1
            } else {
                return 0
            }
        }
    })

    lastCategory = ''
    groupedUsers.forEach(gu => {
        if (!lastCategory || lastCategory !== gu.category) {
            gu.showCategory = true
        } else {
            gu.showCategory = false
        }
        lastCategory = gu.category

    })

    return groupedUsers
}


@Concurrent
function groupUserInfoTask(userIds: string[], groupId = ''): UIUserInfo[] {
    let groupedUsers: UIUserInfo[] = []
    let lastCategory: string = '';

    let userInfos = wfc.getUserInfos(userIds, groupId)
    userInfos.forEach(user => {
        let category: string = pinyin4js.getShortPinyin(user.displayName.substring(0, 1)).toUpperCase() as string
        if (category < 'A' || category > 'Z') {
            category = '#'
        }
        if (!lastCategory || lastCategory !== category) {
            groupedUsers.push({
                showCategory: false,
                category: category,
                userInfo: user
            });
        } else {
            groupedUsers.push({
                showCategory: false,
                category: category,
                userInfo: user
            });
        }
        lastCategory = category
    })

    groupedUsers.sort((a, b) => {
        if (a.category !== '#' && b.category !== '#') {
            return a.category > b.category ? 1 : 0
        } else {
            if (a.category === '#' && b.category !== '#') {
                return 1
            } else if (a.category !== '#' && b.category === '#') {
                return -1
            } else {
                return 0
            }
        }
    })

    lastCategory = ''
    groupedUsers.forEach(gu => {
        if (!lastCategory || lastCategory !== gu.category) {
            gu.showCategory = true
        } else {
            gu.showCategory = false
        }
        lastCategory = gu.category

    })

    return groupedUsers
}