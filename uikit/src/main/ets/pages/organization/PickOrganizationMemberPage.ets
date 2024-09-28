import Employee from '../../api/model/employee';
import Organization from '../../api/model/organization';
import OrganizationEx from '../../api/model/organizationEx';
import orgServer from '../../api/orgServer';
import { router } from '@kit.ArkUI';

@Entry
@Component
export default struct PickOrganizationMemberPage{
    @Consume('mainNavPathStack') mainNavPathStack: NavPathStack;
    @State title: string = '组织结构'
    @State curOrganization?: Organization = undefined
    @State organizationEx?: OrganizationEx = undefined
    @State subOrganizations?: Organization[] = []
    @State employees?: Employee[] = []
    @State orgPath: Organization[] = [];
    private scroller: Scroller = new Scroller()
    @State checkedEmployees: Employee[] = []
    @State checkedOrganizations: Organization[] = []
    public static PICK_RESULT = 'pickOrganizationMemberResult';

    aboutToAppear() {
        // let params = this.mainNavPathStack.getParamByIndex(this.mainNavPathStack.size() - 1) as Record<string, Object>;
        let params = router.getParams() as Record<string, Object>
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
        this.scroller.scrollEdge(Edge.End)
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

    isOrganizationChecked(org: Organization) {
        return this.checkedOrganizations.findIndex(checkedOrg => org.id === checkedOrg.id) >= 0
    }

    isEmployeeChecked(employee: Employee) {
        let index = this.checkedEmployees.findIndex(e => e.employeeId === employee.employeeId)
        if (index >= 0) {
            return true;
        } else {
            let orgId = employee.organizationId;
            index = this.checkedOrganizations.findIndex(org => orgId === org.id);
            return index >= 0
        }
    }

    build() {
        NavDestination() {
            Column() {
                Scroll(this.scroller) {
                    Row() {
                        ForEach(this.orgPath, (org: Organization, index: number) => {
                            Text(org.name)
                                .fontColor(index === this.orgPath.length - 1 ? '#3B62E0' : '#485666')
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
                                    Checkbox()
                                        .select(this.checkedOrganizations.findIndex(checkedOrg => org.id === checkedOrg.id) >= 0)
                                        .onChange((value: boolean) => {
                                            // do nothing
                                        })
                                        .responseRegion({
                                            x: 0,
                                            y: 0,
                                            width: 0,
                                            height: 0
                                        })
                                    Image($r('app.media.ic_deparment'))
                                        .width(40)
                                        .height(40)
                                        .borderRadius(4)
                                    Text(org.name + `(${org.memberCount})`)
                                        .maxLines(1)
                                        .padding({ left: 10 })
                                    Blank()
                                    Text('下级')
                                        .enabled(!this.isOrganizationChecked(org))
                                        .fontColor('#3B62E0')
                                        .visibility(this.isOrganizationChecked(org) ? Visibility.None : Visibility.Visible)
                                        .onClick((event: ClickEvent) => {
                                            this.onClickOrg(org)
                                        })
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
                                    let i = this.checkedOrganizations.findIndex(checkedOrg => checkedOrg.id === org.id)
                                    if (i >= 0) {
                                        this.checkedOrganizations.splice(i, 1);
                                    } else {
                                        this.checkedOrganizations.push(org)
                                    }
                                })
                            }
                        }, (org: Organization, index: number) => org.id + 'o')

                        ForEach(this.employees, (employee: Employee, index: number) => {
                            ListItem() {
                                Row() {
                                    Checkbox()
                                        .select(this.isEmployeeChecked(employee))
                                        .onChange((value: boolean) => {
                                            // do nothing
                                        })
                                        .responseRegion({
                                            x: 0,
                                            y: 0,
                                            width: 0,
                                            height: 0
                                        })
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
                                    let i = this.checkedEmployees.findIndex(checkedEmployee => checkedEmployee.employeeId === employee.employeeId)
                                    if (i >= 0) {
                                        this.checkedEmployees.splice(i, 1);
                                    } else {
                                        this.checkedEmployees.push(employee)
                                    }
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
        .menus(this.NavigationMenus)
    }

    @Builder
    NavigationMenus() {
        Row() {
            Button('确定')
                .type(ButtonType.Normal)
                .height(30)
                .width(60)
                .margin({ right: 18 })
                .enabled(this.checkedEmployees.length > 0 || this.checkedOrganizations.length > 0)
                .fontSize(14)
                .borderRadius(4)// .backgroundColor(Color.Blue)
                .onClick(() => {
                    LocalStorage.getShared()
                        .setOrCreate<PickOrganizationMemberResult>(PickOrganizationMemberPage.PICK_RESULT, {
                            employees: this.checkedEmployees,
                            organizations: this.checkedOrganizations,
                        });
                })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
    }
}

export interface PickOrganizationMemberResult {
    employees: Employee[]
    organizations: Organization[]
}
