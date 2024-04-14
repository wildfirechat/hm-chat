/**
 * 多媒体数据类
 */
export default interface MediaBean {
    /**
     * 文件名称
     */
    fileName: string;

    /**
     * 文件大小
     */
    fileSize: number;

    /**
     * 文件类型
     */
    fileType: string;

    /**
     * 本地存储地址
     */
    localUrl: string;
}