function Assert-ConsoleHelpLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines,
        [string]$Label = 'CLI help'
    )

    $blocks = [Collections.Generic.List[object]]::new()
    $current = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -le $Lines.Count; $index++) {
        if ($index -eq $Lines.Count -or [string]::IsNullOrWhiteSpace($Lines[$index])) {
            if ($current.Count -gt 0) {
                $blocks.Add($current.ToArray())
                $current.Clear()
            }
            continue
        }
        $current.Add([pscustomobject]@{ Text = $Lines[$index]; Number = $index + 1 })
    }

    foreach ($block in $blocks) {
        $rows = [Collections.Generic.List[object]]::new()
        $continuations = [Collections.Generic.List[object]]::new()
        $longestCommand = 0
        $firstExplanationColumn = $null
        foreach ($line in $block) {
            $text = [string]$line.Text
            if ($text.Contains("`t")) {
                throw "${Label}:$($line.Number): use spaces for help columns, not tabs."
            }
            $indent = $text.Length - $text.TrimStart().Length
            $row = [regex]::Match($text, '^(?<command> *\S.*?)(?<gap> {2,})(?<explanation>\S.*)$')
            if ($row.Success -and (
                $null -eq $firstExplanationColumn -or $indent -lt $firstExplanationColumn
            )) {
                if ($null -eq $firstExplanationColumn) {
                    $firstExplanationColumn = $row.Groups['explanation'].Index
                }
                $longestCommand = [Math]::Max($longestCommand, $row.Groups['command'].Length)
                $rows.Add([pscustomobject]@{
                    Number = $line.Number
                    Column = $row.Groups['explanation'].Index
                })
            }
            elseif ($text.TrimStart().StartsWith('[')) {
                # Wrapped command arguments still occupy the command column.
                $longestCommand = [Math]::Max($longestCommand, $text.TrimEnd().Length)
            }
            elseif ($rows.Count -eq 0 -and $text.TrimEnd().EndsWith(':')) {
                # A block heading has no explanation column.
                continue
            }
            else {
                $continuations.Add([pscustomobject]@{ Number = $line.Number; Column = $indent })
            }
        }

        if ($rows.Count -eq 0) {
            # Titles and footer metadata are not command tables.
            foreach ($line in $block) {
                if ($line.Text -match '^\s+\S' -and
                    $line.Text -notmatch '^\s*[A-Za-z][A-Za-z ]*:') {
                    throw "${Label}:$($line.Number): command block has no separated explanation column."
                }
            }
            continue
        }

        $expectedColumn = $longestCommand + 4
        foreach ($row in @($rows.ToArray()) + @($continuations.ToArray())) {
            if ($row.Column -ne $expectedColumn) {
                throw (
                    "${Label}:$($row.Number): explanation starts at column " +
                    "$($row.Column + 1); expected $($expectedColumn + 1) " +
                    '(four spaces after the longest command in this block).'
                )
            }
        }
    }
}
