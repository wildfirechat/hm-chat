export default function assign(target: Object, ...source: Object[]): Object {
    let nt = target as Record<string, Object>
    for (const items of source) {
        for (const key of Object.keys(items)) {
            nt[key] = Reflect.get(items, key)
        }
    }
    return nt;
}