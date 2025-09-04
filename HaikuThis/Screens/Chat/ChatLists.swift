import SwiftUI

struct RoomList: View {
	 @State private var model = RoomListModel()
	 @EnvironmentObject var modelAuth: authModel
	 @State private var selectedRoom: RoomStruct?
	 @State private var addRoomToggle = false
	 @State private var isLoading = false

	 let sampleRooms: [RoomStruct] = [
			RoomStruct(roomID: "1", roomName: "General Chat", lastMessage: "Welcome everyone!", messageTime: "10:15 AM"),
			RoomStruct(roomID: "2", roomName: "iOS Developers", lastMessage: "Anyone tried Xcode 17 yet?", messageTime: "09:42 AM"),
			RoomStruct(roomID: "3", roomName: "SwiftUI Study Group", lastMessage: "Let’s meet tomorrow at 7 PM.", messageTime: "08:30 PM"),
			RoomStruct(roomID: "4", roomName: "Tennis Fans", lastMessage: "US Open final predictions?", messageTime: "06:12 PM"),
			RoomStruct(roomID: "5", roomName: "Friends", lastMessage: "See you this weekend 🍕", messageTime: "11:55 PM")
	 ]

	 var body: some View {
			NavigationStack {
				 ScrollView {
						HStack {
							 Text("Social")
									.font(
										 .system(size: 35, weight: .bold, design: .monospaced)
									)
									.foregroundColor(.black)
							 Spacer()
							 Text("Hello, Marisa!")
									.font(.system(size: 16, weight: .bold, design: .monospaced))
									.foregroundColor(.gray)
						}
						.padding(.horizontal)

						VStack {
							 VStack(spacing: 0) {
									ForEach(model.fetchedRooms) { room in
										 NavigationLink(value: room) {
												HStack {
													 VStack(alignment: .leading, spacing: 15) {
															HStack {
																 Text(room.roomName)
																		.font(.system(size: 17, weight: .semibold, design: .rounded))
																		.foregroundColor(.black)
																 Spacer()
																 Text(room.messageTime)
																		.font(.system(size: 13, weight: .regular, design: .monospaced))
																		.foregroundColor(.gray)
															}
															Text(room.lastMessage)
																 .font(
																		.system(
																			 size: 14,
																			 weight: .regular,
																			 design: .monospaced
																		)
																 )
																 .foregroundColor(.black.opacity(0.7))
													 }
													 .padding(.vertical, 12)
												}
												.padding(.horizontal)
												.background(Color.white.mix(with: .gray, by: 0.1))
										 }

										 if room != model.fetchedRooms.last {
												Divider()
													 .padding(.leading)
										 }
									}
							 }
							 .animation(.spring(), value: model.fetchedRooms)
							 .cornerRadius(10)
							 .padding(.horizontal)
						}
						.padding(.top, 10)
				 }
				 .background(Color.warmCream.mix(with: .yellow, by: 0.3).ignoresSafeArea())
				 .onAppear {
						guard let userID = modelAuth.userSession?.uid else {
							 print("userID is not here - fetching room")
							 return
						}
						withAnimation {
							 model.fetchRoomsUserID(userID: userID)
						}
				 }
				 .toolbar {
						ToolbarItem(placement: .navigationBarTrailing) {
							 Button {
									model.addRoomToggle.toggle()
							 } label: {
									Image(systemName: "plus")
										 .foregroundColor(.black)
							 }
						}
				 }
				 .sheet(isPresented: $model.addRoomToggle) {
						InfoBox(model: model, modelAuth: modelAuth) { room in
							 model.addRoomToggle.toggle()
							 isLoading = true
							 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
									isLoading = false
									selectedRoom = room
							 }
						}
						.presentationDetents([.height(210)])
						.presentationBackground(.clear)
				 }
				 .overlay {
						if isLoading {
							 Color.black.opacity(0.3)
									.ignoresSafeArea()
							 ProgressView("Creating room...")
									.padding()
									.background(Color.white)
									.cornerRadius(12)
						}
				 }
				 .navigationDestination(for: RoomStruct.self) { room in
						ChatRoom(roomData: room)
							 .toolbar(.hidden, for: .tabBar)
				 }
				 .navigationDestination(isPresented: Binding(
						get: { selectedRoom != nil },
						set: { if !$0 { selectedRoom = nil } }
				 )) {
						if let room = selectedRoom {
							 ChatRoom(roomData: room)
									.toolbar(.hidden, for: .tabBar)
						}
				 }
			}
	 }
}


struct InfoBox: View {
	 var model: RoomListModel
	 var modelAuth: authModel
	 var onRoomSelected: (RoomStruct) -> Void
	 @State private var roomName: String = ""
	 @State private var joinRoomID: String = ""
	 @State private var animate = false
	 @State private var joinErrorMessage: String? = nil
	 @State private var showJoinErrorAlert = false
	 

	 var body: some View {
			VStack(spacing: 20) {

				 TextFieldCreateRoom(
						text: $roomName,
						placeholder: "Write your room's name here",
						buttonTitle: "Create"
				 ) {
						guard let userID = modelAuth.userSession?.uid else {
							 print("userID is not here")
							 return
						}
						guard !roomName.isEmpty else { return }
						let formatter = DateFormatter()
						formatter.dateFormat = "h:mm a"
						formatter.amSymbol = "AM"
						formatter.pmSymbol = "PM"
						let messageTime = formatter.string(from: Date())
						let lastMessage = "Send a chat message!"
						let newRoomID = generateRoomID()

						let newRoom = RoomStruct(roomID: newRoomID, roomName: roomName, lastMessage: lastMessage, messageTime: messageTime)
						model.createRoom(roomName: roomName, roomID: newRoomID, userID: userID)

						withAnimation(.easeInOut(duration: 1)) {
							 onRoomSelected(newRoom)
							 model.fetchedRooms.append(newRoom)
						}
				 }
				 .padding(.horizontal, 20)

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
				 .padding(.horizontal)
				 .padding(.vertical, -10)

				 TextFieldJoinRoom(
						text: $joinRoomID,
						placeholder: "Write your room's ID here",
						buttonTitle: "Join"
				 ) {
						guard !joinRoomID.isEmpty else { return }

						guard let userID = modelAuth.userSession?.uid else {
							 print("userID is not here")
							 return
						}

						model.joinRoom(roomID: joinRoomID, userID: userID) { result in
							 switch result {
									case .success(let joinedRoom):
										 withAnimation(.easeInOut(duration: 1)) {
												onRoomSelected(joinedRoom)
												model.fetchedRooms.append(joinedRoom)
										 }
									case .failure(let error):
										 joinErrorMessage = error.localizedDescription
										 showJoinErrorAlert = true
							 }
						}
				 }
				 .padding(.horizontal, 20)
				 .alert("Error Joining Room", isPresented: $showJoinErrorAlert, actions: {
						Button("OK", role: .cancel) { }
				 }, message: {
						Text(joinErrorMessage ?? "Unknown error")
				 })
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.frame(height: safeArea.bottom == .zero ? 395 : 165)
			.background(.white)
			.clipShape(.rect(cornerRadius: 30))
			.padding(.horizontal, 15)
	 }

	 var safeArea: UIEdgeInsets {
			if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
				 .keyWindow?.safeAreaInsets {
				 return safeArea
			}
			return .zero
	 }

	 private func generateRoomID() -> String {
			let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
			return String((0..<6).compactMap { _ in chars.randomElement() })
	 }
}



struct TextFieldCreateRoom: View {
	 @Binding var text: String
	 var placeholder: String
	 var buttonTitle: String
	 var action: () -> Void

	 @State private var isTooLong = false

	 var body: some View {
			VStack(alignment: .leading, spacing: 4) {
				 HStack(spacing: 10) {
						TextField("", text: $text, prompt: Text(isTooLong ? "Max 15 characters!" : placeholder)
							 .font(.caption)
							 .foregroundColor(isTooLong ? .red : .gray))
						.textFieldStyle(PlainTextFieldStyle())
						.padding(8)
						.foregroundStyle(.black)
						.background(Color.gray.opacity(0.1))
						.cornerRadius(8)
						.onChange(of: text) { oldValue, newValue in
							 if newValue.count > 15 {
									text = oldValue
									isTooLong = true
							 } else {
									isTooLong = false
									text = newValue
							 }
						}

						Button(action: action) {
							 Text(buttonTitle)
									.foregroundStyle(.gray)
									.font(.callout)
									.padding(.horizontal, 11)
									.padding(.vertical, 6)
									.background(Color.yellow.opacity(0.2))
									.cornerRadius(8)
						}
				 }

				 if isTooLong {
						Text("Maximum 15 characters allowed.")
							 .font(.caption)
							 .foregroundColor(.red)
				 }
			}
	 }
}

struct TextFieldJoinRoom: View {
	 @Binding var text: String
	 var placeholder: String
	 var buttonTitle: String
	 var action: () -> Void

	 @State private var isTooLong = false

	 var body: some View {
			VStack(alignment: .leading, spacing: 4) {
				 HStack(spacing: 10) {
						TextField("RoomID", text: $text, prompt: Text(isTooLong ? "Max 6 characters!" : placeholder)
							 .font(.caption)
							 .foregroundColor(isTooLong ? .red : .gray))
						.textFieldStyle(PlainTextFieldStyle())
						.padding(8)
						.foregroundStyle(.black)
						.background(Color.gray.opacity(0.1))
						.cornerRadius(8)
						.onChange(of: text) { oldValue, newValue in
							 let uppercased = newValue.uppercased()
							 if uppercased.count > 6 {
									text = oldValue
									isTooLong = true
							 } else {
									isTooLong = false
									text = uppercased
							 }
						}

						Button(action: action) {
							 Text(buttonTitle)
									.foregroundStyle(.gray)
									.font(.callout)
									.padding(.horizontal, 20)
									.padding(.vertical, 6)
									.background(Color.yellow.opacity(0.2))
									.cornerRadius(8)
						}
				 }

				 if isTooLong {
						Text("Maximum 15 characters allowed.")
							 .font(.caption)
							 .foregroundColor(.red)
				 }
			}
	 }
}



#Preview {
	 RoomList()
			.environmentObject(authModel())
}
