export default class OrgServerError extends Error {
    errorCode: number;

    constructor(errorCode: number, message: string) {
        super(message);
        this.errorCode = errorCode;
    }

    toString() {
        return this.errorCode + '-' + this.message;
    }
}
