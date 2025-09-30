import { FeedListPage } from './FeedListPage';
import { PostFeedPage } from './PostFeedPage';

export const MOMENT_NAV_DESTINATION_PREFIX = 'moment_'

export class momentNavigationDestinations {
    static FeedListPage = MOMENT_NAV_DESTINATION_PREFIX + 'feedListPage'
    static PostFeedPage = MOMENT_NAV_DESTINATION_PREFIX + 'postFeedPage'
}

@Builder
export function MomentPageMap(name: string) {
    if (name === momentNavigationDestinations.FeedListPage) {
        FeedListPage()
    } else if (name === momentNavigationDestinations.PostFeedPage) {
        PostFeedPage()
    }
    NavDestination() {
        Column() {
            Text('TODO Moment')
        }
        .width('100%')
        .height('100%')
    }
}
