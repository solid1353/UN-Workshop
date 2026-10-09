Set-StrictMode -Version Latest

function Get-GhidraTargetImage {
    param([Parameter(Mandatory)][object]$Item,
          [Parameter(Mandatory)][string]$InputPath)

    $bytes = [IO.File]::ReadAllBytes($InputPath)
    if ($Item.source_offset) {
        if (-not $Item.source_size -or -not $Item.container_sha256) {
            throw "Embedded input requires size and container hash: $($Item.program)"
        }
        $containerHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
        if ($containerHash -ne $Item.container_sha256) {
            throw "Container hash mismatch: $($Item.source)"
        }
        $offset = [Convert]::ToInt64($Item.source_offset.Substring(2), 16)
        $size = [int64]$Item.source_size
        if ($offset -lt 0 -or $size -le 0 -or $offset + $size -gt $bytes.Length) {
            throw "Embedded input exceeds container: $($Item.program)"
        }
        $image = New-Object byte[] $size
        [Array]::Copy($bytes, $offset, $image, 0, $size)
        $bytes = $image
        if ($Item.format -ne 'iop_elf' -or $bytes.Length -lt 52 -or
            [Convert]::ToHexString($bytes[0..5]) -ne '7F454C460101' -or
            [BitConverter]::ToUInt16($bytes, 16) -ne 0xFF80 -or
            [BitConverter]::ToUInt16($bytes, 18) -ne 8) {
            throw "Embedded input is not a little-endian MIPS IOP ELF: $($Item.program)"
        }
        $ph = [BitConverter]::ToUInt32($bytes, 28)
        $stride = [BitConverter]::ToUInt16($bytes, 42)
        $count = [BitConverter]::ToUInt16($bytes, 44)
        if ($stride -ne 32 -or $ph + $stride * $count -gt $bytes.Length) {
            throw "Invalid embedded ELF program table: $($Item.program)"
        }
        $loads = 0
        for ($i = 0; $i -lt $count; $i++) {
            $row = $ph + $stride * $i
            if ([BitConverter]::ToUInt32($bytes, $row) -ne 1) { continue }
            $loads++
            $fileOffset = [BitConverter]::ToUInt32($bytes, $row + 4)
            $address = [BitConverter]::ToUInt32($bytes, $row + 8)
            $fileSize = [BitConverter]::ToUInt32($bytes, $row + 16)
            $memorySize = [BitConverter]::ToUInt32($bytes, $row + 20)
            if ($address -ne 0 -or $fileSize -gt $memorySize -or
                [int64]$fileOffset + $fileSize -gt $bytes.Length) {
                throw "Embedded IOP load segment cannot be mapped: $($Item.program)"
            }
        }
        if ($loads -ne 1) { throw "Embedded IOP input requires one load segment: $($Item.program)" }
    }
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
    if ($hash -ne $Item.expected_sha256) { throw "Source hash mismatch: $($Item.source) ($($Item.program))" }
    return ,$bytes
}
