var checksum = function(input) {
	var result = 0

	for (var i = 0; i < input.length; i++) {
		var i2 = (i + (input.length / 2)) % input.length
//		console.log(`Current: ${input.charAt(i)}(${i})`)
		if (input.charAt(i) === input.charAt(i2)) {
//			console.log(`Match: ${input.charAt(i)}`)
			result += parseInt(input.charAt(i))
		}
	}

	return result
}

var result = checksum(process.argv[2]);

console.log(`Sum: ${result}`)
