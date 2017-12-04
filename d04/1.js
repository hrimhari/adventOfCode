const fs = require('fs')

const filterValid = function(passphrase) {
	let valid = true
	const words = []

	return passphrase.split(/\s+/).every(word => {
		if (words.indexOf(word) < 0) {
			words.push(word)
			return true
		}
		return false
	})
}

const countValid = function(passphraseArray) {
	let count = passphraseArray.filter(filterValid).length
	
	console.log(`Valid count: ${count}`)
}

const input = fs.readFileSync(process.argv[2] || 'input.txt', {encoding: 'utf8'})

const passphraseArray = input.split('\n').filter(pw => pw !== '')

countValid(passphraseArray)
