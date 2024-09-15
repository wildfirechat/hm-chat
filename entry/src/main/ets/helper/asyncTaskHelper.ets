import { pinyin4js } from '@ohos/pinyin4js';
import { UIUserInfo } from '../common/Types';
import wfc from '../wfc/client/wfc';
import UserInfo from '../wfc/model/userInfo';
import taskpool from '@ohos.taskpool';

// 文件功能说明
// 本文件包含一些异步辅助方法，耗时方法，都应当采用类似的方法处理，防止 UI 卡顿

// exported functions
export function loadAndGroupContactUserInfos(includeFavUser: boolean = false): Promise<UIUserInfo[]> {
    return new Promise((resolve, reject) => {
        taskpool.execute(loadContactAndGroupTask, includeFavUser).then((ret: Object) => {
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

export function loadContactUserInfos(): Promise<UserInfo[]> {
    return new Promise((resolve, reject) => {
        taskpool.execute(loadContactUserInfosTask).then((ret: Object) => {
            let userInfos = ret as UserInfo[]
            resolve(userInfos)
        })
    })
}

// exported functions end

// concurrent task start

@Concurrent
function loadContactUserInfosTask(): UserInfo[] {
    let friendUserIds = wfc.getMyFriendList()
    let userInfos = wfc.getUserInfos(friendUserIds, '')

    return userInfos;
}

@Concurrent
function loadContactAndGroupTask(includeFavUser: boolean): UIUserInfo[] {
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
            return a.category.localeCompare(b.category);
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

    let favUserInfos = wfc.getUserInfos(wfc.getFavUsers())
    let faUIUserInfos: UIUserInfo[] = favUserInfos.map(u => {
        return {
            showCategory: false,
            category: '☆',
            userInfo: u,
        } as UIUserInfo
    })

    groupedUsers.splice(0, 0, ...faUIUserInfos)

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
            return a.category.localeCompare(b.category)
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

// concurrent task end