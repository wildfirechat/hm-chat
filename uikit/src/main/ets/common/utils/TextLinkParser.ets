export interface TextSegment {
    text: string;
    isUrl: boolean;
}

export function parseTextLinks(text: string): TextSegment[] {
    const urlRegex = new RegExp('((?:[a-zA-Z][a-zA-Z0-9+.-]*://|mailto:|tel:|sms:|store:|www\\.)[^\\s]+)', 'g');
    const segments: TextSegment[] = [];
    let lastIndex = 0;
    let match = urlRegex.exec(text);

    while (match !== null) {
        if (match.index > lastIndex) {
            segments.push({ text: text.substring(lastIndex, match.index), isUrl: false });
        }
        segments.push({ text: match[0], isUrl: true });
        lastIndex = match.index + match[0].length;
        match = urlRegex.exec(text);
    }

    if (lastIndex < text.length) {
        segments.push({ text: text.substring(lastIndex), isUrl: false });
    }

    return segments;
}

export function normalizeUrl(url: string): string {
    if (new RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:').test(url)) {
        return url;
    }
    return 'http://' + url;
}

export function isHttpUrl(url: string): boolean {
    return url.startsWith('http://') || url.startsWith('https://');
}
