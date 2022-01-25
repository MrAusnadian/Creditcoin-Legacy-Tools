$DebugPreference = "SilentlyContinue"
# $DebugPreference = "Continue" # Uncomment to enable debug messages
$InformationPreference = "SilentlyContinue"
$InformationPreference = "Continue" # Uncomment to enable debug messages

$leader = "http://creditcoin-gateway.gluwa.com:8008/blocks"

$nodes = "http://node-000.creditcoin.org:8008/blocks",
         "http://node-001.creditcoin.org:8008/blocks",
         "http://node-002.creditcoin.org:8008/blocks",
         "http://node-003.creditcoin.org:8008/blocks",
         "http://node-004.creditcoin.org:8008/blocks",
         "http://node-005.creditcoin.org:8008/blocks",
         "http://creditcoin-internal.westus.cloudapp.azure.com:8008/blocks",
         "http://creditcoin-node.gluwa.com:8008/blocks"

$latest_block = (irm http://creditcoin-gateway.gluwa.com:8008/blocks?limit=1).data.header.block_num
$i = $latest_block - 250

Write-Information "Latest block on Gateway node is $latest_block"
Write-Information "Looking for block differences between blocks $i and $latest_block ($($latest_block - $i) blocks)"

while ($i -le $latest_block) {
	$expected_current_block = ""
	try {
		$expected_current_block = (irm "$leader/$i").data.header_signature.Substring(0,8)
	}
	catch { # Retry after 30 seconds if the leader node is restarting
		Start-Sleep 30
		$expected_current_block = (irm "$leader/$i").data.header_signature.Substring(0,8)
	}
	
	Write-Host -NoNewLine "`rChecking block $i ($expected_current_block)...     "
	foreach($node in $nodes) {
		$node_name = $node -replace "http://","" -replace ":8008/blocks",""
		$node_previous_block = ""
		$node_current_block = ""
		$failCount = 0 # Extra line just to make the output pretty
		try {
			$node_current_block = (irm "$node/$i").data.header_signature.Substring(0,8)
			$found = $true
		}
		catch {
			Write-Debug " - Block not found on $node_name"
			$found = $false
		}
		if ($found -ne $false) {
			if ($node_current_block -ne $expected_current_block){
				if($failCount -eq 0) { Write-Host "" } # Extra lines just to make the output pretty
				$failCount++ # Extra lines just to make the output pretty
				Write-Warning "Expected block ID $expected_current_block, found $node_current_block on $node_name"
				$nodes = $nodes -ne $node
			}
			else {
				Write-Debug "Block ID $node_current_block matched expected block ID $expected_current_block on $node_name"
			}
		}
	}
	$i++
}

Write-Host "" # Extra line just to make the output pretty
Write-Information "All done!"
