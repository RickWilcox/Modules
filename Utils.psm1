Function Get-FilePath ($initialDirectory) {
	<# 
		.SYNOPSIS
			Accepts an array and presents as a list of choices to the user.
		.DESCRIPTION 
			This script accepts and 1 demensional array of strings as input. The array will be presented to the 
			viewer as a list of choices. The choice is made by enter the number of the choice item.
		.EXAMPLE
			Get-ListChoices $arrayOfStrings
		.NOTES
			This function is intended to be used via a script ran from the PowerShell console as the list choices are output to the screen.
	#>

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All Files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}  #end function Get-CSVFile
Function Invoke-ChoiceList {
	<# 
		.SYNOPSIS
			Accepts an array and presents as a list of choices to the user.
		.DESCRIPTION 
			This script accepts and 1 demensional array of strings as input. The array will be presented to the 
			viewer as a list of choices. The choice is made by enter the number of the choice item.
		.EXAMPLE
			Get-ListChoices $arrayOfStrings
		.NOTES
			This function is intended to be used via a script ran from the PowerShell console as the list choices are output to the screen.
	#>

	[cmdletBinding()]
	param (
		[Array]$ArrayOfStrings,
		[String]$Message
	)
	
	$LoopCount = 1
	Write-Host "Selection List:" -ForegroundColor Green -BackgroundColor Black
	while ($LoopCount -le $ArrayOfStrings.Count){
		Write-Host $LoopCount "." $ArrayOfStrings.Get($LoopCount-1) -ForegroundColor White -BackgroundColor Black
		$LoopCount++
	}
	do{
		Write-Host $Message -BackgroundColor DarkBlue -ForegroundColor Yellow
		Write-Host "Input the number of your choice: " -NoNewline -ForegroundColor Green -BackgroundColor Black	
		$userInput = Read-Host
		Write-Host 
	}
	until ($userInput -in 1..$ArrayOfStrings.Count)
	
	$userInput = $ArrayOfStrings.Get($userInput-1)
	return $userInput
}
function Write-ToLogFile {
	[cmdletBinding()]
	param(
		[Parameter(Mandatory = $true,Position=0)][String]$logMessage,
		[Parameter(Mandatory = $true)][String]$logPath,
		[Parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter] $Visible=$false,
		[Parameter(Mandatory = $false)][ValidateSet("Error","Warning","Information")][String]$entryType = "Information"
	)
    
    $timeStamp = Get-Date -Format s
    $testFile = Test-Path $logPath
    If ($testFile -eq $false){
		"$timeStamp Created log file" | Out-File $logPath
	}
    Switch ($entryType){
        "Error" {$entryTypeText = "Error:";$typeColor = "Yellow";$typeBackColor = "Red"
            #if((Get-WmiObject Win32_OperatingSystem).Caption -like "*server*"){Send-MailMessage -To "6187918715@txt.att.net" -from "AutomationFailure@ehi.com" -Subject "Automation Failure" -Body "$logMessage" -SmtpServer "smtp.corp.erac.com"}    
        }
		"Warning" {
			$entryTypeText = "Warning:";$typeColor = "Blue";$typeBackColor = "Yellow"
		}
        "Information" {
			$entryTypeText =  "";$typeColor = "Green";$typeBackColor = "Black"
		}
    }
    $logText = "$timeStamp - " + $entryTypeText + $logMessage
    $logText | out-file $logPath -Append
    If($visible){
		Write-Host "$(Get-Date -Format T) $logMessage" -ForegroundColor $typeColor -BackgroundColor $typeBackColor
	}
}
Function Convert-ArrayToHTML {
	Param (
		[Array]$Collection,
		[String]$Title
	)
	
	$Properties = @()
	$Properties = $($Collection[0].PSObject.Properties).Name
    
    ForEach($Property in $Properties) 
	{
		$ColumnHeaders += "<td><b>$($Property)</b></td>"
	}

    $body += "<font face=arial><center><table border=5 width=90% cellspacing=0 cellpadding=8 cols=$($Properties.count)>"
    If($Title){$body += "<tr><b><th colspan=$($Properties.count)><h3><br>$($Title)</h3></th></tr>"}
    $body += "<tr><b><h2><br>$($ColumnHeaders)</h2></tr>"
    
	$Row = 2
	ForEach($Item in $Collection)
	{
		$i=0
		$CellValues = ""
		For($i=0; $i -lt $Properties.Count ; $i++)
		{
			$CellValues += "<td>$($Item.($Properties[$i]))</td>"
		}
		If ($Row % 2){$body += "<font face=arial size=2><center><tr bgcolor=aliceblue>$CellValues</tr></font>";$Row++}
		Else{$body += "<font face=arial size=2><center><tr bgcolor=lavender>$CellValues</tr></font>";$Row++}
	}
	$body = $body + "</table></center></font>"
	Return $body
} #end Function to Convert a collection to HTML for use in an HTML email body
Function Select-Date {
	[CmdletBinding()]
	Param (
		[Array]$Collection,
		[String]$Title
	)
	process {
		Add-Type -AssemblyName System.Windows.Forms
		Add-Type -AssemblyName System.Drawing

		$form = New-Object Windows.Forms.Form 

		$form.Text = "Select a Date" 
		$form.Size = New-Object Drawing.Size @(243,230) 
		$form.StartPosition = "CenterScreen"

		$calendar = New-Object System.Windows.Forms.DateTimePicker
		$calendar.ShowTodayCircle = $False
		$calendar.MaxSelectionCount = 1
		$form.Controls.Add($calendar)
		
		$OKButton = New-Object System.Windows.Forms.Button
		$OKButton.Location = New-Object System.Drawing.Point(38,165)
		$OKButton.Size = New-Object System.Drawing.Size(75,23)
		$OKButton.Text = "OK"
		$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
		$form.AcceptButton = $OKButton
		$form.Controls.Add($OKButton)

		$CancelButton = New-Object System.Windows.Forms.Button
		$CancelButton.Location = New-Object System.Drawing.Point(113,165)
		$CancelButton.Size = New-Object System.Drawing.Size(75,23)
		$CancelButton.Text = "Cancel"
		$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
		$form.CancelButton = $CancelButton
		$form.Controls.Add($CancelButton)

		$form.Topmost = $True

		$result = $form.ShowDialog() 

		if ($result -eq [System.Windows.Forms.DialogResult]::OK)
		{
			$date = $calendar.SelectionStart
			Write-Host "Date selected: $($date.ToShortDateString())"
		}	
		return $date.ToShortDateString()
	}
	
}
