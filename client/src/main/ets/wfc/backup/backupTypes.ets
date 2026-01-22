//
// backupTypes.ets
// hm-chat client
//
// 备份恢复功能类型定义
// 与iOS版本保持完全一致
//

import Conversation from '../model/conversation';
import ConversationInfo from '../model/conversationInfo';

/**
 * 备份模式枚举
 */
export enum BackupMode {
  MessageOnly = 0,          // 仅备份消息
  MessageWithMedia = 1      // 备份消息和媒体文件
}

/**
 * 备份错误码枚举
 */
export enum BackupError {
  NoError = 0,
  FileNotFound = 1001,
  InvalidFormat = 1002,
  IOError = 1003,
  OutOfSpace = 1004,
  Cancelled = 1005,
  EncryptionFailed = 3001,
  DecryptionFailed = 3002,
  WrongPassword = 3003,
  InvalidPassword = 3004,
  NotEncrypted = 3006,
  RestoreFailed = 4001
}

/**
 * 加密信息结构
 */
export interface EncryptionInfo {
  enabled: boolean;                 // 是否启用加密
  algorithm?: string;               // 加密算法
  keyDerivation?: string;           // 密钥派生算法
  passwordHint?: string;            // 密码提示
}

/**
 * 时间范围结构
 */
export interface TimeRange {
  firstMessageTime: number;         // 最早消息时间戳（毫秒）
  lastMessageTime: number;          // 最晚消息时间戳（毫秒）
}

/**
 * 统计信息结构
 */
export interface BackupStatistics {
  totalConversations: number;       // 会话总数
  totalMessages: number;            // 消息总数
  mediaFileCount: number;           // 媒体文件数量
  mediaTotalSize: number;           // 媒体文件总大小（字节）
  timeRange: TimeRange;             // 时间范围
}

/**
 * 备份元数据结构
 */
export interface BackupMetadata {
  version: string;                    // 版本号
  format: string;                     // 格式类型
  backupTime: string;                 // 备份时间（ISO 8601格式）
  userId: string;                     // 用户ID
  appType: string;                    // 应用类型
  backupMode: string;                 // 备份模式
  deviceName?: string;                // 设备名称（可选）
  encryption: EncryptionInfo;         // 加密信息
  statistics: BackupStatistics;       // 统计信息
  conversations: ConversationMetadata[]; // 会话列表
}

/**
 * 会话元数据结构
 */
export interface ConversationMetadata {
  conversationId: string;             // 会话ID
  type: number;                       // 会话类型
  target: string;                     // 目标ID
  line: number;                       // 线路号
  messageCount: number;               // 消息数量
  mediaCount: number;                 // 媒体文件数量
  directory: string;                  // 目录名
  mediaFiles?: string[];              // 媒体文件列表（文件名，相对于media目录）
}

/**
 * 备份结果
 */
export interface BackupResult {
  success: boolean;                   // 是否成功
  backupPath: string;                 // 备份路径
  messageCount: number;               // 消息数量
  mediaCount: number;                 // 媒体文件数量
  mediaSize: number;                  // 媒体文件总大小
  error?: BackupError;                // 错误码（失败时）
}

/**
 * 恢复结果
 */
export interface RestoreResult {
  success: boolean;                   // 是否成功
  messageCount: number;               // 恢复的消息数量
  mediaCount: number;                 // 恢复的媒体文件数量
  error?: BackupError;                // 错误码（失败时）
}

/**
 * 会话备份结果
 */
export interface BackupConversationResult {
  messageCount: number;               // 消息数量
  mediaCount: number;                 // 媒体文件数量
  mediaSize: number;                  // 媒体文件总大小
  firstMessageTime: number;           // 最早消息时间
  lastMessageTime: number;            // 最晚消息时间
  mediaFiles: string[];               // 媒体文件列表
  error?: BackupError;                // 错误码
}

/**
 * 会话恢复结果
 */
export interface RestoreConversationResult {
  messageCount: number;               // 恢复的消息数量
  mediaCount: number;                 // 恢复的媒体文件数量
  error?: BackupError;                // 错误码
}

/**
 * 进度回调函数类型
 */
export type ProgressCallback = (progress: number, current: string) => void;

/**
 * 备份信息摘要
 */
export interface BackupInfo {
  format: string;                     // 格式
  isEncrypted: boolean;               // 是否加密
  version: string;                    // 版本
  backupTime: string;                 // 备份时间
  userId: string;                     // 用户ID
  deviceName: string;                 // 设备名称
  totalConversations: number;         // 会话总数
  totalMessages: number;              // 消息总数
  mediaFileCount: number;             // 媒体文件数量
  mediaTotalSize: number;             // 媒体文件总大小
  hasPasswordHint: boolean;           // 是否有密码提示
}

/**
 * 会话信息结构（用于备份数据）
 */
export interface BackupConversationInfo {
  type: number;
  target: string;
  line: number;
}

/**
 * 会话设置结构
 */
export interface ConversationSettings {
  isTop: number;
  isSilent: boolean;
  draft: string;
}

/**
 * 本地媒体信息结构
 */
export interface LocalMediaInfo {
  relativePath: string;               // 相对路径
  fileId: string;                     // 文件ID
  fileSize: number;                   // 文件大小
  md5: string;                        // MD5哈希
}

/**
 * 消息载荷备份数据结构
 */
export interface MessagePayloadBackupData {
  contentType: number;                // 内容类型
  searchableContent?: string;         // 可搜索内容
  pushContent?: string;               // 推送内容
  pushData?: string;                  // 推送数据
  content?: string;                   // 内容
  binaryContent?: string;             // 二进制内容（Base64编码）
  localContent?: string;              // 本地内容
  mentionedType?: number;             // @提醒类型
  mentionedTargets?: string[];        // @提醒目标列表
  extra?: string;                     // 扩展数据
  notLoaded?: number;                 // 是否未加载
  mediaType?: number;                 // 媒体类型
  remoteMediaUrl?: string;            // 远程媒体URL
  localMediaPath?: string;            // 本地媒体路径
  localMediaInfo?: LocalMediaInfo;    // 本地媒体信息
}

/**
 * 消息备份数据结构
 */
export interface MessageBackupData {
  messageUid: number;                 // 消息唯一ID
  fromUser: string;                   // 发送者
  toUsers?: string[];                 // 接收者列表
  direction: number;                  // 方向
  status: number;                     // 状态
  timestamp: number;                  // 时间戳
  localExtra: string;                 // 本地扩展数据
  payload: MessagePayloadBackupData;  // 消息载荷
  mediaFileSize?: number;             // 媒体文件大小（可选）
}

/**
 * 会话备份数据结构（messages.json内容）
 */
export interface ConversationBackupData {
  version: string;                    // 版本
  conversation: BackupConversationInfo; // 会话信息
  settings: ConversationSettings;     // 会话设置
  messages: MessageBackupData[];      // 消息列表
}

/**
 * 加密数据结构
 */
export interface EncryptedData {
  salt: string;                       // 盐值（Base64）
  iv: string;                         // 初始化向量（Base64）
  data: string;                       // 加密数据（Base64）
  iterations: number;                 // PBKDF2迭代次数
}
