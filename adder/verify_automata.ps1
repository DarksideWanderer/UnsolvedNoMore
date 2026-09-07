param(
    [string]$Cxx = "g++",
    [switch]$Sanitize
)

$ErrorActionPreference = "Stop"
$addonRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $addonRoot
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Get-CodeBlocks {
    param([string]$Path, [string]$Language = "cpp")
    $document = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
    $fence = [string]::new([char]96, 3)
    $pattern = '(?ms)^' + $fence + [regex]::Escape($Language) +
        '\r?\n(.*?)^' + $fence + '\s*$'
    $blocks = [regex]::Matches($document, $pattern)
    if ($blocks.Count -eq 0) { throw "No $Language blocks: $Path" }
    return ($blocks | ForEach-Object { $_.Groups[1].Value }) -join "`n"
}

# The original templates are read-only. Inject public accessors into an
# in-memory AC source copy; never rewrite string/02-ACam.md.
$acSource = Get-CodeBlocks (Join-Path $repoRoot "string/02-ACam.md")
$members = Get-CodeBlocks (Join-Path $addonRoot "05-ac-applications.md") "cpp-member"
$anchor = '    vector<long long> count_occurrences(const string& text) const {'
if (-not $acSource.Contains($anchor)) { throw "AC integration anchor changed" }
$acSource = $acSource.Replace($anchor, $members + "`n" + $anchor)
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add($acSource)
foreach ($path in @("string/03-Pam.md", "string/07-Kmp.md",
                    "graph/10-euler-tour-lca.md")) {
    $parts.Add((Get-CodeBlocks (Join-Path $repoRoot $path)))
}
foreach ($name in @("00-range-query.md", "04-parent-tree-tricks.md",
                    "05-ac-applications.md", "06-pam-applications.md",
                    "07-kmp-automaton.md", "08-subsequence-automaton.md",
                    "09-trie-pam.md")) {
    $parts.Add((Get-CodeBlocks (Join-Path $addonRoot $name)))
}
$parts.Add((Get-Content -LiteralPath (Join-Path $addonRoot "automata_tests.cpp") `
    -Encoding UTF8 -Raw))
$parts.Add((Get-Content -LiteralPath (Join-Path $addonRoot "trie_pam_tests.cpp") `
    -Encoding UTF8 -Raw))
$executable = Join-Path $addonRoot (".automata-tests-" + [guid]::NewGuid() + ".exe")
try {
    $arguments = @("-x", "c++", "-std=c++20", "-Wall", "-Wextra", "-Wshadow",
                   "-Wconversion", "-pedantic", "-finput-charset=UTF-8")
    if ($Sanitize) {
        $arguments += @("-O1", "-g", "-fsanitize=address,undefined",
                        "-fno-omit-frame-pointer", "-D_GLIBCXX_ASSERTIONS")
    } else {
        $arguments += "-O2"
    }
    $arguments += @("-o", $executable, "-")
    ($parts -join "`n") | & $Cxx @arguments
    if ($LASTEXITCODE -ne 0) { throw "Automata applications failed to compile" }
    & $executable
    if ($LASTEXITCODE -ne 0) { throw "Automata applications tests failed" }
    Write-Host "[PASS] automata-applications"
} finally {
    if (Test-Path -LiteralPath $executable) {
        Remove-Item -LiteralPath $executable
    }
}
