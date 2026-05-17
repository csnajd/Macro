import SwiftUI

struct WelcomView: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("هاي")
                .font(.largeTitle.bold())
            
            Spacer()
            
            Button("ابدأ", action: onGetStarted)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 48)
        }
    }
}
