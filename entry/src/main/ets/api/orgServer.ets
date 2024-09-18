// 引入包名
import http from '@ohos.net.http';
import data_preferences from '@ohos.data.preferences';
import wfc from 'marswrapper'
import Config from '../config';
import { GlobalContext } from '../globalContext';
import common from '@ohos.app.ability.common';
import url from '@ohos.url';
import GroupAnnouncement from './model/groupAnnouncement';
import AppServerError from './appServerError';
import OrgServerError from './orgServerError';
import Organization from './model/organization';
import OrganizationRelationShip from './model/organizationRelationShip';
import OrganizationEx from './model/organizationEx';
import Employee from './model/employee';
import EmployeeEx from './model/employeeEx';
import UserInfo from '../wfc/model/userInfo';

class OrgServer {
    baseUrl = Config.ORGANIZATION_SERVER;
    authToken = '';
    isServiceAvailable = false;

    constructor() {
        let context = GlobalContext.getContext().getObject<common.UIAbilityContext>('context');
        let preference = data_preferences.getPreferencesSync(context, {
            name: 'wfcstore'
        })
        let _url = url.URL.parseURL(this.baseUrl)
        this.authToken = preference.getSync(`authToken-${_url.host}-${_url.port}`, '') as string
    }

    login(): Promise<void> {
        return new Promise((resolve, reject) => {
            wfc.getAuthCode('admin', 2, '', (code: string) => {
                let path = '/api/user_login';
                this._post(path, {
                    'authCode': code
                } as Record<string, Object>)
                    .then((result: object) => {
                        resolve()
                    })
                    .catch((err: OrgServerError) => {
                        reject(err)
                    })
            }, (err: number) => {
                reject(new Error('getAuthCode error' + err))
            })
        })
    }

    async getRootOrganization(): Promise<Organization[]> {
        let result = await this._post('/api/organization/root');
        return result as Organization[]
    }

    async getRelationShip(employeeId: string): Promise<OrganizationRelationShip[]> {
        let result = await this._post('/api/relationship/employee', { 'employeeId': employeeId } as Record<string, string>);
        return result as OrganizationRelationShip[]
    }

    async getOrganizationEx(orgId: number): Promise<OrganizationEx> {
        let result = await this._post('/api/organization/query_ex', { 'id': orgId } as Record<string, Object>);
        return result as OrganizationEx
    }

    async getOrganizations(orgIds: number[]): Promise<Organization[]> {
        let result = await this._post('/api/organization/query_list', { 'ids': orgIds } as Record<string, Object>);
        return result as Organization[]
    }

    async getOrganizationEmployees(orgIds: number[]): Promise<Employee[]> {
        let employeeIds = await this._post('/api/organization/batch_employees', { 'ids': orgIds } as Record<string, Object>);
        return this.getEmployeeList(employeeIds as string[]);
    }

    async getOrgEmployees(orgId: number) {
        let employeeIds = await this._post('/api/organization/employees', { 'ids': [orgId] } as Record<string, Object>);
        return this.getEmployeeList(employeeIds as string[]);
    }

    async getEmployeeList(employeeIds: string[]): Promise<Employee[]> {
        let result = await this._post('/api/employee/query_list', { 'employeeIds': employeeIds } as Record<string, Object>)
        return result as Employee[]
    }

    async getEmployee(employeeId: string): Promise<Employee> {
        let result = await this._post('/api/employee/query', { 'employeeId': employeeId } as Record<string, Object>);
        return result as Employee;
    }

    async getEmployeeEx(employeeId: string): Promise<EmployeeEx> {
        let result = await this._post('/api/employee/query_ex', { 'employeeId': employeeId } as Record<string, Object>);
        return result as EmployeeEx;
    }

    async searchEmployee(orgId: number, keyword: string): Promise<Employee[]> {
        let result = await this._post('/api/employee/search', { 'organizationId': orgId, 'keyword': keyword } as Record<string, Object>);
        return result as Employee[]
    }

    async getOrganizationPath(orgId: number): Promise<Organization[]> {
        return (await this._getOrganizationPath(orgId)).reverse()
    }

    async _getOrganizationPath(orgId: number): Promise<Organization[]> {
        let pathList: Organization[] = [];
        let org = await this._getOrganizationSync(orgId);
        if (org) {
            pathList.push(org)
            if (org.parentId) {
                pathList.push(...await this._getOrganizationPath(org.parentId));
            }
            return pathList
        } else {
            return []
        }
    }

    async _getOrganizationSync(orgId: number): Promise<Organization | null> {
        let orgs = await this.getOrganizations([orgId])
        return orgs && orgs.length > 0 ? orgs[0] : null;
    }

    employeeToUserInfo(employee: Employee): UserInfo {
        let userInfo = new UserInfo();
        userInfo.uid = employee.employeeId;
        userInfo.name = employee.name;
        userInfo.displayName = employee.name;
        userInfo.portrait = employee.portraitUrl ? employee.portraitUrl : Config.DEFAULT_PORTRAIT_URL;
        userInfo.gender = employee.gender;
        userInfo.mobile = employee.mobile;
        userInfo.email = employee.email;
        userInfo.updateDt = employee.updateDt;
        //0 normal; 1 robot; 2 thing;
        userInfo.type = 1;
        userInfo.deleted = 0;
        return userInfo;
    }

    _post(path: string, data?: string | object): Promise<object> {
        return new Promise((resolve, reject) => {
            let httpRequest = http.createHttp();
            // 用于订阅HTTP响应头，此接口会比request请求先返回。可以根据业务需要订阅此消息
            // 从API 8开始，使用on('headersReceive', Callback)替代on('headerReceive', AsyncCallback)。 8+
            // httpRequest.on('headersReceive', (header) => {
            //     console.info('header: ' + JSON.stringify(header));
            // if (header.toString() === 'authToken') {
            //     this.authToken = header.toString();
            //         let context = GlobalContext.getContext().getObject<common.ApplicationContext>('applicationContext');
            //         let preference = data_preferences.getPreferencesSync(context, {
            //             name: 'wfcstore'
            //         })
            //         let _url = url.URL.parseURL(this.baseUrl)
            //         preference.put(`authToken-${_url.host}-${_url.port}`, this.authToken)
            // }
            // });
            console.log('request', path, data)
            httpRequest.request(// 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
                this.baseUrl + path,
                {
                    method: http.RequestMethod.POST, // 可选，默认为http.RequestMethod.GET
                    // 开发者根据自身业务需要添加header字段
                    header: {
                        'Content-Type': 'application/json',
                        'authToken': this.authToken
                    },
                    // 当使用POST请求时此字段用于传递内容
                    extraData: data,
                    expectDataType: http.HttpDataType.OBJECT, // 可选，指定返回数据的类型
                    usingCache: true, // 可选，默认为true
                    priority: 1, // 可选，默认为1
                    connectTimeout: 60000, // 可选，默认为60000ms
                    readTimeout: 60000, // 可选，默认为60000ms
                    usingProtocol: http.HttpProtocol.HTTP1_1, // 可选，协议类型默认值由系统自动指定
                }, (err, data) => {
                if (!err) {
                    // data.result为HTTP响应内容，可根据业务需要进行解析
                    console.info('Result:' + JSON.stringify(data.result));
                    console.info('code:' + JSON.stringify(data.responseCode));
                    // data.header为HTTP响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + JSON.stringify(data.cookies)); // 8+
                    // 取消订阅HTTP响应头事件
                    // httpRequest.off('headersReceive');
                    // 当该请求使用完毕时，调用destroy方法主动销毁
                    httpRequest.destroy();
                    console.log('response', data)
                    let result = data.result as Record<string, Object>
                    if (result.code === 0) {
                        // 30ba6ab2d4d249d4ab9114a02a9850fc
                        let authToken: string = data.header['authtoken']
                        if (!authToken) {
                            authToken = data.header['authToken']
                        }
                        if (authToken) {
                            this.authToken = authToken
                            let context = GlobalContext.getContext()
                                .getObject<common.ApplicationContext>('context');
                            let preference = data_preferences.getPreferencesSync(context, {
                                name: 'wfcstore'
                            })
                            let _url = url.URL.parseURL(this.baseUrl)
                            preference.putSync(`authToken-${_url.host}-${_url.port}`, this.authToken)
                        }
                        resolve(result.result)
                    } else {
                        reject(new OrgServerError(result.code as number, result.message as string))
                    }
                } else {
                    console.info('error:' + JSON.stringify(err));
                    // 取消订阅HTTP响应头事件
                    httpRequest.off('headersReceive');
                    // 当该请求使用完毕时，调用destroy方法主动销毁。
                    httpRequest.destroy();
                    console.error('err', err)
                    reject(new OrgServerError(-1, err.message))
                }
            }
            )
        })
    }
}

let self = new OrgServer();

export default self


