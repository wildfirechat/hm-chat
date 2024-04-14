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

const TAG = 'AudioRecordManager';

export default class AudioRecordManager {
    private audioRecorder?: media.AVRecorder;
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

    init() {
        this.release();
        media.createAVRecorder((err, recorder: media.AVRecorder) => {
            if (recorder !== null) {
                this.audioRecorder = recorder;
                this.audioRecorder.on('stateChange', async (state: media.AVRecorderState) => {
                    switch (state.toString()) {
                        case 'idle':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        case 'prepared':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            this.audioRecorder!.start((err) => {
                                if (!err) {
                                    Logger.info(TAG, `The AVRecorder start success`);
                                } else {
                                    Logger.info(TAG, `The AVRecorder start failed, error: ${err.message}`);
                                }
                            })
                            break;
                        case 'started':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        case 'paused':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        case 'stopped':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        case 'released':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        case 'error':
                            Logger.info(TAG, `The AVRecorder state is: ${this.audioRecorder!.state}`);
                            break;
                        default:
                            break;
                    }
                    Logger.info(TAG, `The AVRecorder state is changed to: ${this.audioRecorder!.state}`);
                });
                this.audioRecorder.on('error', (error) => {
                    Logger.info(TAG, `The AVRecorder error, err code is: ${error.code}, err message is: ${error.message}`);
                });
                Logger.info(TAG, `create AVRecorder success`);
            } else {
                Logger.info(TAG, `create AVRecorder failed, error: ${err.message}`);
            }
        });
    }

    release() {
        if (this.audioRecorder !== undefined) {
            this.audioRecorder!.release((err) => {
                if (!err) {
                    Logger.info(TAG, `release AVRecorder success`);
                } else {
                    Logger.info(TAG, `release AVRecorder failed, error: ${err.message}`);
                }
            });
        } else {
            Logger.info(TAG, `No need to release AVRecorder`);
        }
    }

    start(filePath: string) {
        if (this.audioRecorder !== undefined) {
            this.recordConfig.url = filePath;
            this.audioRecorder!.prepare(this.recordConfig, (err) => {
                if (!err) {
                    Logger.info(TAG, `AVPlayer prepare success`);
                } else {
                    Logger.info(TAG, `AVPlayer prepare failed, error: ${err.message}`);
                }
            });
        } else {
            Logger.info(TAG, `No AVRecorder found`);
        }
    }

    pause() {
        if (this.audioRecorder!.state === 'started') {
            this.audioRecorder!.pause((err) => {
                if (!err) {
                    Logger.info(TAG, `AVRecorder pause success`);
                } else {
                    Logger.info(TAG, `AVRecorder pause failed, error: ${err.message}`);
                }
            });
        } else {
            Logger.info(TAG, `AVRecorder pause failed, current state is wrong, now is: ${this.audioRecorder!.state}`);
        }
    }

    resume() {
        if (this.audioRecorder!.state === 'paused') {
            this.audioRecorder!.resume((err) => {
                if (!err) {
                    Logger.info(TAG, `AVRecorder resume success`);
                } else {
                    Logger.info(TAG, `AVRecorder resume failed, error: ${err.message}`);
                }
            });
        } else {
            Logger.info(TAG, `AVRecorder resume failed, current state is wrong, now is: ${this.audioRecorder!.state}`);
        }
    }

    finish() {
        if (this.audioRecorder!.state === 'started' || this.audioRecorder!.state === 'paused') {
            this.audioRecorder!.stop((err) => {
                if (!err) {
                    Logger.info(TAG, `AVRecorder stop success`);
                } else {
                    Logger.info(TAG, `AVRecorder stop failed, error: ${err.message}`);
                }
            });
        } else {
            Logger.info(TAG, `AVRecorder stop failed, current state is wrong, now is: ${this.audioRecorder!.state}`);
        }
    }
}