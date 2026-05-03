# Serrano Group repo separation
#
# Creates Code\serrano-group-site\ as a sibling to Code\myinspector\,
# then MOVES (not copies) all Serrano Group corporate scaffolding out of
# the MyInspector product repo into the new dedicated directory.
#
# Why:
# - MyInspector repo is for product code only
# - SG-* files plus brand assets pollute the product repo
# - Separation is what Lead asked for during Track 2 setup
#
# Safety:
# - Uses Move-Item, not Copy + Delete. If a Move fails the source is untouched.
# - Skips any file that does not exist (no errors on already-moved state).
# - Idempotent: rerunning after a partial run finishes the job.
# - Does NOT touch myinspector/index.html (that is the MyInspector product app).
#   The marketing site comes from SG-BRAND-WEBSITE.html and becomes the new
#   repo's index.html.
#
# Usage:
#   cd "C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector"
#   powershell -ExecutionPolicy Bypass -File .\SG-REPO-SEPARATION.ps1

$ErrorActionPreference = 'Stop'

$src = "C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector"
$dst = "C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\serrano-group-site"

# --- Create directory structure ---

Write-Host "Creating directory structure at $dst" -ForegroundColor Cyan

$dirs = @(
    "$dst",
    "$dst\assets",
    "$dst\brand",
    "$dst\legal",
    "$dst\sales",
    "$dst\ops"
)

foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  + $dir" -ForegroundColor Green
    } else {
        Write-Host "  = $dir (already exists)" -ForegroundColor Yellow
    }
}

# --- Move map: source to destination ---

$moves = @(
    # Marketing site: SG-BRAND-WEBSITE.html becomes the new repo's index.html.
    # myinspector/index.html is the MyInspector product app and is NEVER moved.
    @{ From = "$src\SG-BRAND-WEBSITE.html";              To = "$dst\index.html" },

    # Brand
    @{ From = "$src\SG-BRAND-LOGOS.html";                To = "$dst\brand\logos-preview.html" },
    @{ From = "$src\SG-LINKEDIN-COMPANY-BRIEF.md";       To = "$dst\brand\linkedin-company-brief.md" },
    @{ From = "$src\.coordination\BRAND_REGISTRY.md";    To = "$dst\brand\BRAND_REGISTRY.md" },

    # Assets
    @{ From = "$src\SG-ASSETS-favicon.svg";              To = "$dst\assets\favicon.svg" },
    @{ From = "$src\SG-ASSETS-app-icon.svg";             To = "$dst\assets\app-icon.svg" },
    @{ From = "$src\SG-ASSETS-linkedin-avatar.svg";      To = "$dst\assets\linkedin-avatar.svg" },
    @{ From = "$src\SG-ASSETS-linkedin-banner.svg";      To = "$dst\assets\linkedin-banner.svg" },
    @{ From = "$src\SG-ASSETS-og-card.svg";              To = "$dst\assets\og-card.svg" },
    @{ From = "$src\SG-ASSETS-email-signature.svg";      To = "$dst\assets\email-signature.svg" },
    @{ From = "$src\SG-ASSETS-README.md";                To = "$dst\assets\README.md" },

    # Legal
    @{ From = "$src\SG-LEGAL-TOS.md";                    To = "$dst\legal\terms.md" },
    @{ From = "$src\SG-LEGAL-PRIVACY.md";                To = "$dst\legal\privacy.md" },
    @{ From = "$src\SG-LEGAL-DPA.md";                    To = "$dst\legal\dpa.md" },
    @{ From = "$src\SG-LEGAL-EMAIL-LAWYER.md";           To = "$dst\legal\email-lawyer.md" },
    @{ From = "$src\SG-LEGAL-EMAIL-BOSS.md";             To = "$dst\legal\email-boss.md" },

    # Sales
    @{ From = "$src\SG-SALES-PROPOSAL.md";               To = "$dst\sales\proposal-template.md" },
    @{ From = "$src\SG-SALES-TARGETS.md";                To = "$dst\sales\targets-tier1-2-3.md" },
    @{ From = "$src\SG-OUTREACH-TIER1.md";               To = "$dst\sales\outreach-tier1.md" },

    # Ops
    @{ From = "$src\SG-BOOKKEEPING-EXPENSES.csv";        To = "$dst\ops\expenses.csv" },

    # Repo-level README from MyInspector context
    @{ From = "$src\SG-README.md";                       To = "$dst\REPO-README-FROM-MYINSPECTOR.md" }
)

# --- Execute moves ---

Write-Host "`nMoving files..." -ForegroundColor Cyan

$moved = 0
$skipped = 0
$failed = 0

foreach ($m in $moves) {
    $fromName = Split-Path -Leaf $m.From
    if (Test-Path $m.From) {
        try {
            $toDir = Split-Path -Parent $m.To
            if (!(Test-Path $toDir)) { New-Item -ItemType Directory -Path $toDir -Force | Out-Null }
            Move-Item -Path $m.From -Destination $m.To -Force
            $shortTo = $m.To.Replace($dst, '.')
            Write-Host "  + $fromName -> $shortTo" -ForegroundColor Green
            $moved++
        } catch {
            Write-Host "  ! Failed: $fromName -- $_" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "  - $fromName (not found, already moved or never existed)" -ForegroundColor DarkGray
        $skipped++
    }
}

# --- Summary ---

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Moved:   $moved" -ForegroundColor Green
Write-Host "Skipped: $skipped (likely already moved)" -ForegroundColor Yellow

if ($failed -gt 0) {
    Write-Host "Failed:  $failed" -ForegroundColor Red
} else {
    Write-Host "Failed:  $failed" -ForegroundColor Green
}

Write-Host "`nNew repo location: $dst" -ForegroundColor Cyan
Write-Host "`nNext steps (Buddy will write README.md to the new dir; Jorge initializes git):" -ForegroundColor Cyan
Write-Host "  cd `"$dst`"" -ForegroundColor White
Write-Host "  git init" -ForegroundColor White
Write-Host "  git add ." -ForegroundColor White
Write-Host "  git commit -m 'Initial commit, split out from myinspector'" -ForegroundColor White

if ($failed -eq 0) {
    Write-Host "`nDone. MyInspector repo is clean of SG-* scaffolding." -ForegroundColor Green
    Write-Host "Tell Buddy 'script ran' so he can write the canonical README to the new dir." -ForegroundColor Cyan
} else {
    Write-Host "`nDone with errors. Review the failures above and re-run." -ForegroundColor Red
    exit 1
}
