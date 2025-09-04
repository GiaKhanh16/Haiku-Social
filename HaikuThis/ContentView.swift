import SwiftUI

struct ContentView: View {
	 @EnvironmentObject var model: authModel

	 var body: some View {
			Group {
				 if (model.userSession != nil) {
						TabScreen()
				 } else {
						IntroScreen()
				 }
			}
			.animation(.easeInOut(duration: 0.6), value: model.userSession)
	 }
}
