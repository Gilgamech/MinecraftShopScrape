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

#region Functions
filter Replace-Kirin {
$_ = $_ -replace "\+  Welcome to Kirin","Riink"
$_ = $_ -replace "§7",""
$_ = $_ -replace "§r",""
$_ = $_ -replace "bonemeal","bone meal"
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
		[string]$ChatLogName = "$ChatLogLocation\latest.log",
		[int]$LogGoesBackDays = 7,
		[int]$Tail = 0
	)
	
	if ($LogGoesBackDays -gt 0) {
		write-host "Gathering logs"
		ls $ChatLogLocation -Exclude 'latest.log'| where {$_.LastWriteTime -gt (get-date).AddDays($LogGoesBackDays*-1)} | %{
			$t = $_;$chatlog += ConvertFrom-Gzip -Path $_.FullName|%{
				($t.CreationTime.tostring() -split " ")[0] + "," + $_
			}
		}
	write-host "Parsing $($chatlog.count +1) log records"
	}
	
	$date = (get-date -f d)
	if ($Tail -gt 0) {
		$chatlog += (Get-Content -Tail $Tail $ChatLogName)|%{$date + "," + $_}
	}else{
		$chatlog += (Get-Content  $ChatLogName)|%{$date + "," + $_}
	}
	
	$chatlog = $chatlog -replace "§0","" -replace "§1","" -replace "§2","" -replace "§3","" -replace "§4","" -replace "§5","" -replace "§6","" -replace "§7","" -replace "§8","" -replace "§9","" -replace "§a","" -replace "§b","" -replace "§c","" -replace "§d","" -replace "§e","" -replace "§f","" -replace "§r",""
	$list = $chatlog -replace "\[+ Mod\]",'' -replace "\[Donor\]",'' -replace "\[Skytitan\]",'' -replace "\[Skygod\]",'' -replace "\[Skyking\]",'' -replace "\[Skylord\]",''  -replace "\[Skyknight\]",'' -replace "\[",'' -replace "\] ",',' -replace ": ",',' | ConvertFrom-Csv -Header Date,Time,type,source,user,message,Shopkeeper
	$listcount=$list.count
	
	$list | %{
		$f=$list.IndexOf($_)+1
		$i = [math]::round(($f/$listcount)*100,2)

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
		Write-Progress -Activity "Parsing Date $($_.date) - $f of $listcount" -Status "$i% Complete:" -PercentComplete $i
		$_.shopkeeper = $shopkeeper
	}
	
	#write-host "Outputting $($list.count) shops"
	$list | select Date,type,source,user,message,Shopkeeper
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
		$outvar.Variance = [math]::Round($outvar.Rate - $outvar.Average,5)
		
		$out += $outvar
	}
	$out 	
}

Function Get-MCBookOutput {
	param(
		$items = ((($mci | group item | sort count -d).name |select -Unique)[0..49])
	)
	
	<#
	$f=((Get-History).CommandLine |Select-String "Get-MCWhoSells") -replace "Get-MCWhoSells ","" -replace "-clip ","" -replace "-match ","" -replace "-unique ","" -replace "-BuySell ","" -replace "buying ","" -replace "-m ","" -replace "-u ",""
	$f = $f -replace '"',""
	$g = $f |group
	$items = ($g|sort count -Descending)[0..55].name
	$TextInfo = (Get-Culture).TextInfo
	$TextInfo.ToTitleCase($items)
	#>

$items | sort | %{((((Get-MCWhoSells $_) -replace "These shops are selling ","" )[0..255] -join "" -replace "\r","" -split ", " |select-string "\)"| select -u) -join ", ")}
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
	$out.NonEmptyShops = ($mcbPlayer|where {[int]$_.transactions -gt 0}).count
	$out.EmptyShopPct = 1-([int]$out.NonEmptyShops/[int]$out.TotalShops)
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
	$PMCcount=$ParseMinecraftChat.count
	write-host "Combining $PMCcount log records"
	$ParseMinecraftChat = $ParseMinecraftChat | select user,message,Qty,BuySell,Item,Grass,Shopkeeper,Transactions,Rate,Date,Time,TradeItem | where {$_.user -match "this shop"}
	$ParseMinecraftChat | %{
		$f=$ParseMinecraftChat.IndexOf($_)
		$i = [math]::round(($f/$PMCcount)*100,2)
		Write-Progress -Activity "Compiling Shopkeeper $($_.Shopkeeper) - $f of $PMCcount" -Status "$i% Complete:" -PercentComplete $i

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

		#$_.Date = try{get-date $_.Date}catch{$_.date}
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
	write-host "Parsing $($pd.count) player dates."
	
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
	$pd
	
}

Function Get-MCShopkeepers {
	param(
		$visit="visit",
		$mcp = (($MCSRTA | where {$_.lastchange -gt (get-date).AddDays(-1)} | where {$_.ShopRating -gt 50}| where {$_.totalshops}|sort totalshops).Player + ($MCSRTA | where {$_.lastchange -gt (get-date).AddDays(-1)} | where {$_.totalshops -eq $null} | sort Player).Player),
		$out = ($mcp |where {$_.length -gt 1}|select -Unique)
	)
	$out | %{"/$visit " + $_ }
}

Function Get-MCShopkeepers2 {
	param(
		$visit="visit",
		$mcp = (($MCSR | where {$_.lastchange -gt (get-date).AddDays(-1)} |  where {$_.totalshops}|sort totalshops).Player + ($MCSR | where {$_.lastchange -gt (get-date).AddDays(-1)} | where {$_.totalshops -eq $null} | sort Player).Player),
		$out = ($mcp |where {$_.length -gt 1}|select -Unique)
	)
	$out | %{"/$visit " + $_ }
}

Function Get-MCShopReport {
	$mcps | %{ 
		$f=$mcps.IndexOf($_)
		$c=$mcps.count
		$i = [math]::round(($f/$c)*100,2)
		Write-Progress -Activity "Compiling player $($_.Player) - $f of $c" -Status "$i% Complete:" -PercentComplete $i
		$_ = $_ | select Player, Status, LastChange, EmptyShopPct, EmptyShops, Variance, TotalShops, ShopRating, RelativeTotalShops, StoreTime, ShopTime, ShopTimeVariance
		$mces = (Get-MCEmptyShop $_.Player -pmc $pmc -mcb $mcb);
		$mcs = (Get-MCShopRating $_.Player)
		
		$_.EmptyShopPct =[math]::Round($mces.EmptyShopPct,2)
		$_.EmptyShops = $mces.TotalShops-$mces.NonEmptyShops
		$_.TotalShops = $mces.TotalShops
		try{$_.ShopRating = [Math]::Round($mcs.ShopRating,5)}catch{}
		try{$_.RelativeTotalShops = $_.ShopRating*$_.TotalShops}catch{}
		$_.StoreTime = Get-MCShopTime $_.Player
		$_.Variance = [Math]::Round(($mcs.Variance|Measure-Object -Average).average,5)
		try{$_.ShopTime = [Math]::Round($_.StoreTime/$mces.TotalShops,2)}catch{}
		$_
	}
}

Function Get-MCShopNames {
	param(
		[int]$LogGoesBackDays = 7,
		$ParseMinecraftChat = (Parse-MCChat -LogGoesBackDays $LogGoesBackDays)
	)
	$ParseMinecraftChat | sort message | select message,shopkeeper -u | group message | select name,@{n="shopkeeper";e={$_.group.shopkeeper -replace "{",'' -replace "'s island\.",""}}
}

Function Get-MCShopRating {
	param(
		$Player="Haberson",
		$MCAvgPriceList = (Get-MCAvgPriceList $Player)
	)
	$mces = Get-MCEmptyShop $Player -pmc $pmc -mcb $mcb
	$AvgVariance = ($MCAvgPriceList.variance |where {$_ -gt -10} |where {$_ -lt 10}|Measure-Object -Average).average
	$Output = "" | select ShopRating,Variance
try{
	$Output.ShopRating = $mces.NonEmptyShops*100*(1-$AvgVariance)
	#$Output.ShopRating = (1-$mces.EmptyShopPct)*100*(-$AvgVariance)
}catch{}
	$Output.Variance = $AvgVariance
	$Output
}

function Get-MCShopTime{
	param(
		$Player="Haberson"
	)
try{
$diffdate = ($mci|where {$_.shopkeeper -match $Player}|where {(get-date $_.date).date -eq (get-date).date}).date |sort
$diffdate |%{$_ = try{get-date $_}catch{$_}}
$first = get-date $diffdate[0]
$last = get-date $diffdate[-1]
[math]::round(($last - $first).TotalSeconds,2) |where {[int]$_ -lt 600}
}catch{}

}

function Get-MCShopTimeAvg{
($mcsr.storetime |where {[int]$_}|Measure-Object -Sum).sum/($mcsr.totalshops |where {[int]$_}|Measure-Object -Sum).sum
}

Function Get-MCSRTA {
	$mcsr |%{
		$f=$mcsr.IndexOf($_)
		$c=$mcsr.count
		$i = [math]::round(($f/$c)*100,2)
		Write-Progress -Activity "Compiling player $($_.Player) - $f of $c" -Status "$i% Complete:" -PercentComplete $i
		$_ = $_ | select Player, Status, LastChange, EmptyShopPct, EmptyShops, Variance, TotalShops, ShopRating, RelativeTotalShops, StoreTime, ShopTime, ShopTimeVariance

		$sta = Get-MCShopTimeAvg
		$_.ShopTimeVariance = [Math]::Round($_.ShopTime/$sta,5)#($_.ShopTime - $sta,5)
		try{$_.ShopRating = [Math]::Round($_.ShopRating * (1/$_.ShopTimeVariance)/$_.TotalShops,5)}catch{}
		#try{$_.ShopRating = [Math]::Round($_.ShopRating * (1-$_.ShopTimeVariance)/$_.TotalShops,5)}catch{}
<#
		
		$mces = (Get-MCEmptyShop $_.Player -pmc $pmc -mcb $mcb);
		$mcs = (Get-MCShopRating $_.Player)
		
		$_.EmptyShopPct =[math]::Round($mces.EmptyShopPct,2)
		$_.EmptyShops = $mces.TotalShops-$mces.NonEmptyShops
		$_.TotalShops = $mces.TotalShops
		$_.StoreTime = Get-MCShopTime $_.Player
		$_.Variance = [Math]::Round(($mcs.Variance|Measure-Object -Average).average,5)
		try{$_.ShopTime = [Math]::Round($_.StoreTime/$mces.TotalShops,2)}catch{}
#>		
		$_
	}

}

Function Get-MCSeen {
	$output = Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp (($mcps | where {$_.lastchange -gt (get-date).AddDays(-30)} | where {$_.EmptyShopPct -lt .5}).Player | sort -unique)
	$output += Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp (($mcps | where {$_.lastchange -gt (get-date).AddDays(-2)} | where {$_.totalshops -eq $null}).Player | sort -Unique)
	#Get-MCShopkeepers -visit "seen" -mcps $mcps -mcp ($mcps.Player)
	$output -split " ","" | %{"/seen " + $_ } |sort -u
}

Function Get-MCWhoSells {
	param(
		$Item = "Diamond",
		[ValidateSet("buying","selling","trading")][string]$BuySell = "selling",
		[switch]$Clip,
		[switch]$Match,
		[switch]$Unique
	)
	$mci2 = ($mci  | where {$_.transactions -gt 0})#| where {$_.date -gt (get-date).AddDays(-1)}

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
	if ($Unique){
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

#$loglength= (Parse-MCChat -LogGoesBackDays 0).count
$logdate=get-date
Function Run-Skybot{
	param(
		$item,
		$sort="date",
		[string]$ChatLogLocation = "$env:APPDATA\.minecraft\logs"
	)
#csv to check who's bought how many requests
#10? a day free
#10? per grass
#Use a signed coupon book and chat logs.

	$sellbuy = "selling"
	$a=1
	echo $null | clip.exe
	Write-Host "Clearing clipboard for startup."
	
	while($a -eq 1){
		$d = get-date
		$date = (get-date -f d)
		$pb = Parse-MCChat -LogGoesBackDays 0 -tail 100
		$l = $pb.count
		$loglength = $pb.IndexOf(($pb |where {$_.date -eq $logdate} |select -first 1))
		$logdate = $pb[-1].date
		$llpl = $l - $loglength
		#"`n"
		$pr = $pb[$loglength..$l]
		$loglength = $l
		foreach ($p in $pr) {
			if ($p.message -eq "bot off") {
				#kill switch
				$a=0
				Write-Host $p
			}
			if ((($p.user -match "Gilgamech") -OR($p.user -match "me ->")) -AND (($p.message -match "These shops are ") -OR ($p.message -match "Nobody sells ") -OR ($p.message -match "Do /visit Audibility ") -OR ($p.message -match "Get grass from "))) {
				Write-Host "Response found, clearing clipboard."
				echo $null | clip.exe
			}
			if (($p.message -match "how to make a shop?") -OR ($p.message -match "how to make a cobble gen?") -OR ($p.message -match "is there a shop tutorial?")) {
			#How to make a shop
				Write-Host "$($p.user) asked $($p.message)"
				$gmcw = "Do /visit Audibility for a tutorial"
				$gmcw | clip
			}
			if (($p.message -match "how to silence chat?") -OR ($p.message -match "how to make chat quiet?") -OR ($p.message -match "is there a way to silence c hat?")) {
				#How to silence chat
				Write-Host "$($p.user) asked $($p.message)"
				$gmcw = "Do /visit Audibility for a tutorial"
				$gmcw | clip
			}
				

			#Who Sells
			if (($p.message -match "who sells")  -OR ($p.message -match "who sell")  -OR ($p.message -match "whos selling") -OR ($p.message -match "who selling ") -OR ($p.message -match "who's selling ") -OR ($p.message -match "who is selling ") -OR ($p.message -match "anyone sell ") -OR ($p.message -match "anyone sells ") -OR ($p.message -match "anyone selling ") -OR ($p.message -match "anyone have ") -OR ($p.message -match "anyone selling ") -OR ($p.message -match "any shop selling ") -OR ($p.message -match "who buys")  -OR ($p.message -match "who buy")  -OR ($p.message -match "whos buying") -OR ($p.message -match "who buying ") -OR ($p.message -match "who's buying ") -OR ($p.message -match "who is buying ") -OR ($p.message -match "anyone buy ") -OR ($p.message -match "anyone buys ") -OR ($p.message -match "anyone buying ") -OR ($p.message -match "anyone have ") -OR ($p.message -match "anyone buying ") -OR ($p.message -match "any shop buying ")) {
				switch -wildcard ($p.message) {
					"*who sell*" {
						$before,$item = $p.message -split "who sell " 
						$sellbuy = "selling"
					}
					"*who sells*" {
						$before,$item = $p.message -split "who sells " 
						$sellbuy = "selling"
					}
					"*who selling*" {
						$before,$item = $p.message -split "who selling " 
						$sellbuy = "selling"
					}
					"*whos selling*" {
						$before,$item = $p.message -split "whos selling " 
						$sellbuy = "selling"
					}
					"*who's selling*" {
						$before,$item = $p.message -split "who's selling " 
						$sellbuy = "selling"
					}
					"*who is selling*" {
						$before,$item = $p.message -split "who is selling " 
						$sellbuy = "selling"
					}
					"*anyone sell*" {
						$before,$item = $p.message -split "anyone sell " 
						$sellbuy = "selling"
					}
					"*anyone sells*" {
						$before,$item = $p.message -split "anyone sells " 
						$sellbuy = "selling"
					}
					"*anyone selling*" {
						$before,$item = $p.message -split "anyone selling " 
						$sellbuy = "selling"
					}
					"*anyone have*" {
						$before,$item = $p.message -split "anyone have " 
						$sellbuy = "selling"
					}
					"*anybody selling*" {
						$before,$item = $p.message -split "anybody selling " 
						$sellbuy = "selling"
					}
					"*any shop selling*" {
						$before,$item = $p.message -split "any shop selling " 
						$sellbuy = "selling"
					}
				#Buy shops
					"*who buy*" {
						$before,$item = $p.message -split "who buy " 
						$sellbuy = "buying"
					}
					"*who buys*" {
						$before,$item = $p.message -split "who buys " 
						$sellbuy = "buying"
					}
					"*who buying*" {
						$before,$item = $p.message -split "who buying " 
						$sellbuy = "buying"
					}
					"*whos buying*" {
						$before,$item = $p.message -split "whos buying " 
						$sellbuy = "buying"
					}
					"*who's buying*" {
						$before,$item = $p.message -split "who's buying " 
						$sellbuy = "buying"
					}
					"*who is buying*" {
						$before,$item = $p.message -split "who is buying " 
						$sellbuy = "buying"
					}
					"*anyone buy*" {
						$before,$item = $p.message -split "anyone buy " 
						$sellbuy = "buying"
					}
					"*anyone buys*" {
						$before,$item = $p.message -split "anyone buys " 
						$sellbuy = "buying"
					}
					"*anyone buying*" {
						$before,$item = $p.message -split "anyone buying " 
						$sellbuy = "buying"
					}
					"*anyone want*" {
						$before,$item = $p.message -split "anyone have " 
						$sellbuy = "buying"
					}
					"*anybody buying*" {
						$before,$item = $p.message -split "anybody buying " 
						$sellbuy = "buying"
					}
					"*any shop buying*" {
						$before,$item = $p.message -split "any shop buying " 
						$sellbuy = "buying"
					}
					default {
						write-host Switch 0 Default Output 
						$sellbuy = "null"
					}
					}
				#Build response
				Write-Host "$($p.user) asked for $item - $($p.message)"
				$p.user = $p.user -replace "§0","" -replace "§1","" -replace "§2","" -replace "§3","" -replace "§4","" -replace "§5","" -replace "§6","" -replace "§7","" -replace "§8","" -replace "§9","" -replace "§a","" -replace "§b","" -replace "§c","" -replace "§d","" -replace "§e","" -replace "§f","" -replace "§r",""
				$item = $item -replace "[^a-zA-Z ]",""
				if($item -match 's$'){$item=$item.Substring(0,$item.Length-1)}
				$gmcw = ""
				switch -wildcard ($item) {
"*Yellow Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Yellow Wool"}
"*Yellow Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Yellow Stained Clay"}
"*Yellow Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Yellow Glazed Terracotta"}
"*Written Book*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Written Book"}
"*White Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "White Wool"}
"*White Tulip*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "White Tulip"}
"*White Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "White Stained Clay"}
"*White Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "White Glazed Terracotta"}
"*Wheat*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Wheat"}
"*Wheat Seed*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Wheat Seeds"}
"*Ward Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ward Disc"}
"*Wait Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Wait Disc"}
"*Voter Crate Key*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Voter Crate Key"}
"*Vine*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Vines"}
"*Trapped Chest*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Trapped Chest"}
"*Torch*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Torch"}
"*TNT*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "TNT"}
"*Tall Gras*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Tall Grass"}
"*Sunflower*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sunflower"}
"*Sugar*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sugar"}
"*Sugar Cane*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sugar Canes"}
"*String*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "String"}
"*Strad Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Strad Disc"}
"*Stone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone"}
"*Stone Sword*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Sword"}
"*Stone Slab*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Slab"}
"*Stone Shovel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Shovel"}
"*Stone Pickaxe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Pickaxe"}
"*Stone Button*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Button"}
"*Stone Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Bricks"}
"*Stone Brick Slab*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stone Brick Slab"}
"*Sticky Piston*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sticky Piston"}
"*Steak*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Steak"}
"*Stal Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Stal Disc"}
"*Spruce Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Spruce Wood"}
"*Spruce Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Spruce Sapling"}
"*Spruce Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Spruce Leaves"}
"*Sponge*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sponge"}
"*Spider Eye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Spider Eye"}
"*Soul Sand*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Soul Sand"}
"*Snowball*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Snowball"}
"*Snow*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Snow"}
"*Snow Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Snow Block"}
"*Slimeball*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Slimeball"}
"*Slime Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Slime Block"}
"*Sheep Spawner*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sheep Spawner"}
"*Shear*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Shears"}
"*Sea Lantern*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Sea Lantern"}
"*Saddle*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Saddle"}
"*Rotten Flesh*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rotten Flesh"}
"*Rose Red*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rose Red"}
"*Rose Bush*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rose Bush"}
"*Redstone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone"}
"*Redstone Torch (on)*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Torch (on)"}
"*Redstone Repeater*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Repeater"}
"*Redstone Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Ore"}
"*Redstone Lamp (inactive)*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Lamp (inactive)"}
"*Redstone Comparator*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Comparator"}
"*Redstone Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Redstone Block"}
"*Red Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Wool"}
"*Red Tulip*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Tulip"}
"*Red Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Stained Clay"}
"*Red Sandstone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Sandstone"}
"*Red Sand*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Sand"}
"*Red Nether Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Nether Brick"}
"*Red Mushroom Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Mushroom Block"}
"*Red Mushroom*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Mushroom"}
"*Red Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Red Glazed Terracotta"}
"*Raw Salmon*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Salmon"}
"*Raw Porkchop*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Porkchop"}
"*Raw Mutton*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Mutton"}
"*Raw Fish*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Fish"}
"*Raw Chicken*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Chicken"}
"*Raw Beef*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Raw Beef"}
"*Rare Pot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rare Pot"}
"*Rare Crate Key*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rare Crate Key"}
"*Rail*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rail"}
"*Rabbit Food*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Rabbit Food"}
"*Quartz Stair*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Quartz Stairs"}
"*Quartz Slab*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Quartz Slab"}
"*Quartz Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Quartz Block"}
"*Purpur Pillar*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purpur Pillar"}
"*Purpur Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purpur Block"}
"*Purple Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purple Wool"}
"*Purple Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purple Stained Clay"}
"*Purple Shulker Box*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purple Shulker Box"}
"*Purple Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purple Glazed Terracotta"}
"*Purple Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Purple Dye"}
"*Pumpkin*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pumpkin"}
"*Pumpkin Seed*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pumpkin Seeds"}
"*Pumpkin Pie*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pumpkin Pie"}
"*Pufferfish*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pufferfish"}
"*Prismarine*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Prismarine"}
"*Prismarine Shard*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Prismarine Shard"}
"*Prismarine Crystal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Prismarine Crystals"}
"*Prismarine Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Prismarine Bricks"}
"*Powered Rail*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Powered Rail"}
"*Potion*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Potion"}
"*Potato*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Potato"}
"*Poppy*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Poppy"}
"*Polished Granite*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Polished Granite"}
"*Polished Diorite*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Polished Diorite"}
"*Piston*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Piston"}
"*Pink Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pink Wool"}
"*Pink Tulip*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pink Tulip"}
"*Pink Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pink Stained Clay"}
"*Pink Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pink Glazed Terracotta"}
"*Pink Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Pink Dye"}
"*pig Spawner*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "pig Spawner"}
"*Peony*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Peony"}
"*Paper*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Paper"}
"*Painting*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Painting"}
"*Packed Ice*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Packed Ice"}
"*Oxeye Daisy*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Oxeye Daisy"}
"*Orange Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Orange Wool"}
"*Orange Tulip*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Orange Tulip"}
"*Orange Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Orange Stained Clay"}
"*Orange Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Orange Glazed Terracotta"}
"*Orange Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Orange Dye"}
"*Obsidian*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Obsidian"}
"*Observer*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Observer"}
"*Oak Wood Plank*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Oak Wood Plank"}
"*Oak Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Oak Wood"}
"*Oak Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Oak Sapling"}
"*Oak Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Oak Leaves"}
"*Note Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Note Block"}
"*Netherrack*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Netherrack"}
"*Nether Wart*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Wart"}
"*Nether Wart Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Wart Block"}
"*Nether Star*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Star"}
"*Nether Quartz*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Quartz"}
"*Nether Quartz Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Quartz Ore"}
"*Nether Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Brick"}
"*Nether Brick Fence*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Nether Brick Fence"}
"*Name Tag*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Name Tag"}
"*Mycelium*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mycelium"}
"*Mushroom Stew*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mushroom Stew"}
"*Mossy Stone Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mossy Stone Bricks"}
"*Moss Stone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Moss Stone"}
"*Monster Egg*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Monster Egg"}
"*Mob Head (Human)*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mob Head (Human)"}
"*Minecart*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Minecart"}
"*Melon*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Melon"}
"*Melon Seed*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Melon Seeds"}
"*Melon Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Melon Block"}
"*Mellohi Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mellohi Disc"}
"*Mall Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Mall Disc"}
"*Magma Cream*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magma Cream"}
"*Magma Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magma Block"}
"*Magic Notebook*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magic Notebook"}
"*Magenta Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magenta Wool"}
"*Magenta Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magenta Stained Clay"}
"*Magenta Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magenta Glazed Terracotta"}
"*Magenta Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Magenta Dye"}
"*Lime Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lime Wool"}
"*Lime Shulker Box*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lime Shulker Box"}
"*Lime Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lime Glazed Terracotta"}
"*Lime Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lime Dye"}
"*Lily Pad*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lily Pad"}
"*Lilac*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lilac"}
"*Light Gray Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Gray Wool"}
"*Light Gray Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Gray Stained Clay"}
"*Light Gray Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Gray Glazed Terracotta"}
"*Light Gray Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Gray Dye"}
"*Light Blue Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Blue Wool"}
"*Light Blue Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Blue Stained Clay"}
"*Light Blue Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Blue Glazed Terracotta"}
"*Light Blue Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Light Blue Dye"}
"*Leather*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Leather"}
"*Leather Tunic*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Leather Tunic"}
"*Leather Pant*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Leather Pants"}
"*Leather Helmet*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Leather Helmet"}
"*Leather Boot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Leather Boots"}
"*Lead*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lead"}
"*Lapis Lazuli*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lapis Lazuli"}
"*Lapis Lazuli Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lapis Lazuli Ore"}
"*Lapis Lazuli Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Lapis Lazuli Block"}
"*Jungle Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Jungle Wood"}
"*Jungle Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Jungle Sapling"}
"*Jungle Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Jungle Leaves"}
"*Jungle Door*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Jungle Door"}
"*Jukebox*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Jukebox"}
"*Item Frame*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Item Frame"}
"*Iron Sword*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Sword"}
"*Iron Shovel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Shovel"}
"*Iron Pickaxe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Pickaxe"}
"*Iron Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Ore"}
"*Iron Ingot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Ingot"}
"*Iron Horse Armor*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Horse Armor"}
"*Iron Hoe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Hoe"}
"*Iron Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Block"}
"*Iron Bar*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Bars"}
"*Iron Axe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Iron Axe"}
"*Ink Sack*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ink Sack"}
"*Independence Pickaxe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Independence Pickaxe"}
"*Ice*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ice"}
"*Hopper*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Hopper"}
"*Hay Bale*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Hay Bale"}
"*Hardened Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Hardened Clay"}
"*Hard Boiled Egg*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Hard Boiled Egg"}
"*Gunpowder*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gunpowder"}
"*Green Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Green Wool"}
"*Green Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Green Stained Clay"}
"*Green Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Green Glazed Terracotta"}
"*Gray Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gray Wool"}
"*Gray Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gray Stained Clay"}
"*Gray Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gray Glazed Terracotta"}
"*Gray Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gray Dye"}
"*Gravel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gravel"}
"*Granite*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Granite"}
"*Golden Sword*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Sword"}
"*Golden Shovel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Shovel"}
"*Golden Pickaxe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Pickaxe"}
"*Golden Legging*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Leggings"}
"*Golden Horse Armor*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Horse Armor"}
"*Golden Hoe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Hoe"}
"*Golden Helmet*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Helmet"}
"*Golden Chestplate*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Chestplate"}
"*Golden Carrot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Carrot"}
"*Golden Boot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Boots"}
"*Golden Axe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Axe"}
"*Golden Apple*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Golden Apple"}
"*Gold Sword*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gold Sword"}
"*Gold Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gold Ore"}
"*Gold Ingot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gold Ingot"}
"*Gold Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Gold Block"}
"*Glowstone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Glowstone"}
"*Glowstone Dust*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Glowstone Dust"}
"*Glas*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Glass"}
"*Glass Pane*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Glass Pane"}
"*Glass Bottle*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Glass Bottle"}
"*Ghast Tear*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ghast Tear"}
"*Furnace*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Furnace"}
"*Fortunate*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Fortunate"}
"*Flower Pot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Flower Pot"}
"*Flint*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Flint"}
"*Flint and Steel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Flint and Steel"}
"*Fishing Rod*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Fishing Rod"}
"*Firework Rocket*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Firework Rocket"}
"*Fire Charge*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Fire Charge"}
"*Feather*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Feather"}
"*Far Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Far Disc"}
"*Eye of Ender*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Eye of Ender"}
"*Ender Pearl*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ender Pearl"}
"*Ender Chest*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ender Chest"}
"*End Stone Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "End Stone Bricks"}
"*End Stone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "End Stone"}
"*End Rod*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "End Rod"}
"*End Crystal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "End Crystal"}
"*Enchantment Table*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Enchantment Table"}
"*Enchanted Golden Apple*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Enchanted Golden Apple"}
"*Enchanted Book*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Enchanted Book"}
"*Empty Map*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Empty Map"}
"*Emerald*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Emerald"}
"*Egg*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Egg"}
"*Dropper*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dropper"}
"*Dispenser*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dispenser"}
"*Diorite*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diorite"}
"*Diamond*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond"}
"*Diamond Sword*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond Sword"}
"*Diamond Shovel*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond Shovel"}
"*Diamond Pickaxe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond Pickaxe"}
"*Diamond Horse Armor*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond Horse Armor"}
"*Diamond Axe*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Diamond Axe"}
"*Detector Rail*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Detector Rail"}
"*Daylight Sensor*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Daylight Sensor"}
"*Dark Prismarine*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dark Prismarine"}
"*Dark Oak Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dark Oak Wood"}
"*Dark Oak Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dark Oak Sapling"}
"*Dark Oak Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dark Oak Leaves"}
"*Dandelion*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dandelion"}
"*Dandelion Yellow*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Dandelion Yellow"}
"*Cyan Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cyan Wool"}
"*Cyan Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cyan Stained Clay"}
"*Cyan Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cyan Glazed Terracotta"}
"*Cyan Dye*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cyan Dye"}
"*Create a Skyblock*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Create a Skyblock"}
"*Cracked Stone Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cracked Stone Bricks"}
"*Cookie*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cookie"}
"*Cooked Porkchop*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cooked Porkchop"}
"*Cooked Mutton*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cooked Mutton"}
"*Cooked Fish*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cooked Fish"}
"*Cooked Chicken*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cooked Chicken"}
"*Concrete*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Concrete"}
"*Concrete Powder*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Concrete Powder"}
"*Compas*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Compass"}
"*Common Crate Key*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Common Crate Key"}
"*Coco Bean*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Coco Beans"}
"*Cobweb*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cobweb"}
"*Cobblestone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cobblestone"}
"*Cobblestone Slab*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cobblestone Slab"}
"*Coal Ore*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Coal Ore"}
"*Coal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Coal"}
"*Clock*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Clock"}
"*Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Clay"}
"*Chorus Fruit*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chorus Fruit"}
"*Chorus Flower*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chorus Flower"}
"*Chiseled Stone Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chiseled Stone Bricks"}
"*Chirp Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chirp Disc"}
"*Chest*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chest"}
"*Charcoal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Charcoal"}
"*Chainmail Legging*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chainmail Leggings"}
"*Chainmail Helmet*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chainmail Helmet"}
"*Chainmail Chestplate*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chainmail Chestplate"}
"*Chainmail Boot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Chainmail Boots"}
"*Cat Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cat Disc"}
"*Carrot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Carrot"}
"*Carrot on a Stick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Carrot on a Stick"}
"*Cake*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cake"}
"*Cactu*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cactus"}
"*Cactus Green*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Cactus Green"}
"*Brown Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brown Wool"}
"*Brown Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brown Stained Clay"}
"*Brown Mushroom*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brown Mushroom"}
"*Brown Mushroom Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brown Mushroom Block"}
"*Brown Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brown Glazed Terracotta"}
"*Brick*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bricks"}
"*Brewing Stand*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Brewing Stand"}
"*Bread*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bread"}
"*Bow*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bow"}
"*Bottle o' Enchanting*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bottle o' Enchanting"}
"*Bookshelf*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bookshelf"}
"*Book*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Book"}
"*Book and Quill*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Book and Quill"}
"*Bone*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bone"}
"*Bone Meal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bone Meal"}
"*Bone Block*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Bone Block"}
"*Blue Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blue Wool"}
"*Blue Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blue Stained Clay"}
"*Blue Shulker Box*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blue Shulker Box"}
"*Blue Orchid*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blue Orchid"}
"*Blue Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blue Glazed Terracotta"}
"*Blocks Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blocks Disc"}
"*Block of Coal*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Block of Coal"}
"*Blaze Rod*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blaze Rod"}
"*Blaze Powder*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Blaze Powder"}
"*Black Wool*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Black Wool"}
"*Black Stained Clay*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Black Stained Clay"}
"*Black Shulker Box*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Black Shulker Box"}
"*Black Glazed Terracotta*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Black Glazed Terracotta"}
"*Birch Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Birch Wood"}
"*Birch Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Birch Sapling"}
"*Birch Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Birch Leaves"}
"*Beetroot Seed*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Beetroot Seeds"}
"*Beetroot*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Beetroot"}
"*Beater*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Beater"}
"*Beacon*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Beacon"}
"*Banner*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Banner"}
"*Azure Bluet*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Azure Bluet"}
"*Arrow*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Arrow"}
"*Armor Stand*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Armor Stand"}
"*Armor and weapon set*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Armor and weapon set"}
"*Apple*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Apple"}
"*Andesite*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Andesite"}
"*Allium*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Allium"}
"*Ad Crate Key*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Ad Crate Key"}
"*Activator Rail*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Activator Rail"}
"*Acacia Wood*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Acacia Wood"}
"*Acacia Sapling*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Acacia Sapling"}
"*Acacia Leave*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Acacia Leaves"}
"*13 Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "13 Disc"}
"*11 Disc*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "11 Disc"}


					"*axe*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match axe}
					"*Bard*" {$gmcw = "These players are selling Bard: Bard (245@11:1)"}
					"*bottle of enchantment*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "Bottle o' Enchanting"}
					"*bottle o*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "Bottle o' Enchanting"}
					"*clay*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match clay}
					"*cobble*" {$gmcw = Get-MCWhoSells -buysell $sellbuy cobblestone}
					"*daisie*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match daisy}
					"*dia pick*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique "diamond pickaxe"}
					"*dirt*" {$gmcw = "Use grass for dirt. Get grass from /vote, vote parties, word unscrambles, maybe sb /lottery, /ma j, & /warp crates too. Or your own shop, or sell to a buy shop like mine. "}
					"*disc*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique Disc}
					"*dye*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique dye}
					"*flower*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match flower}
					"*gra*" {$gmcw = "Get grass from /vote, vote parties, word unscrambles, maybe sb /lottery, /ma j, & /warp crates too. Or your own shop, or sell to a buy shop like mine. "}
					"*hoe*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match hoe}
					"*inde*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique independence}
					"*indi*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique independence}
					"*indy*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique independence}
					"*iron*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "iron ingot"}
					"*key*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "voter crate key"}
					"*lapi*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "lapis lazuli"}
					"*lava*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique obsidian}
					"*leave*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique leaves}
					"*mobspawner*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique spawner}
					"*Netherack*"{$gmcw = Get-MCWhoSells -buysell $sellbuy "Netherrack"}
					"*obby*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "Obsidian"}
					"*obsedian*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "Obsidian"}
					"*pickaxe*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match pickaxe}
					"*pick*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match pickaxe}
					"*quart*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "nether quartz"}
					"*quartz*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "nether quartz"}
					"*sand*" {$gmcw = Get-MCWhoSells -buysell $sellbuy "red sand"}
					"*sapling*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique sapling}
					"*seed*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match seed}
					"*shear*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique shears}
					"*shovel*" {$gmcw = Get-MCWhoSells -buysell $sellbuy se-unique -match shovel}
			


			"*shulker*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique shulker}
					"*spawner*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique spawner}
					"*Stained Clay*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique clay}
					"*sword*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match sword}
					"*Terracotta*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique Terracotta}
					"*wood*" { $gmcw = Get-MCWhoSells -buysell $sellbuy -match -unique wood}
					"*wool*" {$gmcw = Get-MCWhoSells -buysell $sellbuy -unique -match wool}
					default{#thxu drive thru
						#$gmcw = Get-MCWhoSells -buysell $sellbuy (($mci -match $item)|%{$_.item}|sort -Unique) |select -first 1
						write-host "Switch 1 Default Output"
					}
				}
				Write-Host "GMCW output: $gmcw"
				#Write-Host $extra
				switch -wildcard ($tem) {
					"lava *" { 
						$gmcw = "Use obsidian for lava. " + $gmcw
					}
					"sand *" { 
						$gmcw = "You want red sand. Long story. " + $gmcw
					}
					default
					{#thxu drive thru
						#write-host "Switch 2 Default Output"
					}
				}
				if ($p.user -match "me -> ") {
					write-host "Me sending to someone else, ignore."
				}elseif ($p.user -match "-> me") {
					#respond in msg if called in msg, might make always.
					$p.user = $p.user -replace "-> me",""
					#if ($gmcw -eq ""){ $gmcw = "Nobody sells $item"}
					write-host "MSG back to $($p.user)"
					#$gmcw = "/msg " + $p.user + " " + $gmcw
					#$gmcw | clip
				}elseif ($gmcw -match "These shops are selling :"){
					#Do nothing
				}else {
					if ($gmcw -ne ""){
						write-host "Replying to $($p.user)"
					}
				}
					$gmcw = "/msg " + $p.user + " " + $gmcw
					$gmcw | clip
			}
		}
		#$runtime = ((Get-Date)-(Get-Date $d)).totalseconds
		#$i = $llpl/25*100
		$maxtime = 5
		#$pctMax =($runtime/$maxtime*100)
		#if($pctMax -gt 100){$pctMax2 = 100}else{$pctMax2 = $pctMax}
		#Write-Progress -Activity "Processed $llpl lines in $runtime seconds" -Status "Using $pctMax percent of max $maxtime seconds" -PercentComplete $pctMax2

		try{sleep ((Get-Date $d).AddSeconds($maxtime) - (Get-Date)).totalseconds}catch{sleep 2}
	}

}

function get-mcw3($item){$mci | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.item -match $item} | sort rate | ft}
function get-mcw4($item){$mcb | where {$_.date -gt (get-date).AddDays(-1)} | where {$_.item -match $item} | sort rate | ft}

function Get-MCPlayerReport($sort="ShopRating"){$MCSRTA |sort player -unique|where {$_.LastChange -gt (get-date).adddays(-1)}|where {$_.totalshops}|sort $sort -d|select Player, EmptyShopPct, EmptyShops, Variance, TotalShops, ShopRating, StoreTime, ShopTime, ShopTimeVariance|ft}
#endregion

<# Ads
New players - want to stretch your grass? &c[Click Here]&f to visit my &6G()ld Sh()p&f. Get 800 gold nuggets for your grass block, or bring your own. Many items for just 10 nuggets and weapons for 100 nuggets!
New players ==> &c[Click Here]&f to visit my &6G()ld Sh()p&f. Don't want 128 carrots for 1 grass? Get 1 carrot for 10 gold nuggets.
I sell 64 wheat seeds for 1 grass, or 1 wheat, melon, or pumpkin seed for 10 gold nuggets. Get 800 gold nuggets for your grass block at my &6G()ld Sh()p&f.
New players ==> Do &a/vote&f to get grass blocks, then &c[Click Here]&f to check out my &6G()ld Sh()p&f. Most items just 10 gold nuggets and weapons 100 nuggets! Get 800 gold nuggets for 1 grass, or bring your own.
Try to keep your grass from Kirby's donation bin. 
Renting hoppers, starting at 1 grass/day. 
If your baby refuses to do the hanky panky, you may be eligible for a grass settlement. &c[Click Here]&f for more details. 


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


Want grass more than voter keys? &c[Click Here]&f to sell your keys at my shop!

Suicidal squid in my doorway. Free ink sacs to my next visitor! Get it before clag does!
Slime spawner only works in slime chunks. To spawn slimes: Google "slime chunk finder" and use the seed Skyblock to find a slime chunk in your base. 
 - Learn to make a shop at /visit audibility
Are you ready for the &c4th&f of &9July&f? &c[Click Here]&f and stop by &cOne-Eyed&f Raven's &9Fireworks&f! Get a bite of the &c4th&f of &9July&f barbecue while you're here!

#>

<# Help Messages

Villagers *can* be spawned, and zombie villagers cured. They farm, but you can't buy from them (only /warp grass). Iron golems can be constructed but don't spawn.
Enable mob spawning in /settings. Animals stack so use a name tag to separate one for breeding. 
Cobble gen and stone gen make ores every 100-400 stones or so. Also, if you don't use 1.12.2 then Herobrine breaks your doors and fences.
Fun fact: You can do /kit sapling every 45 minutes.
Grass is currency. To check your balance, look in your inventory or chest to see how many grass blocks you have. You might want the Economy server.
If you're building over the void, there's client side voidlag from recalculating the lighting over the whole void. Server lag is additional. 

7 ways to expand your surface: 1. generate cobble. 2. grow trees 3. Get netherrack 4. Shave sheep 5. Grow a LOT of melons. 6. Spawn skeletons & make bone blocks. 7. buy stone at a shop like mine.

It's Minecraft - do what you'd do on any other server. Mine, craft, fight mobs, build your base, have fun!

Use grass for dirt. Get grass from /vote, vote parties, word unscrambles, maybe sb /lottery, /ma j, & /warp crates too. Or your own shop, or sell to a buy shop like mine. 

New players ==> Do &a/vote&f to get grass blocks, then &c[Click Here]&f to get 800 gold nuggets for 1 grass at my &6G()ld Sh()p&f, or bring your own. Most items just 10 gold nuggets and weapons 100 nuggets!

Tired of L()()King at the endless void? &c[Click Here]&f to visit my island paradise!  ==> Fish! Swim (don't drown)! Get free food! Make friends with the boat dogs! Slay cows and sheep at the mob grinder!

Want to be in my list of shops? It's easy and free! Just /mail Gilgamech "Scan my shop" and I'll scan your shop tomorrow and each day you play! 

Feeling stressed? Do /chat to change to local chat, and &c[Click Here]&f to visit my island paradise. Relax among the trees and enjoy the water.

Are you lagging? &c[Click Here]&f to visit my shop. Let retail therapy clear your worries until ClearLag clears the lag.

You can ride your bike with no handlebars at my island. &c[Click Here]&f to visit!

Wifi is available at my island. &c[Click Here]&f to visit!

You Require More Pylons. &c[Click Here]&f to obtain them!

Selling red dirt 1:1 - Ender Pears 3:1 - harmburgers 64:1 - pimpkings 64:1 - peach cobble 2240:1 - water lemons 64:1 - boney meals 64:1 - oak woof 128:1 - Zombie Pigment for 55 grass. Now selling gluten-free wool. &c[Click Here]&f for more info!

There are shops at /warp grass but many player shops (like mine) have better prices.

&6G()ld Sh()p&f
&c[Click Here]&f to visit!

"can I join someone's company? I'm really good at business, but got fired from my normal business?"

WhoSells v4 is out now! &c[Click Here]&f to exchange your v3 copy for a v4!

The One Piece could be in my sea. &c[Click Here]&f to visit!

Donate to end world hunger. Your donation of 1 grass block can feed 64 hungry minecrafters. &c[Click Here]&f to help now!

Have you been accused of dirt trade? &c[Click Here]&f to get legal help in clearing your good name. (by Law Office of Gilgamech, esquire)

"The best way to provide charity is to set up the world so that people don't need to beg in the first place." - adapted from Maimonides

"Nothing is to be feared. It is only to be understood. Now is the time to understand more, so that we may fear less." - Marie Curie.

If you're going to change the world, please change it for the better. We have enough people changing it for the worse.

It's dangerous to go alone. &c[Click Here]&f to take this: (>^_^)>

We have the most lag. The greatest lag. The best lag ever.
Lagging in the morning, lagging in the evening, lagging at suppertime. When you're on a Skyblock, you could be lagging anytime!
#>

<# WhoSells run

#Mute noisy shop ads
/ignore LadyAnkie
/ignore sqrtman
/ignore monster_sparkles


#import other player's chatlog
$dmc = Parse-MCChat -ChatLogName "C:\Users\Gillie\Downloads\MC_Output_Log_18-07" -LogGoesBackDays 0
$pmc += $dmc
$mcb = Get-MCItemPrices -ParseMinecraftChat $pmc -NoTransFilter
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb

#system startup
cd C:\Dropbox\
ipmo -Force .\script.ps1
$mcb = gc (".\MCItemPrices_"+(get-date -f yyyyMMdd)+".csv")  |ConvertFrom-Csv
$mcps = gc (".\MCPlayerState_"+(get-date -f yyyyMMdd)+".csv") |ConvertFrom-Csv
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$pmc = Parse-MCChat -LogGoesBackDays 1
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb
$mcsr = Get-MCShopReport
$MCSRTA = get-MCSRTA
$mcb|ConvertTo-Csv > (".\MCItemPrices_"+(get-date -f yyyyMMdd)+".csv")
$mcps|ConvertTo-Csv > (".\MCPlayerState_"+(get-date -f yyyyMMdd)+".csv")
Get-MCPlayerReport


/visit dexgeta
/visit panglong

#seen
Get-MCSeen -mcps $mcps -mcp $mcp  |clip

#shopkeepers
$pmc = Parse-MCChat -LogGoesBackDays 1
$mcb = Get-MCItemPrices -ParseMinecraftChat $pmc -NoTransFilter
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb
Get-MCShopkeepers -mcps $mcps |clip

#final processing and report
$pmc = Parse-MCChat -LogGoesBackDays 0
$mcb = Get-MCItemPrices -ParseMinecraftChat $pmc -NoTransFilter
$mci = $mcb | where {[int]$_.Transactions -gt 0} | where {[int]$_.Transactions -lt 2147483647} | where {[int]$_.Qty -le 2240}
$mcps = Get-MCPlayerState -pmc $pmc -mcb $mcb
$mcsr = Get-MCShopReport
$MCSRTA = get-MCSRTA
$mcb|ConvertTo-Csv > (".\MCItemPrices_"+(get-date -f yyyyMMdd)+".csv")
$mcps|ConvertTo-Csv > (".\MCPlayerState_"+(get-date -f yyyyMMdd)+".csv")
Get-MCPlayerReport

#book output
Get-MCBookOutput > .\book.txt




#>

<# WhoSells header


WhoSells v5
7/31/2019
Gilgamech Press

49 items most sold in the past week, from shops played in the past 24h. Your shop is missing? /mail Gilgamech to request a scan.

Player (Total@Qty:Grass)






#>




