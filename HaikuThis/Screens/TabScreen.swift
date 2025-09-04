import SwiftUI



struct TabScreen: View {
	 var body: some View {
			TabView {
				 RoomList()
						.tabItem {
							 Image(systemName: "sailboat")
							 Text("Boat")
						}

				 SimpleView()
						.tabItem {
							 Image(systemName: "wind")
							 Text("Wind")
						}
			}
	 }
}


struct SimpleView: View {
	 var body: some View {
			VStack(spacing: 20) {
				 Text("Hello, SwiftUI!")
						.font(.largeTitle)
						.fontWeight(.bold)

				 Text("This is a simple view")
						.foregroundColor(.gray)

				 Button(action: {
						print("Button tapped!")
				 }) {
						Text("Tap Me")
							 .padding()
							 .background(Color.blue)
							 .foregroundColor(.white)
							 .cornerRadius(10)
				 }
			}
			.padding()
	 }
}

#Preview {
//	 CustomizationTabView()
}


