import SwiftUI
import FirebaseCore
import FirebaseAuth


struct ChatRoom: View {
	 let roomData: RoomStruct
	 @State private var inputText: String = ""
	 @EnvironmentObject var modelAuth: authModel
	 @State private var model = ChatRoomManager()
	 @State private var currentLineIndex: Int = 0
	 @FocusState private var isTextFieldFocused: Bool
	 @State private var scrollToBottomTrigger = UUID()

	 var body: some View {
			VStack {
				 ScrollViewReader { proxy in
						ScrollView(.vertical, showsIndicators: false) { 
							 ForEach(model.receivedMessages) { message in
									HStack {
										 if message.userID == Auth.auth().currentUser?.uid {
												Spacer()
												Text(message.message ?? "")
													 .padding()
													 .background(Color.blue.opacity(0.8))
													 .foregroundColor(.white)
													 .cornerRadius(12)
													 .frame(maxWidth: 250, alignment: .trailing)
										 } else {
												VStack(alignment: .leading, spacing: 2) {
													 Text(message.username ?? "Unknown")
															.font(.caption)
															.foregroundColor(.gray)
													 Text(message.message ?? "")
															.padding()
															.background(Color.gray.opacity(0.2))
															.foregroundColor(.black)
															.cornerRadius(12)
															.frame(maxWidth: 250, alignment: .leading)
												}
												Spacer()
										 }
									}
							 }
							 Color.clear
									.frame(height: 1)
									.id(scrollToBottomTrigger)
						}
						.onChange(of: inputText) { _, _ in
							 withAnimation {
									proxy.scrollTo(scrollToBottomTrigger, anchor: .bottom)
							 }
						}
						.onChange(of: isTextFieldFocused) { _, focused in
							 if focused {
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
										 withAnimation {
												proxy.scrollTo(scrollToBottomTrigger, anchor: .bottom)
										 }
									}
							 }
						}
						.onAppear {
							 DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
									withAnimation {
										 proxy.scrollTo(scrollToBottomTrigger, anchor: .bottom)
									}
							 }
						}
				 }

			}
			.padding(.horizontal)
			.contentShape(Rectangle())
			.onTapGesture {
				 isTextFieldFocused = false
			}
			.safeAreaInset(edge: .bottom) {
				 chatInputArea
						.ignoresSafeArea(.keyboard, edges: .bottom)
			}
			.toolbar {
				 ToolbarItem(placement: .principal) {
						Text(roomData.roomID)
				 }
			}
			.onAppear {
				 model.fetchMessages(roomID: roomData.roomID)
				 if let currentUser = Auth.auth().currentUser {
						model.connect(userID: currentUser.uid, roomID: roomData.roomID)
				 } else {
						model.connect(userID: "guest", roomID: roomData.roomID)
				 }
			}
			.onDisappear {
				 model.disconnect()
			}
	 }


	 private var chatInputArea: some View {
			ZStack {
				 Color(.systemBackground)
						.ignoresSafeArea()
						.clipShape(.rect(topLeadingRadius: 60, topTrailingRadius: 60))

				 VStack {
						HStack {
							 TextField("Text", text: $inputText, axis: .vertical)
									.foregroundColor(.black)
									.lineLimit(4)
									.frame(maxWidth: .infinity, alignment: .leading)
									.padding([.top, .horizontal])
									.font(.system(size: 16))
									.focused($isTextFieldFocused)
									.onChange(of: inputText) { _, newValue in
										 let lines = newValue.split(separator: "\n", omittingEmptySubsequences: false)
										 if lines.count > 4 {
												inputText = lines.prefix(4).joined(separator: "\n")
										 }
										 if lines.count >= 4 && newValue.last == "\n" {
												inputText = String(newValue.dropLast())
										 }
												// Update current line index based on the number of lines
										 currentLineIndex = min(lines.count - 1, 2)
									}

							 Spacer()
							 Text("\(syllableCountForCurrentLine())")
									.font(.caption)
									.padding(.trailing)
						}

						HStack {
							 Image(systemName: "5.lane")
									.font(.title2)
									.foregroundStyle(countSyllables(firstLine()) == 5 ? .blue.mix(with: .green, by: 0.5) : .primary)
									.if(countSyllables(firstLine()) != 5) {
										 $0.symbolEffect(.wiggle, options: .repeat(.periodic(delay: 0.5)))
									}

							 Image(systemName: "7.lane")
									.font(.title2)
									.foregroundStyle(countSyllables(secondLine()) == 7 ? .blue.mix(with: .green, by: 0.5) : .primary)
									.if(countSyllables(secondLine()) != 7) {
										 $0.symbolEffect(.wiggle, options: .repeat(.periodic(delay: 0.5)))
									}

							 Image(systemName: "5.lane")
									.font(.title2)
									.foregroundStyle(countSyllables(thirdLine()) == 5 ? .blue.mix(with: .green, by: 0.5) : .primary)
									.if(countSyllables(thirdLine()) != 5) {
										 $0.symbolEffect(.wiggle, options: .repeat(.periodic(delay: 0.5)))
									}

							 Spacer()

							 Button {
									sendMessage()
									isTextFieldFocused = false
							 } label: {
									Text("Send")
										 .font(.caption)
										 .foregroundStyle(.black)
										 .padding(.horizontal, 9)
										 .padding(.vertical, 9)
										 .background(.gray.opacity(0.3))
										 .cornerRadius(10)
										 .padding(.bottom, 2)
							 }
						}
						.padding(.horizontal)
						.padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
				 }
				 .padding(5)
				 .background(.ultraThinMaterial)
				 .clipShape(.rect(cornerRadius: 30))
				 .padding([.horizontal])
				 .padding(.top, -50)
			}
			.offset(y: isTextFieldFocused ? 20 : 40)
			.animation(.easeInOut(duration: 0.3), value: isTextFieldFocused)
			.frame(height: 130)
	 }

	 private func sendMessage() {
			let trimmed = inputText.trimmingCharacters(in: .whitespaces)
			guard !trimmed.isEmpty else { return }

			if let currentUser = Auth.auth().currentUser {
				 model.send(
						text: trimmed,
						to: roomData.roomID,
						userID: currentUser.uid
				 )
			} else {
				 guard let currentUser = Auth.auth().currentUser else {
						print("no userID")
						return 
				 }
				 print("❌ No current user found")
				 model.send(
						text: trimmed,
						to: roomData.roomID,
						userID: currentUser.uid,
				 )
			}

			inputText = ""
	 }

	 private func firstLine() -> String {
			let lines = inputText.split(separator: "\n", omittingEmptySubsequences: false)
			return lines.isEmpty ? "" : String(lines[0])
	 }

	 private func secondLine() -> String {
			let lines = inputText.split(separator: "\n", omittingEmptySubsequences: false)
			return lines.count > 1 ? String(lines[1]) : ""
	 }

	 private func thirdLine() -> String {
			let lines = inputText.split(separator: "\n", omittingEmptySubsequences: false)
			return lines.count > 2 ? String(lines[2]) : ""
	 }

	 private func isValidHaiku() -> Bool {
			let first = countSyllables(firstLine())
			let second = countSyllables(secondLine())
			let third = countSyllables(thirdLine())
			return first == 5 && second == 7 && third == 5
	 }

	 private func laneSymbol(for count: Int) -> String {
			if count == 0 {
				 return "lane"
			} else {
				 return "\(count).lane"
			}
	 }

	 private func syllableCountForCurrentLine() -> Int {
			switch currentLineIndex {
				 case 0:
						return countSyllables(firstLine())
				 case 1:
						return countSyllables(secondLine())
				 case 2:
						return countSyllables(thirdLine())
				 default:
						return 0
			}
	 }

	 private func targetSyllablesForLine(_ lineIndex: Int) -> Int {
			switch lineIndex {
				 case 0:
						return 5
				 case 1:
						return 7
				 case 2:
						return 5
				 default:
						return 0
			}
	 }
}

extension View {
	 @ViewBuilder
	 func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
			if condition {
				 transform(self)
			} else {
				 self
			}
	 }
}

