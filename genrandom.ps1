# excuse the magic numbers all over the place

# creates a field across the width of the screen to capture system information from
function initScreen {
	Add-Type -AssemblyName System.Windows.Forms
	$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
}
# returns an array with the x and y positions of the cursor
function getCursorPos {
	return @([Windows.Forms.Cursor]::Position.X, [Windows.Forms.Cursor]::Position.Y)
}
# generates the cryptographically secure number using the cursor as a source of entropy
function extractRandom {
	# used to customize level of security
	param($cycles, $bits)
	[int]$CyclesDone = 0
	$lastCoords = @(0,0)
	$coordList = @()
	# find the closest power of 2 to round the user's choice down to
	while ([math]::Pow(2,[int]$power) -le $bits) {
		$power += 1
	}
	# determines the size of the final product
	switch ($power) {
		3 {[byte]$Result = [byte]$sizedinput = 0}
		4 {[uint16]$Result = [uint16]$sizedinput = 0}
		5 {[uint32]$Result = [uint32]$sizedinput = 0}
		6 {[uint64]$Result = [uint64]$sizedinput = 0}
	}
	do {
		# creates a progress bar based on cycles completed
		Write-Progress -Activity "Collecting entropy... (move your mouse) " -PercentComplete ([math]::Floor(($CyclesDone * 100) / $cycles))
		# compares the coordinate array to the last in the coordinate list; only continues if mouse has moved
		if (Compare-Object -ReferenceObject $lastCoords -DifferenceObject (getCursorPos)) {
			$lastCoords = getCursorPos
			$coordList += $lastCoords
			$CyclesDone += 1
			}
		} while ($CyclesDone -lt $cycles)
	return $coordList
}
function convertToNumber {
	param($inputarr, $output)
	forEach($coord in $inputarr) {
		for ($xorcycles = 0; $xorcycles -le $power; $xorcycles += 1){
			$output = $output -bxor (((($coord[0] % 10) * 10) + ($coord[0] % 10))*([math]::Pow(2, $xorcycles)))
		}
	}
	Write-Output "Pseudorandom number: $output"
}
# allows the user to choose cycle/bit count
function userInterface {
	[int]$usercycles = Read-Host "How many cycles should be run? Higher numbers are more secure (64)"
	[int]$userbits = Read-Host "How many bits of random data should be returned? Must be a power of 2 between 8 and 64 (32)"
	if ($usercycles -eq 0)  {
		$usercycles = 64
	}
	if ($userbits -eq 0) {
		$userbits = 32
	}
	initScreen 
	convertToNumber -inputarr (extractRandom -cycles $usercycles -bits $userbits) -output $Result
}
userInterface
