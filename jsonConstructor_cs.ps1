param (
    [Parameter(Mandatory = $false)][string]$CSVFolderPath = 'csv_files'
    #[Parameter(Mandatory = $false)][string]$JSONoutputFolderPath = '.'
)
$jsonConstructor = New-Object -TypeName psobject #Creation for psobject without any properties, which is used as json constructor later.
$ContentOfFolder = (Get-ChildItem -Path $CSVFolderPath | Where-Object { $_.Name -like '*.csv' }).FullName #Array of all CSV file names inside of provided folder path
foreach ($csv in $ContentOfFolder) {
    #Main foreach loop, that based on provided csv data will prepare json
    $CurrentCSV = Import-Csv -Path $csv -Delimiter ',' -Header A, B, C | Select-Object -Unique B
    foreach ($item in $CurrentCSV.B) {
        $item = $item -replace '[[+*?()\\.]', '\$&' #Escape of all reserved characters by regex
        $ProcessingText = $null
        $obj = [PSCustomObject]@{
            ID   = ''
            TEXT = $item
        }
        #REGION regex for ID used for translating json
        $ID = ([regex]::matches($item, '^.\d{2,4}|^\d{2,4}')).Value
        if ($ID) {
            $obj.ID = $ID.Trim()
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
            [array]$NumberPointer = ([regex]::matches($ProcessingText, '(?<=(?i:viz ))\d{2,4}')).Value
            [array]$NumberPointer2 = $NumberPointer | ForEach-Object { "[to=$_]" }
        }
        else {
            [array]$NumberPointer = ([regex]::matches($item, '(?<=(?i:viz ))\d{2,4}')).Value
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
        #REGION matching VRAŤTE SE KE HŘE pattern
        $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::CultureInvariant
        if ($ProcessingText) {
            [array]$BTGPointer = ([regex]::matches($ProcessingText, 'VRAŤTE SE(.*) KE HŘE', $options)).Value
            [array]$BTGPointer2 = $BTGPointer | ForEach-Object { "[to=BTG]" }
        }
        else {
            [array]$BTGPointer = ([regex]::matches($item, 'VRAŤTE SE(.*) KE HŘE', $options)).Value
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

        $ProcessingText = $ProcessingText -replace '"', "'" #Czech version has illegal characters in text for json, replacing " with '

        $ProcessingText = $ProcessingText -replace '\\', '' #removing escape character used in regex matches

        $obj.TEXT = $ProcessingText.Trim()

        $jsonConstructor | Add-Member -MemberType NoteProperty -Name "$($obj.ID)" -Value "$($obj.TEXT)"
    }
    $outputJson = $jsonConstructor | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines("rules.cs.json", $outputJson, $Utf8NoBomEncoding)
}