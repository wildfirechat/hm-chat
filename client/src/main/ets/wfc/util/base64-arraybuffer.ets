const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const charsArr = chars.split('')

// Use a lookup table to find the index.
const lookup = typeof Uint8Array === 'undefined' ? [] : new Uint8Array(256);
for (let i = 0; i < chars.length; i++) {
    lookup[chars.charCodeAt(i)] = i;
}

export const encode = (arraybuffer: ArrayBuffer): string => {
    let bytes = new Uint8Array(arraybuffer),
        i:number,
        len = bytes.length,
        base64 = '';

    for (i = 0; i < len; i += 3) {
        base64 += charsArr[bytes[i] >> 2];
        base64 += charsArr[((bytes[i] & 3) << 4) | (bytes[i + 1] >> 4)];
        base64 += charsArr[((bytes[i + 1] & 15) << 2) | (bytes[i + 2] >> 6)];
        base64 += charsArr[bytes[i + 2] & 63];
    }

    if (len % 3 === 2) {
        base64 = base64.substring(0, base64.length - 1) + '=';
    } else if (len % 3 === 1) {
        base64 = base64.substring(0, base64.length - 2) + '==';
    }

    return base64;
};

export const decode = (base64: string): ArrayBuffer => {
    let bufferLength = base64.length * 0.75,
        len = base64.length,
        i:number,
        p = 0,
        encoded1:number,
        encoded2:number,
        encoded3:number,
        encoded4:number;

    if (base64[base64.length - 1] === '=') {
        bufferLength--;
        if (base64[base64.length - 2] === '=') {
            bufferLength--;
        }
    }

    const arraybuffer = new ArrayBuffer(bufferLength),
        bytes = new Uint8Array(arraybuffer);

    for (i = 0; i < len; i += 4) {
        encoded1 = lookup[base64.charCodeAt(i)];
        encoded2 = lookup[base64.charCodeAt(i + 1)];
        encoded3 = lookup[base64.charCodeAt(i + 2)];
        encoded4 = lookup[base64.charCodeAt(i + 3)];

        bytes[p++] = (encoded1 << 2) | (encoded2 >> 4);
        bytes[p++] = ((encoded2 & 15) << 4) | (encoded3 >> 2);
        bytes[p++] = ((encoded3 & 3) << 6) | (encoded4 & 63);
    }

    return arraybuffer;
};