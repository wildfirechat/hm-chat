export declare type FailCallback = (err: number) => void

export declare type SuccessCallback = () => void

export declare type CallbackWithValue_1<V> = (value: V) => void

export declare type CallbackWithValue_2<V1, V2> = (value1: V1, value2: V2) => void

export declare type FailCallbackOrNull = ((err: number) => void) | null

export declare type SuccessCallbackOrNull = (() => void) | null

export declare type CallbackWithValue_1_OrNull<V> = ((value: V) => void) | null

export declare type CallbackWithValue_2_OrNull<V1, V2> = ((value1: V1, value2: V2) => void) | null

export declare type numberArray = number[]

export declare type stringArray = string[]

export declare type JSONObject = Record<string, Object>

export declare type JSONArray = Record<string, Object>[]

export const SuccessCallbackDefault = () => {
}

export const FailCallbackDefault = (err: number) => {
    console.error('failed', err)
}

export const CallbackWithValue_1_Default = (v: Object) => {
}

export const CallbackWithValue_2_Default = (v: Object, v2: Object) => {
}
