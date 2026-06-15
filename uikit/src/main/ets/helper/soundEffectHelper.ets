import common from '@ohos.app.ability.common';
import media from '@ohos.multimedia.media';

export async function playRawSound(context: common.Context, fileName: string): Promise<void> {
    try {
        const player = await media.createAVPlayer()
        player.on('stateChange', async (state: media.AVPlayerState) => {
            if (state === 'initialized') {
                await player.prepare()
            } else if (state === 'prepared') {
                await player.play()
            } else if (state === 'completed') {
                await player.release()
            }
        })
        const rawFd = await context.resourceManager.getRawFd(fileName)
        player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    } catch (e) {
        console.error('playRawSound error', JSON.stringify(e))
    }
}
