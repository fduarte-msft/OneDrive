# FILE_ATTRIBUTE_UNPINNED
$FILE_ATTRIBUTE_UNPINNED = 0x00100000 

# FILE_ATTRIBUTE_PINNED
$FILE_ATTRIBUTE_PINNED = 0x00080000

# FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS
$FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = 0x00400000

$oneDriveFiles = Get-ChildItem $env:OneDriveCommercial -Recurse -File

$files = [System.Collections.Generic.List[psobject]]::new()

foreach ($oneDriveFile in $oneDriveFiles) {
    # Get decimal attribute
    $attributes = $oneDriveFile.Attributes

    # Convert DEC attribute to HEX
    $hexattributes = '0x{0:X8}' -f [int]$attributes 

    # Create known attributes and Append HexAttributes to file object
    $knownattributes = $attributes -band (-bnot ($FILE_ATTRIBUTE_UNPINNED -bor $FILE_ATTRIBUTE_PINNED -bor $FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS))
    Add-Member -InputObject $oneDriveFile -MemberType NoteProperty -Name HexAttributes -Value $hexattributes
    Add-Member -InputObject $oneDriveFile -MemberType NoteProperty -Name KnownAttributes -TypeName [System.IO.FileAttributes] -Value $knownattributes

    # Determine if file has FILE_ATTRIBUTE_PINNED attribute and append it to file object if true
    $pinned = ($attributes -band $FILE_ATTRIBUTE_PINNED) -ne 0 
    Add-Member -InputObject $oneDriveFile -MemberType NoteProperty -Name FILE_ATTRIBUTE_PINNED -TypeName [System.Boolean] -Value $pinned 

    # Determine if file has FILE_ATTRIBUTE_UNPINNED and append it to file object if true
    $unpinned = ($attributes -band $FILE_ATTRIBUTE_UNPINNED) -ne 0 
    Add-Member -InputObject $oneDriveFile -MemberType NoteProperty -Name FILE_ATTRIBUTE_UNPINNED -TypeName [System.Boolean] -Value $unpinned 

    # Determine if file has FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS and append it to file object if true
    $recall_on_access = ($attributes -band $FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS) -ne 0
    Add-Member -InputObject $oneDriveFile -MemberType NoteProperty -Name FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS -TypeName [System.Boolean] -Value $recall_on_access
    
    # Build output object with all files
    $files.add(($oneDriveFile | Select-Object -Property FullName, Length, Attributes, HexAttributes, KnownAttributes, FILE_ATTRIBUTE_PINNED, FILE_ATTRIBUTE_UNPINNED, FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS ))
}  

# Sync OneDrive files if needed
foreach ($file in $files) {
    if (!($File.FILE_ATTRIBUTE_PINNED)) {
        try {
            $pinFile = Start-Process -FilePath "$env:windir\system32\attrib.exe" -ArgumentList "+p `"$($File.FullName)`"" -WindowStyle Hidden -PassThru -Wait -ErrorAction Stop
            $pinFile.WaitForExit()
        } catch {
            exit [int32]1
        }
    }
}

# Sync OneDrive Status
$pinStatus = @()
foreach ($file in $files) {
    if (!($File.FILE_ATTRIBUTE_PINNED)) {
        $pinStatus += $File
    }
}

if ($pinStatus.count -ne 0) {
    $filesNotSyncedPath = "$env:TEMP\$($env:COMPUTERNAME)_$((Get-Date).ToString("s").Replace(":","-")).csv"
    $pinStatus | Export-Csv -Path $filesNotSyncedPath -NoTypeInformation
    $exitCode = [int32]1
} else {
    $exitCode = [int32]0
}

exit $exitCode