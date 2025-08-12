import SwiftUI


struct ChatRoom: View {
	 let roomData: RoomStruct
	 @State private var newMessage: String = ""

	 @State private var model = chatRoomManager()

	 var body: some View {
			VStack {
				 ScrollView {
						LazyVStack(alignment: .leading, spacing: 8) {
							 ForEach(model.receivedMessages, id: \.self) { message in
									HStack {
//										 if message.sender  {
												Spacer()
												Text(message.message)
													 .padding()
													 .background(Color.blue.opacity(0.8))
													 .foregroundColor(.white)
													 .cornerRadius(12)
//										 } else {
//												Text(message.message)
//													 .padding()
//													 .background(Color.gray.opacity(0.2))
//													 .cornerRadius(12)
//												Spacer()
//										 }
									}
									.padding(.horizontal)
							 }
						}
				 }
						HStack {
							 TextField("Type a message...", text: $newMessage)
									.textFieldStyle(RoundedBorderTextFieldStyle())
									.padding(.vertical, 8)

							 Button("Send") {
									sendMessage()
							 }
							 .padding(.horizontal)
							 .buttonStyle(.borderedProminent)
						}
						.padding()
						.background(Color(UIColor.systemGray6))
			}
			.toolbar {
				 ToolbarItem(placement: .principal) {
						Text(roomData.roomName)
				 }
			}
			.onAppear {
				 model.fetchMessages(roomID: roomData.roomID)
			}
			.onAppear {
				 model.connect(roomID: roomData.roomID)
			}
			.onDisappear {
				 model.disconnect()
			}
	 }

	 private func sendMessage() {
			let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
			guard !trimmed.isEmpty else { return }

			model.send(text: trimmed, to: roomData.roomID)
			newMessage = ""
	 }
}

#Preview {
	 RoomList()
}
