import Employee from './employee';
import Organization from './organization';

export default class OrganizationEx {
    organizationId = 0;
    organization?: Organization;
    subOrganizations?: Organization[] = [];
    employees: Employee[] = [];
}