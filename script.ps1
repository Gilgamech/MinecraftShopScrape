Function ConvertFrom-Gzip {
<#
.SYNOPSIS
This function will decompress the contents of a GZip file and output it to the pipeline.  Each line in the converted file is 
output as distinct object.

.DESCRIPTION
Using the System.IO.GZipstream class this function will decompress a GZip file and send the contents into 
the pipeline.  The output is one System.String object per line.  It supports the various types of encoding 
provided by the System.text.encoding class.

.EXAMPLE
ConvertFrom-Gzip -path c:\test.gz

test content

.EXAMPLE
get-childitem c:\archive -recure -filter *.gz | convertfrom-Gzip -encoding unicode | select-string -pattern "Routing failed" -simplematch

Looks through the c:\archive folder for all .gz files, those files are then converted to system.string 
objects, all that data is piped to select-string.  Strings which match the pattern "Routing failed" are returned to the console.

.EXAMPLE
get-item c:\file.txt.gz | convertfrom-Gzip | out-string | out-file c:\file.txt

Converts c:\file.txt.gz to a string array and then into a single string object.  That string object is then written into a new file.

.NOTES
Written by Jason Morgan
Created on 1/10/2013
Last Modified 7/11/2014
# added support for relative paths

#>
[CmdletBinding()]
Param
    (
        # Enter the path to the target GZip file, *.gz
        [Parameter(
        Mandatory = $true,
        ValueFromPipeline=$True, 
        ValueFromPipelineByPropertyName=$True,
        HelpMessage="Enter the path to the target GZip file, *.gz",
        ParameterSetName='Default')]             
        [Alias("Fullname")]
        [ValidateScript({$_.endswith(".gz")})]
        [String]$Path,
        # Specify the type of encoding of the original file, acceptable formats are, "ASCII","Unicode","BigEndianUnicode","Default","UTF32","UTF7","UTF8"
        [Parameter(Mandatory=$false,
        ParameterSetName='Default')]
        [ValidateSet("ASCII","Unicode","BigEndianUnicode","Default","UTF32","UTF7","UTF8")]
        [String]$Encoding = "ASCII"
    )
Begin 
    {
        Set-StrictMode -Version Latest
        Write-Verbose "Create Encoding object"
        $enc= [System.Text.Encoding]::$encoding
    }
Process 
    {
        Write-Debug "Beginning process for file at path: $Path"
        Write-Verbose "test path"
        if (-not ([system.io.path]::IsPathRooted($path)))
          {
            Write-Verbose 'Generating absolute path'
            Try {$path = (Resolve-Path -Path $Path -ErrorAction Stop).Path} catch {throw 'Failed to resolve path'}
            Write-Debug "New Path: $Path"
          } 
        Write-Verbose "Opening file stream for $path"
        $file = New-Object System.IO.FileStream $path, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
        Write-Verbose "Create MemoryStream Object, the MemoryStream will hold the decompressed data until it is loaded into `$array"
        $stream = new-object -TypeName System.IO.MemoryStream
        Write-Verbose "Construct a new [System.IO.GZipStream] object, created in Decompress mode"
        $GZipStream = New-object -TypeName System.IO.Compression.GZipStream -ArgumentList $file, ([System.IO.Compression.CompressionMode]::Decompress)
        Write-Verbose "Open a Buffer that will be used to move the decompressed data from `$GZipStream to `$stream"
        $buffer = New-Object byte[](1024)
        Write-Verbose "Instantiate `$count outside of the Do/While loop"
        $count = 0
        Write-Verbose "Start Do/While loop, this loop will perform the job of reading decopressed data from the gzipstream object into the MemoryStream object.  The Do/While loop continues until `$GZipStream has been emptied of all data, which is when `$count = 0"
        do
            {
                $count = $gzipstream.Read($buffer, 0, 1024)
                if ($count -gt 0)
                    {
                        $Stream.Write($buffer, 0, $count)
                    }
            }
        While ($count -gt 0)
        Write-Verbose "Take the data from the MemoryStream and convert it to a Byte Array"
        $array = $stream.ToArray()
        Write-Verbose "Close the GZipStream object instead of waiting for a garbage collector to perform this function"
        $GZipStream.Close()
        Write-Verbose "Close the MemoryStream object instead of waiting for a garbage collector to perform this function"
        $stream.Close()
        Write-Verbose "Close the FileStream object instead of waiting for a garbage collector to perform this function"
        $file.Close()
        Write-Verbose "Create string(s) from byte array, a split is added after the conversion to ensure each new line character creates a new string"
        $enc.GetString($array).Split("`n")
    }
End {}
}

Function Parse-MCChat {
	param(
		$chatlog = @(),
		[string]$ChatLogLocation = "$env:APPDATA\.minecraft\logs",
		[int]$LogGoesBackDays = 7
	)
	
	write-host "Gathering logs"
	ls $ChatLogLocation -Exclude 'latest.log'| where {$_.LastWriteTime -gt (get-date).AddDays($LogGoesBackDays*-1)} | %{
		$t = $_;$chatlog += ConvertFrom-Gzip -Path $_.FullName|%{
			($t.CreationTime.tostring() -split " ")[0] + "," + $_
		}
	}
	
	$date = (get-date -f d)
	$chatlog += (gc "$ChatLogLocation\latest.log")|%{$date + "," + $_}
	
	write-host "Parsing $($chatlog.count) log records"
	$list = $chatlog -replace "\[",'' -replace "\] ",',' -replace ": ",',' | ConvertFrom-Csv -Header Date,Time,type,source,user,message,Shopkeeper
	
	$list | %{
		if($_.date -and $_.time){
			try{
				$_.date = get-date ($_.date +" "+ $_.time)
			}catch{
			}
		}
		if($_.user -match "'s island\."){
			$shopkeeper = ($_.user -replace "Visiting ","" -replace "'s island.","");
		}else{
		}
		$_.shopkeeper = $shopkeeper
	}
	
	write-host "Outputting $($list.count) shops"
	$list | select Date,type,source,user,message,Shopkeeper
}

#Monitor output - out of stock, shops to visit (Who have I visited in the past month but not past week?), good deals, chat name to visit name mapping, buying and selling requests, arbitrage opporunities, last time I visited this store, 
#Report on - overall market trends, 
#Static data - my own shops, /warp grass, website store, 

Function Get-MCShopNames {
	param(
		[int]$LogGoesBackDays = 7,
		$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays)
	)
	$ParseMinecraftChat | sort message | select message,shopkeeper -u | group message | select name,@{n="shopkeeper";e={$_.group.shopkeeper -replace "{",'' -replace "'s island\.",""}}
}
	#Paginate, auto-ads? 
	#Entertainment edition with shop features - casinos, parkour, music, (public) portals, banks, hotels,enchanting (lvl)? Ender chest? Much Lag? Free mob spawners? Roller coaster? People mover? Bulk orders? Quote Wall? Connects to other players?
	#$mcs | %{$_.Name+":";$_.shopkeeper;"`r"}
	#Manual blacklist (written book etc) and separations
	#Builder list
	
<#
9 areas
- Center Shop
- Tree island with cobble gen
- Sunken Ship
- Food Island
- Mob Farm
- Mushroom farm with mycelium
- Donation wall
- Parkour? 
- Nether
- Residential and Commercial
- Hotel/apartments
- Bank?
- Casino? 
- Other machines?

#>

Function Get-MCItemPrices {
	[CmdletBinding()]
	param(
		[int]$LogGoesBackDays = 7,
		$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays)
	)
	write-host "Combining $($ParseMinecraftChat.count) log records"
	$ParseMinecraftChat = $ParseMinecraftChat | select user,message,Qty,BuySell,Item,Grass,Shopkeeper,Transactions,Rate,Date,Time,TradeItem | where {$_.user -match "this shop"}
	$ParseMinecraftChat | %{
		$Transactions = 0;
		$usersplit=($_.user -split " ")
		if($_.user -match "Item\(s\) this shop sells to you"){
			[String]$Item = $_.message
		}
		if($_.user -match "Item\(s\) this shop buys from you"){
			[String]$Item = $_.message
		}
		if($_.user -match "Item\(s\) this shop trades to you"){
			[String]$Item = $_.message
		}
		if($_.user -match "You can buy"){
			[String]$BuySell = "Selling"
			[int]$Qty = $usersplit[3]
			[int]$GrassLoc = 8+($item -split " ").count
			$Grass = $usersplit[$GrassLoc]
			$TradeItem = "Grass"
		}
		if($_.user -match "You can sell"){
			[String]$BuySell = "Buying"
			[int]$Qty = $usersplit[3]
			[int]$GrassLoc = 8+($item -split " ").count
			$Grass = $usersplit[$GrassLoc]
			$TradeItem = "Grass"
		}
		if($_.user -match "You can barter"){
			[String]$BuySell = "Trading"
			[int]$Qty = $usersplit[3]
			[int]$GrassLoc = 10+($item -split " ").count
			$Grass = $usersplit[$GrassLoc]
			$TradeItem = $usersplit[($grassloc+1)..99] -join " " -replace '\(s\)',"" -replace "\.",""
		}
		if($_.user -match "This shop is currently able to provide "){
			[int]$Transactions = $usersplit[7]

		$_.Qty = $Qty
		$_.BuySell = $BuySell
		$_.Item = $Item
		$_.Grass = $Grass
		$_.Shopkeeper = ($_.Shopkeeper -split "'")[0]
		$_.Transactions = $Transactions
		try{$_.Rate = if($Qty -and $Grass){[math]::Round($Grass/$Qty,3)}}catch{	}
		$_.TradeItem = $TradeItem
		}
	}

	$ParseMinecraftChat | where {$_.Transactions} | select Date, Shopkeeper, BuySell, Item, Qty, Grass, Transactions, Rate, TradeItem | sort item
} 

Function Get-MCAvgPrice {
	param(
		$Item = "Diamond",
		[int]$LogGoesBackDays = 7,
		$mci = (Get-MCItemPrices 1)
	)
	$m2 = $mci | where {$_.item -match $Item} | sort shopkeeper -Unique | sort rate | where {$_.transactions -gt 0}
	$m2.rate | Measure-Object -Average
}

Function Get-MCWhoSells {
	param(
		[ValidateSet("buying","selling","trading")][string]$BuySell = "selling",
		$Item = "Diamond",
		[int]$LogGoesBackDays = 2,
		$mci = (Get-MCItemPrices $LogGoesBackDays),
		[switch]$clip
	)
	$Shopkeepers = (($mci | where {$_.item -match $Item} | where {$_.BuySell -match $BuySell} | sort date | where {$_.transactions -gt 0} | select shopkeeper -Unique).shopkeeper) #-join ", ")
	if ($clip){
		"These shops are $BuySell $Item"+": " + $Shopkeepers | clip
	} else {
	$Shopkeepers 
	}
	
}

Function Get-MCArbitrage {
	param(
		[int]$LogGoesBackDays = 2,
		$mci = (Get-MCItemPrices $LogGoesBackDays),
		$item = "iron ingot"
	)
	#ipmo -Force .\script.ps1;$mci = Get-MCItemPrices -ParseMinecraftChat $parseminecraftchat;$sell = $mci | where {$_.buysell -match "sel"};$buy = $mci | where {$_.buysell -match "buy"};$buy[0]|ft;$sell | where {$_.item -match $buy[0].item} |ft

#$buy |%{$b=$_;$b;$sell | where {$_.item -match $b.item}|where {$_.rate -lt $b.rate}} | ft
	$buyrate = ($mci | where {$_.buysell -match "buy"}| where {$_.item -match $item})[0].rate;
	write-host $buyrate;
	$mci |where {$_.item -match $item} | where {$_.rate -gt $buyrate}| sort rate 
}

Function Get-MCBookOutput {
	param(
		[ValidateSet("buying","selling")][string]$BuySell = "selling",
		$Item = "Diamond",
		[int]$LogGoesBackDays = 2,
		#$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays),
		$mci = (Get-MCItemPrices $LogGoesBackDays),
		[switch]$clip
	)
	$BOutput = $mci | group item
	$ic = 0
	$x = @("Buying","Selling")
	$BOutput | where {$_.name -ne "???"} | %{
		if (($_.Group.buysell | Select-String $x[0]).count -gt 0) {
			$x[0] + " " + $_.name + ":"; 
			$ic++
			if ($ic%14 -eq 0) { }	 
			$_.group | where {$_.buysell -match $x[0]}| sort shopkeeper -unique | %{
				""+ $_.shopkeeper + "|"+$_.Qty+":"+$_.Grass+"|"+((get-date) - (get-date $_.date)).days
				$ic++
				if ($ic%14 -eq 0) { }	 
			};
			"`r";
			$ic++
			if ($ic%14 -eq 0) { }	 
		}
		if (($_.Group.buysell | Select-String $x[1]).count -gt 0) {
			$x[1] + " " + $_.name + ":"; 
			$ic++
			if ($ic%14 -eq 0) { }	 
			$blanklines = ($_.group.count + (14-($ic%14)))
			if ($blanklines -lt $_.group.count) { 
				$blanklines | %{"`r";	$ic++}
				
			} else {
			$_.group |where {$_.buysell -match $x[1]}| sort shopkeeper -unique | %{
				""+ $_.shopkeeper + "|"+$_.Qty+":"+$_.Grass+"|"+((get-date) - (get-date $_.date)).days
				$ic++
				if ($ic%14 -eq 0) { }	 
			};
			"`r"
			$ic++
			if ($ic%14 -eq 0) { }	 
			} 

		}	
 	}
"Pages: "+($ic/14)
}



<#


Date,Shopkeeper,BuySell,Item,Qty,Grass,Transactions,Rate,TradeItem
0,"WarpGrass","Selling","Brewing Stand",1,6,999,.16,"Grass"
0,"WarpGrass","Selling","End Stone",16,4,999,4,"Grass"
0,"WarpGrass","Selling","Red Tulip",4,1,999,4,"Grass"
0,"WarpGrass","Selling","Rose Bush",4,1,999,4,"Grass"
0,"WarpGrass","Selling","Bat Egg",2,1,999,2,"Grass"
0,"WarpGrass","Selling","Netherrack",32,1,999,32,"Grass"
0,"WarpGrass","Selling","Slimeball",8,1,999,8,"Grass"
0,"WarpGrass","Selling","Mycelium",1,5,999,.2,"Grass"
0,"WarpGrass","Selling","Cobblestone",48,1,999,48,"Grass"
0,"WarpGrass","Selling","Snow",32,1,999,32,"Grass"

0,"WarpGrass","Trading","Diamond",10,1,999,10,"Horse Egg"

0,"Website","Selling","Grass",10,3.75,999,RATE,"Grass"
0,"Website","Selling","Elytra",1,11.25,999,RATE,"Grass"
0,"Website","Selling","Beacon",1,7.50,999,RATE,"Grass"
0,"Website","Selling","Pig Spawner",1,3.75,999,RATE,"Grass"
0,"Website","Selling","Pig Spawner",4,11.25,999,RATE,"Grass"
0,"Website","Selling","Diamonds",8,11.25,999,RATE,"Grass"
0,"Website","Selling","Diamonds",32,33.75,999,RATE,"Grass"
0,"Website","Selling","Iron Ingots",12,4.88,999,RATE,"Grass"
0,"Website","Selling","Enchanting Table",1,3.75,999,RATE,"Grass"
0,"Website","Selling","Brewing Pack and Pis",1,4.13,999,RATE,"Grass"
0,"Website","Selling","Enchanted Diamond Pi",1,3.75,999,RATE,"Grass"
0,"Website","Selling","Skyknight",1,7.50,999,RATE,"Grass"
0,"Website","Selling","Skyknight to Skyking",1,11.25,999,RATE,"Grass"
0,"Website","Selling","Skyking",1,18.75,999,RATE,"Grass"
0,"Website","Selling","Skyking to Skylord",1,18.75,999,RATE,"Grass"
0,"Website","Selling","Skylord",1,37.50,999,RATE,"Grass"
0,"Website","Selling","Skylord to Skygod",1,37.50,999,RATE,"Grass"
0,"Website","Selling","Skyking to Skygod",1,56.25,999,RATE,"Grass"
0,"Website","Selling","Skygod",1,75.00,999,RATE,"Grass"
0,"Website","Selling","Skygod to Skytitan",1,112.50,999,RATE,"Grass"
0,"Website","Selling","Skytitan",1,187.50,999,RATE,"Grass"
0,"Website","Selling","Cobble Kit",1,7.50,999,RATE,"Grass"
0,"Website","Selling","Wood Kit",1,7.50,999,RATE,"Grass"
0,"Website","Selling","Iron Ingot Kit",1,15.00,999,RATE,"Grass"
0,"Website","Selling","Colored Wool Kit",1,15.00,999,RATE,"Grass"
0,"Website","Selling","Mob Spawner Kit",1,41.25,999,RATE,"Grass"
0,"Website","Selling","Fly Mode",1,15.00,999,RATE,"Grass"
0,"Website","Selling","Rare Key",1,4.25,999,RATE,"Grass"
0,"Website","Selling","Rare Key",4,12.75,999,RATE,"Grass"
0,"Website","Selling","Legendary Key",1,8.50,999,RATE,"Grass"
0,"Website","Selling","149x149",1,11.25,999,RATE,"Grass"
0,"Website","Selling","199x199",1,18.75,999,RATE,"Grass"
0,"Website","Selling","Upgrade from 149x149",1,7.50,999,RATE,"Grass"

#>


<#


Want grass more than voter keys? Click Here to sell your keys at my shop!
Click Here to visit my island paradise!  - L()()K L()()K -> Fish! Swim (don't drown)! Bring your own Boat! Frolic among the trees! Enjoy the sunrise or sunset from the rooftop lounge! Visit the floating faerie rings!
Tired of L()()King at the endless void? Come drown in my sea! If you're lucky, you'll find free ink sacs! Fight monsters on my faerie rings! See the under-construction spaceport!
Suicidal squid in my doorway. Free ink sacs to my next visitor! Get it before clag does!


Now renting hoppers, starting at 1 grass/day.


Fire doesn't spread. Mycelium spreads faster than grass. Snowmen don't make snow but chickens do drop eggs. 
Villagers *can* be spawned, and zombie villagers cured, but you can't buy from them (only /warp grass), and they don't farm. Iron golems can be constructed but don't spawn.
Cobble gen and stone gen make ores every 100-400 stones or so.
Animals stack so use a nametag to separate one for breeding.
Get grass from /vote, vote parties, word unscrambles, sb /lottery maybe /ma j and /warp crates too.
7 ways to expand your surface: 1. generate cobble. 2. grow trees 3. Find a public nether portal and bring back netherrack 4. Shave sheep 5. Grow a LOT of pumpkins/melons. 6. Spawn skeletons and make bone blocks out of your enemies. 7. trade your grass for stone at a shop like mine.


New players - want to stretch your grass? Click Here to visit my Gold Nugget Shop. Get 800 gold nuggets for your grass block. Many items for just 10 nuggets and weapons for 100 nuggets!
New players L()()K L()()K -> Click Here to visit my Gold Shop. Don't want 128 carrots for 1 grass? Get 1 carrot for 10 gold nuggets.
Click Here to check out my new Gold Shop. Most items just 10 gold nuggets! Get gold nuggets 800:1.



"Nothing is to be feared. It is only to be understood. Now is the time to understand moreee, so that we may fear less." - Marie Curie.

We have the most lag. The greatest lag. The best lag ever.

It's Minecraft - do what you'd do in any other server - grow stuff, mine, harvest, build your base, and have fun.
NeonThunder Rumor is they archived it once to classic skyblock, but no they don't reset. except Nether which is every 1-3 months or whenever.

Make a slot 3 wide and 2 deep - put water at the top of 1 side, lava at top of other, where they flow together is your cobble gen.

#>

