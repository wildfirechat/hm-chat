import { WantAgent, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';

export function startContinuousTask(context: Context) {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
        // 点击通知后，将要执行的动作列表
        // 添加需要被拉起应用的bundleName和abilityName
        wants: [
            {
                bundleName: 'cn.wildfirechat.av',
                abilityName: 'EntryAbility',
            }
        ],
        // 指定点击通知栏消息后的动作是拉起ability
        actionType: wantAgent.OperationType.START_ABILITY,
        // 使用者自定义的一个私有值
        requestCode: 0,
        // 点击通知后，动作执行属性
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        backgroundTaskManager.startBackgroundRunning(context,
            backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, wantAgentObj).then(() => {
            console.info(`Succeeded in operationing startBackgroundRunning.`);
        }).catch((err: BusinessError) => {
            console.error(`Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
        });
    });
}

export function stopContinuousTask(context: Context) {
    backgroundTaskManager.stopBackgroundRunning(context).then(() => {
        console.info(`Succeeded in operationing stopBackgroundRunning.`);
    }).catch((err: BusinessError) => {
        console.error(`Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
    });
}

