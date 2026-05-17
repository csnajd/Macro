import SwiftUI

struct MainContainerView: View {
    var body: some View {
        TabView {
            Text("الرئيسية")
                .tabItem {
                    Label("الرئيسية", systemImage: "house.fill")
                }
            Text("المحفظة")
                .tabItem {
                    Label("المحفظة", systemImage: "chart.pie.fill")
                }
        }
    }
}
