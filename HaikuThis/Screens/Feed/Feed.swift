//
//  Feed.swift
//  HaikuThis
//
//  Created by Khanh Nguyen on 7/30/25.
//

import SwiftUI

struct Feed: View {
	 var haikuPoems: [String] = [
			"An old silent pond\nA frog jumps into the pond—\nSplash! Silence again.",
			"Winter seclusion—\nListening, that evening,\nTo the rain in the mountain.",
			"Over the wintry\nForest, winds howl in rage\nWith no leaves to blow.",
			"In the cicada's cry\nNo sign can foretell\nHow soon it must die.",
			"Light of the moon\nMoves west, flowers' shadows\nCreep eastward."
	 ]

	 var body: some View {
			ScrollView {
				 ForEach(haikuPoems, id: \.self) { poem in
						VStack {
							 Text(poem)
									.multilineTextAlignment(.leading)
//									.padding()
									.frame(maxWidth: .infinity, alignment: .leading)

							 HStack(spacing: 16) {
										 // Upvote
									Button(action: {  }) {
										 VStack(spacing: 2) {
												Image(systemName: "chevron.up")
													 .font(.headline)
												Text("0")
													 .font(.caption)
										 }
									}
									.buttonStyle(.plain)
									.foregroundColor(.primary)

										 // Downvote
									Button(action: {  }) {
										 Image(systemName: "chevron.down")
												.font(.headline)
									}
									.buttonStyle(.plain)
									.foregroundColor(.primary)

									Spacer()

										 // Comments
									Button(action: { /* open comments */ }) {
										 HStack(spacing: 6) {
												Image(systemName: "text.bubble")
												Text("Comment")
										 }
									}
									.buttonStyle(.plain)

										 // Share
									Button(action: { /* share action */ }) {
										 HStack(spacing: 6) {
												Image(systemName: "square.and.arrow.up")
												Text("Share")
										 }
									}
									.buttonStyle(.plain)
							 }
						}
						.padding()
						.background(
							 RoundedRectangle(cornerRadius: 12)
									.fill(Color.white)
									.shadow(radius: 1)
						)
				 }
				 .padding(.horizontal)

			}
	 }
}

#Preview {
	 Feed()
}
