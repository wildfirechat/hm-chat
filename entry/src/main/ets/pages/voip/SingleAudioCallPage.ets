@Entry
@Component
export default struct SingleAudioCallPage {
    build() {
        NavDestination() {
            Text('TODO')

        }
        .title('Voip Test')
        .backgroundColor(Color.Green)
        .expandSafeArea([SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
}