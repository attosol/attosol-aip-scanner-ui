#
# attosol-aip-scanner-ui.ps1
#

<#

.SYNOPSIS
    A UI wrapper for the Microsoft AIP Scanner.

.DESCRIPTION
    You can use our AIP Scanner UI to:
        * Work with Microsoft Azure Information Protection Scanner from a GUI console
        * View current scan settings
        * Change scan settings
        * Start a scan
        * Do a custom scan (which is very tedious to do directly using PowerShell and prone to error)
        * View reports

    # Prerequisites
        * This solution should be executed from the AIP Scanner Server
        * You should know the AIP Scanner Report location before using this solution
        * PowerShell v5.0 and above is requied

.EXAMPLE
    # Getting Started
        After the prerequisites are installed or met, perform the following steps to use these scripts:
        * Download the contents of the repositories to your local machine.
        * Extract the files to a local folder (e.g. C:\attosol-aip-scanner-ui) on the AIP Scanner Server
        * Run PowerShell and browse to the directory (e.g. cd C:\attosol-aip-scanner-ui)
        * Once in the folder run .\attosol-aip-scanner-ui.ps1 -reportPath c:\Users\AlexW\AppData\Local\Microsoft\MSIP\Scanner\Reports where reportPath is the location of AIP Scanner Reports.

.NOTES
    # Questions and comments.
        Do you have any questions about our projects? Do you have any comments or ideas you would like to share with us?
        We are always looking for great new ideas. You can send your questions and suggestions to us in the Issues section of this repository or contact us at contact@attosol.com.

        Author:         Noble K Varghese
        Version:        1.0
        Creation Date:  11-July-2018
        Purpose/Change: A UI wrapper for the Microsoft AIP Scanner.

.LINK
    # Additional Resources
        * https://docs.microsoft.com/en-us/azure/information-protection/deploy-use/deploy-aip-scanner
        * https://cloudblogs.microsoft.com/enterprisemobility/2017/10/25/azure-information-protection-scanner-in-public-preview


#>

#########################################

#region Bindings

[cmdletbinding()]

    param
    (
        [Parameter(
            
            Mandatory=$true,
            HelpMessage = "Please specify the Scanner Report Location"
        )]
        $reportPath
    )


#endregion

#########################################

#region TypeDecleration

Add-Type -AssemblyName presentationframework, presentationcore, System.Windows.Forms, System.Drawing, System.Data

Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

#endregion

#########################################

#region Functions

#31,scanNow(),40
Function getReports([int32] $eventCode, [int32] $taskCat){

    try{
    
        $wpf.tbSummaryReport.Text = ""
    
        $foundItems = Get-ChildItem $reportPath -ErrorAction SilentlyContinue

        if(!$?) {

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Warning" -message "Failed fetching reports from $($reportPath).`r`n$($Error.Exception)" -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Warning" -message "Function getReports(). Failed fetching reports from $($reportPath).`r`n$($Error.Exception)" -place textFile -fileName $logFile
        }
        else {

            foreach($item in $foundItems) {
    
                $itemExt = $item.Name.Split('.')[-1]
    
                switch($itemExt) {
            
                    txt {
                
                        $parseContent = gc $item.VersionInfo.FileName
                        foreach($content in $parseContent) {
                    
                            $wpf.tbSummaryReport.Text += "$($content)`r`n"
                        }
                    }
                    csv {
                
                        $csvcontent = Import-Csv $item.VersionInfo.FileName
    
                        $wpf.dgDetailedReport.ItemsSource = $csvcontent
                    }
                }
            }
            $wpf.lbRefreshTimeR.Content = [datetime]::now
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Success fetching reports from $($reportPath)." -place textFile -fileName $logFile
        } 
    }
    catch{
        
       [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::getReports()",'OK','ERROR')
       
       writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed fetching reports from $($reportPath).`r`n$($_.Exception)" -place eventViewer
       writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function getReports(). Failed fetching reports from $($reportPath).`r`n$($_.Exception)" -place textFile -fileName $logFile
    }
}

#########################################
#32,33,34,36,37,38.1,38.4
Function viewSettings([string] $control,[int32] $eventCode, [int32] $taskCat) {
	switch($control) {

		scanConfig {

			try{
				$scanConfig=@()
                $scanConfig = Get-AIPScannerConfiguration | Out-String
                
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Success fetching configuration.`r`n$(($scanConfig).trim())" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Function viewSettings(). Success fetching configuration.`r`n$(($scanConfig).Trim())" -place textFile -fileName $logFile

				Return $scanConfig
			}
			Catch {

                [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::viewSettings(Config)",'OK',"WARN")
                
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed fetching configuration.`r`n$($_.Exception)" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function viewSettings(). Failed fetching configuration.`r`n$($_.Exception)" -place textFile -fileName $logFile
			}
		}

		viewRepo {
			
			try {
                
                $singleHash = $null
				$repoarray = New-Object System.Collections.ArrayList
				$Script:aiprepo = Get-AIPScannerRepository
                
                if($Script:aiprepo) {
                
                    if($Script:aiprepo.count -ge "2") {
                
                        $repoarray.AddRange($aiprepo)

                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Success fetching repositories.`r`n$((($repoarray)|Out-String).trim())" -place eventViewer
                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Function viewSettings(). Success fetching repositories.`r`n$((($repoarray)|Out-String).trim())" -place textFile -fileName $logFile

			    	    return $repoarray
                    }
                    else {
                
                        $singleHash = @{
                    
                            Repository = $Script:aiprepo.Repository
                            OverrideLabel = $Script:aiprepo.OverrideLabel
                            PreserveFileDetails = $Script:aiprepo.PreserveFileDetails
                            DefaultOwner = $Script:aiprepo.DefaultOwner
                            DefaultLabel = $Script:aiprepo.DefaultLabel
                            ScannedFileTypes = $Script:aiprepo.ScannedFileTypes
                            MatchPolicy = $Script:aiprepo.MatchPolicy
                        }

                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Success fetching repositories.`r`n$((($singleHash)|Out-String).Trim())" -place eventViewer
                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Success fetching repositories.`r`n$((($singleHash)|Out-String).Trim())" -place textFile -fileName $logFile

                        return $singleHash
                    }
                }
			}
			catch {
                
                [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::viewSettings(Repo)",'OK',"WARN")
                
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed fetching repositories.`r`n$($_.Exception)" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function viewSettings(). Failed fetching respositories.`r`n$($_.Exception)" -place textFile -fileName $logFile
			}
		}
	}
}

#########################################
#34
Function configureSettinigs([int32] $eventCode, [int32] $taskCat) {
	#region ScanMode
    try {
	    $flagScanMode = 0;
	    switch($wpf.rbDiscover.IsChecked) {

		    true {

			    $scanMode = "Off"
		    }
		    false {

			    switch($wpf.rbEnforce.IsChecked) {

				    true {

					    $scanMode = "On"
				    }
				    false {
					    $flagScanMode++
					    $scanMode = (Get-AIPScannerConfiguration).Enforce
				    }
			    }
		    }
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(scanMode)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to set scanMode.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to set scanMode.`r`n$($_.Exception)" -place textFile -fileName $logFile
    }
	#endregion

	#region Schedule
    try {
	    $flagSchedule = 0
	    switch($wpf.rbOneTime.IsChecked) {

		    true {

			    $scanSchedule = "OneTime"
		    }
		    false {

			    switch($wpf.rbContinuous.IsChecked) {

				    true {

					    $scanSchedule = "Continuous"
				    }
				    false {

					    $flagSchedule++
					    $scanSchedule = (Get-AIPScannerConfiguration).Schedule
				    }
			    }
		    }
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(scanSchedule)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to set scanSchedule.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to set scanSchedule.`r`n$($_.Exception)" -place textFile -fileName $logFile


    }
	#endregion

	#region Type
    try {
	    $flagType = 0
	    switch($wpf.rbFull.IsChecked) {

		    true{

			    $scanType = "Full"
		    }
		    false {

			    switch($wpf.rbIncremental.IsChecked) {

				    true {

					    $scanType = "Incremental"
				    }
				    false {

					    $flagType++
					    $scanType = (Get-AIPScannerConfiguration).Type
				    }
			    }
		    }
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(scanType)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to set scanType.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to set scanType.`r`n$($_.Exception)" -place textFile -fileName $logFile
    }
	#endregion

	#region ReportLevel
    try {
	    $flagReport = 0
	    switch($wpf.rbInfo.IsChecked) {

		    true {

			    $reportLevel = "Info"
		    }
		    false {

			    switch($wpf.rbDebug.IsChecked) {

				    true {

					    $reportLevel = "Debug"
				    }
				    false {

					    switch($wpf.rbError.IsChecked) {

						    true {

							    $reportLevel = "Error"
						    }
						    false {

							    switch($wpf.rbOff.IsChecked) {

								    true {

									    $reportLevel = "Off"
								    }
								    false {

									    $flagReport++
									    $reportLevel = (Get-AIPScannerConfiguration).ReportLevel
								    }
							    }
						    }
					    }
				    }
			    }
		    }
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(reportLevel)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to set reportLevel.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to set reportLevel.`r`n$($_.Exception)" -place textFile -fileName $logFile
    }
	#endregion

	#region OptionalSettings
		
    try {
    
        switch($wpf.rbPolicyAll.IsChecked) {
        
            true {
            
                $discoverType = "PolicyOnly"
            }
            false {
            
                switch($wpf.rbAll.IsChecked) {
                
                    true {
                    
                        $discoverType = "All"
                    }
                    false {
                    
                        $discoverType = (Get-AIPScannerConfiguration).DiscoverInformationTypes
                    }
                }
            } 
        }
    }
    catch {
    
    
    }

	#endregion
    
    #region Hash%20Set
    try {
	    $configHash = @{

		    ScanSchedule = $scanSchedule
		    ScanMode = $scanMode
		    ScanType = $scanType
		    ReportLevel = $reportLevel
            DiscoverType = $discoverType
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(configHash)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to set configHash.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to set configHash.`r`n$($_.Exception)" -place textFile -fileName $logFile
    }

    try {

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Saving Configurations.`r`n$((($configHash)|Out-String).Trim())" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Information" -message "Function configureSettings(). Failed to set configHash.`r`n$((($configHash)|Out-String).Trim())" -place textFile -fileName $logFile

	    Set-AIPScannerConfiguration -Enforce $configHash.ScanMode -Schedule $configHash.ScanSchedule -Type $configHash.ScanType -ReportLevel $configHash.ReportLevel -DiscoverInformationTypes $discoverType
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::configureSettings(saveConfig)",'OK',"WARN")

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Failed to save configurations.`r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "$($eventCode)" -category "$($taskCat)" -entryType "Error" -message "Function configureSettings(). Failed to save configurations.`r`n$($_.Exception)" -place textFile -fileName $logFile
    }
    #endregion
}

#########################################
#38
Function createCustomForm([int32] $eventCode, [int32] $taskCat) {

	#########################################
	
    #region XAMLFormConversion_TC3_104
    
    try {
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Loading SubWindow() using XAML" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Loading SubWindow() using XAML from sources" -place textFile -fileName $logFile
        
	    $cwpf = @{ }
	    $cinputXML = Get-Content -Path .\source\SubWindow.xaml
	    $cinputXMLClean = $cinputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
	    [xml]$cxaml = $cinputXMLClean
	    $creader = New-Object System.Xml.XmlNodeReader $cxaml
	    $ctempform = [Windows.Markup.XamlReader]::Load($creader)
	    $cnamedNodes = $cxaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
	    $cnamedNodes | ForEach-Object {
	
		    $cwpf.Add($_.Name, $ctempform.FindName($_.Name))
	    }

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Loaded SubWindow() using XAML" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Loaded SubWindow() using XAML from sources" -place textFile -fileName $logFile
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::XAMLConv",'OK','ERROR')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Error" -message "Failed loading SubWindow. Check XAML files. `r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Error" -message "Failed loading SubWindow. Check XAML files. $($_.Exception)" -place textFile -fileName $logFile  
    }
	    #endregion

	#########################################

	#region formActions_TC3_103
    
    #38.1C
    $cwpf.customSubWindow.Add_Loaded({

        try {
            
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "customSubWindow.Add_Loaded(). Calling Function viewSettings()." -place textFile -fileName $logFile

            $cwpf.dgCustomRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode $eventCode -taskCat $taskCat
        }
        catch {
        
            [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::customSubWindow.Add_Loaded()",'OK','WARN')

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Warning" -message "Unable to call Function viewSettings().`r`n$($_.Exception)." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Warning" -message "customSubWindow.Add_Loaded(). Unable to call Function viewSettings().`r`n$($_.Exception)." -place textFile -fileName $logFile
        }
    })

    #38.2C
    $cwpf.bAddList.Add_Click({
    
        try {
            
            if(Get-AIPScannerRepository) {
            
                $index = $cwpf.dgCustomRepo.SelectedIndex
                $customitemSelected = $Script:aiprepo[$index].Repository

        
                if($cwpf.lvCustomList.Items -contains $customitemSelected) {
        
                    [System.Windows.Forms.MessageBox]::Show("Already a member",'Action Failed::DuplicateMember','OK','Info')
                }
                else {
        
                    $cwpf.lvCustomList.Items.Add($customitemSelected)

                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Adding repository to custom scan:$($customitemSelected)." -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bAddList.Add_Click(). Adding repository to custom scan:$($customitemSelected).`r`n$($_.Exception)." -place textFile -fileName $logFile
                }
            }
            else {
        
                [System.Windows.Forms.MessageBox]::Show("No repositories selected",'Action Failed::EmptyList','OK','Info')
            }
        }
        catch {
        
            [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bAddList.Add_Click()",'OK','WARN')

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Unhandled Exception.`r`n$($_.Exception)." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "bAddList.Add_Click(). Unhandled Exception.`r`n$($_.Exception)." -place textFile -fileName $logFile
        }   
    })

    #38.3C
    $cwpf.bRemoveList.Add_Click({
    
        try {
            
            if($cwpf.lvCustomList.HasItems) {
                
                $cwpf.lvCustomList.Items.RemoveAt($cwpf.lvCustomList.Items.IndexOf($cwpf.lvCustomList.SelectedItem))

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Removed repository from custom scan." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bRemoveList.Add_Click(). Removed repository from custom scan." -place textFile -fileName $logFile
            }
            else {
            
                [System.Windows.Forms.MessageBox]::Show("No repositories selected",'Action Failed::EmptyList','OK','Info')
            }
        }
        catch {
        
            [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bRemoveList.Add_Click()",'OK','WARN')

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Unhandled Exception.`r`n$($_.Exception)." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "bRemoveList.Add_Click(). Unhandled Exception.`r`n$($_.Exception)." -place textFile -fileName $logFile
        }
    })

    #38.4C
    $cwpf.bCustomContinue.Add_Click({
    
        try {
            if(!$cwpf.lvCustomList.HasItems) {

                [System.Windows.Forms.MessageBox]::Show("No changes made. Choose OK to Continue",'NoChangeDetected','OK','INFO')

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "No configurations made for custom scan. Control back to MainWindow" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). No configurations made for custom scan. Control back to MainWindow." -place textFile -fileName $logFile

                $cwpf.customSubWindow.Close()
            }
            else {
            
                $fileNameString = "masterRepo_$((get-date).tostring("yyyyMMddHHmm")).txt"
                New-Item -ItemType File -Path $PWD\repoList -Name $fileNameString -Force | Out-Null

                Get-AIPScannerRepository|select *|Export-Csv -Path $PWD\repoList\$fileNameString -NoTypeInformation

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Exporting Repository configurations:$($PWD)\repoList\$($fileNameString)" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Exporting Repository configurations:$($PWD)\repoList\$($fileNameString)." -place textFile -fileName $logFile

                foreach($repo in Get-AIPScannerRepository) {
            
                    Remove-AIPScannerRepository -Path $repo.Repository

                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Removed Repository:$($repo.Repository)" -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Removed Repository:$($repo.Repository)." -place textFile -fileName $logFile
                }

                for($i = 0; $i -lt $cwpf.lvCustomList.Items.Count; $i++) {
            
                    Add-AIPScannerRepository -Path $cwpf.lvCustomList.Items[$i]

                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Added Repository:$($cwpf.lvCustomList.Items[$i])" -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCodes -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Added Repository:$($cwpf.lvCustomList.Items[$i])." -place textFile -fileName $logFile
                }
                
                $cwpf.customSubWindow.close()

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Calling Function viewSettings()." -place textFile -fileName $logFile
                
                $wpf.dgUpdateRepo.ItemsSource = $null
                $wpf.dgUpdateRepo.Items.Refresh()
                $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode $eventCode -taskCat $taskCat

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function scanNow().`r`nStarting Scan" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Calling Function scanNow().`r`nStarting Scan." -place textFile -fileName $logFile
            
                scanNow -eventCode $eventCode -taskCat $taskCat

                $restoreRepo = Import-Csv $PWD\repoList\$fileNameString

                foreach($_ in $restoreRepo) {

                    if($_.DefaultLabel -eq "PolicyDefaultLabel") {
                    
                        Add-AIPScannerRepository -Path $_.Repository -OverrideLabel $_.OverrideLabel -PreserveFileDetails $_.PreserveFileDetails -DefaultOwner $_.DefaultOwner -DefaultLabelId "00000000-0000-0000-0000-000000000000"

                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Added Repository: $($_.Repository)" -place eventViewer
                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Added Repository: $($_.Repository)" -place textFile -fileName $logFile
                    }
                    else {

                        Add-AIPScannerRepository -Path $_.Repository -OverrideLabel $_.OverrideLabel -PreserveFileDetails $_.PreserveFileDetails -DefaultOwner $_.DefaultOwner

                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Added Repository: $($_.Repository)" -place eventViewer
                        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Added Repository: $($_.Repository)" -place textFile -fileName $logFile
                    }
                }

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click. Calling Function viewSettings()." -place textFile -fileName $logFile

                $wpf.dgUpdateRepo.ItemsSource = $null
                $wpf.dgUpdateRepo.Items.Refresh()
                $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode $eventCode -taskCat $taskCat
            }
        }
        catch {
        
            [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bCustomContinue.Add_Click()",'OK','WARN')

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Unhandled Exception. Custom Scan failed`r`n$($_.Exception)." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "bCustomContinue.Add_Click(). Unhandled Exception. Custom Scan failed`r`n$($_.Exception)." -place textFile -fileName $logFile


            $restoreRepo = Import-Csv $PWD\repoList\$fileNameString

            foreach($_ in $restoreRepo) {

                if($_.DefaultLabel -eq "PolicyDefaultLabel") {
                
                    Add-AIPScannerRepository -Path $_.Repository -OverrideLabel $_.OverrideLabel -PreserveFileDetails $_.PreserveFileDetails -DefaultOwner $_.DefaultOwner -DefaultLabelId "00000000-0000-0000-0000-000000000000"

                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Added Repository: $($_.Repository)" -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Added Repository: $($_.Repository)" -place textFile -fileName $logFile
                }
                else {

                    Add-AIPScannerRepository -Path $_.Repository -OverrideLabel $_.OverrideLabel -PreserveFileDetails $_.PreserveFileDetails -DefaultOwner $_.DefaultOwner

                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Added Repository: $($_.Repository)" -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Added Repository: $($_.Repository)" -place textFile -fileName $logFile
                }
            }

            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click. Calling Function viewSettings()." -place textFile -fileName $logFile

            $wpf.dgUpdateRepo.ItemsSource = $null
            $wpf.dgUpdateRepo.Items.Refresh()
            $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode $eventCode -taskCat $taskCat
        }
    })

	#endregion

	#########################################
    #38.5C
	#region displayForm

    try {
	
        $cwpf.customSubWindow.MaxHeight = 350
        $cwpf.customSubWindow.MaxWidth = 800
        $cwpf.customSubWindow.MinHeight = 350
        $cwpf.customSubWindow.MinWidth = 800

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling ShowDialog() on subWindow()`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "bCustomContinue.Add_Click(). Calling ShowDialog() on subWindow()`r`n$($_.Exception)." -place textFile -fileName $logFile

        $cwpf.customSubWindow.ShowDialog() | Out-Null
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::displaySubWindow()",'OK','Error')

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Failed to display subWindow()`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "bCustomContinue.Add_Click(). Failed to display subWindow()`r`n$($_.Exception)." -place textFile -fileName $logFile
    }

	#endregion

	#########################################
}

#########################################
#38.4,39
Function scanNow([int32] $eventCode, [int32] $taskCat) {

    try {
        if((Get-Service AIPScanner).Status -ne "Stopped") {

            [System.Windows.Forms.MessageBox]::Show('A Scan is in Progress. Wait and retry','Scan In Progress','OK','INFO')
            
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Service AIPScanner is Running. Scan In Progress." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Service AIPScanner is Running. Scan In Progress." -place textFile -fileName $logFile
        }
        else {

            if((Get-AIPScannerConfiguration).Schedule -eq "Never") {

                [System.Windows.Forms.MessageBox]::Show('Run failed, Schedule set to Never','Schedule is Never','OK','INFO')

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Scan Schedule is set to Never. Service AIPScanner will stop." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Scan Schedule is set to Never. Service AIPScanner will stop." -place textFile -fileName $logFile
            }
            elseif((Get-AIPScannerConfiguration).Schedule -eq "OneTime") {

                Start-Service AIPScanner

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Scan Started. Service AIPScanner Started" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Scan Started. Service AIPScanner Started." -place textFile -fileName $logFile
                
                while((Get-Service AIPScanner).Status -ne "Stopped") {
            
                    Start-Sleep -Seconds 10
                    
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Scan In progress" -place eventViewer
                    writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Scan In progress." -place textFile -fileName $logFile
			    }
                
                [System.Windows.Forms.MessageBox]::Show('Scan Complete','','OK','INFO')

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Scan Completed. Stopping Service AIPScanner." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Scan Completed. Stopping Service AIPScanner." -place textFile -fileName $logFile
            
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Calling Function viewSettings()." -place textFile -fileName $logFile
                
                $wpf.tbUpdateSettings.Text = viewSettings -control 'scanConfig' -eventCode $eventCode -taskCat $taskCat

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Calling Function getReports().`r`nPath is: $($reportPath)." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow().Calling Function getReports().Path is: $($reportPath)." -place textFile -fileName $logFile

                $wpf.tbSummaryReport.Text = $null
                $wpf.dgDetailedReport.ItemsSource = $null
                $wpf.dgDetailedReport.Items.Refresh()

                getReports -eventCode $eventCode -taskCat $taskCat
            }
            elseif((Get-AIPScannerConfiguration).Schedule -eq "Continuous") {
        
                Start-Service AIPScanner
                [System.Windows.Forms.MessageBox]::Show('Scan started and will continue in background','Scan Started::Continuous','OK','INFO')

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Scan Started in Continuous mode. Service AIPScanner Started" -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Information" -message "Function scanNow(). Scan Started in Continuous mode. Service AIPScanner Started." -place textFile -fileName $logFile
            }
        }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::scanNow()",'OK','Error')

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Unhandled Exception in Function scanNow().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID $eventCode -category $taskCat -entryType "Error" -message "Function scanNow(). Unhandled Exception.`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
}

#########################################

Function writeEvent([string] $logName, [string] $source, [string] $message, [int32] $eventID, [string] $entryType, [int32] $category, [string] $place, [string] $fileName) {

    switch ($place) {
        
        eventViewer {  

            try {
                
                Write-EventLog -LogName $logName -Source $source -EventId $eventID -Category $category -EntryType $entryType -Message $message
            }
            catch {
            
                          
            }
        }

        textFile {

            try {
                
                Add-Content -Path .\logs\$fileName -Value "[$([DateTime]::Now)]`t[$($eventID)#$($category)]`t[$($entryType)]`t[$($logName)#$($source)]`t[$($message)]" -Encoding UTF8
            }
            catch {
            
                
            }
        }
    } 
}

#endregion

#########################################

#region main

#########################################

#region logFile

$logFile = "scannerUI_$((get-date).tostring("yyyyMMdd")).log"

if(!(Test-Path .\logs\$logFile)) {

    New-Item -ItemType File -Name $logFile -Path .\logs -Force | Out-Null
}
else {

    Add-Content -Path .\logs\$logFile -Value "`n`n"
}

#endregion

#########################################

#region EventSourceRegistration_TC1_101C

if([System.Diagnostics.EventLog]::SourceExists("Scanner UI")) {

    writeEvent -logName "Azure Information Protection" -source "Azure Information Protection" -eventID "101" -category "1" -entryType "Information" -message "Source Scanner UI exists. Skipping source creation." -place eventViewer
}
else {

    try {
        
        [System.Diagnostics.EventLog]::CreateEventSource("Scanner UI", "Azure Information Protection")
        writeEvent -logName "Azure Information Protection" -source "Azure Information Protection" -eventID "101" -category "1" -entryType "Information" -message "Source Scanner UI creation success." -place eventViewer
    }
    catch {
    
        writeEvent -logName "Azure Information Protection" -source "Azure Information Protection" -eventID "101" -category "1" -entryType "Error" -message "Failed to create source Scanner UI. Logging is disabled" -place eventViewer
    }
}
 
#endregion

#########################################

#region XAMLFromConversion_TC2_102C

    try {
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Information" -message "Loading MainWindow() using XAML" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Information" -message "Loading MainWindow() using XAML from sources" -place textFile -fileName $logFile

        $wpf = @{ }
	    $inputXML = Get-Content -Path .\source\MainWindow.xaml
	    $inputXMLClean = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
	    [xml]$xaml = $inputXMLClean
	    $reader = New-Object System.Xml.XmlNodeReader $xaml
	    $tempform = [Windows.Markup.XamlReader]::Load($reader)
	    $namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
	    $namedNodes | ForEach-Object {
	
		    $wpf.Add($_.Name, $tempform.FindName($_.Name))
        }
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Information" -message "Loaded MainWindow() using XAML" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Information" -message "Loaded MainWindow() using XAML from sources" -place textFile -fileName $logFile
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::XAMLConv",'OK','ERROR')

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Error" -message "Failed loading MainWindow. Check XAML files. `r`n$($_.Exception)" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "102" -category "2" -entryType "Error" -message "Failed loading MainWindow. Check XAML files. $($_.Exception)" -place textFile -fileName $logFile 
	}

#endregion

#########################################

#region formActions_TC3_103

#31
$wpf.mainForm.Add_Loaded({
    try {
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "31" -entryType "Information" -message "Calling Function getReports().`r`nPath is: $($reportPath)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "31" -entryType "Information" -message "mainForm.Add_Loaded().Calling Function getReports().Path is: $($reportPath)." -place textFile -fileName $logFile
        
        getReports -eventCode "103" -taskCat "31"
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::FormLoad",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "31" -entryType "Warning" -message "Unable to call Function getReports().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "31" -entryType "Warning" -message "mainForm.Add_Loaded().Unable to call Function getReports().`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
})

#32
$wpf.bGo.Add_Click({

	try {

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "32" -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "32" -entryType "Information" -message "bGo.Add_Click(). Calling Function viewSettings()." -place textFile -fileName $logFile

		if($wpf.rbView.IsChecked -eq $true) {

			$wpf.tbSettings.Text = viewSettings -control 'scanConfig' -eventCode "103" -taskCat "32"
			$wpf.dgviewRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode "103" -taskCat "32"
		}
		elseif($wpf.rbRefresh.IsChecked -eq $true) {

			$wpf.tbSettings.Text = viewSettings -control 'scanConfig' -eventCode "103" -taskCat "32"
			$wpf.dgviewRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode "103" -taskCat "32"
		}
	}
	catch{

        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bGO",'OK','WARN')

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "32" -entryType "Warning" -message "Unable to call Function viewSettings().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "32" -entryType "Warning" -message "bGo.Add_Click(). Unable to call Function viewSettings().`r`n$($_.Exception)." -place textFile -fileName $logFile
	} 
})

#33
$wpf.tabUpdate.Add_Loaded({

    try {
    
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "33" -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "33" -entryType "Information" -message "tabUpdate.Add_Loaded(). Calling Function viewSettings()." -place textFile -fileName $logFile

        $wpf.tbMessage.Text = (Get-AIPScannerConfiguration).JustificationMessage
	    $wpf.tbUpdateSettings.Text = viewSettings -control 'scanConfig' -eventCode "103" -taskCat "33"
    	$wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode "103" -taskCat "33"
    }
    Catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::tabUpdate",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "33" -entryType "Warning" -message "Unable to call Function viewSettings().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "33" -entryType "Warning" -message "tabUpdate.Add_Loaded(). Unable to call Function viewSettings().`r`n$($_.Exception)." -place textFile -fileName $logFile 
    }
})

#34
$wpf.bSave.Add_Click({
    
    try {

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Information" -message "Calling Function configureSettings()." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Information" -message "bSave.Add_Click(). Calling Function configureSettings()." -place textFile -fileName $logFile

	    configureSettinigs -eventCode "103" -taskCat "34"

	    Set-AIPScannerConfiguration -JustificationMessage $wpf.tbMessage.Text

        $wpf.tbMessage.Text = (Get-AIPScannerConfiguration).JustificationMessage
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Information" -message "Calling Function viewSettings()." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Information" -message "bSave.Add_Click(). Calling Function viewSettings()." -place textFile -fileName $logFile

	    $wpf.tbUpdateSettings.Text = viewSettings -control 'scanConfig' -eventCode "103" -taskCat "34"
	    $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo'  -eventCode "103" -taskCat "34"
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bSave",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Warning" -message "Unable to call Function configureSettings().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "34" -entryType "Warning" -message "bSave.Add_Click(). Unable to call Function configureSettings().`r`n$($_.Exception)." -place textFile -fileName $logFile 
    }
})

#35
$wpf.dgUpdateRepo.Add_SelectionChanged({
    try {

	    $selectedRow = $wpf.dgUpdateRepo.SelectedIndex

	    if(($itemSelected = $Script:aiprepo[$selectedRow].Repository)) {

		    $wpf.tbUpadteRepo.Text = $itemSelected
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::dgUpdateRepo.Add_SelectionChanged()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "35" -entryType "Warning" -message "Unhandled Exception.`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "35" -entryType "Warning" -message "dgUpdateRepo.Add_SelectionChanged(). Unhandled Exception.`r`n$($_.Exception)." -place textFile -fileName $logFile 
    }
})

#36
$wpf.bRemove.Add_Click({
    
    try {
	    if(!$wpf.tbUpadteRepo.Text) {

		    [System.Windows.Forms.MessageBox]::Show("Expecting a valid Path",'Action Failed::InvalidPath','OK','Error')
	    }
	    else {
        
            foreach($item in (Get-AIPScannerRepository).Repository) {
        
                if($wpf.tbUpadteRepo.Text -eq $item) {
            
                    $flag = "found"
                }
            }

            if($flag -eq "found") {
        
                Remove-AIPScannerRepository -Path $wpf.tbUpadteRepo.Text
                
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Information" -message "Removing repository: $($wpf.tbUpadteRepo.Text)." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Information" -message "bRemove.Add_Click(). Removing repository: $($wpf.tbUpadteRepo.Text)." -place textFile -fileName $logFile
            }
            else {
        
                [System.Windows.Forms.MessageBox]::Show("Repository $($wpf.tbUpadteRepo.Text) not found",'Action Failed::InvalidRepo','OK','WARN')

                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Warning" -message "Invalid Repository: $($wpf.tbUpadteRepo.Text) does not exist." -place eventViewer
                writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Warning" -message "bRemove.Add_Click(). Invalid Repository: $($wpf.tbUpadteRepo.Text) does not exist." -place textFile -fileName $logFile          
            }
        
            if((Get-AIPScannerRepository)) {
		        $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode "103" -taskCat "36"
		        $wpf.tbUpadteRepo.Text = ""
            }
            else {
                #$wpf.tbUpadteRepo.Text = ""
                $wpf.dgUpdateRepo.ItemsSource = $null
                $wpf.dgUpdateRepo.Items.Refresh()
            }
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bRemove.Add_Click()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Warning" -message "Couldn't remove Repository $($wpf.tbUpadteRepo.Text).`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "36" -entryType "Warning" -message "bRemove.Add_Click(). Couldn't remove Repository $($wpf.tbUpadteRepo.Text).`r`n$($_.Exception)." -place textFile -fileName $logFile 
    }
})

#37
$wpf.bAdd.Add_Click({

    try {

	    if(!$wpf.tbUpadteRepo.Text) {

		    [System.Windows.Forms.MessageBox]::Show("Expecting a valid path",'Action Failed::InvalidPath','OK','Error')
	    }
	    else {

		    Add-AIPScannerRepository -Path $wpf.tbUpadteRepo.Text
    
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "37" -entryType "Information" -message "Adding repository: $($wpf.tbUpadteRepo.Text)." -place eventViewer
            writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "37" -entryType "Information" -message "Adding repository: $($wpf.tbUpadteRepo.Text)." -place textFile -fileName $logFile
            
		    $wpf.dgUpdateRepo.ItemsSource = viewSettings -control 'viewRepo' -eventCode "103" -taskCat "37"
		    $wpf.tbUpadteRepo.Text = ""
	    }
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bAdd.Add_Click()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "37" -entryType "Warning" -message "Couldn't add Repository $($wpf.tbUpadteRepo.Text).`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "37" -entryType "Warning" -message "bAdd.Add_Click(). Couldn't add Repository $($wpf.tbUpadteRepo.Text).`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
})

#38
$wpf.bCustomScan.Add_Click({

    try {
    
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Information" -message "Calling Function createCustomForm()." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Information" -message "bCustomScan.Add_Click(). Calling Function createCustomForm()." -place textFile -fileName $logFile

        createCustomForm -eventCode "104" -taskCat "38"
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bCustomScan.Add_Click()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Warning" -message "Unable to call Function createCustomForm().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Warning" -message "bCustomScan.Add_Click(). Unable to call Function createCustomForm().`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
})

#39
$wpf.bScanNow.Add_Click({

    try {
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "39" -entryType "Information" -message "Calling Function scanNow().`r`nStarting Scan" -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "39" -entryType "Information" -message "bScanNow.Add_Click(). Calling Function scanNow().Starting Scan." -place textFile -fileName $logFile
        scanNow -eventCode "103" -taskCat "39"
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bscanNow.Add_Click()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Warning" -message "Unable to call Function scanNow().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "38" -entryType "Warning" -message "bscanNow().Add_Click(). Unable to call Function scanNow().`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
})

#40
$wpf.bRefreshReport.Add_Click({

    try {
        $wpf.tbSummaryReport.Text = $null
        $wpf.dgDetailedReport.ItemsSource = $null
        $wpf.dgDetailedReport.Items.Refresh()
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "40" -entryType "Information" -message "Calling Function getReports().`r`nPath is: $($reportPath)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "40" -entryType "Information" -message "bRefreshReport.Add_Click().Calling Function getReports().Path is: $($reportPath)." -place textFile -fileName $logFile

        getReports -eventCode "103" -taskCat "40"
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::bRefreshReport.Add_Click()",'OK','WARN')
        
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "40" -entryType "Warning" -message "Unable to call Function getReports().`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "103" -category "40" -entryType "Warning" -message "bRefreshReport.Add_Click(). Unable to call Function getReports().`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
})

$wpf.tbAbout.Text = "AIP ScannerUI v1.0
                    `r`nThe scanner runs as a service on Windows Server and lets you discover, classify, and protect files on
                    `r`n * Local folders on the Windows Server computer that runs the scanner.
                    `r`n * UNC paths for network shares that use the Server Message Block (SMB) protocol.
                    `r`n * Sites and libraries for SharePoint Server 2016 and SharePoint Server 2013.
                    `r`nThis tool provides a Graphical User Interface to work with Azure Information Protection Scanner.



                    `r`nRead More Here: https://docs.microsoft.com/en-us/azure/information-protection/deploy-use/deploy-aip-scanner
                    `r`nDeveloped by:
                    `r`nNoble Varghese <noblev@attosol.com>
                    `r`nAttosol Technologies
                `n
"

#endregion

#########################################

#4
#region displayForm_TC4_104
	
    try{ 
        
        <# https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui #>
        
        $consolePtr = [Console.Window]::GetConsoleWindow()   
        [Console.Window]::ShowWindow($consolePtr, 0)
        
    }
    catch {
    
        #[System.Windows.Forms.MessageBox]::Show($_.Exception,"Failed",'OK','WARN')
    }

    try {
    
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "104" -category "4" -entryType "Information" -message "Calling ShowDialog() on mainWindow()`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "104" -category "4" -entryType "Information" -message "main(). Calling ShowDialog() on mainWindow()`r`n$($_.Exception)." -place textFile -fileName $logFile

        $wpf.mainForm.ShowDialog() | Out-Null
    }
    catch {
    
        [System.Windows.Forms.MessageBox]::Show("Something went wrong`r`nCheck Logs $($PWD)\$($logFile)","Action Failed::displayMainWindow()",'OK','Error')

        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "104" -category "4" -entryType "Error" -message "Failed to display mainWindow()`r`n$($_.Exception)." -place eventViewer
        writeEvent -logName "Azure Information Protection" -source "Scanner UI" -eventID "104" -category "4" -entryType "Error" -message "main(). Failed to display mainWindow()`r`n$($_.Exception)." -place textFile -fileName $logFile
    }
	

#endregion

#########################################

#endregion

#########################################