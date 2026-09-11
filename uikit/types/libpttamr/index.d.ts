/*
 * Copyright (c) 2026 WildFireChat. All rights reserved.
 */

/**
 * libpttamr.so 的类型声明。
 *
 * libpttamr.so（opencore-amrnb）打包在对讲 SDK uikit/libs/ptt.har 里，随 ptt.har 一起打进 HAP，这里只声明语音输入用到的编码接口，
 * 和 hm-ptt 项目 ptt/src/main/cpp/types/libpttamr/index.d.ts 保持一致。
 */

/**
 * 创建一个 AMR-NB 编码器，返回编码器句柄；返回 0 表示创建失败。
 */
export const encoderInit: () => number;
/**
 * 释放编码器
 */
export const encoderRelease: (handle: number) => void;
/**
 * 编码 PCM 数据。
 * @param handle 编码器句柄
 * @param pcm 8000Hz、单声道、S16LE 的 PCM 数据，长度需要是 320 字节（20ms）的整数倍，不足一帧的尾部会被忽略
 * @param mode AMR-NB 编码模式，参考 opencore 的 Mode 枚举，默认 7（MR122，12.2kbps）
 * @returns 首尾相接的 AMR 帧（存储格式，每帧以 TOC 字节开头）
 */
export const encode: (handle: number, pcm: ArrayBuffer, mode?: number) => ArrayBuffer;
