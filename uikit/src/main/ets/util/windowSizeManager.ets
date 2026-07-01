/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { window } from '@kit.ArkUI'

// 宽度断点（vp）。参考 HarmonyOS 一多断点：sm[0,600) md[600,840) lg[840,+)
export type WidthBreakpoint = 'sm' | 'md' | 'lg'

// AppStorage key：当前窗口宽度（vp）与宽度断点，供各页做宽屏/平板自适应
export const STORAGE_KEY_WINDOW_WIDTH_VP = 'windowWidthVp'
export const STORAGE_KEY_WIDTH_BREAKPOINT = 'widthBreakpoint'

function computeBreakpoint(widthVp: number): WidthBreakpoint {
    if (widthVp >= 840) {
        return 'lg'
    }
    if (widthVp >= 600) {
        return 'md'
    }
    return 'sm'
}

/**
 * 跟踪主窗口尺寸并把「宽度(vp) / 宽度断点」实时写入 AppStorage，供页面响应宽屏（Pad）布局。
 * 在 EntryAbility.onWindowStageCreate 拿到主窗口后调用 init(mainWin)。
 */
class WindowSizeManager {
    private size: window.Size = { width: 0, height: 0 };
    private mainWindow?: window.Window;

    private onSizeChange = (size: window.Size) => {
        this.update(size)
    }

    init(win: window.Window): void {
        this.mainWindow = win
        try {
            const rect: window.Rect = win.getWindowProperties().windowRect;
            this.update({ width: rect.width, height: rect.height })
        } catch (e) {
            console.error('[windowSizeManager] read windowRect failed', JSON.stringify(e))
        }
        win.on('windowSizeChange', this.onSizeChange)
    }

    private update(sizePx: window.Size): void {
        const widthVp = px2vp(sizePx.width)
        const heightVp = px2vp(sizePx.height)
        this.size.width = widthVp
        this.size.height = heightVp
        AppStorage.setOrCreate(STORAGE_KEY_WINDOW_WIDTH_VP, widthVp)
        AppStorage.setOrCreate<WidthBreakpoint>(STORAGE_KEY_WIDTH_BREAKPOINT, computeBreakpoint(widthVp))
    }

    destroy(): void {
        if (this.mainWindow) {
            try {
                this.mainWindow.off('windowSizeChange', this.onSizeChange)
            } catch (e) {
                console.error('[windowSizeManager] off windowSizeChange failed', JSON.stringify(e))
            }
            this.mainWindow = undefined
        }
    }

    get(): window.Size {
        return this.size;
    }
}

export const windowSizeManager: WindowSizeManager = new WindowSizeManager();
