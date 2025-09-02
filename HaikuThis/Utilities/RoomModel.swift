import Foundation

@Observable
class RoomListModel {
	 var fetchedRooms: [RoomStruct] = []
	 var addRoomToggle: Bool = false
	 var joinRoom: Bool = false

	 func createRoom(roomName: String, roomID: String, userID: String) {
			let formatter = DateFormatter()
			formatter.dateFormat = "h:mm a"
			formatter.amSymbol = "AM"
			formatter.pmSymbol = "PM"
			let messageTime = formatter.string(from: Date())
			let lastMessage = "Send a chat message!"

			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/Haiku-CreateRoom-Post") else {
				 print("Invalid URL")
				 return
			}

			let payload: [String: Any] = [
				 "roomID": roomID,
				 "roomName": roomName,
				 "userID": userID,
				 "lastMessage": lastMessage,
				 "messageTime": messageTime
			]

			guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
				 print("JSON serialize error")
				 return
			}

			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = jsonData

			URLSession.shared.dataTask(with: request) { data, response, error in
				 if let error = error {
						print("Error creating room:", error.localizedDescription)
						return
				 }
				 if let httpResponse = response as? HTTPURLResponse {
						if (200...299).contains(httpResponse.statusCode) {
							 print("✅ Successfully created room")
						} else {
							 print("❌ Server responded with status:", httpResponse.statusCode)
						}
				 }
				 if let data = data, let responseText = String(data: data, encoding: .utf8) {
						print("Response:", responseText)
				 }

			}.resume()

	 }

	 func fetchRoomsUserID(userID: String) {

			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/HaikuGetRooms?userID=\(userID)") else {
				 print("invalid url")
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
						let fetchedRooms = try JSONDecoder().decode([RoomStruct].self, from: data)
						DispatchQueue.main.async {
							 self.fetchedRooms = fetchedRooms
						}
				 } catch {
						print("JSON decoding error:", error)
				 }
			}.resume()
	 }

	 func joinRoom(roomID: String, userID: String, completion: @escaping (Result<RoomStruct, Error>) -> Void) {
			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/HaikuGetRooms?roomID=\(roomID)&userID=\(userID)") else {
				 completion(.failure(RoomListModelError.roomNotFound))
				 return
			}

			let request = URLRequest(url: url)
			URLSession.shared.dataTask(with: request) { data, _, error in
				 if let error = error {
						completion(.failure(error))
						return
				 }

				 guard let data = data else {
						completion(.failure(RoomListModelError.roomNotFound))
						return
				 }

				 do {
						let fetchedRooms = try JSONDecoder().decode([RoomStruct].self, from: data)
						if let fetchedRoom = fetchedRooms.first {
									// Now join the room on backend
							 self.updateUserID(roomID: roomID, userID: userID) { success in
									DispatchQueue.main.async {
										 if success {
												completion(.success(fetchedRoom))
										 } else {
												completion(.failure(RoomListModelError.roomNotFound))
										 }
									}
							 }
						} else {
							 completion(.failure(RoomListModelError.roomNotFound))
						}
				 } catch {
						completion(.failure(error))
				 }
			}.resume()
	 }

	 func updateUserID(roomID: String, userID: String, completion: @escaping (Bool) -> Void) {
			guard let url = URL(string: "https://fvw2w2pmw7.execute-api.us-east-2.amazonaws.com/production/joinRoom") else {
				 completion(false)
				 return
			}

			let payload: [String: Any] = ["roomID": roomID, "userID": userID]
			guard let jsonPayload = try? JSONSerialization.data(withJSONObject: payload) else {
				 completion(false)
				 return
			}

			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = jsonPayload

			URLSession.shared.dataTask(with: request) { _, response, error in
				 if let error = error {
						print("Error joining room:", error.localizedDescription)
						completion(false)
						return
				 }
				 if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
						completion(true)
				 } else {
						completion(false)
				 }
			}.resume()
	 }

}

struct RoomStruct: Codable, Identifiable, Hashable {
	 let roomID: String
	 let roomName: String
	 let lastMessage: String
	 let messageTime: String

	 var id: String { roomID }
}

enum RoomListModelError: LocalizedError {
	 case roomNotFound
	 var errorDescription: String? {
			switch self {
				 case .roomNotFound: return "No room found with that ID."
			}
	 }
}
