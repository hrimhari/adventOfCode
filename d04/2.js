const fs = require('fs')

const isAnagram = function(entry, word) {
	if (entry.length !== word.length) return false

	const letters = word.split('')

	return entry.split('').every(letter => {
		const pos = letters.indexOf(letter)

		if (pos < 0) {
			return false
		}

		letters.splice(pos, 1)
		return true
	})
}

const containsAnagram = function(collection, word) {
	return collection.some(entry => isAnagram(entry, word))
}

const filterValid = function(passphrase) {
	let valid = true
	const words = []

	return passphrase.split(/\s+/).every(word => {
		if (!containsAnagram(words, word)) {
			words.push(word)
			return true
		}
		return false
	})
}

const countValid = function(passphraseArray) {
	let count = passphraseArray.filter(passphrase => {
		const isValid = filterValid(passphrase)
		console.log(`${isValid && 'valid'}: ${passphrase}`)
		return isValid
	}).length
	
	console.log(`Valid count: ${count}`)
}

const input = fs.readFileSync(process.argv[2] || 'input.txt', {encoding: 'utf8'})

const passphraseArray = input.split('\n').filter(pw => pw !== '')

countValid(passphraseArray)
