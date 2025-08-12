import SwiftUI

struct RoomList: View {
	 @State private var model = RoomListModel()
	 @EnvironmentObject var modelAuth: authModel
	 @State private var selectedRoom: RoomStruct?
	 @State private var addRoomToggle = false
	 @State private var isLoading = false

	 var body: some View {
			NavigationStack {
				 List(model.fetchedRooms) { room in
						NavigationLink(value: room) {
							 Text(room.roomName)
						}
				 }
				 .navigationTitle("Chat Rooms")
				 .toolbar {
						ToolbarItem(placement: .navigationBarTrailing) {
							 Button {
									model.addRoomToggle.toggle()
							 } label: {
									Image(systemName: "plus")
							 }
						}
				 }
				 .onAppear {
						guard let userID = modelAuth.userSession?.uid else {
							 print("userID is not here - fetching room")
							 return
						}
						withAnimation {
							 model.fetchRoomsUserID(userID: userID)
						}
				 }
				 .sheet(isPresented: $model.addRoomToggle) {
						InfoBox(model: model, modelAuth: modelAuth) { room in

							 withAnimation(.easeInOut(duration: 1)) {
									model.addRoomToggle.toggle()
							 }
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
				 }
				 .navigationDestination(isPresented: Binding(
						get: { selectedRoom != nil },
						set: { if !$0 { selectedRoom = nil } }
				 )) {
						if let room = selectedRoom {
							 ChatRoom(roomData: room)
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

						let newRoomID = generateRoomID()
						let newRoom = RoomStruct(roomID: newRoomID, roomName: roomName)
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
									.font(.callout)
									.padding(.horizontal, 10)
									.padding(.vertical, 6)
									.background(Color.blue.opacity(0.2))
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
									.font(.callout)
									.padding(.horizontal, 10)
									.padding(.vertical, 6)
									.background(Color.blue.opacity(0.2))
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
