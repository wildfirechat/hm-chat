import http from '@ohos.net.http';
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config';
import Collection from '@wfc/client/src/main/ets/wfc/model/collection';
import { JSONObject } from '@wfc/client/src/main/ets/wfc/type/types';
import { parseHostAndPort } from './Util';

export class CollectionService {
    baseUrl = Config.COLLECTION_SERVER_ADDRESS;

    createCollection(groupId: string, title: string, desc: string, template: string,
        expireType: number, expireAt: number, maxParticipants: number): Promise<Collection> {
        let params = {
            'groupId': groupId,
            'title': title,
            'expireType': expireType,
            'maxParticipants': maxParticipants
        } as Record<string, Object>

        if (expireType === 1) {
            params['expireAt'] = expireAt;
        }
        if (desc) {
            params['description'] = desc;
        }
        if (template) {
            params['template'] = template;
        }

        return this.postWithAuth<JSONObject>('/api/collections', params)
            .then((result: JSONObject) => {
                return Collection.fromJson(result);
            });
    }

    getCollection(collectionId: number, groupId: string): Promise<Collection> {
        let params = {} as Record<string, Object>
        if (groupId) {
            params['groupId'] = groupId;
        }
        return this.postWithAuth<JSONObject>(`/api/collections/${collectionId}/detail`, params)
            .then((result: JSONObject) => {
                return Collection.fromJson(result);
            });
    }

    joinCollection(collectionId: number, groupId: string, content: string): Promise<void> {
        let params = {
            'content': content
        } as Record<string, Object>
        if (groupId) {
            params['groupId'] = groupId;
        }
        return this.postWithAuth<void>(`/api/collections/${collectionId}/join`, params) as Promise<void>
    }

    deleteCollectionEntry(collectionId: number, groupId: string): Promise<void> {
        let params = {} as Record<string, Object>
        if (groupId) {
            params['groupId'] = groupId;
        }
        return this.postWithAuth<void>(`/api/collections/${collectionId}/delete`, params) as Promise<void>
    }

    closeCollection(collectionId: number, groupId: string): Promise<void> {
        let params = {} as Record<string, Object>
        if (groupId) {
            params['groupId'] = groupId;
        }
        return this.postWithAuth<void>(`/api/collections/${collectionId}/close`, params) as Promise<void>
    }

    private postWithAuth<T>(path: string, data?: Record<string, Object>): Promise<T> {
        if (!this.baseUrl) {
            return Promise.reject(new Error('接龙服务未配置'));
        }

        return new Promise((resolve, reject) => {
            const pair = parseHostAndPort(this.baseUrl);
            wfc.getAuthCode('collection', 2, pair.host, (authCode: string) => {
                const httpRequest = http.createHttp();
                httpRequest.request(
                    this.baseUrl + path,
                    {
                        method: http.RequestMethod.POST,
                        header: {
                            'Content-Type': 'application/json',
                            'authCode': authCode
                        },
                        extraData: data,
                        expectDataType: http.HttpDataType.OBJECT,
                        usingCache: true,
                        priority: 1,
                        connectTimeout: 60000,
                        readTimeout: 60000,
                        usingProtocol: http.HttpProtocol.HTTP1_1,
                    }, (err, data) => {
                    httpRequest.destroy();
                    if (!err && data.responseCode == 200) {
                        const result = data.result as Record<string, Object>
                        if (result.code === 0) {
                            resolve(result.data as T);
                        } else {
                            reject(new Error(result.message as string));
                        }
                    } else {
                        reject(new Error(err ? err.message : `HTTP Error ${data.responseCode}`));
                    }
                }
                );
            }, (err: number) => {
                reject(new Error('获取认证码失败: ' + err));
            });
        });
    }
}

let collectionService = new CollectionService();

export default collectionService;
