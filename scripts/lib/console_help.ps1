Set-StrictMode -Version Latest

function ConvertFrom-UnHelpInlineMarkdown {
    param([Parameter(Mandatory)][string]$Text)

    [regex]::Replace($Text, '`([^`]+)`', '$1')
}

function Format-UnHelpBulletBlock {
    param([Parameter(Mandatory)][object[]]$Items)

    $labelWidth = @(
        $Items |
            Where-Object { $null -ne $_.Label } |
            ForEach-Object { $_.Label.Length }
    ) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    if ($null -eq $labelWidth) { $labelWidth = 0 }

    foreach ($item in $Items) {
        if ($null -ne $item.Label) {
            '    {0}  {1}' -f (
                $item.Label.PadRight($labelWidth)
            ), $item.Description
        }
        else {
            "    $($item.Text)"
        }
    }
}

function Get-UnConsoleHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][Collections.IDictionary]$Values
    )

    $markdown = Get-Content -Raw -LiteralPath $Path
    foreach ($entry in $Values.GetEnumerator()) {
        $placeholder = '{{' + [string]$entry.Key + '}}'
        if (-not $markdown.Contains($placeholder)) {
            throw "Help placeholder not found: $placeholder"
        }
        $markdown = $markdown.Replace($placeholder, [string]$entry.Value)
    }

    $unresolved = [regex]::Match($markdown, '\{\{[A-Z][A-Z0-9_]*\}\}')
    if ($unresolved.Success) {
        throw "Help placeholder has no value: $($unresolved.Value)"
    }

    $output = [Collections.Generic.List[string]]::new()
    $bullets = [Collections.Generic.List[object]]::new()
    $lastBlock = ''
    $paragraphIndent = ''

    foreach ($line in ($markdown -split '\r?\n')) {
        $codeBullet = [regex]::Match(
            $line,
            '^- `(?<label>[^`]+)` — (?<description>.+)$'
        )
        $textBullet = [regex]::Match($line, '^- (?<text>.+)$')
        if ($codeBullet.Success) {
            $bullets.Add([pscustomobject]@{
                Label = $codeBullet.Groups['label'].Value
                Description = ConvertFrom-UnHelpInlineMarkdown `
                    -Text $codeBullet.Groups['description'].Value
                Text = $null
            })
            continue
        }
        if ($textBullet.Success) {
            $bullets.Add([pscustomobject]@{
                Label = $null
                Description = $null
                Text = ConvertFrom-UnHelpInlineMarkdown `
                    -Text $textBullet.Groups['text'].Value
            })
            continue
        }
        if ($bullets.Count -gt 0) {
            foreach ($formatted in (Format-UnHelpBulletBlock -Items @($bullets))) {
                $output.Add($formatted)
            }
            $bullets.Clear()
            $lastBlock = 'bullets'
        }

        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $heading = [regex]::Match($line, '^(?<level>#{1,4}) (?<text>.+)$')
        if ($heading.Success) {
            $level = $heading.Groups['level'].Value.Length
            $text = ConvertFrom-UnHelpInlineMarkdown `
                -Text $heading.Groups['text'].Value
            if ($level -eq 1) {
                $output.Add($text)
                $paragraphIndent = ''
                $lastBlock = 'h1'
            }
            elseif ($level -eq 2) {
                if ($output.Count -gt 0 -and $output[$output.Count - 1] -ne '') {
                    $output.Add('')
                }
                $output.Add("${text}:")
                $paragraphIndent = ''
                $lastBlock = 'h2'
            }
            elseif ($level -eq 3) {
                if ($lastBlock -ne 'h2' -and
                    $output.Count -gt 0 -and
                    $output[$output.Count - 1] -ne '') {
                    $output.Add('')
                }
                $output.Add("  $text")
                $paragraphIndent = '      '
                $lastBlock = 'h3'
            }
            else {
                if ($output.Count -gt 0 -and $output[$output.Count - 1] -ne '') {
                    $output.Add('')
                }
                $output.Add("  ${text}:")
                $paragraphIndent = '    '
                $lastBlock = 'h4'
            }
            continue
        }

        $output.Add(
            $paragraphIndent + (ConvertFrom-UnHelpInlineMarkdown -Text $line)
        )
        $lastBlock = 'paragraph'
    }

    if ($bullets.Count -gt 0) {
        foreach ($formatted in (Format-UnHelpBulletBlock -Items @($bullets))) {
            $output.Add($formatted)
        }
    }
    $output
}
