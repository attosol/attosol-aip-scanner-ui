# attosol-aip-scanner-ui
A UI wrapper for the Microsoft AIP Scanner.

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

# Getting Started
After the prerequisites are installed or met, perform the following steps to use these scripts:
* Download the contents of the repositories to your local machine.
* Extract the files to a local folder (e.g. C:\attosol-aip-scanner-ui) on the AIP Scanner Server
* Run PowerShell and browse to the directory (e.g. cd C:\attosol-aip-scanner-ui)
* Once in the folder run ``.\attosol-aip-scanner-ui.ps1 -reportPath c:\Users\AlexW\AppData\Local\Microsoft\MSIP\Scanner\Reports`` where reportPath is the location of AIP Scanner Reports.

# Questions and comments.
Do you have any questions about our projects? Do you have any comments or ideas you would like to share with us?
We are always looking for great new ideas. You can send your questions and suggestions to us in the Issues section of this repository or contact us at ``contact@attosol.com``.

# Additional Resources
* [Deploy AIP Scanner](https://docs.microsoft.com/en-us/azure/information-protection/deploy-use/deploy-aip-scanner)
* [AIP Scanner Public Preview](https://cloudblogs.microsoft.com/enterprisemobility/2017/10/25/azure-information-protection-scanner-in-public-preview/)
