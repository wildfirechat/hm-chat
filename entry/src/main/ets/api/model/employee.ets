import Config from '../../config';
import UserInfo from '../../wfc/model/userInfo';

export default class Employee {
    employeeId = '';
    organizationId = 0;
    name = '';
    title = '';
    level = 0;
    mobile = '';
    email = '';
    ext = '';
    office = '';
    city = '';
    portraitUrl = '';
    jobNumber = '';
    joinTime = '';
    type = 0;
    gender = 0;
    sort = 0;
    createDt = 0;
    updateDt = 0;

    public static toUserInfo(employee: Employee): UserInfo {
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
}