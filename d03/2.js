var printGrid = function(grid) {
//	console.log(grid)
	for (var y = 0; y < grid.length; y++) {
		var consoleLine = ''
		for (var x = 0; x < grid.length; x++) {
			value = grid[y][x]
			consoleLine += `${value || '-'}\t`
		}
		console.log(consoleLine)
	}
	console.log('')
}

var expandGrid = function(grid) {
	grid.forEach(line => {
		line.unshift(0)
	})
	grid.unshift([])
	grid.push([])
}

var fill = function(grid, x, y) {
	console.log(`Will fill ${x},${y} of:`)
	printGrid(grid)
	var value = 0
	for (var stepY = 0; stepY < 3; stepY++) {
		var localY = y + stepY - 1
		if (localY < 0 || localY >= grid.length) {
			continue
		}
		for (var stepX = 0; stepX < 3; stepX++) {
			var localX = x + stepX - 1
			if (localX < 0) {
				continue
			}
//			console.log(`grid[${localY}][${localX}]`)
			value += grid[localY][localX] || 0
		}
	}
	grid[y][x] = value
	return value
}

var buildOneLayer = function(grid, maxValue) {

	expandGrid(grid)

	var x
	var y
	var value = 0
	// Fill right side
	console.log('Will fill right side')
	for (x = grid.length - 1, y = grid.length - 2; y >= 0 && value < maxValue; y--) {
		value = fill(grid, x, y)
	}

	// Fill up side
	console.log('Will fill up side')
	for (y = 0, x--; x >= 0 && value < maxValue; x--) {
		value = fill(grid, x, y)
	}

	// Fill left side
	console.log('Will fill left side')
	for (x++, y++; y < grid.length && value < maxValue; y++) {
		value = fill(grid, x, y)
	}

	// Fill bottom side
	console.log('Will fill bottom side')
	for (y--, x++; x < grid.length && value < maxValue; x++) {
		value = fill(grid, x, y)
	}

	console.log(`Layer: ${Math.floor(grid.length / 2) + 1}, value: ${value}`)
	return {grid: grid, value: value}
}

var buildGrid = function(maxValue) {
	var value = 1
	var grid = [[value]]
	while (value < maxValue) {
		var result = buildOneLayer(grid, maxValue)
		grid = result.grid
		value = result.value
	}

	console.log(`Value: ${value}`)
	printGrid(grid)
}

buildGrid(process.argv[2])
