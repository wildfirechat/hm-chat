import Employee from '../../api/model/employee';
import Organization from '../../api/model/organization';
import OrganizationEx from '../../api/model/organizationEx';
import orgServer from '../../api/orgServer';
import { showToast } from '../../common/utils/Toast';
import { navigationDestinations } from '../navigationConfig';

@Entry
@Component
export default struct OrganizationTreePage {
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State title: string = '组织结构'
    @State curOrganization?: Organization = undefined
    @State organizationEx?: OrganizationEx = undefined
    @State subOrganizations?: Organization[] = []
    @State employees?: Employee[] = []
    @State orgPath: Organization[] = [];
    private scroller: Scroller = new Scroller()

    aboutToAppear() {
        let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        this.curOrganization = params['organization'] as Organization
        this.title = this.curOrganization.name;
        if (this.curOrganization.parentId) {
            this.loadOrganizationPath(this.curOrganization.id)
        } else {
            this.orgPath = [this.curOrganization]
            setTimeout(() => {
                this.scroller.scrollEdge(Edge.End)
            })
        }
        this.loadOrganizationMembers(this.curOrganization.id)
    }

    async loadOrganizationPath(orgId: number) {
        this.orgPath = await orgServer.getOrganizationPath(orgId)
        setTimeout(() => {
            this.scroller.scrollEdge(Edge.End)
        }, 100)
    }

    async loadOrganizationMembers(orgId: number) {
        let orgEx = await orgServer.getOrganizationEx(orgId)
        this.subOrganizations = orgEx.subOrganizations;
        this.employees = orgEx.employees;

        this.scroller.scrollEdge(Edge.End)
    }

    onClickOrg(org: Organization) {
        this.curOrganization = org;
        let index = this.orgPath.findIndex(item => item.id === org.id)
        if (index >= 0) {
            this.orgPath = this.orgPath.slice(0, index + 1)
        } else {
            this.orgPath.push(org)
        }
        this.curOrganization = org;
        this.loadOrganizationMembers(org.id)
    }

    build() {
        NavDestination() {
            Column() {
                Scroll(this.scroller) {
                    Row() {
                        ForEach(this.orgPath, (org: Organization, index: number) => {
                            Text(org.name)
                                .fontColor(index === this.orgPath.length - 1 ? '#485666' : '#3B62E0')
                                .onClick(() => {
                                    if (index < this.orgPath.length - 1) {
                                        this.onClickOrg(this.orgPath[index])
                                    }
                                })
                            if (index != this.orgPath.length - 1) {
                                Text(' > ')
                            }
                        }, (org: Organization, index: number) => index + '')
                    }
                    .padding({ left: 10, right: 10 })
                    .justifyContent(FlexAlign.Start)
                }
                .align(Alignment.Start)
                .scrollBar(BarState.Off)
                .scrollable(ScrollDirection.Horizontal)
                .direction(Direction.Ltr)
                .height('40')
                .width('100%')

                Column() {
                    List() {
                        ForEach(this.subOrganizations, (org: Organization, index: number) => {
                            ListItem() {
                                Row() {
                                    Image($r('app.media.ic_deparment'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text(org.name + `(${org.memberCount})`)
                                        .maxLines(1)
                                        .padding({ left: 10 })
                                }
                                .height(60)
                                .width('100%')
                                .padding({ left: 10, right: 10 })
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                                .onClick(() => {
                                    this.onClickOrg(org)
                                })
                            }
                        }, (org: Organization, index: number) => org.id + 'o')

                        ForEach(this.employees, (employee: Employee, index: number) => {
                            ListItem() {
                                Row() {
                                    Image(employee.portraitUrl)
                                        .alt($r('app.media.avatar_def'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text(employee.name)
                                        .maxLines(1)
                                        .padding({ left: 10 })
                                }
                                .height(60)
                                .width('100%')
                                .padding({ left: 10, right: 10 })
                                .stateStyles({
                                    pressed: {
                                        .backgroundColor('#E5E5E5')
                                    },
                                    normal: {
                                        .backgroundColor(Color.White)
                                    }
                                })
                                .onClick(() => {
                                    this.mainNavPathStack.pushPathByName(navigationDestinations.UserInfoPage, { 'userInfo': orgServer.employeeToUserInfo(employee) } as Record<string, Object>)
                                })
                            }
                        },
                            (employee: Employee, index: number) => employee.employeeId)
                    }
                    .width('100%')
                    .height('100%')
                }
                .layoutWeight(1)
                .backgroundColor(Color.White)
            }
        }
        .title(this.title)
        .height('100%')
        .width('100%')
    }
}
