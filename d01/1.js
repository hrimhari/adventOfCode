var checksum = function(input) {
	var inputPlusOne = input + input.charAt(0)

	var result = 0

	for (var i = 1; i < inputPlusOne.length; i++) {
//		console.log(`Current: ${inputPlusOne.charAt(i)}(${i})`)
		if (inputPlusOne.charAt(i) === inputPlusOne.charAt(i - 1)) {
//			console.log(`Match: ${inputPlusOne.charAt(i)}`)
			result += parseInt(inputPlusOne.charAt(i))
		}
	}

	return result
}

var result = checksum(process.argv[2]);

console.log(`Sum: ${result}`)
