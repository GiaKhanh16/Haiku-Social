import SwiftUI
import AuthenticationServices

struct IntroScreen: View {
	 @AppStorage("isFirstTime") private var isFirstTime: Bool = true
	 @EnvironmentObject var auth: authModel

	 var body: some View {
			VStack(spacing: 15) {
				 Text("Welcome to the\nHaiku Debate")
						.font(.largeTitle.bold())
						.multilineTextAlignment(.center)
						.padding(.top, 45)
						.padding(.bottom, 35)

						/// Points View
				 VStack(alignment: .leading, spacing: 25, content: {
						PointView(symbol: "newspaper", title: "Haiku News Feed", subTitle: "Debate and troll and critique any topics in Haiku format")

						PointView(symbol: "chart.bar.fill", title: "Chat Room", subTitle: "Haiku Chat with your group or friends about things.")

				 })
				 .frame(maxWidth: .infinity, alignment: .leading)
				 .padding(.horizontal, 15)

				 Spacer(minLength: 10)

				 

				 LoginButtons()

			}
			.background(.white)
	 }

			/// Point View
	 @ViewBuilder
	 func PointView(symbol: String, title: String, subTitle: String) -> some View {
			HStack(spacing: 20) {
				 Image(systemName: symbol)
						.font(.largeTitle)
						.foregroundStyle(.blue.gradient)
						.frame(width: 45)

				 VStack(alignment: .leading, spacing: 6, content: {
						Text(title)
							 .font(.title3)
							 .fontWeight(.semibold)

						Text(subTitle)
							 .font(.callout)
							 .foregroundStyle(.gray)
				 })
			}
	 }

	 @ViewBuilder
	 func LoginButtons() -> some View {
			VStack(spacing: 12) {
				 SignInWithAppleButton(.signIn) { request in

						let nonce = auth.randomNonceString()
						auth.nonce = nonce
						request.requestedScopes = [.email, .fullName]
						request.nonce = auth.sha256(auth.nonce!)

				 } onCompletion: { result in
						switch result {
							 case .success(let authorization):
									auth.loginWithApple(authorization)
							 case .failure(let error):
									print(error)
						}
				 }
				 .frame(maxHeight: 50)
				 .signInWithAppleButtonStyle(.whiteOutline)

				 HStack {
						VStack {
							 Divider()
									.background(Color.white)
						}
						Text("or")
							 .foregroundColor(.gray)
						VStack {
							 Divider()
									.background(Color.white)
						}
				 }
				 Button {
						Task {
							 try await auth.signInGoogle()
						}
				 } label: {
						Label("Sign Up With Google", systemImage: "envelope.fill")
							 .foregroundStyle(.white)
							 .fillButton(.buton)
				 }
			}
			.padding(15)
	 }
}
extension View {
	 @ViewBuilder
	 func fillButton(_ color: Color) -> some View {
			self
				 .fontWeight(.bold)
				 .frame(maxWidth: .infinity)
				 .padding(.vertical, 15)
				 .background(color, in: .rect(cornerRadius: 15))
	 }
}

#Preview {
	 IntroScreen()
}
