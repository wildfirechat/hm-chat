//
// backupCrypto.ets
// hm-chat client
//
// 备份加密工具类
// 提供备份文件的加密和解密功能
// 使用AES-256-CBC和PBKDF2-SHA256，与iOS版本保持完全一致
//

import cryptoFramework from '@ohos.security.cryptoFramework';
import { util } from '@kit.ArkTS';
import { EncryptedData } from './backupTypes';
import fs from '@ohos.file.fs';

/**
 * 加密常量定义
 */
const KEY_SIZE = 32;                  // AES-256密钥大小（字节）
const SALT_SIZE = 16;                 // 盐值大小（字节）
const IV_SIZE = 16;                   // IV大小（字节）
const PBKDF2_ITERATIONS = 5000;       // PBKDF2迭代次数（与iOS保持一致）

const textEncoder = new util.TextEncoder();
const textDecoder = util.TextDecoder.create('utf-8');

/**
 * 备份加密工具类
 */
export class BackupCrypto {

  /**
   * 从密码派生加密密钥（PBKDF2-SHA256）
   * 使用HarmonyOS内置的PBKDF2实现，与iOS保持完全一致
   * @param password 用户密码
   * @param salt 盐值（随机生成）
   * @param iterations PBKDF2迭代次数
   * @returns 派生的密钥数据（32字节，用于AES-256）
   */
  static async deriveKeyFromPassword(
    password: string,
    salt: Uint8Array,
    iterations: number = PBKDF2_ITERATIONS
  ): Promise<Uint8Array | null> {
    try {
      if (!password || salt.length === 0) {
        return null;
      }

      console.log(`[BackupCrypto] Starting PBKDF2 key derivation, iterations: ${iterations}, keySize: ${KEY_SIZE}`);

      // 使用HarmonyOS内置的PBKDF2实现
      const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');

      const spec: cryptoFramework.PBKDF2Spec = {
        algName: 'PBKDF2',
        password: password,
        salt: salt,
        iterations: iterations,
        keySize: KEY_SIZE
      };

      const secret = await kdf.generateSecret(spec);
      console.log(`[BackupCrypto] PBKDF2 key derivation successful, key length: ${secret.data.length}`);

      return secret.data;
    } catch (error) {
      console.error('[BackupCrypto] Key derivation failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 加密数据（AES-256-CBC）
   * @param data 明文数据
   * @param password 用户密码
   * @returns 加密结果字典，包含salt、iv、data、iterations
   */
  static async encrypt(data: Uint8Array, password: string): Promise<EncryptedData | null> {
    try {
      if (!data || data.length === 0 || !password) {
        return null;
      }

      // 1. 生成随机Salt
      const salt: Uint8Array = BackupCrypto.generateRandomData(SALT_SIZE);
      if (!salt || salt.length === 0) {
        return null;
      }

      // 2. 派生密钥
      const keyData = await BackupCrypto.deriveKeyFromPassword(password, salt);
      if (!keyData) {
        return null;
      }

      // 3. 生成随机IV
      const iv: Uint8Array = BackupCrypto.generateRandomData(IV_SIZE);
      if (!iv || iv.length === 0) {
        return null;
      }

      // 4. 创建AES密钥
      const keyBlob: cryptoFramework.DataBlob = {
        data: keyData
      };
      const keyGen = cryptoFramework.createSymKeyGenerator('AES256');
      const aesKey: cryptoFramework.SymKey = await keyGen.convertKey(keyBlob);

      // 5. 创建Cipher对象
      const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
      const mode = cryptoFramework.CryptoMode.ENCRYPT_MODE;

      // 6. 初始化
      const ivBlob: cryptoFramework.DataBlob = { data: iv };
      const ivParams: cryptoFramework.IvParamsSpec = {
        algName: 'IvParamsSpec',
        iv: ivBlob
      };
      await cipher.init(mode, aesKey, ivParams);

      // 7. 加密
      const input: cryptoFramework.DataBlob = { data: data };
      const encrypted: cryptoFramework.DataBlob = await cipher.doFinal(input);

      // 8. 返回加密结果（Base64编码）
      const base64 = new util.Base64();
      const result: EncryptedData = {
        salt: base64.encodeToStringSync(salt),
        iv: base64.encodeToStringSync(iv),
        data: base64.encodeToStringSync(encrypted.data),
        iterations: PBKDF2_ITERATIONS
      };
      return result;
    } catch (error) {
      console.error('[BackupCrypto] Encryption failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 解密数据（AES-256-CBC）
   * @param encryptedData 加密数据字典（包含salt, iv, data, iterations）
   * @param password 用户密码
   * @returns 解密后的明文数据
   */
  static async decrypt(encryptedData: EncryptedData, password: string): Promise<Uint8Array | null> {
    try {
      // 1. 解析加密参数
      const base64 = new util.Base64();
      const salt: Uint8Array = base64.decodeSync(encryptedData.salt);
      const iv: Uint8Array = base64.decodeSync(encryptedData.iv);
      const ciphertext: Uint8Array = base64.decodeSync(encryptedData.data);
      const iterations: number = encryptedData.iterations;

      if (!salt || !iv || !ciphertext) {
        return null;
      }

      // 2. 派生密钥
      const keyData = await BackupCrypto.deriveKeyFromPassword(password, salt, iterations);
      if (!keyData) {
        return null;
      }

      // 3. 创建AES密钥
      const keyBlob: cryptoFramework.DataBlob = {
        data: keyData
      };
      const keyGen = cryptoFramework.createSymKeyGenerator('AES256');
      const aesKey: cryptoFramework.SymKey = await keyGen.convertKey(keyBlob);

      // 4. 创建Cipher对象
      const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
      const mode = cryptoFramework.CryptoMode.DECRYPT_MODE;

      // 5. 初始化
      const ivBlob: cryptoFramework.DataBlob = { data: iv };
      const ivParams: cryptoFramework.IvParamsSpec = {
        algName: 'IvParamsSpec',
        iv: ivBlob
      };
      await cipher.init(mode, aesKey, ivParams);

      // 6. 解密
      const input: cryptoFramework.DataBlob = { data: ciphertext };
      const decrypted: cryptoFramework.DataBlob = await cipher.doFinal(input);

      return decrypted.data;
    } catch (error) {
      console.error('[BackupCrypto] Decryption failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 验证密码
   * @param encryptedData 加密数据字典
   * @param password 用户密码
   * @returns 密码是否正确
   */
  static async verifyPassword(encryptedData: EncryptedData, password: string): Promise<boolean> {
    try {
      const decrypted = await BackupCrypto.decrypt(encryptedData, password);
      return decrypted !== null;
    } catch (error) {
      return false;
    }
  }

  /**
   * 生成随机数据
   * @param size 数据大小（字节数）
   * @returns 随机数据
   */
  static generateRandomData(size: number): Uint8Array {
    try {
      if (size <= 0) {
        return new Uint8Array(0);
      }

      const random = cryptoFramework.createRandom();
      const randomData: cryptoFramework.DataBlob = random.generateRandomSync(size);
      return randomData.data;
    } catch (error) {
      console.error('[BackupCrypto] Failed to generate random data:', JSON.stringify(error));
      return new Uint8Array(0);
    }
  }

  /**
   * 计算文件的MD5
   * @param filePath 文件路径
   * @returns MD5字符串（32位十六进制）
   */
  static async calculateFileMD5(filePath: string): Promise<string | null> {
    try {
      const md = cryptoFramework.createMd('MD5');
      const file = await BackupCrypto.readFile(filePath);

      // 分块计算MD5
      const chunkSize = 4096;
      let offset = 0;

      while (offset < file.byteLength) {
        const end: number = Math.min(offset + chunkSize, file.byteLength);
        const chunk: Uint8Array = new Uint8Array(file, offset, end - offset);
        const blob: cryptoFramework.DataBlob = { data: chunk };
        md.update(blob);
        offset = end;
      }

      const md5Result: cryptoFramework.DataBlob = await md.digest();
      const md5Bytes: Uint8Array = md5Result.data;

      // 转换为十六进制字符串
      const hexArray: string[] = [];
      for (let i = 0; i < md5Bytes.length; i++) {
        const hex: string = md5Bytes[i].toString(16);
        hexArray.push(hex.length === 1 ? '0' + hex : hex);
      }

      return hexArray.join('');
    } catch (error) {
      console.error('[BackupCrypto] Failed to calculate MD5:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 加密JSON对象
   * @param obj JSON对象
   * @param password 密码
   * @returns 加密结果
   */
  static async encryptObject(obj: ESObject, password: string): Promise<EncryptedData | null> {
    try {
      // 1. 转换为JSON字符串
      const jsonStr: string = JSON.stringify(obj);

      // 2. 转换为Uint8Array
      const data: Uint8Array = textEncoder.encodeInto(jsonStr);

      // 3. 加密
      return await BackupCrypto.encrypt(data, password);
    } catch (error) {
      console.error('[BackupCrypto] Failed to encrypt object:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 解密为JSON对象
   * @param encryptedData 加密数据
   * @param password 密码
   * @returns JSON对象
   */
  static async decryptToObject<T extends ESObject>(
    encryptedData: EncryptedData,
    password: string
  ): Promise<T | null> {
    try {
      // 1. 解密
      const decrypted = await BackupCrypto.decrypt(encryptedData, password);
      if (!decrypted) {
        return null;
      }

      // 2. 转换为字符串
      const jsonStr: string = textDecoder.decodeWithStream(new Uint8Array(decrypted), { stream: false });

      // 3. 解析为对象
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      console.error('[BackupCrypto] Failed to decrypt to object:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 辅助函数：读取文件
   */
  private static async readFile(filePath: string): Promise<ArrayBuffer> {
    const stat: fs.Stat = fs.statSync(filePath);
    const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);
    return buffer;
  }
}
