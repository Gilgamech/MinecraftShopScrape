<#
#Monitor output - out of stock, shops to visit (Who have I visited in the past month but not past week?), good deals, chat name to visit name mapping, buying and selling requests, arbitrage opporunities, last time I visited this store, 
#Report on - overall market trends, 
#Static data - my own shops, /warp grass, website store, 

	#Paginate, auto-ads? 
	#Entertainment edition with shop features - casinos, parkour, music, (public) portals, banks, hotels,enchanting (lvl)? Ender chest? Much Lag? Free mob spawners? Roller coaster? People mover? Bulk orders? Quote Wall? Connects to other players?
	#$mcs | %{$_.Name+":";$_.shopkeeper;"`r"}
	#Manual blacklist (written book etc) and separations
	#Builder list
	
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

filter Replace-Kirin {
$_ = $_ -replace "\+  Welcome to Kirin","Riink"
$_
}

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

Function Get-MCShopNames {
	param(
		[int]$LogGoesBackDays = 7,
		$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays)
	)
	$ParseMinecraftChat | sort message | select message,shopkeeper -u | group message | select name,@{n="shopkeeper";e={$_.group.shopkeeper -replace "{",'' -replace "'s island\.",""}}
}
	
Function Get-MCBookOutput {
	param(
		$items = ((($mci | group item | sort count -d).name |select -Unique)[0..49])
	)
$items | sort | %{((((Get-MCWhoSells $_) -replace "These shops are selling ","" )[0..255] -join "" -replace "\r","" -split ", " |select-string "\)"| select -u) -join ", ")}
}

Function Get-MCArbitrage {
	$items = $mci | %{$_.item} | sort -Unique
	$items = $items[3..$items.count]
	$items | %{
	#foreach ($item in $items){
		$item = $_;
		$buy = ""
		$sell = ""
		try{
			$buy = ($mci | where {$_.item -eq $item} | where {$_.buysell -match "buy"} | sort rate)[-1];
			$sell=$mci | where {$_.item -eq $item} | where {$_.buysell -match "sell"}|where {$_.rate -lt $buy.rate} | sort shopkeeper -unique
		}catch{};
		if($buy -and $sell){$buy;$sell}
	} 
}

Function Get-MCAvgPrice {
	param(
		$Item = "Diamond",
		[ValidateSet("buying","selling","trading")][string]$BuySell = "selling"
	)
	$m2 = $mci | where {$_.item -eq $Item} | where {$_.buysell -match $buysell} | sort shopkeeper -Unique | sort rate 

	$r2 = $m2 |%{$_.rate}
	$avg = ($r2 |measure-object -Average).average
		[math]::Round($avg,5)
}

Function Get-MCAvgPriceList {
	param(
		$Shopkeeper = "Haberson",
		[ValidateSet("buying","selling","trading")][string]$BuySell = "selling"
	)
	
	$items = ($mci | where {$_.buysell -match $buysell}| where {$_.Shopkeeper -match $Shopkeeper}) 
	$out = @()
	$items |%{
		$outvar = $_ | select Item, Rate, Average, Variance
		$outvar.Average = Get-MCAvgPrice $_.item
		$outvar.Variance = [math]::Round($outvar.Average - $outvar.Rate,5)
		
		$out += $outvar
	}
	$out 	
}

Function Get-MCEmptyShop {
	param(
		$player,
		$pmc = (Parse-MCChat -LogGoesBackDays 1),
		$mcb = (Get-MCItemPrices -NoTransFilter -LogGoesBackDays 1 -ParseMinecraftChat $pmc),
		$mcbPlayer = ($mcb | where {$_.shopkeeper -match $player}),
		$out = ("" | select TotalShops,NonEmptyShops,EmptyShopPct)
	)
	
try{
	$out.TotalShops = $mcbPlayer.count
	$out.NonEmptyShops = ($mcbPlayer|where {$_.transactions}).count
	$out.EmptyShopPct = 1-($out.NonEmptyShops/$out.TotalShops)
	$out
}catch{}

}

Function Get-MCItemPrices {
	[CmdletBinding()]
	param(
		[int]$LogGoesBackDays = 7,
		$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays),
		[switch]$NoTransFilter
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
		try{$_.Rate = if($Qty -and $Grass){[math]::Round($Grass/$Qty,6)}}catch{	}
		$_.TradeItem = $TradeItem
		}
	}

	if($NoTransFilter){
	$ParseMinecraftChat | where {$_.Item} | select Date, Shopkeeper, BuySell, Item, Qty, Grass, Transactions, Rate, TradeItem | sort item
	}else{
	$ParseMinecraftChat | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240} | select Date, Shopkeeper, BuySell, Item, Qty, Grass, Transactions, Rate, TradeItem | sort item
	}
} 

Function Get-MCItemSplit {
	param(
		$shopkeeper = "Haberson",
		$item="acacia sapling"
	)
	$b = $mci | where {$_.buysell -match "b"} 
	$s = $mci | where {$_.buysell -match "s"} 
	[array]$c =""
	foreach ($a in $b){
		$r = $s | where {$_.item -match $a.item} |where {$_.shopkeeper -match $a.shopkeeper}
		if ($r) {
		$out = $a | select Shopkeeper, Item, BuyGrass, BuyQty, BuyRate, SellGrass, SellQty, SellRate, Spread
		$out.BuyQty = $a.Qty
		$out.BuyGrass = $a.Grass
		$out.BuyRate = $a.Rate
		$out.SellQty = $r.Qty
		$out.SellGrass = $r.Grass
		$out.SellRate = $r.Rate
		$out.Spread = $a.rate/$r.rate
		$c+=$out 
		}
		
	}
	$c
}

Function Get-MCPlayerState {
	param(
		#$pmc = (Parse-MCChat -LogGoesBackDays 1),
		#$mcb = (Get-MCItemPrices -NoTransFilter -LogGoesBackDays 1 -ParseMinecraftChat $pmc)
	)
	write-host "Parsing $($pmc.count) lines"
	$playerdata = ($pmc | where {$_.message -match "has been online"}).message
	$playerdata += ($pmc | where {$_.message -match "has been offline"}).message
	$playerdata += ($pmc | where {$_.user -match "has been online"}).user
	$playerdata += ($pmc | where {$_.user -match "has been offline"}).user
	$pd = $playerdata -replace "Player ","" -replace " has been ","," -replace " since ","," -replace "\.",""|ConvertFrom-Csv -Header "Player","Status","LastChange"|sort player -unique
	write-host "Parsing player dates."
	
	$pd|%{
	#write-host "Parsing player $($_.Player) date"
		$NewDate = ""|select Month, Day, Hour, Minute, Second
		if($_.lastchange -match "month"){
			$NewDate.Month = ($_.lastchange -replace "s","" -split" month")
			$NewDate.Day = ($NewDate.Month -split" day")
			$NewDate.Hour = ($NewDate.Day -split" hour")
			$NewDate.Minute = 0
			$NewDate.Second = 0
		}elseif($_.lastchange -match "day"){
			$NewDate.Month = 0
			$NewDate.Day = ($_.lastchange -replace "s" -split" day")
			$NewDate.Hour = ($NewDate.Day -split" hour")
			$NewDate.Minute = ($NewDate.Hour -split" minute")
			$NewDate.Second = 0
		}elseif($_.lastchange -match "hour"){
			$NewDate.Month = 0
			$NewDate.Day = 0
			$NewDate.Hour = ($_.lastchange -replace "s" -split" hour")
			$NewDate.Minute = ($NewDate.Hour -split" minute")
			$NewDate.Second = ($NewDate.Second -split" econd")
		}elseif($_.lastchange -match "minute"){
			$NewDate.Month = 0
			$NewDate.Day = 0
			$NewDate.Hour = 0
			$NewDate.Minute = ($_.lastchange -replace "s","" -split" minute")
			$NewDate.Second = ($NewDate.Second -split" econd")
		}elseif($_.lastchange -match "econd"){
			$NewDate.Month = 0
			$NewDate.Day = 0
			$NewDate.Hour = 0
			$NewDate.Minute = 0
			$NewDate.Second = ($_.lastchange -replace "s","" -split" econd")
		}
		
		$_.lastchange = (get-date).AddMonths(-1*$NewDate.Month[0]).AddDays(-1*$NewDate.Day[0]).AddHours(-1*$NewDate.Hour[0]).AddMinutes(-1*$NewDate.Minute[0]).AddSeconds(-1*$NewDate.Second[0])
		
	}
	write-host "Combining $($pd.count) records."
	
	$pd | %{ 
		$_ = $_ | select Player, Status, LastChange, EmptyShopPct, EmptyShops, TotalShops, ShopRating, StoreTime, ShopTime
		$mces = (Get-MCEmptyShop $_.Player -pmc $pmc -mcb $mcb);
		
		$_.EmptyShopPct =[math]::Round($mces.EmptyShopPct,2)
		$_.EmptyShops = $mces.TotalShops-$mces.NonEmptyShops
		$_.TotalShops = $mces.TotalShops
		$_.ShopRating = [Math]::Round((Get-MCShopRating $_.Player),5)*100
		$_.StoreTime = Get-MCShopTime $_.Player
		try{$_.ShopTime = [Math]::Round($_.StoreTime/$mces.NonEmptyShops,2)}catch{}
		$_
	}
}

Function Get-MCShopkeepers {
	param(
		$visit="visit",
		$mcp = (($mcps | where {$_.lastchange -gt (get-date).AddDays(-1)} | where {$_.emptyshoppct -lt 0.5}| where {$_.totalshops}|sort totalshops).Player + ($mcps | where {$_.lastchange -gt (get-date).AddDays(-1)} | where {$_.totalshops -eq $null} | sort Player).Player),
		$out = ($mcp |where {$_.length -gt 1}|select -Unique)
	)
	$out | %{"/$visit " + $_ }
}

Function Get-MCShopRating {
	param(
		$Player="Haberson",
		$l = (Get-MCAvgPriceList $Player)
	)
	$mces = Get-MCEmptyShop $Player -pmc $pmc -mcb $mcb
	$m = ($l.variance |where {$_ -gt -10} |where {$_ -lt 10}|Measure-Object -Average).average
	$n = $mces.NonEmptyShops
try{
	$o = $n*((1-$m))/$mces.TotalShops
}catch{}
	$o
}

Function Get-MCSeen {
	$output = Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp (($mcps | where {$_.lastchange -gt (get-date).AddDays(-15)} | where {$_.EmptyShopPct -lt .5}).Player | sort -unique)
	$output += Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp (($mcps | where {$_.lastchange -gt (get-date).AddDays(-2)} | where {$_.totalshops -eq $null}).Player | sort -Unique)
	#Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp ($mcps.Player)
	$output
}

Function Get-MCWhoSells {
	param(
		$Item = "Diamond",
		[ValidateSet("buying","selling","trading")][string]$BuySell = "selling",
		[switch]$clip,
		[switch]$match,
		[switch]$unique
	)
	$mci2 = ($mci | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.transactions -gt 0})

	if ($match){
		$mci2 = $mci2 | where {$_.item -match $Item} 
	} else {
		$mci2 = $mci2 | where {$_.item -eq $Item} 
	}
	if ($BuySell -eq "buying"){
		$mci2 = $mci2 | where {$_.BuySell -match $BuySell} | sort rate -d
	} else {
		$mci2 = $mci2 | where {$_.BuySell -match $BuySell} | sort rate
	}
	$Shopkeepers = ($mci2 | select shopkeeper -Unique).shopkeeper
	
	$s2 = $Shopkeepers |%{$sh=$_;$mci2 | where {$_.shopkeeper -eq $sh}|sort rate } |select shopkeeper,qty,grass,transactions
	if ($unique){
		$s2 = $s2 | sort shopkeeper -Unique | sort rate
	} else {
	}
	$out = ($s2 |%{$_.shopkeeper+" ("+([int]$_.transactions*[int]$_.qty)+"@"+$_.qty+":"+$_.grass+")"}) -join ", "
	$out = ($out -split ", "|select -Unique) -join ", "

	$out = "These shops are $BuySell $Item"+": " + $out
	if ($clip){
		$out -join "" | Replace-Kirin | clip
	} else {
		$out | Replace-Kirin 
	}
	
}

Function get-mcw2{
	param(
		$item,
		$sort="date"
	)
	$mci | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.item -match $item} | sort $sort
}

function get-mcw3($item){$mci | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.item -match $item} | sort rate | ft}
function get-mcw4($item){$mcb | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.item -match $item} | sort rate | ft}

function Get-MCShopTime{
	param(
		$Player="Haberson"
	)
try{
$diffdate = ($mci|where {$_.shopkeeper -match $Player}|where {$_.date -gt (get-date).AddDays(-1)}).date |sort
$first = $diffdate[0]
$last = $diffdate[-1]
[math]::round(($last - $first).TotalSeconds,2)
}catch{}

}

function Get-MCPlayerReport{$mcps |sort player -unique|where {$_.LastChange  -gt (get-date).AddDays(-1)}|where {$_.totalshops}|sort ShopRating -d|ft}

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
New players - want to stretch your grass? [&cClick Here&f] to visit my &6G()ld Sh()p&f. Get 800 gold nuggets for your grass block, or bring your own. Many items for just 10 nuggets and weapons for 100 nuggets!
New players ==> [&cClick Here&f] to visit my &6G()ld Sh()p&f. Don't want 128 carrots for 1 grass? Get 1 carrot for 10 gold nuggets.
I sell 64 wheat seeds for 1 grass, or 1 wheat, melon, or pumpkin seed for 10 gold nuggets. Get 800 gold nuggets for your grass block at my &6G()ld Sh()p&f.
New players ==> Do &a/vote&f to get grass blocks, then [&cClick Here&f] to check out my &6G()ld Sh()p&f. Most items just 10 gold nuggets and weapons 100 nuggets! Get 800 gold nuggets for 1 grass, or bring your own.
Try to keep your grass from Kirby's donation bin. 
Renting hoppers, starting at 1 grass/day. 
If your baby refuses to do the hanky panky, you may be eligible for a grass settlement. [&cClick Here&f] for more details. 


Nether was last reset on June 8th
Bookshelf
6 planks = 1.5 logs
3 books = 3 leather + 3 paper = 3 sugar cane

64 = 96 logs + 192 leather + 192 sugar cane
64 = 1.5 grass + 3 grass + 3 grass = ~7 grass

Book and Quill
1 book = 1 leather + 3 paper = 3 sugar cane
1 feather
1 ink sac

64 = 64 feather + 64 ink sac + 192 sugar cane
64 = 1 grass + 1 grass + 3 grass = ~5 grass


Dmac: Website


Want grass more than voter keys? [&cClick Here&f] to sell your keys at my shop!

Suicidal squid in my doorway. Free ink sacs to my next visitor! Get it before clag does!
Slime spawner only works in slime chunks. To spawn slimes: Google "slime chunk finder" and use the seed Skyblock to find a slime chunk in your base. 
 - Learn to make a shop at /visit audibility
Are you ready for the &c4th&f of &9July&f? [&cClick Here&f] and stop by &cOne-Eyed&f Raven's &9Fireworks&f! Get a bite of the &c4th&f of &9July&f barbecue while you're here!

#>

<#

Villagers *can* be spawned, and zombie villagers cured, but you can't buy from them (only /warp grass), and they don't farm. Iron golems can be constructed but don't spawn.
Cobble gen and stone gen make ores every 100-400 stones or so.
Enable mob spawning in /settings. Animals stack so use a name tag to separate one for breeding.
If you don't use 1.12.2 then Herobrine breaks your doors and fences.
Fun fact: You can do /kit sapling every 45 minutes.
Grass is currency. To check your balance, look in your inventory or chest to see how many grass blocks you have. You might want the Economy server.
7 ways to expand your surface: 1. generate cobble. 2. grow trees 3. Get netherrack 4. Shave sheep 5. Grow a LOT of pumpkins/melons. 6. Spawn skeletons & make bone blocks. 7. buy stone at a shop like mine.
If you're building over the void, there's client side voidlag from recalculating the lighting over the whole void. Server lag is additional. 

It's Minecraft - do what you'd do on any other server. Mine, craft, fight mobs, build your base, have fun!

Use grass for dirt. Get grass from /vote, vote parties, word unscrambles, maybe sb /lottery, /ma j, & /warp crates too. Or your own shop, or sell to a buy shop like mine. 

Tired of L()()King at the endless void? [&cClick Here&f] to visit my island paradise!  ==> Fish! Swim (don't drown)! Get free food! Make friends with the boat dogs! Slay cows and sheep at the mob grinder!

Feeling stressed? Set /quiet and [&cClick Here&f] to visit my island paradise. Relax among the trees and enjoy the water.

You can ride your bike with no handlebars at my island. [&cClick Here&f] to visit!

Wifi is available at my island. [&cClick Here&f] to visit!

You Require More Pylons. [&cClick Here&f] to obtain them!

Selling red dirt 1:1 - Ender Pears 3:1 - harmburgers 64:1 - pimpkings 64:1 - peach cobble 2240:1 - water lemons 64:1 - boney meals 64:1 - oak woof 128:1 - Zombie Pigment for 55 grass. Now selling gluten-free wool. [&cClick Here&f] for more info!

There are shops at /warp grass but many player shops (like mine) have better prices.

New players ==> Do &a/vote&f to get grass blocks, then [&cClick Here&f] to get 800 gold nuggets for 1 grass at my &6G()ld Sh()p&f, or bring your own. Most items just 10 gold nuggets and weapons 100 nuggets!

WhoSells v2 is out now! [&cClick Here&f] to exchange your v1.2 copy for a v2!

Donate to end world hunger. Your donation of 1 grass block can feed 64 hungry minecrafters. [&cClick Here&f] to help now!

Have you been accused of dirt trade? [&cClick Here&f] to get legal help in clearing your good name. (by Law Office of Gilgamech, esquire)

Are you lagging? [&cClick Here&f] to visit my shop. Let retail therapy clear your worries until ClearLag clears the lag.

"The best way to provide charity is to set up the world so that people don't need to beg in the first place." - adapted from Maimonides

"Nothing is to be feared. It is only to be understood. Now is the time to understand more, so that we may fear less." - Marie Curie.

If you're going to change the world, please change it for the better. We have enough people changing it for the worse.

Has your wam become dedotated? [&cClick Here&f] to get assistance in reversing the process. 

It's dangerous to go alone. Here, take this: (>^_^)>

We have the most lag. The greatest lag. The best lag ever.
Lagging in the morning, lagging in the evening, lagging at suppertime. When you're on a Skyblock, you could be lagging anytime!
#>

<#

cd C:\Dropbox\
ipmo -Force .\script.ps1
$mcb = gc .\MCItemPrices_20190710.csv |ConvertFrom-Csv
$mcps = gc .\MCPlayerState_20190710.csv |ConvertFrom-Csv
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}

/visit dexgeta
/visit panglong


Get-MCSeen -mcps $mcps -mcp $mcp  |clip

$pmc = Parse-MCChat -LogGoesBackDays 1
$mcb = Get-MCItemPrices -ParseMinecraftChat $pmc -NoTransFilter
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb
Get-MCShopkeepers -mcps $mcps |clip

$pmc = Parse-MCChat -LogGoesBackDays 1
$mcb = Get-MCItemPrices -ParseMinecraftChat $pmc -NoTransFilter
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb

$mcb|ConvertTo-Csv > .\MCItemPrices_20190711.csv 
$mcps|ConvertTo-Csv > .\MCPlayerState_20190711.csv 

Get-MCBookOutput > .\book.txt




#>

<#


WhoSells?
Volume Test
7/3/2019

Listing shops on bases played in the past month, with more than half of shops in-stock.

PlayerName (Total@Qty:Grass)





#>




