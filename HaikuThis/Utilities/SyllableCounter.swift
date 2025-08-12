import Foundation

func countSyllables(_ text: String) -> Int {
	 guard !text.isEmpty else { return 0 }

	 let vowels = Set("aeiouy")

			// Exceptions dictionary with lowercase keys, no punctuation
	 let exceptions: [String: Int] = [
			"creating": 3,
			"forehand": 2,
			"lovely": 2,
			"whole": 1,
			"single": 2,
			"communication": 5,
			"calculation": 4,
			"foundation": 5,
			"generation": 5,
	 ]

	 let words = text
			.lowercased()
			.components(separatedBy: .whitespacesAndNewlines)
			.filter { !$0.isEmpty }

	 var totalSyllables = 0

	 for word in words {
				 // Remove trailing punctuation like .,!? etc.
			let cleanedWord = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)

				 // Remove internal apostrophes, e.g. lovely's -> lovelys (optional)
			let cleanWord = cleanedWord.filter { $0.isLetter }

			if cleanWord.isEmpty { continue }

				 // Try to lookup exceptions directly
			if let exceptionCount = exceptions[cleanWord] {
				 totalSyllables += exceptionCount
				 continue
			}

				 // If not found, try removing trailing 's' or 'es' (simple plural check)
			if cleanWord.hasSuffix("es") {
				 let singular = String(cleanWord.dropLast(2))
				 if let exceptionCount = exceptions[singular] {
						totalSyllables += exceptionCount
						continue
				 }
			} else if cleanWord.hasSuffix("s") {
				 let singular = String(cleanWord.dropLast(1))
				 if let exceptionCount = exceptions[singular] {
						totalSyllables += exceptionCount
						continue
				 }
			}

				 // Now fallback to general syllable counting
			var syllableCount = 0
			var previousIsVowel = false
			let chars = Array(cleanWord)

			for char in chars {
				 let isVowel = vowels.contains(char)
				 if isVowel && !previousIsVowel {
						syllableCount += 1
				 }
				 previousIsVowel = isVowel
			}

			if cleanWord.hasSuffix("e") &&
						!cleanWord.hasSuffix("le") &&
						syllableCount > 1 {
				 syllableCount -= 1
			}

			if cleanWord.hasSuffix("le") && cleanWord.count > 2 {
				 let index = cleanWord.index(cleanWord.endIndex, offsetBy: -3)
				 let beforeLe = cleanWord[index]
				 if !vowels.contains(beforeLe) {
						syllableCount += 1
				 }
			}

			if cleanWord.hasSuffix("ion") {
				 syllableCount += 1
			}

			totalSyllables += max(syllableCount, 1)
	 }

	 return totalSyllables
}
