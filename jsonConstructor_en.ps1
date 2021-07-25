param (
    [Parameter(Mandatory=$true)][string]$CSVFolderPath,
    [Parameter(Mandatory=$true)][string]$JSONoutputFolderPath
)
$jsonConstructor = New-Object -TypeName psobject #Creation for psobject without any properties, which is used as json constructor later.
$ContentOfFolder = (Get-ChildItem -Path $CSVFolderPath | Where-Object { $_.Name -like '*.csv' }).FullName #Array of all CSV file names inside of provided folder path
foreach ($csv in $ContentOfFolder) { #Main foreach loop, that based on provided csv data will prepare json
    $CurrentCSV = Import-Csv -Path $csv -Delimiter ',' -Header A, B, C | Select-Object -Unique A
    foreach ($item in $CurrentCSV.A) {
        $item = $item -replace '[[+*?()\\.]', '\$&' #Escape of all reserved characters by regex
        $ProcessingText = $null
        $obj = [PSCustomObject]@{
            ID   = ''
            TEXT = $item
        }
        #REGION regex for ID used for translating json
        $ID = ([regex]::matches($item, '^\d{2,4}')).Value
        if ($ID) {
            $obj.ID = $ID
        }
        else {
            continue
        }
        #ENDREGION
        #REGION regex for bold ending pattern
        $BoldMatchEnding = ([regex]::matches($item, '>[^–]*\.$')).Value
        if ($BoldMatchEnding) {
            $ProcessingText = $item -replace $BoldMatchEnding, "<strong>$BoldMatchEnding</strong>"
        }
        #ENDREGION
        #REGION matching bold text pattern from csv to html5 format
        if ($ProcessingText) {
            [array]$BoldPatternMatches = ([regex]::matches($ProcessingText, '>.*–')).Value
            [array]$BoldPatternMatches2 = $BoldPatternMatches | ForEach-Object { "<strong>$_</strong>" }
        }
        else {
            [array]$BoldPatternMatches = ([regex]::matches($item, '>.*–')).Value
            [array]$BoldPatternMatches2 = $BoldPatternMatches | ForEach-Object { "<strong>$_</strong>" }
        }
        if ($BoldPatternMatches) {
            for ($i = 0; $i -lt $BoldPatternMatches.Count; $i++) {
                $CurrentReplaceText = $BoldPatternMatches[$i]
                $ReplaceText = $BoldPatternMatches2[$i]
                if (!$ProcessingText) {
                    $ProcessingText = $item -replace "$CurrentReplaceText", "$ReplaceText"
                }
                else {
                    $ProcessingText = $ProcessingText -replace "$CurrentReplaceText", "$ReplaceText"
                }
            }
        }
        #ENDREGION
        #REGION matching paragraph pattern from csv to html5 format
        if ($ProcessingText) {
            [array]$Paragraph = ([regex]::matches($ProcessingText, '\s{2}.*')).Value
            [array]$Paragraph2 = $Paragraph | ForEach-Object { "<p>$_</p>" }
        }
        else {
            [array]$Paragraph = ([regex]::matches($item, '\s{2}.*')).Value
            [array]$Paragraph2 = $Paragraph | ForEach-Object { "<p>$_</p>" }
        }
        if ($Paragraph) {
            for ($i = 0; $i -lt $Paragraph.Count; $i++) {
                $CurrentReplaceParagraph = $Paragraph[$i]
                $ReplaceParagraph = $Paragraph2[$i]
                if (!$ProcessingText) {
                    $ProcessingText = $item -replace "$CurrentReplaceParagraph", "$ReplaceParagraph"
                }
                else {
                    $ProcessingText = $ProcessingText -replace "$CurrentReplaceParagraph", "$ReplaceParagraph"
                }
            }
        }
        #ENDREGION
        #REGION matching pointing to different ID pattern
        if ($ProcessingText) {
            [array]$NumberPointer = ([regex]::matches($ProcessingText, '(?<=(?i:see ))\d{2,4}')).Value
            [array]$NumberPointer2 = $NumberPointer | ForEach-Object { "[to=$_]" }
        }
        else {
            [array]$NumberPointer = ([regex]::matches($item, '(?<=(?i:see ))\d{2,4}')).Value
            [array]$NumberPointer2 = $NumberPointer | ForEach-Object { "[to=$_]" }
        }
        if ($NumberPointer) {
            for ($i = 0; $i -lt $NumberPointer.Count; $i++) {
                $CurrentReplaceNumberPointer = $NumberPointer[$i]
                $ReplaceNumberPointer = $NumberPointer2[$i]
                if (!$ProcessingText) {
                    $ProcessingText = $item -replace "$CurrentReplaceNumberPointer", "$ReplaceNumberPointer"
                }
                else {
                    $ProcessingText = $ProcessingText -replace "$CurrentReplaceNumberPointer", "$ReplaceNumberPointer"
                }
            }
        }
        #ENDREGION
        #REGION matching BACK TO GAME pattern
        if ($ProcessingText) {
            [array]$BTGPointer = ([regex]::matches($ProcessingText, 'BACK TO GAME')).Value
            [array]$BTGPointer2 = $BTGPointer | ForEach-Object { "[to=BTG]" }
        }
        else {
            [array]$BTGPointer = ([regex]::matches($item, 'BACK TO GAME')).Value
            [array]$BTGPointer2 = $BTGPointer | ForEach-Object { "[to=BTG]" }
        }
        if ($BTGPointer) {
            for ($i = 0; $i -lt $BTGPointer.Count; $i++) {
                $currentReplaceBTGPointer = $BTGPointer[$i]
                $ReplaceBTGPointer = $BTGPointer2[$i]
                if (!$ProcessingText) {
                    $ProcessingText = $item -replace "$currentReplaceBTGPointer", "$ReplaceBTGPointer"
                }
                else {
                    $ProcessingText = $ProcessingText -replace "$currentReplaceBTGPointer", "$ReplaceBTGPointer"
                }
            }
        }
        #ENDREGION
        #REGION matching italics pattern from csv
        if (!$ProcessingText) {
            $ProcessingText = ($item -replace '“', '<em>“') -replace '”', '”</em>'
        }
        else {
            $ProcessingText = ($ProcessingText -replace '“', '<em>“') -replace '”', '”</em>'
        }
        #ENDREGION
        #REGION matching newline pattern from csv
        if (!$ProcessingText) {
            $ProcessingText = ($item -replace '  ', '') -replace "`n", '<br />'
        }
        else {
            $ProcessingText = ($ProcessingText -replace '  ', '') -replace "`n", '<br />'
        }
        #ENDREGION
        $ProcessingText = $ProcessingText -replace '\\', '' #removing escape character used in regex matches

        $obj.TEXT = $ProcessingText

        $jsonConstructor | Add-Member -MemberType NoteProperty -Name "$($obj.ID)" -Value "$($obj.TEXT)"
    }
    $outputJson = $jsonConstructor | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines("$JSONoutputFolderPath\rules.en.json", $outputJson, $Utf8NoBomEncoding)
}