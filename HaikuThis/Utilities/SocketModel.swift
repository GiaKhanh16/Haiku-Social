import Foundation
import Observation
import FirebaseAuth

	 // MARK: - Message Model
struct MessageStruct: Codable, Identifiable, Hashable {
	 let action: String?
	 let roomID: String?
	 let message: String?
	 let userID: String?
	 let username: String?
	 let timestamp: String?

			// Unique ID for SwiftUI ForEach
	 var id: String { UUID().uuidString }

	 enum CodingKeys: String, CodingKey {
			case action
			case message
			case roomID = "roomID"
			case userID = "userID"
			case username
			case timestamp
	 }
}

	 // MARK: - Chat Room Manager
@Observable
class ChatRoomManager {

	 private var webSocketTask: URLSessionWebSocketTask?

			// Received messages
	 var receivedMessages: [MessageStruct] = []

			// Connect to WebSocket
	 func connect(userID: String, roomID: String) {
			guard let url = URL(string: "wss://im399zomd2.execute-api.us-east-2.amazonaws.com/production?roomID=\(roomID)&userID=\(userID)") else {
				 print("Invalid URL")
				 return
			}

			let session = URLSession(configuration: .default)
			webSocketTask = session.webSocketTask(with: url)
			webSocketTask?.resume()
			receive()
	 }

			// Disconnect WebSocket
	 func disconnect() {
			webSocketTask?.cancel(with: .goingAway, reason: nil)
	 }

			// Send a message
	 func send(text: String, to roomID: String, userID: String, username: String = "Khanh") {
			let formatter = DateFormatter()
			formatter.dateFormat = "h:mm a"
			formatter.amSymbol = "AM"
			formatter.pmSymbol = "PM"
			let messageTime = formatter.string(from: Date())

			let message = MessageStruct(
				 action: "sendmessage",
				 roomID: roomID,
				 message: text,
				 userID: userID,
				 username: username,
				 timestamp: messageTime
			)

			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .iso8601

			guard let data = try? encoder.encode(message),
						let jsonString = String(data: data, encoding: .utf8) else {
				 print("Failed to encode message")
				 return
			}

			webSocketTask?.send(.string(jsonString)) { error in
				 if let error = error {
						print("WebSocket send error: \(error)")
				 }
			}

				 // Append locally for immediate UI update
			receivedMessages.append(message)
	 }

			// Receive WebSocket messages continuously
	 private func receive() {
			webSocketTask?.receive { [weak self] result in
				 guard let self = self else { return }

				 switch result {
						case .failure(let error):
							 print("WebSocket receive error: \(error)")

						case .success(let message):
							 switch message {
									case .string(let text):
										 if let data = text.data(using: .utf8) {
												let decoder = JSONDecoder()
												decoder.dateDecodingStrategy = .iso8601
												do {
													 let decodedMessage = try decoder.decode(MessageStruct.self, from: data)
													 DispatchQueue.main.async {
															self.receivedMessages.append(decodedMessage)
													 }
												} catch {
													 print("Failed to decode message JSON:", error)
												}
										 }

									case .data(let data):
										 print("Binary message received: \(data)")

									@unknown default:
										 break
							 }

									// Keep listening
							 self.receive()
				 }
			}
	 }

	 func fetchMessages(roomID: String) {
			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/production/getRoomMessages?roomID=\(roomID)") else {
				 print("Invalid URL")
				 return
			}

			let request = URLRequest(url: url)

			URLSession.shared.dataTask(with: request) { data, response, error in
				 if let error = error {
						print("Error fetching messages:", error.localizedDescription)
						return
				 }

				 guard let data = data else {
						print("No data received")
						return
				 }

				 do {
						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .iso8601
						let fetchedMessages = try decoder.decode([MessageStruct].self, from: data)
						DispatchQueue.main.async {
							 let formatter = ISO8601DateFormatter()

							 self.receivedMessages = fetchedMessages.sorted { first, second in
									let date1 = formatter.date(from: first.timestamp ?? "") ?? Date.distantPast
									let date2 = formatter.date(from: second.timestamp ?? "") ?? Date.distantPast
									return date1 < date2
							 }
						}
				 } catch {
						print("JSON decoding error:", error)
				 }

			}.resume()
	 }
}
