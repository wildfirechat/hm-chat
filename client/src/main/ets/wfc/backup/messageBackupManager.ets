//
// messageBackupManager.ets
// hm-chat client
//
// 消息备份管理器
// 负责聊天消息的备份和恢复功能
// 与iOS版本保持完全一致的逻辑和数据格式
//

import fs from '@ohos.file.fs';
import { util } from '@kit.ArkTS';
import taskpool from '@ohos.taskpool';
import type { WfcManager } from '../client/wfc';
import ConversationInfo from '../model/conversationInfo';
import Conversation from '../model/conversation';
import Message from '../messages/message';
import MessagePayload from '../messages/messagePayload';
import MessageContent from '../messages/messageContent';
import MediaMessageContent from '../messages/mediaMessageContent';
import UnknownMessageContent from '../messages/unknownMessageContent';
import ConversationType from '../model/conversationType';
import Long from '../util/long';
import { BackupCrypto } from './backupCrypto';
import {
  BackupMode,
  BackupError,
  BackupMetadata,
  BackupResult,
  RestoreResult,
  BackupConversationResult,
  RestoreConversationResult,
  ProgressCallback,
  BackupInfo,
  ConversationBackupData,
  MessageBackupData,
  MessagePayloadBackupData,
  ConversationMetadata,
  LocalMediaInfo,
  EncryptedData,
  ConversationSettings,
  BackupConversationInfo
} from './backupTypes';

const textEncoder = new util.TextEncoder();
const textDecoder = util.TextDecoder.create('utf-8');


/**
 * TaskPool 任务：读取文本文件
 */
@Concurrent
function readTextFileTask(filePath: string): string | null {
  try {
    const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(filePath);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);
    const result = new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(buffer), { stream: false });
    return result;
  } catch (error) {
    console.error('[MessageBackupManager] TaskPool readTextFile failed:', JSON.stringify(error));
    return null;
  }
}

/**
 * TaskPool 任务：写入文本文件
 */
@Concurrent
function writeTextFileTask(filePath: string, content: string): boolean {
  try {
    const uint8Array = new util.TextEncoder().encodeInto(content);
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    const arrayBuffer = uint8Array.buffer;
    fs.writeSync(file.fd, arrayBuffer);
    fs.closeSync(file);
    return true;
  } catch (error) {
    console.error('[MessageBackupManager] TaskPool writeTextFile failed:', JSON.stringify(error));
    return false;
  }
}

/**
 * TaskPool 任务：复制文件
 */
@Concurrent
function copyFileTask(srcPath: string, destPath: string): boolean {
  try {
    const srcFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);
    const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    const stat = fs.statSync(srcPath);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(srcFile.fd, buffer);
    fs.writeSync(destFile.fd, new Uint8Array(buffer));
    fs.closeSync(srcFile);
    fs.closeSync(destFile);
    return true;
  } catch (error) {
    console.error('[MessageBackupManager] TaskPool copyFile failed:', JSON.stringify(error));
    return false;
  }
}

/**
 * WfcManager类型定义
 */
type WfcManagerInstance = WfcManager;

/**
 * 常量定义（与iOS保持一致）
 */
const BACKUP_VERSION = '1';
const BACKUP_FORMAT = 'directory';
const BACKUP_APP_TYPE = 'harmony-chat';
const BACKUP_MODE_MESSAGE_WITH_MEDIA = 'message_with_media';
const BACKUP_ENCRYPTION_ALGORITHM = 'AES-256-CBC';
const BACKUP_KEY_DERIVATION = 'PBKDF2-SHA256';
const DEFAULT_MESSAGE_BATCH_SIZE = 100;  // 每次获取100条消息
const THUMBNAIL_COMPRESSION_QUALITY = 0.45;

/**
 * 批量恢复消息的结果接口
 */
interface BatchRestoreResult {
  success: boolean;
  hasMedia?: boolean;
  message?: Message;
  direction?: number;
  status?: number;
}

/**
 * 消息备份管理器类
 */
export class MessageBackupManager {
  private static instance: MessageBackupManager | null = null;
  private isCancelled: boolean = false;
  private currentBackupDirectory: string = '';
  private wfc: WfcManagerInstance | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(): MessageBackupManager {
    if (!MessageBackupManager.instance) {
      MessageBackupManager.instance = new MessageBackupManager();
    }
    return MessageBackupManager.instance;
  }

  private constructor() {
    // 私有构造函数，强制使用单例
  }

  /**
   * 设置WfcManager实例
   */
  setWfcManager(wfc: WfcManagerInstance): void {
    this.wfc = wfc;
  }

  /**
   * 取消当前操作
   */
  cancel(): void {
    this.isCancelled = true;
    console.log('[MessageBackupManager] Operation cancelled');
  }

  /**
   * 创建基于目录的备份（v2.0格式）
   * @param outputDir 输出目录
   * @param conversations 要备份的会话列表（如果为空则备份所有会话）
   * @param password 加密密码（可选，默认使用userId）
   * @param passwordHint 密码提示（可选）
   * @param progressCallback 进度回调
   * @returns 备份结果
   */
  async createBackup(
    outputDir: string,
    conversations: ConversationInfo[] = [],
    password?: string,
    passwordHint?: string,
    progressCallback?: ProgressCallback
  ): Promise<BackupResult> {
    try {
      // 参数验证
      if (!outputDir || outputDir.length === 0) {
        return {
          success: false,
          backupPath: '',
          messageCount: 0,
          mediaCount: 0,
          mediaSize: 0,
          error: BackupError.InvalidFormat
        } as BackupResult;
      }

      // 重置取消标志
      this.isCancelled = false;
      this.currentBackupDirectory = outputDir;

      // 1. 创建备份根目录和conversations子目录
      try {
        // 尝试创建输出目录，如果已存在则忽略
        try {
          fs.mkdirSync(outputDir);
        } catch (err) {
          // 目录可能已存在，这是正常的，继续执行
          console.log('[MessageBackupManager] Output directory may already exist:', outputDir);
        }

        // 创建conversations子目录
        const conversationsDir = `${outputDir}/conversations`;
        try {
          fs.mkdirSync(conversationsDir);
        } catch (err) {
          // 目录可能已存在，这是正常的，继续执行
          console.log('[MessageBackupManager] Conversations directory may already exist:', conversationsDir);
        }
      } catch (error) {
        console.error('[MessageBackupManager] Failed to setup backup directories:', JSON.stringify(error));
        this.currentBackupDirectory = '';
        return {
          success: false,
          backupPath: '',
          messageCount: 0,
          mediaCount: 0,
          mediaSize: 0,
          error: BackupError.IOError
        } as BackupResult;
      }

      // 2. 获取要备份的会话（如果未传入则加载所有会话）
      let backupConversations = conversations;
      if (backupConversations.length === 0 && this.wfc) {
        // 获取所有类型的会话
        const types = [ConversationType.Single, ConversationType.Group, ConversationType.ChatRoom, ConversationType.Channel];
        backupConversations = this.wfc.getConversationInfoList(types, [0]);
      }

      if (this.isCancelled) {
        this.cleanupIncompleteBackup();
        return {
          success: false,
          backupPath: '',
          messageCount: 0,
          mediaCount: 0,
          mediaSize: 0,
          error: BackupError.Cancelled
        } as BackupResult;
      }

      // 收集元数据
      const conversationMetadata: ConversationMetadata[] = [];
      let totalMessages = 0;
      let totalMediaFiles = 0;
      let totalMediaSize = 0;
      let firstMessageTime = Number.MAX_SAFE_INTEGER;
      let lastMessageTime = 0;

      // 3. 遍历每个会话
      for (let i = 0; i < backupConversations.length; i++) {
        if (this.isCancelled) break;

        const convInfo = backupConversations[i];
        const progress = Math.floor((i / backupConversations.length) * 100);

        if (progressCallback) {
          progressCallback(progress, `正在备份会话 ${i + 1}/${backupConversations.length}`);
        }

        // 3.1 创建会话目录
        const convDirName = this.getConversationDirectoryName(convInfo);
        const convDir = `${outputDir}/conversations/${convDirName}`;
        try {
          fs.mkdirSync(convDir);
        } catch (err) {
          console.log('[MessageBackupManager] Conversation directory may already exist:', convDir);
        }

        // 3.2 创建media子目录
        const mediaDir = `${convDir}/media`;
        try {
          fs.mkdirSync(mediaDir);
        } catch (err) {
          console.log('[MessageBackupManager] Media directory may already exist:', mediaDir);
        }

        // 3.3 备份该会话的消息
        const backupResult = await this.backupConversation(
          convInfo,
          convDir,
          mediaDir,
          progressCallback
        );

        if (backupResult.error) {
          console.error('[MessageBackupManager] Failed to backup conversation:', convInfo.conversation.target);
          continue;
        }

        // 3.4 收集统计信息
        totalMessages += backupResult.messageCount;
        totalMediaFiles += backupResult.mediaCount;
        totalMediaSize += backupResult.mediaSize;
        if (backupResult.firstMessageTime < firstMessageTime) {
          firstMessageTime = backupResult.firstMessageTime;
        }
        if (backupResult.lastMessageTime > lastMessageTime) {
          lastMessageTime = backupResult.lastMessageTime;
        }

        // 3.5 收集会话元数据
        const conv = convInfo.conversation;
        conversationMetadata.push({
          conversationId: convDirName,
          type: conv.type,
          target: conv.target,
          line: conv.line,
          messageCount: backupResult.messageCount,
          mediaCount: backupResult.mediaCount,
          directory: convDirName,
          mediaFiles: backupResult.mediaFiles
        });

        // 3.6 如果提供了密码，加密messages.json
        if (password && password.length > 0) {
          console.log(`[MessageBackupManager] About to encrypt messages.json for: ${convDir}`);
          const encryptResult = await this.encryptMessagesFile(`${convDir}/messages.json`, password);
          console.log(`[MessageBackupManager] Encryption result for ${convDir}: ${encryptResult ? 'SUCCESS' : 'FAILED'}`);
        } else {
          console.log(`[MessageBackupManager] No password provided, skipping encryption for: ${convDir}`);
        }
      }

      if (this.isCancelled) {
        this.cleanupIncompleteBackup();
        return {
          success: false,
          backupPath: '',
          messageCount: 0,
          mediaCount: 0,
          mediaSize: 0,
          error: BackupError.Cancelled
        } as BackupResult;
      }

      // 4. 创建metadata.json
      await this.createMetadataJSON(
        outputDir,
        password,
        passwordHint,
        conversationMetadata,
        totalMessages,
        totalMediaFiles,
        totalMediaSize,
        firstMessageTime,
        lastMessageTime
      );

      // 备份成功
      this.currentBackupDirectory = '';

      if (progressCallback) {
        progressCallback(100, '备份完成');
      }

      return {
        success: true,
        backupPath: outputDir,
        messageCount: totalMessages,
        mediaCount: totalMediaFiles,
        mediaSize: totalMediaSize
      } as BackupResult;
    } catch (error) {
      console.error('[MessageBackupManager] Backup failed:', JSON.stringify(error));
      this.cleanupIncompleteBackup();
      return {
        success: false,
        backupPath: '',
        messageCount: 0,
        mediaCount: 0,
        mediaSize: 0,
        error: BackupError.IOError
      } as BackupResult;
    }
  }

  /**
   * 从备份恢复
   * @param backupDir 备份目录
   * @param password 解密密码（如果备份未加密则不传）
   * @param overwriteExisting 是否覆盖已存在的消息
   * @param progressCallback 进度回调
   * @returns 恢复结果
   */
  async restoreFromBackup(
    backupDir: string,
    password?: string,
    overwriteExisting: boolean = false,
    progressCallback?: ProgressCallback
  ): Promise<RestoreResult> {
    try {
      // 参数验证
      if (!backupDir || backupDir.length === 0) {
        return {
          success: false,
          messageCount: 0,
          mediaCount: 0,
          error: BackupError.FileNotFound
        } as RestoreResult;
      }

      // 重置取消标志
      this.isCancelled = false;

      // 1. 读取metadata.json
      const metadataPath = `${backupDir}/metadata.json`;
      const metadata = await this.readMetadataFile(metadataPath);
      if (!metadata) {
        return {
          success: false,
          messageCount: 0,
          mediaCount: 0,
          error: BackupError.FileNotFound
        } as RestoreResult;
      }

      // 2. 检查是否需要密码
      const isEncrypted = metadata.encryption.enabled;

      if (isEncrypted && (!password || password.length === 0)) {
        console.error('[MessageBackupManager] Backup is encrypted but no password provided');
        return {
          success: false,
          messageCount: 0,
          mediaCount: 0,
          error: BackupError.InvalidPassword
        } as RestoreResult;
      }

      // 2.1 如果加密，验证密码（使用第一个会话的messages.json）
      if (isEncrypted && password && metadata.conversations.length > 0) {
        const firstConv = metadata.conversations[0];
        const messagesPath = `${backupDir}/conversations/${firstConv.directory}/messages.json`;
        const encryptedData = await this.readEncryptedMessagesFile(messagesPath);

        if (encryptedData) {
          const encrypted: EncryptedData = {
            salt: encryptedData['salt'] as string,
            iv: encryptedData['iv'] as string,
            data: encryptedData['data'] as string,
            iterations: encryptedData['iterations'] as number
          };

          // 验证密码
          const isValid = await BackupCrypto.verifyPassword(encrypted, password);
          if (!isValid) {
            console.error('[MessageBackupManager] Password verification failed');
            return {
              success: false,
              messageCount: 0,
              mediaCount: 0,
              error: BackupError.WrongPassword
            } as RestoreResult;
          }
          console.log('[MessageBackupManager] Password verified successfully');
        } else {
          console.error('[MessageBackupManager] Failed to read encrypted messages file');
        }
      }

      // 3. 遍历会话列表
      let totalMessages = 0;
      let totalMedia = 0;

      for (let i = 0; i < metadata.conversations.length; i++) {
        if (this.isCancelled) break;

        const convInfo = metadata.conversations[i];
        const progress = Math.floor((i / metadata.conversations.length) * 100);

        if (progressCallback) {
          progressCallback(progress, `正在恢复会话 ${i + 1}/${metadata.conversations.length}`);
        }

        // 3.1 读取messages.json
        const convDir = `${backupDir}/conversations/${convInfo.directory}`;
        const messagesPath = `${convDir}/messages.json`;

        let messagesData: ConversationBackupData | null = null;

        // 3.2 如果加密，先解密
        if (isEncrypted && password) {
          const encryptedData = await this.readEncryptedMessagesFile(messagesPath);
          if (encryptedData) {
            const encrypted: EncryptedData = {
              salt: encryptedData['salt'] as string,
              iv: encryptedData['iv'] as string,
              data: encryptedData['data'] as string,
              iterations: encryptedData['iterations'] as number
            };
            messagesData = await BackupCrypto.decryptToObject<ConversationBackupData>(
              encrypted,
              password
            );
          }
        } else {
          // 未加密，直接读取（使用异步方法）
          messagesData = await this.readMessagesFileAsync(messagesPath);
        }

        if (!messagesData) {
          console.error('[MessageBackupManager] Failed to read messages for:', convInfo.directory);
          continue;
        }

        // 3.3 恢复消息到数据库
        const mediaDir = `${convDir}/media`;
        const restoreResult = await this.restoreConversation(
          messagesData,
          mediaDir,
          overwriteExisting
        );

        totalMessages += restoreResult.messageCount;
        totalMedia += restoreResult.mediaCount;
        
        // 让出主线程，避免长时间占用（增加延迟时间）
        await new Promise<void>(resolve => setTimeout(resolve, 10));
      }

      if (this.isCancelled) {
        return {
          success: false,
          messageCount: 0,
          mediaCount: 0,
          error: BackupError.Cancelled
        } as RestoreResult;
      }

      if (progressCallback) {
        progressCallback(100, '恢复完成');
      }

      return {
        success: true,
        messageCount: totalMessages,
        mediaCount: totalMedia
      } as RestoreResult;
    } catch (error) {
      console.error('[MessageBackupManager] Restore failed:', JSON.stringify(error));
      return {
        success: false,
        messageCount: 0,
        mediaCount: 0,
        error: BackupError.RestoreFailed
      } as RestoreResult;
    }
  }

  /**
   * 获取备份信息
   * @param backupDir 备份目录
   * @returns 备份信息
   */
  async getBackupInfo(backupDir: string): Promise<BackupInfo | null> {
    try {
      const metadataPath = `${backupDir}/metadata.json`;
      console.log(`[MessageBackupManager] Reading metadata from: ${metadataPath}`);
      const metadata = await this.readMetadataFile(metadataPath);

      if (!metadata) {
        console.log(`[MessageBackupManager] Failed to read metadata from: ${metadataPath}`);
        return null;
      }

      return {
        format: metadata.format,
        isEncrypted: metadata.encryption.enabled,
        version: metadata.version,
        backupTime: metadata.backupTime,
        userId: metadata.userId,
        deviceName: metadata.deviceName || '',
        totalConversations: metadata.conversations.length,
        totalMessages: metadata.statistics.totalMessages,
        mediaFileCount: metadata.statistics.mediaFileCount,
        mediaTotalSize: metadata.statistics.mediaTotalSize,
        hasPasswordHint: !!metadata.encryption.passwordHint
      };
    } catch (error) {
      console.error('[MessageBackupManager] Failed to get backup info:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 获取本地备份列表
   * @param backupRootDir 备份根目录
   * @returns 备份列表
   */
  async getLocalBackupList(backupRootDir: string): Promise<BackupInfo[]> {
    try {
      console.log(`[MessageBackupManager] Getting backup list from: ${backupRootDir}`);
      const backups: BackupInfo[] = [];

      // 列出所有以backup_开头的目录
      const files = fs.listFileSync(backupRootDir);
      console.log(`[MessageBackupManager] Found ${files.length} files/dirs in backup root`);
      console.log(`[MessageBackupManager] Files: ${JSON.stringify(files)}`);

      for (const file of files) {
        console.log(`[MessageBackupManager] Checking: ${file}, starts with 'backup_': ${file.startsWith('backup_')}`);
        if (file.startsWith('backup_')) {
          const backupPath = `${backupRootDir}/${file}`;
          console.log(`[MessageBackupManager] Reading backup info from: ${backupPath}`);
          const info = await this.getBackupInfo(backupPath);
          if (info) {
            console.log(`[MessageBackupManager] Found valid backup: ${file}`);
            backups.push(info);
          } else {
            console.log(`[MessageBackupManager] Failed to read backup info from: ${backupPath}`);
          }
        }
      }

      // 按备份时间排序
      backups.sort((a, b) => {
        return new Date(b.backupTime).getTime() - new Date(a.backupTime).getTime();
      });

      return backups;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to get backup list:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除备份
   * @param backupDir 备份目录
   * @returns 是否成功
   */
  deleteBackup(backupDir: string): boolean {
    try {
      // 递归删除目录
      this.deleteDirectoryRecursive(backupDir);
      console.log('[MessageBackupManager] Backup deleted:', backupDir);
      return true;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to delete backup:', JSON.stringify(error));
      return false;
    }
  }

  // ==================== 私有方法 ====================

  /**
   * 清理不完整的备份目录
   */
  private cleanupIncompleteBackup(): void {
    if (this.currentBackupDirectory && this.currentBackupDirectory.length > 0) {
      try {
        this.deleteDirectoryRecursive(this.currentBackupDirectory);
        console.log('[MessageBackupManager] Cleaned up incomplete backup:', this.currentBackupDirectory);
      } catch (error) {
        console.error('[MessageBackupManager] Failed to cleanup backup directory:', JSON.stringify(error));
      }
      this.currentBackupDirectory = '';
    }
  }

  /**
   * 递归删除目录
   */
  private deleteDirectoryRecursive(dirPath: string): void {
    const stat = fs.statSync(dirPath);
    if (stat.isDirectory()) {
      const files = fs.listFileSync(dirPath);
      for (const file of files) {
        const filePath = `${dirPath}/${file}`;
        this.deleteDirectoryRecursive(filePath);
      }
      fs.rmdirSync(dirPath);
    } else {
      fs.unlinkSync(dirPath);
    }
  }

  /**
   * 生成会话目录名
   */
  private getConversationDirectoryName(convInfo: ConversationInfo): string {
    const conv = convInfo.conversation;
    // 格式：conv_{type}_{target}_{line}
    // 对target进行URL编码以避免特殊字符问题
    const encodedTarget = encodeURIComponent(conv.target);
    return `conv_type${conv.type}_${encodedTarget}_line${conv.line}`;
  }

  /**
   * 备份单个会话
   */
  private async backupConversation(
    convInfo: ConversationInfo,
    convDir: string,
    mediaDir: string,
    progressCallback?: ProgressCallback
  ): Promise<BackupConversationResult> {
    try {
      if (!this.wfc) {
        return {
          messageCount: 0,
          mediaCount: 0,
          mediaSize: 0,
          firstMessageTime: 0,
          lastMessageTime: 0,
          mediaFiles: [],
          error: BackupError.IOError
        } as BackupConversationResult;
      }

      const messagesArray: MessageBackupData[] = [];
      let convMessageCount = 0;
      let convMediaCount = 0;
      let convMediaSize = 0;
      let firstTime = Number.MAX_SAFE_INTEGER;
      let lastTime = 0;
      const mediaFiles: string[] = [];  // 收集媒体文件列表

      // 获取该会话的所有消息
      const conversation = convInfo.conversation;
      let fromIndex = 0;

      while (true) {
        if (this.isCancelled) break;

        // 使用Promise包装异步获取消息
        const messages = await new Promise<Message[]>((resolve, reject) => {
          this.wfc!.getMessagesV2(
            conversation,
            fromIndex,
            false,  // before: 获取更旧的消息
            DEFAULT_MESSAGE_BATCH_SIZE,
            '',
            (msgs: Message[]) => {
              resolve(msgs);
            },
            (err: number) => {
              reject(err);
            }
          );
        });

        if (messages.length === 0) break;

        for (const msg of messages) {
          if (this.isCancelled) break;

          // 编码消息
          const msgDict = await this.encodeMessage(msg, mediaDir);
          messagesArray.push(msgDict);
          convMessageCount++;

          // 统计媒体文件
          if (msgDict.payload.localMediaInfo) {
            convMediaCount++;
            convMediaSize += msgDict.mediaFileSize || 0;

            // 收集媒体文件名（只保存文件名，不包含路径）
            const relativePath = msgDict.payload.localMediaInfo.relativePath;
            if (relativePath) {
              // relativePath 格式为 "media_xxx.ext" 或 "media_xxx.jpg"
              // 我们需要提取文件名
              const fileName = relativePath.split('/').pop() || relativePath;
              mediaFiles.push(fileName);
            }
          }

          // 统计时间范围
          const msgTime = msg.timestamp;
          if (msgTime < firstTime) firstTime = msgTime;
          if (msgTime > lastTime) lastTime = msgTime;
        }

        fromIndex = messages[messages.length-1].messageId;
      }

      // 保存messages.json
      const settings: ConversationSettings = {
        isTop: convInfo.top,
        isSilent: convInfo.isSilent,
        draft: convInfo.draft || ''
      };

      const backupConvInfo: BackupConversationInfo = {
        type: conversation.type,
        target: conversation.target,
        line: conversation.line
      };

      const messagesData: ConversationBackupData = {
        version: BACKUP_VERSION,
        conversation: backupConvInfo,
        settings: settings,
        messages: messagesArray
      };

      const messagesJsonPath = `${convDir}/messages.json`;
      // 使用TaskPool写入文件以避免阻塞主线程
      await this.writeTextFileAsync(messagesJsonPath, JSON.stringify(messagesData, null, 2));

      return {
        messageCount: convMessageCount,
        mediaCount: convMediaCount,
        mediaSize: convMediaSize,
        firstMessageTime: firstTime,
        lastMessageTime: lastTime,
        mediaFiles: mediaFiles
      } as BackupConversationResult;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to backup conversation:', JSON.stringify(error));
      return {
        messageCount: 0,
        mediaCount: 0,
        mediaSize: 0,
        firstMessageTime: 0,
        lastMessageTime: 0,
        mediaFiles: [],
        error: BackupError.IOError
      } as BackupConversationResult;
    }
  }

  /**
   * 恢复单个会话
   */
  private async restoreConversation(
    convData: ConversationBackupData,
    mediaDir: string,
    overwriteExisting: boolean
  ): Promise<RestoreConversationResult> {
    try {
      if (!this.wfc) {
        return {
          messageCount: 0,
          mediaCount: 0,
          error: BackupError.RestoreFailed
        } as RestoreConversationResult;
      }

      // 解析会话信息
      const convDict = convData.conversation;
      const conversation = new Conversation(convDict.type, convDict.target, convDict.line);

      // 恢复会话设置（置顶、静音、草稿）
      const settings = convData.settings;
      try {
        // 设置置顶
        if (settings.isTop !== 0) {
          this.wfc.setConversationTop(conversation, settings.isTop, () => {
            console.log('[MessageBackupManager] Conversation top set successfully');
          }, (errorCode: number) => {
            console.error('[MessageBackupManager] Failed to set conversation top:', errorCode);
          });
        }
        // 设置静音
        if (settings.isSilent) {
          this.wfc.setConversationSlient(conversation, settings.isSilent, () => {
            console.log('[MessageBackupManager] Conversation silent set successfully');
          }, (errorCode: number) => {
            console.error('[MessageBackupManager] Failed to set conversation silent:', errorCode);
          });
        }
        // 设置草稿
        if (settings.draft && settings.draft.length > 0) {
          this.wfc.setConversationDraft(conversation, settings.draft);
        }
        console.log('[MessageBackupManager] Conversation settings restored:', conversation.target);
      } catch (error) {
        console.error('[MessageBackupManager] Failed to restore conversation settings:', JSON.stringify(error));
        // 继续恢复消息，不因为设置失败而中断
      }

      let restoredCount = 0;
      let restoredMediaCount = 0;

      // 批量处理消息，避免阻塞主线程
      // 减小批量大小以降低单批次处理时间，避免 AppFreeze
      const BATCH_SIZE = 10; // 每批处理10条消息
      const totalMessages = convData.messages.length;
      
      for (let i = 0; i < totalMessages; i += BATCH_SIZE) {
        if (this.isCancelled) break;

        const batchEnd = Math.min(i + BATCH_SIZE, totalMessages);
        const batchMessages = convData.messages.slice(i, batchEnd);
        
        // 顺序处理批次中的消息，避免并发过多文件 I/O 导致 AppFreeze
        const batchResults: BatchRestoreResult[] = [];
        for (const msgDict of batchMessages) {
          if (this.isCancelled) break;
          
          try {
            // 解码消息
            const result = await this.decodeMessage(msgDict, conversation, mediaDir);
            if (result) {
              // 插入到数据库
              let insertedMsg: Message | null = null;
              if (result.messageUid && result.messageUid !== Long.ZERO) {
                insertedMsg = this.wfc!.insertMessageEx(
                  result.messageUid,
                  result.conversation,
                  result.from,
                  result.messageContent,
                  result.status,
                  result.timestamp,
                  result.localExtra || ''
                );
              }

              if (insertedMsg) {
                batchResults.push({
                  success: true,
                  hasMedia: !!msgDict.payload.localMediaInfo,
                  message: insertedMsg,
                  direction: result.direction,
                  status: result.status
                } as BatchRestoreResult);
              } else {
                batchResults.push({ success: false } as BatchRestoreResult);
              }
            } else {
              batchResults.push({ success: false } as BatchRestoreResult);
            }
          } catch (error) {
            console.error('[MessageBackupManager] Failed to restore message:', JSON.stringify(error));
            batchResults.push({ success: false } as BatchRestoreResult);
          }
          
          // 每处理一条消息后让出线程，确保UI响应
          await new Promise<void>(resolve => setTimeout(resolve, 0));
        }

        // 统计成功恢复的消息
        for (const result of batchResults) {
          if (result.success) {
            restoredCount++;
            if (result.hasMedia) {
              restoredMediaCount++;
            }
          }
        }

        // 让出主线程，避免长时间占用（增加延迟时间）
        await new Promise<void>(resolve => setTimeout(resolve, 10));
      }

      return {
        messageCount: restoredCount,
        mediaCount: restoredMediaCount
      } as RestoreConversationResult;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to restore conversation:', JSON.stringify(error));
      return {
        messageCount: 0,
        mediaCount: 0,
        error: BackupError.RestoreFailed
      } as RestoreConversationResult;
    }
  }

  /**
   * 编码消息（优化版本，使用TaskPool处理文件操作）
   */
  private async encodeMessage(message: Message, mediaDir: string): Promise<MessageBackupData> {
    // 编码基本信息
    const msgDict: MessageBackupData = {
      messageUid: message.messageUid.toNumber(),
      fromUser: message.from,
      toUsers: message.to ? [message.to] : [],
      direction: message.direction,
      status: message.status,
      timestamp: message.timestamp,
      localExtra: message.localExtra || '',
      payload: this.encodeMessagePayload(message)
    };

    // 处理媒体消息
    if (message.messageContent instanceof MediaMessageContent) {
      const mediaContent = message.messageContent as MediaMessageContent;
      const localPath = mediaContent.localPath;

      if (localPath && localPath.length > 0) {
        try {
          // 检查文件是否存在
          if (fs.accessSync(localPath)) {
            // 计算MD5
            const md5 = await BackupCrypto.calculateFileMD5(localPath);
            if (md5 && md5.length >= 16) {
              const fileId = md5.substring(0, 16);
              const extension = this.getFileExtension(localPath);
              const fileName = `media_${fileId}.${extension}`;
              const targetPath = `${mediaDir}/${fileName}`;

              // 使用TaskPool复制文件
              const copied = await this.copyFileAsync(localPath, targetPath);
              if (copied) {
                const fileSize = this.getFileSize(localPath);

                // 保存媒体信息
                const mediaInfo: LocalMediaInfo = {
                  relativePath: fileName,
                  fileId: fileId,
                  fileSize: fileSize,
                  md5: md5
                };
                msgDict.payload.localMediaInfo = mediaInfo;

                msgDict.mediaFileSize = fileSize;
              }
            }
          }
        } catch (error) {
          console.error('[MessageBackupManager] Failed to backup media file:', JSON.stringify(error));
        }
      }
    }

    return msgDict;
  }

  /**
   * 编码消息载荷
   */
  private encodeMessagePayload(message: Message): MessagePayloadBackupData {
    const payload: MessagePayloadBackupData = {
      contentType: message.messageContent.type,
      mentionedType: message.messageContent.mentionedType,
      mentionedTargets: message.messageContent.mentionedTargets,
      notLoaded: message.messageContent.notLoaded
    };

    // 获取encoded payload
    const encoded = message.messageContent.encode();

    if (encoded.searchableContent) {
      payload.searchableContent = encoded.searchableContent;
    }
    if (encoded.pushContent) {
      payload.pushContent = encoded.pushContent;
    }
    if (encoded.pushData) {
      payload.pushData = encoded.pushData;
    }
    if (encoded.content) {
      payload.content = encoded.content;
    }
    if (encoded.binaryContent) {
      payload.binaryContent = encoded.binaryContent;
    }
    if (encoded.localContent) {
      payload.localContent = encoded.localContent;
    }
    if (encoded.extra) {
      payload.extra = encoded.extra;
    }

    // 媒体消息特有字段
    if (message.messageContent instanceof MediaMessageContent) {
      const mediaContent = message.messageContent as MediaMessageContent;
      payload.mediaType = mediaContent.mediaType;
      if (mediaContent.remotePath) {
        payload.remoteMediaUrl = mediaContent.remotePath;
      }
    }

    return payload;
  }

  /**
   * 解码消息
   */
  private async decodeMessage(
    msgDict: MessageBackupData,
    conversation: Conversation,
    mediaDir: string
  ): Promise<Message | null> {
    try {
      if (!this.wfc) {
        return null;
      }

      // 创建Message对象（先用UnknownMessageContent作为占位符）
      const message = new Message(conversation, new UnknownMessageContent());
      message.messageUid = Long.fromNumber(msgDict.messageUid);
      message.from = msgDict.fromUser;
      message.to = msgDict.toUsers && msgDict.toUsers.length > 0 ? msgDict.toUsers[0] : '';
      message.direction = msgDict.direction;
      message.status = msgDict.status;
      message.timestamp = msgDict.timestamp;
      message.localExtra = msgDict.localExtra || '';

      // 解码payload
      const payloadDict = msgDict.payload;

      // 处理本地媒体文件恢复
      if (payloadDict.localMediaInfo && this.wfc) {
        const mediaInfo = payloadDict.localMediaInfo;
        const relativePath = mediaInfo.relativePath;
        const fileId = mediaInfo.fileId;

        if (relativePath && fileId) {
          const backupFilePath = `${mediaDir}/${relativePath}`;

          try {
            if (fs.accessSync(backupFilePath)) {
              // 生成新的媒体文件存储路径
              const appPath = this.wfc.getAppPath();
              const extension = this.getFileExtension(relativePath);
              const newFileName = `${fileId}.${extension}`;
              const newFilePath = `${appPath}/sendbox/${newFileName}`;

              // 使用TaskPool复制文件，避免阻塞主线程
              await this.copyFileAsync(backupFilePath, newFilePath);

              // 设置localMediaPath
              payloadDict.localMediaPath = newFilePath;
            }
          } catch (error) {
            console.error('[MessageBackupManager] Failed to restore media file:', JSON.stringify(error));
          }
        }
      }

      // 创建MessagePayload
      const payload = new MessagePayload();
      payload.type = payloadDict.contentType;
      payload.searchableContent = payloadDict.searchableContent || '';
      payload.pushContent = payloadDict.pushContent || '';
      payload.pushData = payloadDict.pushData || '';
      payload.content = payloadDict.content || '';
      payload.binaryContent = payloadDict.binaryContent || '';
      payload.localContent = payloadDict.localContent || '';
      payload.mentionedType = payloadDict.mentionedType || 0;
      payload.mentionedTargets = payloadDict.mentionedTargets || [];
      payload.extra = payloadDict.extra || '';
      payload.notLoaded = payloadDict.notLoaded || 0;

      if (payloadDict.mediaType !== undefined) {
        payload.mediaType = payloadDict.mediaType;
      }
      if (payloadDict.remoteMediaUrl !== undefined) {
        payload.remoteMediaUrl = payloadDict.remoteMediaUrl;
      }
      if (payloadDict.localMediaPath !== undefined) {
        payload.localMediaPath = payloadDict.localMediaPath;
      }

      // 从payload创建MessageContent
      const content = Message.messageContentFromMessagePayload(payload, message.from);
      if (content) {
        message.messageContent = content;
      }

      return message;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to decode message:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 加密messages.json文件
   */
  private async encryptMessagesFile(messagesJsonPath: string, password: string): Promise<boolean> {
    try {
      console.log(`[MessageBackupManager] encryptMessagesFile START: ${messagesJsonPath}`);

      // 1. 在TaskPool中读取原始JSON
      const jsonString = await taskpool.execute(readTextFileTask, messagesJsonPath) as string | null;
      if (!jsonString) {
        console.error(`[MessageBackupManager] Failed to read original JSON from ${messagesJsonPath}`);
        return false;
      }

      console.log(`[MessageBackupManager] Original JSON length: ${jsonString.length}`);

      // 2. 加密（在主线程执行，因为涉及 BackupCrypto）
      const data = textEncoder.encodeInto(jsonString);
      console.log(`[MessageBackupManager] Data encoded, length: ${data.length}`);

      const encrypted = await BackupCrypto.encrypt(data, password);
      if (!encrypted) {
        console.error(`[MessageBackupManager] BackupCrypto.encrypt returned null`);
        return false;
      }

      console.log(`[MessageBackupManager] Encryption successful`);

      // 3. 在TaskPool中写入加密数据
      const encryptedJsonString = JSON.stringify(encrypted);
      const writeSuccess = await taskpool.execute(writeTextFileTask, messagesJsonPath, encryptedJsonString) as boolean;
      
      if (!writeSuccess) {
        console.error(`[MessageBackupManager] Failed to write encrypted data to ${messagesJsonPath}`);
        return false;
      }

      console.log(`[MessageBackupManager] Encrypted data written to ${messagesJsonPath}`);
      return true;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to encrypt messages.json:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 创建metadata.json
   */
  private async createMetadataJSON(
    directoryPath: string,
    password: string | undefined,
    passwordHint: string | undefined,
    conversations: ConversationMetadata[],
    totalMessages: number,
    totalMediaFiles: number,
    totalMediaSize: number,
    firstMessageTime: number,
    lastMessageTime: number
  ): Promise<void> {
    try {
      const userId = this.wfc ? this.wfc.getUserId() : '';

      const metadata: BackupMetadata = {
        version: BACKUP_VERSION,
        format: BACKUP_FORMAT,
        backupTime: new Date().toISOString(),
        userId: userId,
        appType: BACKUP_APP_TYPE,
        backupMode: BACKUP_MODE_MESSAGE_WITH_MEDIA,
        deviceName: 'HarmonyOS Device', // TODO: 获取真实设备名称
        encryption: {
          enabled: !!(password && password.length > 0),
          algorithm: password ? BACKUP_ENCRYPTION_ALGORITHM : undefined,
          keyDerivation: password ? BACKUP_KEY_DERIVATION : undefined,
          passwordHint: passwordHint
        },
        statistics: {
          totalConversations: conversations.length,
          totalMessages: totalMessages,
          mediaFileCount: totalMediaFiles,
          mediaTotalSize: totalMediaSize,
          timeRange: {
            firstMessageTime: firstMessageTime,
            lastMessageTime: lastMessageTime
          }
        },
        conversations: conversations
      };

      // 保存到文件，使用TaskPool优化
      const metadataPath = `${directoryPath}/metadata.json`;
      console.log(`[MessageBackupManager] Creating metadata.json at: ${metadataPath}`);
      const jsonString = JSON.stringify(metadata, null, 2);
      console.log(`[MessageBackupManager] Metadata JSON length: ${jsonString.length}`);
      await this.writeTextFileAsync(metadataPath, jsonString);
      console.log(`[MessageBackupManager] metadata.json created successfully`);
    } catch (error) {
      console.error('[MessageBackupManager] Failed to create metadata.json:', JSON.stringify(error));
    }
  }

  /**
   * 读取metadata.json
   */
  private async readMetadataFile(metadataPath: string): Promise<BackupMetadata | null> {
    try {
      console.log(`[MessageBackupManager] Reading text file: ${metadataPath}`);
      // 使用TaskPool读取文件
      const jsonString = await this.readTextFileAsync(metadataPath);
      if (!jsonString) {
        console.log(`[MessageBackupManager] Failed to read text file, got null`);
        console.log(`[MessageBackupManager] This may be due to a failed backup creation. Please delete and recreate the backup.`);
        return null;
      }
      if (jsonString.length === 0) {
        console.log(`[MessageBackupManager] Read empty file (0 bytes) - backup file is corrupted or incomplete`);
        return null;
      }
      console.log(`[MessageBackupManager] JSON string length: ${jsonString.length}`);
      const metadata = JSON.parse(jsonString) as BackupMetadata;
      console.log(`[MessageBackupManager] Parsed metadata, backupTime: ${metadata.backupTime}`);
      return metadata;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to read metadata.json:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 读取messages.json（异步版本，使用TaskPool）
   */
  private async readMessagesFileAsync(messagesPath: string): Promise<ConversationBackupData | null> {
    try {
      const jsonString = await this.readTextFileAsync(messagesPath);
      if (!jsonString) {
        return null;
      }
      return JSON.parse(jsonString) as ConversationBackupData;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to read messages.json:', JSON.stringify(error));
      return null;
    }
  }


  /**
   * 读取加密的messages.json
   */
  private async readEncryptedMessagesFile(messagesPath: string): Promise<Record<string, Object> | null> {
    try {
      console.log(`[MessageBackupManager] readEncryptedMessagesFile - Reading: ${messagesPath}`);
      // 使用TaskPool读取文件
      const jsonString = await this.readTextFileAsync(messagesPath);
      if (!jsonString) {
        console.error(`[MessageBackupManager] readEncryptedMessagesFile - Failed to read file`);
        return null;
      }

      console.log(`[MessageBackupManager] readEncryptedMessagesFile - File content length: ${jsonString.length}`);

      // Check if content looks like encrypted data (should start with {"salt":)
      const isEncryptedFormat = jsonString.trim().startsWith('{"salt"');
      const isDecryptedFormat = jsonString.trim().startsWith('{"conversation"');
      console.log(`[MessageBackupManager] readEncryptedMessagesFile - Format check - encrypted: ${isEncryptedFormat}, decrypted: ${isDecryptedFormat}`);

      const parsed: Record<string, Object> = JSON.parse(jsonString) as Record<string, Object>;
      console.log(`[MessageBackupManager] readEncryptedMessagesFile - Parsed successfully`);
      return parsed;
    } catch (error) {
      console.error('[MessageBackupManager] Failed to read encrypted messages.json:', JSON.stringify(error));
      return null;
    }
  }


  /**
   * 读取文本文件
   */
  private async readTextFileAsync(filePath: string): Promise<string | null> {
    try {
      return await taskpool.execute(readTextFileTask, filePath) as string | null;
    } catch (error) {
      console.error('[MessageBackupManager] readTextFileAsync failed:', JSON.stringify(error));
      return null;
    }
  }


  /**
   * 写入文本文件
   */
  private async writeTextFileAsync(filePath: string, content: string): Promise<boolean> {
    try {
      return await taskpool.execute(writeTextFileTask, filePath, content) as boolean;
    } catch (error) {
      console.error('[MessageBackupManager] writeTextFileAsync failed:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 复制文件
   */
  private async copyFileAsync(srcPath: string, destPath: string): Promise<boolean> {
    try {
      return await taskpool.execute(copyFileTask, srcPath, destPath) as boolean;
    } catch (error) {
      console.error('[MessageBackupManager] copyFileAsync failed:', JSON.stringify(error));
      return false;
    }
  }


  /**
   * 获取文件大小
   */
  private getFileSize(filePath: string): number {
    try {
      const stat = fs.statSync(filePath);
      return stat.size;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 获取文件扩展名
   */
  private getFileExtension(filePath: string): string {
    const lastDot = filePath.lastIndexOf('.');
    if (lastDot > 0) {
      return filePath.substring(lastDot + 1);
    }
    return '';
  }
}