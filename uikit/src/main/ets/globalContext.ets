export class GlobalContext {
    private constructor() {
    }

    private static instance: GlobalContext;
    private _objects = new Map<string, Object>();

    public static getContext(): GlobalContext {
        if (!GlobalContext.instance) {
            GlobalContext.instance = new GlobalContext();
        }
        return GlobalContext.instance;
    }

    getObject<T>(value: string): T | undefined {
        return this._objects.get(value) as T;
    }

    setObject(key: string, objectClass: Object): void {
        this._objects.set(key, objectClass);
    }
}