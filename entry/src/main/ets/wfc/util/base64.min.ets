import { util } from '@kit.ArkTS';

const c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

const base64Helper = new util.Base64Helper()

export function btoa(e: Uint8Array): string {
    return base64Helper.encodeToStringSync(e)
    // for (
    //     let t = 0, r = 0, o = String(e), n = 0, a = c, i = "";
    //     o.charAt(0 | n) || ((a = "="), n % 1);
    //     i += a.charAt(63 & (t >> (8 - (n % 1) * 8)))
    // ) {
    //     if (255 < (r = o.charCodeAt((n += 0.75))))
    //         throw new Error(
    //             "'btoa' failed: The string to be encoded contains characters outside of the Latin1 range."
    //         );
    //     t = (t << 8) | r;
    // }
    // return i;
}

export function atob(e: string): Uint8Array {
    return base64Helper.decodeSync(e)

    // var t = String(e).replace(/[=]+$/, "");
    // if (t.length % 4 == 1)
    //     throw new Error(
    //         "'atob' failed: The string to be decoded is not correctly encoded."
    //     );
    // for (
    //     var r, o, n = 0, a = 0, i = "";
    //     (o = t.charAt(a++));
    //     ~o && ((r = n % 4 ? 64 * r + o : o), n++ % 4)
    //         ? (i += String.fromCharCode(255 & (r >> ((-2 * n) & 6))))
    //         : 0
    // )
    //     o = c.indexOf(o);
    // return i;
}