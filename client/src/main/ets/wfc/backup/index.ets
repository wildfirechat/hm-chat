//
// index.ets
// hm-chat client backup module
//
// 备份恢复模块导出
// 提供与iOS版本完全兼容的消息备份与恢复功能
//

// 枚举类型
export {
  BackupMode,
  BackupError
} from './backupTypes';

// 数据结构接口
export type {
  EncryptionInfo,
  TimeRange,
  BackupStatistics,
  BackupMetadata,
  ConversationMetadata,
  BackupResult,
  RestoreResult,
  BackupInfo,
  BackupConversationInfo,
  ConversationSettings,
  LocalMediaInfo,
  MessagePayloadBackupData,
  MessageBackupData,
  ConversationBackupData,
  EncryptedData
} from './backupTypes';

// 类型别名
export type {
  ProgressCallback
} from './backupTypes';

// 加密工具
export { BackupCrypto } from './backupCrypto';

// 备份管理器
export { MessageBackupManager } from './messageBackupManager';
