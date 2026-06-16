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
import audio from '@ohos.multimedia.audio';
import sensor from '@ohos.sensor';
import runningLock from '@ohos.runningLock';
import Logger from '../../../common/utils/Logger';
import common from '@ohos.app.ability.common';

const TAG = 'AudioPlayManager';

// AudioRendererInfo for voice-message playback. STREAM_USAGE_VOICE_COMMUNICATION makes the system
// treat this stream like an in-call stream, which is what enables speaker/earpiece routing.
const VOICE_RENDERER_INFO: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION,
    rendererFlags: 0
};

export default class AudioPlayManager {
    public audioPlayer?: media.AVPlayer;
    private playCompleteCallback?: (err?: Error) => void
    private audioRoutingManager?: audio.AudioRoutingManager
    private proximitySensing: boolean = false
    // PROXIMITY_SCREEN_CONTROL lock: while held, the system turns the screen off/on based on the
    // proximity sensor (true screen-off + anti-mistouch), exactly like during a phone call.
    private screenLock?: runningLock.RunningLock
    // Current playback source, kept so we can restart from the beginning on a speaker/earpiece switch.
    private currentUrl?: string
    // Last proximity state, so we only act on actual near<->far transitions (not the initial report).
    private lastNear: boolean = false
    // Desired output for voice-message playback: true = speaker, false = earpiece.
    private desiredSpeakerOn: boolean = true

    init(context: common.Context) {
        this.release();

        try {
            this.audioRoutingManager = audio.getAudioManager().getRoutingManager();
        } catch (e) {
            Logger.error(TAG, `init AudioRoutingManager failed: ${e.message}`);
        }

        // Create the proximity screen-control lock once; held only while a voice message plays.
        try {
            if (runningLock.isSupported(runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL)) {
                runningLock.create('voice_msg_proximity', runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL)
                    .then(lock => this.screenLock = lock)
                    .catch((e: Error) => Logger.error(TAG, `create proximity screen lock failed: ${e.message}`));
            }
        } catch (e) {
            Logger.error(TAG, `runningLock init failed: ${e.message}`);
        }

        media.createAVPlayer((err, player: media.AVPlayer) => {
            if (player === null) {
                Logger.error(TAG, `createAVPlayer failed: ${err.message}`);
                return;
            }
            this.audioPlayer = player;
            this.audioPlayer.on('stateChange', (state: media.AVPlayerState) => {
                switch (state.toString()) {
                    case 'initialized':
                        // audioRendererInfo can only be set in the 'initialized' state, before prepare().
                        this.applyRendererInfo();
                        this.audioPlayer!.prepare((e) => {
                            if (e) {
                                this.playCompleteCallback?.(e)
                                Logger.error(TAG, `AVPlayer prepare failed: ${e.message}`);
                            }
                        });
                        break;
                    case 'prepared':
                        this.audioPlayer!.play((e) => {
                            if (e) {
                                this.playCompleteCallback?.(e)
                                Logger.error(TAG, `AVPlayer play failed: ${e.message}`);
                            }
                        });
                        break;
                    case 'playing':
                        // Each freshly started communication stream (including one created by a
                        // restart on a speaker/earpiece switch) defaults to the earpiece, so the
                        // desired output must be re-asserted once the new stream is actually playing.
                        if (this.proximitySensing) {
                            this.applyAudioRoute();
                        }
                        break;
                    case 'completed':
                        this.playCompleteCallback?.()
                        break;
                    default:
                        break;
                }
            });
            this.audioPlayer.on('error', (error) => {
                this.playCompleteCallback?.(error)
                Logger.error(TAG, `AVPlayer error: ${error.code} ${error.message}`);
            });
        });
    }

    release() {
        this.stopProximitySensing();
        if (this.audioPlayer !== undefined) {
            this.audioPlayer.release();
            this.audioPlayer = undefined;
        }
    }

    play(filePath: string, isNewAudio: boolean = true, callback?: (err?: Error) => void) {
        this.playCompleteCallback = callback
        this.currentUrl = filePath
        if (!isNewAudio) {
            if (this.audioPlayer!.state === 'idle') {
                this.audioPlayer!.url = filePath;
            } else {
                this.audioPlayer!.play((err) => {
                    if (err) {
                        Logger.error(TAG, `AVPlayer play failed: ${err.message}`);
                    }
                    callback?.(err)
                });
            }
        } else {
            this.audioPlayer!.reset((err) => {
                if (err) {
                    Logger.error(TAG, `AVPlayer reset failed: ${err.message}`);
                    return;
                }
                // Setting url drives idle -> initialized; audioRendererInfo is (re)applied in the
                // 'initialized' stateChange handler, which is the only valid state for it.
                this.audioPlayer!.url = filePath;
            });
        }
    }

    pause() {
        if (this.audioPlayer!.state === 'playing') {
            this.audioPlayer!.pause((err) => {
                if (err) {
                    Logger.error(TAG, `AVPlayer pause failed: ${err.message}`);
                }
            });
        }
    }

    duration(): number {
        return this.audioPlayer!.duration;
    }

    state(): media.AVPlayerState {
        return this.audioPlayer!.state;
    }

    // Route audio output: true = speaker (loudspeaker), false = earpiece (receiver).
    setSpeakerOn(enable: boolean) {
        this.desiredSpeakerOn = enable;
        this.applyAudioRoute();
    }

    private applyAudioRoute() {
        if (!this.audioRoutingManager) {
            return;
        }
        this.audioRoutingManager.setCommunicationDevice(audio.CommunicationDeviceType.SPEAKER, this.desiredSpeakerOn, (err) => {
            if (err) {
                Logger.error(TAG, `setCommunicationDevice speaker=${this.desiredSpeakerOn} failed: ${err.message}`);
            }
        });
    }

    // Begin proximity handling for a playback: hold the screen-control lock and watch the sensor
    // to route audio (speaker <-> earpiece) and restart playback on each transition.
    startProximitySensing() {
        if (this.proximitySensing) {
            return;
        }
        this.proximitySensing = true;
        this.lastNear = false;
        this.setSpeakerOn(true);

        if (this.screenLock !== undefined) {
            try {
                this.screenLock.hold(-1);
            } catch (e) {
                Logger.error(TAG, `hold screen lock failed: ${e.message}`);
            }
        }

        try {
            sensor.on(sensor.SensorId.PROXIMITY, (data: sensor.ProximityResponse) => {
                // distance 0 = near (covered), >0 = far.
                const near = data.distance === 0;
                if (near === this.lastNear) {
                    return; // ignore repeats / the initial baseline report
                }
                this.lastNear = near;
                this.setSpeakerOn(!near);
                // Restart the current voice message from the beginning on the device switch.
                this.restartCurrentPlayback();
            });
        } catch (e) {
            Logger.error(TAG, `sensor.on PROXIMITY failed: ${e.message}`);
        }
    }

    // End proximity handling: unsubscribe sensor, release screen lock, restore speaker.
    stopProximitySensing() {
        if (!this.proximitySensing) {
            return;
        }
        this.proximitySensing = false;
        try {
            sensor.off(sensor.SensorId.PROXIMITY);
        } catch (e) {
            Logger.error(TAG, `sensor.off PROXIMITY failed: ${e.message}`);
        }
        if (this.screenLock !== undefined) {
            try {
                this.screenLock.unhold();
            } catch (e) {
                Logger.error(TAG, `unhold screen lock failed: ${e.message}`);
            }
        }
        this.setSpeakerOn(true);
    }

    private applyRendererInfo() {
        // Only voice-message playback (proximity routing active) needs the communication stream that
        // enables earpiece output. Other callers keep the default media routing (speaker).
        if (!this.proximitySensing) {
            return;
        }
        try {
            this.audioPlayer!.audioRendererInfo = VOICE_RENDERER_INFO;
        } catch (e) {
            Logger.error(TAG, `set audioRendererInfo failed: ${e.message}`);
        }
    }

    // Replay the current voice message from the start, keeping the same completion callback.
    // Used when the output device switches between speaker and earpiece mid-playback.
    private restartCurrentPlayback() {
        if (!this.audioPlayer || !this.currentUrl) {
            return;
        }
        const state = this.audioPlayer.state;
        if (state !== 'playing' && state !== 'paused' && state !== 'prepared' && state !== 'completed') {
            return; // nothing active to restart
        }
        this.play(this.currentUrl, true, this.playCompleteCallback);
    }
}
