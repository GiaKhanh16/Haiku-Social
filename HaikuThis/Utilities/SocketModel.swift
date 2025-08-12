import Foundation
import Observation


struct MessageStruct: Codable, Hashable {
	 let roomID: String?
	 let message: String
}



@Observable
class chatRoomManager {

	 private var webSocketTask: URLSessionWebSocketTask?

	 var receivedMessages: [MessageStruct] = []

	 var currentUser: String = "You"

	 func connect(roomID: String) {
			let url = URL(string: "wss://im399zomd2.execute-api.us-east-2.amazonaws.com/production?id=\(roomID)")!

			let session = URLSession(configuration: .default)
			webSocketTask = session.webSocketTask(with: url)
			webSocketTask?.resume()
			receive()
	 }

	 func disconnect() {
			webSocketTask?.cancel(with: .goingAway, reason: nil)
	 }

	 func send(text: String, to roomID: String = "abc123") {
			let message: [String: Any] = [
				 "action": "sendmessage",
				 "roomID": roomID,
				 "message": text
			]
			guard let data = try? JSONSerialization.data(withJSONObject: message),
						let jsonString = String(data: data, encoding: .utf8) else {
				 print("Failed to encode message")
				 return
			}

			webSocketTask?.send(.string(jsonString)) { error in
				 if let error = error {
						print("Send error: \(error)")
				 }
			}

			receivedMessages.append(MessageStruct(roomID: roomID, message: text))
	 }

	 private func receive() {
			webSocketTask?.receive { [weak self] result in
				 guard let self = self else { return }
				 switch result {
						case .failure(let error):
							 print("WebSocket receive error: \(error)")
						case .success(let message):
							 switch message {
									case .string(let text):
										 DispatchQueue.main.async {
												self.receivedMessages.append(MessageStruct(roomID: nil, message: text))
										 }
									case .data(let data):
										 print("Binary message received: \(data)")
									@unknown default:
										 break
							 }
							 self.receive()
				 }
			}
	 }

}

extension chatRoomManager {

	 func fetchMessages(roomID: String) {
			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/production/getRoomMessages?roomID=\(roomID)") else {
				 print("url error")
				 return
			}

			let request = URLRequest(url: url)

			URLSession.shared.dataTask(with: request) { data, response, error in
				 if let error = error {
						print("Error fetching rooms:", error.localizedDescription)
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
							 self.receivedMessages = fetchedMessages
						}
				 } catch {
						print("JSON decoding error:", error)
				 }

			}.resume()
	 }


}
