const fs = require('fs')
const kh = require('../d10/knothash')

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').shift(line => line != '')
	return lines
}

const disk = function(input) {
	const grid = []

	for (let i = 0; i < 128; i++) {
		const hash = kh.hash(`${input}-${i}`)
		const hexaNibbles = hash.split('')
		const bits = hexaNibbles.map(n => parseInt(n, 16).toString(2).padStart(4, '0')).join('').split('')
		grid[i] = bits
	}
	return grid
}

const printDisk = function(disk) {
	for (let i = 0; i < Math.min(10, disk.length); i++) {
		console.log(`${JSON.stringify(disk[i]).substr(0,70)}...`)
	}
}

const regionInfoKey = (lineNo, col) => `${lineNo},${col}`

const setFromNeighborhood = (lineNo, col, bitRegionInfo) => {
	let neighbors = [[lineNo - 1, col], [lineNo + 1, col], [lineNo, col - 1], [lineNo, col + 1]]

	neighbors = neighbors.filter(([y,x]) => y >= 0 && x >= 0)
	const neighborKey = neighbors
		.map(([nLineNo, nCol]) => regionInfoKey(nLineNo, nCol))
		.find(key => bitRegionInfo[key] !== undefined) 

	if (neighborKey !== undefined) {
		const myKey = regionInfoKey(lineNo, col)
		bitRegionInfo[myKey] = bitRegionInfo[neighborKey]
	}

	return neighborKey !== undefined
}

const setNewRegion = function(lineNo, col, bitRegionInfo) {
	bitRegionInfo[regionInfoKey(lineNo, col)] = ++bitRegionInfo.regions
	return bitRegionInfo.regions
}

const mergeNeighborhoods = (lineNo, col, bitRegionInfo) => {
	const neighborhoods = [[lineNo - 1, col], [lineNo + 1, col], [lineNo, col - 1], [lineNo, col + 1], [lineNo, col]]
	const toMerge = {}
	
	neighborhoods.filter(([y,x]) => y >=0 && x >= 0)
		.map(([y, x]) => regionInfoKey(y, x))
		.filter(key => bitRegionInfo[key] !== undefined)
		.forEach(key => {
			const region = bitRegionInfo[key]
			if (Object.keys(toMerge).indexOf(region) < 0) {
				toMerge[region] = []
			}
			toMerge[region].push(key)
		})
	
	const toMergeRegions = Object.keys(toMerge)
	toMergeRegions.sort((a, b) => a - b)

	const mergeTo = toMergeRegions.shift()

	let merged = false
	Object.keys(bitRegionInfo)
		.forEach(key => {
			if (key != 'regions' && toMergeRegions.indexOf('' + bitRegionInfo[key]) >= 0) {
				bitRegionInfo[key] = mergeTo
				merged = true
			}
		})

	return merged && mergeTo
}

const defragRegions = function(bitRegionInfo) {
	Object.keys(bitRegionInfo).slice(0, 9).forEach(key => process.stdout.write(`${key}=>${bitRegionInfo[key]}... `))
	process.stdout.write('\n')
	let regions = Object.keys(bitRegionInfo)
		.filter(key => key != 'regions' && bitRegionInfo[key] !== undefined)

	regions = regions
		.reduce((acc, key) => {
			acc[bitRegionInfo[key]] = bitRegionInfo[key]
			return acc
		}, {})

	let region = 1
	Object.keys(regions)
		.sort((a, b) => a - b)
		.forEach(region => regions[region] = region++)

	Object.keys(regions).slice(0, 9).forEach(key => process.stdout.write(`${key}=>${regions[key]}... `))
	process.stdout.write('\n')

	Object.keys(bitRegionInfo)
		.forEach(key => {
			if (key != 'regions') {
				const region = bitRegionInfo[key]
				bitRegionInfo[key] = regions[region]
			}
		})
}

const computeRegions = function(disk) {
	const bitRegionInfo = {regions: 0}
	let prevProgress = 0
	
	process.stdout.write(`Computing regions on ${disk.length}x${disk[0].length}... `)
	for (let lineNo = 0; lineNo < disk.length; lineNo++) {
		const line = disk[lineNo]
		for (let col = 0; col < line.length; col++) {
			if (disk[lineNo][col] === '0') {
				continue
			}
			const foundNeighbor = setFromNeighborhood(lineNo, col, bitRegionInfo)
			let newRegion = 'no'
			if (!foundNeighbor) {
				newRegion = setNewRegion(lineNo, col, bitRegionInfo)
			}
			const merged = mergeNeighborhoods(lineNo, col, bitRegionInfo)

			const currProgress = Math.floor((lineNo * line.length + col) * 100 / (disk.length * line.length))
			if ((currProgress > prevProgress)) {
				process.stdout.write(`${currProgress}%:${bitRegionInfo.regions}regions,foundNeighbor?${foundNeighbor},new?${newRegion},merged?${merged}... `)
				prevProgress = currProgress
			}
		}
	}
	process.stdout.write('\n')

	defragRegions(bitRegionInfo)

	return bitRegionInfo
}

const count = function(disk) {
	const result = disk.reduce((acc, line) => acc + line.filter(bit => bit === '1').length, 0)
	return result
}

const formatRegion = i => {
	if (i === undefined) return '.'

	const a = 'a'.charCodeAt(0)
	const A = 'A'.charCodeAt(0)
	const z = 'z'.charCodeAt(0)
	const Z = 'Z'.charCodeAt(0)

	if (i < 10) return `${i}`

	i -= 10
	if (i < Z - A) return `${String.fromCharCode(A + i)}`

	i -= Z - A
	if (i < z - a) return `${String.fromCharCode(a + i)}`

	return '+'
}

const printRegions = (disk, bitRegionInfo) => {
	const maxX = Math.min(10, disk[0].length)
	const maxY = Math.min(10, disk.length)
	for (let y = 0; y < maxY; y++) {
		const line = disk[y]
		for (let x = 0; x < maxX; x++) {
			process.stdout.write(formatRegion(bitRegionInfo[regionInfoKey(y, x)]))
		}
		if (y == 0 || y == maxY - 1) {
			process.stdout.write('-->')
		}
		process.stdout.write('\n')
	}
	process.stdout.write(`|${''.padStart(maxX - 2, ' ')}|
|${''.padStart(maxX - 2, ' ')}|
v${''.padStart(maxX - 2, ' ')}v\n`)
}

const getRegions = (bitRegionInfo)  => {
	const regions = Object.keys(bitRegionInfo)
		.reduce((acc, key) => {
			key != 'regions' && (acc[bitRegionInfo[key]] = true)
			return acc
		}, {})

	return Object.keys(regions)
}

const input = parseInput()
const grid = disk(input)
printDisk(grid)
const bitRegionInfo = computeRegions(grid)
printRegions(grid, bitRegionInfo)
console.log(`Count: ${getRegions(bitRegionInfo).length}`)
