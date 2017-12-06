const fs = require('fs')

const findCandidate = function(banks) {
	let candidate = 0

	for (let i = 1; i < banks.length; i++) {
		if (banks[i] > banks[candidate]) {
			candidate = i
		}
	}

	console.log(`Candidate: ${candidate}:${banks[candidate]}`)
	return candidate
}

const rebalance = function(banks, candidate) {
	console.log(`Before rebalance: ${banks}`)
	let amount = banks[candidate]
	banks[candidate] = 0
	let target = candidate + 1

	while (amount > 0) {
		banks[target++ % banks.length]++
		amount--
	}
	console.log(`After rebalance: ${banks}`)
}

const compareSnapshot = function(banks, snapshot) {
	for (let i = 0; i < snapshot.length; i++) {
		if (banks[i] !== snapshot[i]) {
			return false;
		}
	}
	return true
}

const storeSnapshotIfAbsent = function(banks, snapshots) {
	if (snapshots.some(snapshot => compareSnapshot(banks, snapshot))) {
		return false
	}
	const snapshot = banks.filter(() => true)
	snapshots.push(snapshot)
	return true
}

const loop = function(banks) {
	console.log(`Input: ${banks} (${banks.length})`)
	let steps = 0
	const snapshots = []

	while (storeSnapshotIfAbsent(banks, snapshots)) {
		const candidate = findCandidate(banks)
		rebalance(banks, candidate)
		steps++
	}

	console.log(`Steps: ${steps}`)
}

const inputName = process.argv[2] || 'input.txt'
const banks = fs.readFileSync(inputName, {encoding: 'utf8'}).split(/\s+/).filter(line => line != '').map(bank => parseInt(bank))

loop(banks)
