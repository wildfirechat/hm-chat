export default class AppServerError extends Error {
    errorCode: number;

    constructor(errorCode: number, message: string) {
        super(message);
        this.errorCode = errorCode;
    }

    toString() {
        return this.errorCode + '-' + this.message;
    }
}
