/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import media from '@ohos.multimedia.media';
import Logger from '../../../common/utils/Logger';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs'

const TAG = 'AudioRecordManager';

export default class AudioRecordManager {
    private avRecorder?: media.AVRecorder;
    private outputFileFd: number = 0
    private recordProfile: media.AVRecorderProfile = {
        audioBitrate: 48000,
        audioChannels: 2,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        audioSampleRate: 48000,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A
    };
    private recordConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: this.recordProfile,
        url: '',
        rotation: 0,
        // location: { latitude: Const.LATITUDE, longitude: Const.LONGITUDE }
    };

    // 注册audioRecorder回调函数
    setAudioRecorderCallback() {
        if (this.avRecorder != undefined) {
            // 状态机变化回调函数
            this.avRecorder.on('stateChange', (state: media.AVRecorderState, reason: media.StateChangeReason) => {
                console.log(TAG, `AudioRecorder current state is ${state}`);
                            })
            // 错误上报回调函数
            this.avRecorder.on('error', (err: BusinessError) => {
                console.error(TAG, `AudioRecorder failed, code is ${err.code}, message is ${err.message}`);
            })
                    }
    }

    async start(fd: number) {
        this.outputFileFd = fd
        if (this.avRecorder != undefined) {
            await this.avRecorder.reset();
                }
        // 1.创建录制实例
        this.avRecorder = await media.createAVRecorder();
        this.setAudioRecorderCallback();
        // 2.获取录制文件fd赋予avConfig里的url；参考FilePicker文档
        this.recordConfig.url = `fd://${fd}`;

        // 3.配置录制参数完成准备工作
        await this.avRecorder!.prepare(this.recordConfig);
        // 4.开始录制
        await this.avRecorder!.start();
    }

    async finish() {
        if (!this.avRecorder) {
            return
                }
        if (this.avRecorder!.state === 'started' || this.avRecorder!.state === 'paused') {
            await this.avRecorder!.stop();
        } else {
            //Logger.info(TAG, `AVRecorder stop failed, current state is wrong, now is: ${this.avRecorder!.state}`);
            // 2.重置
            await this.avRecorder.reset();
            // 3.释放录制实例
            await this.avRecorder.release();
            this.avRecorder = undefined;
            // 4.关闭录制文件fd
            await fs.close(this.outputFileFd)
        }
    }
}
