/*
 * Copyright (c) 2020 WildFireChat. All rights reserved.
 */

import http from '@ohos.net.http';
import wfc from '@wfc/client'
import Config from '@wfc/client/src/main/ets/config';
import Poll from '../pages/poll/model/poll';
import PollOption from '../pages/poll/model/pollOption';
import PollVoterDetail from '../pages/poll/model/pollVoterDetail';
import { parseHostAndPort } from './Util';

/**
 * 投票回调接口
 */
export interface OnPollCallback<T> {
    /**
     * 成功回调
     * @param result 结果数据
     */
    onSuccess(result: T): void;

    /**
     * 失败回调
     * @param errorCode 错误码
     * @param message 错误信息
     */
    onError(errorCode: number, message: string): void;
}

/**
 * 投票服务实现类
 */
export class PollService {
    baseUrl = Config.POLL_SERVER_ADDRESS;

    /**
     * 创建投票
     */
    createPoll(
        groupId: string,
        title: string,
        description: string,
        options: string[],
        visibility: number,
        type: number,
        maxSelect: number,
        anonymous: number,
        endTime: number,
        showResult: number,
        callback: OnPollCallback<Poll>
    ): void {
        let params = {
            'groupId': groupId,
            'title': title,
            'options': options,
            'visibility': visibility,
            'type': type,
            'maxSelect': maxSelect,
            'anonymous': anonymous,
            'endTime': endTime,
            'showResult': showResult
        } as Record<string, Object>;

        if (description) {
            params['description'] = description;
        }

        this.postWithAuth<Record<string, Object>>('/api/polls', params)
            .then((result: Record<string, Object>) => {
                let poll = Poll.fromJson(result);
                if (poll) {
                    callback.onSuccess(poll);
                } else {
                    callback.onError(-1, '解析投票数据失败');
                }
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '创建投票失败');
            });
    }

    /**
     * 获取投票详情
     */
    getPoll(pollId: number, callback: OnPollCallback<Poll>): void {
        this.postWithAuth<Record<string, Object>>(`/api/polls/${pollId}`, {})
            .then((result: Record<string, Object>) => {
                let poll = Poll.fromJson(result);
                if (poll) {
                    callback.onSuccess(poll);
                } else {
                    callback.onError(-1, '解析投票数据失败');
                }
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '获取投票失败');
            });
    }

    /**
     * 参与投票
     */
    vote(pollId: number, optionIds: number[], callback: OnPollCallback<void>): void {
        let params = {} as Record<string, Object>;
        params['optionIds'] = optionIds;
        this.postWithAuth<void>(`/api/polls/${pollId}/vote`, params)
            .then(() => {
                callback.onSuccess(undefined as void);
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '投票失败');
            });
    }

    /**
     * 结束投票（仅创建者）
     */
    closePoll(pollId: number, callback: OnPollCallback<void>): void {
        this.postWithAuth<void>(`/api/polls/${pollId}/close`, {})
            .then(() => {
                callback.onSuccess(undefined as void);
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '结束投票失败');
            });
    }

    /**
     * 删除投票（仅创建者）
     */
    deletePoll(pollId: number, callback: OnPollCallback<void>): void {
        this.postWithAuth<void>(`/api/polls/${pollId}/delete`, {})
            .then(() => {
                callback.onSuccess(undefined as void);
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '删除投票失败');
            });
    }

    /**
     * 导出投票明细（仅实名投票创建者）
     */
    exportPollDetails(pollId: number, callback: OnPollCallback<PollVoterDetail[]>): void {
        this.postWithAuth<Record<string, Object>[]>(`/api/polls/${pollId}/export`, {})
            .then((result: Record<string, Object>[]) => {
                if (!Array.isArray(result)) {
                    callback.onSuccess([]);
                    return;
                }
                let details = result.map(item => PollVoterDetail.fromJson(item)).filter(item => item !== null) as PollVoterDetail[];
                callback.onSuccess(details);
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '导出投票明细失败');
            });
    }

    /**
     * 获取我的投票列表
     */
    getMyPolls(groupId: string, callback: OnPollCallback<Poll[]>): void {
        let params = {} as Record<string, Object>;
        if (groupId) {
            params['groupId'] = groupId;
        }
        this.postWithAuth<Record<string, Object>[]>('/api/polls/my', params)
            .then((result: Record<string, Object>[]) => {
                if (!Array.isArray(result)) {
                    callback.onSuccess([]);
                    return;
                }
                let polls = result.map(item => Poll.fromJson(item)).filter(item => item !== null) as Poll[];
                callback.onSuccess(polls);
            })
            .catch((error: Error) => {
                callback.onError(-1, error.message || '获取投票列表失败');
            });
    }

    private postWithAuth<T>(path: string, data?: Record<string, Object>): Promise<T> {
        if (!this.baseUrl) {
            return Promise.reject(new Error('投票服务未配置'));
        }

        return new Promise((resolve, reject) => {
            const pair = parseHostAndPort(this.baseUrl);
            wfc.getAuthCode('poll', 2, pair.host, (authCode: string) => {
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

let pollService = new PollService();

export default pollService;
