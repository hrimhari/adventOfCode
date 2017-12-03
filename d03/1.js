
var stepToDistance = function(step) {
	var radius = 0
	var steps = 1
	var side = 0
	while (steps < step) {
		radius++
		side = 2 * radius
		steps += side * 4
	}

	var stepsSideStart = steps - (side * 4)

	var stepOnRadius = step - stepsSideStart - 1

	// Side on which the step is located
	var stepSide = Math.floor(stepOnRadius / side)

	// Side actually includes both corners, so step on side begins at 1
	var stepOnSide = (stepOnRadius % side) + 1

	// Side also includes both corners for distance purposes
	var sideForDistance = side + 1

	// Distance will be difference from half a sideForDistance and the step on the side
	var otherDistance = Math.abs(Math.floor(sideForDistance / 2) - stepOnSide)

	console.log(`${radius} + ${otherDistance} = ${radius + otherDistance}`)
}

stepToDistance(process.argv[2])
