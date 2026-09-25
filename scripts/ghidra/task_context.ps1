Set-StrictMode -Version Latest

function Get-UnWorkshopGhidraTaskContext {
    if ([string]::IsNullOrWhiteSpace($env:NA228_TASK_WORK_ROOT)) {
        throw 'NA228_TASK_WORK_ROOT must name the current chat work directory.'
    }
    $taskRoot = [IO.Path]::GetFullPath($env:NA228_TASK_WORK_ROOT)
    $workRoot = [IO.Path]::GetDirectoryName($taskRoot)
    $projectRoot = [IO.Path]::GetDirectoryName($workRoot)
    $paths = Get-UnWorkshopPaths -ProjectRoot $projectRoot
    if ($null -eq $paths.Work -or
        -not [IO.Path]::Equals($workRoot, [IO.Path]::GetFullPath($paths.Work)) -or
        [string]::IsNullOrWhiteSpace([IO.Path]::GetFileName($taskRoot))) {
        throw 'NA228_TASK_WORK_ROOT must name an immediate child of work/.'
    }
    [pscustomobject]@{
        Root = $taskRoot
        Paths = $paths
    }
}
