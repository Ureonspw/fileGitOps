# ==============================
# Couleurs
# ==============================
$Host.UI.RawUI.ForegroundColor = "Yellow"
$TITLE = "Magenta"
$TEXT = "Yellow"
$HIGHLIGHT = "WhiteBackground"
$BORDER = "DarkMagenta"

# ==============================
# Menu principal
# ==============================
$main_options = @("Installer les outils","Lancer un provisionnement","Aide","Supprimer un provisionnement","Quitter")
$selected_main = 0

# ==============================
# FONCTIONS PLACEHOLDER
# ==============================
function Install-Tools {
    param([string]$option)
    switch ($option) {
        "Windows (Chocolatey)" { Write-Host "[TODO] Installer outils Windows avec Chocolatey" }
        "Windows (Manuel)" { Write-Host "[TODO] Installer outils Windows manuellement" }
    }
}

function Launch-Provision {
    param([string]$option)
    switch ($option) {
        "Local" { Write-Host "[TODO] Lancer provisionnement local" }
        "Cloud" { Write-Host "[TODO] Lancer provisionnement cloud" }
    }
}

function Delete-Provision {
    param([string]$option)
    switch ($option) {
        "Local" { Write-Host "[TODO] Supprimer provisionnement local" }
        "Cloud" { Write-Host "[TODO] Supprimer provisionnement cloud" }
    }
}

# ==============================
# Fonction Menu
# ==============================
function Show-Menu {
    param([string]$title, [array]$options, [int]$selected)
    Clear-Host
    Write-Host "╔" + ("═" * 60) + "╗" -ForegroundColor DarkMagenta
    $padding = [math]::Floor((60 - $title.Length)/2)
    Write-Host ("║" + " " * $padding + $title + " " * (60 - $padding - $title.Length) + "║") -ForegroundColor Magenta
    Write-Host "╠" + ("═" * 60) + "╣" -ForegroundColor DarkMagenta

    for ($i=0; $i -lt $options.Count; $i++) {
        if ($i -eq $selected) {
            Write-Host "║ " $options[$i].PadRight(58) "║" -BackgroundColor White -ForegroundColor Black
        } else {
            Write-Host "║ " $options[$i].PadRight(58) "║" -ForegroundColor Yellow
        }
    }

    Write-Host "╚" + ("═" * 60) + "╝" -ForegroundColor DarkMagenta
    Write-Host "`n↑ ↓ pour naviguer, Entrée pour valider, q pour quitter"
}

# ==============================
# Boucle principale
# ==============================
while ($true) {
    Show-Menu "HIFADHI ONE-CLICK-PROVISIONNING" $main_options $selected_main

    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.VirtualKeyCode) {
        38 { $selected_main--; if ($selected_main -lt 0) { $selected_main = $main_options.Count - 1 } } # Up
        40 { $selected_main++; if ($selected_main -ge $main_options.Count) { $selected_main = 0 } }    # Down
        13 { # Enter
            switch ($main_options[$selected_main]) {
                "Installer les outils" {
                    $submenu = @("Windows (Chocolatey)","Windows (Manuel)","Retour")
                    $sel = 0
                    while ($true) {
                        Show-Menu "Installer les outils" $submenu $sel
                        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        switch ($k.VirtualKeyCode) {
                            38 { $sel--; if ($sel -lt 0) { $sel = $submenu.Count - 1 } }
                            40 { $sel++; if ($sel -ge $submenu.Count) { $sel = 0 } }
                            13 {
                                if ($submenu[$sel] -eq "Retour") { break }
                                Install-Tools $submenu[$sel]
                                Write-Host "`nAppuie sur une touche pour revenir..."; $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            }
                        }
                    }
                }
                "Lancer un provisionnement" {
                    $submenu = @("Local","Cloud","Retour")
                    $sel = 0
                    while ($true) {
                        Show-Menu "Provisionnement" $submenu $sel
                        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        switch ($k.VirtualKeyCode) {
                            38 { $sel--; if ($sel -lt 0) { $sel = $submenu.Count - 1 } }
                            40 { $sel++; if ($sel -ge $submenu.Count) { $sel = 0 } }
                            13 {
                                if ($submenu[$sel] -eq "Retour") { break }
                                Launch-Provision $submenu[$sel]
                                Write-Host "`nAppuie sur une touche pour revenir..."; $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            }
                        }
                    }
                }
                "Supprimer un provisionnement" {
                    $submenu = @("Local","Cloud","Retour")
                    $sel = 0
                    while ($true) {
                        Show-Menu "Supprimer un provisionnement" $submenu $sel
                        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        switch ($k.VirtualKeyCode) {
                            38 { $sel--; if ($sel -lt 0) { $sel = $submenu.Count - 1 } }
                            40 { $sel++; if ($sel -ge $submenu.Count) { $sel = 0 } }
                            13 {
                                if ($submenu[$sel] -eq "Retour") { break }
                                Delete-Provision $submenu[$sel]
                                Write-Host "`nAppuie sur une touche pour revenir..."; $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            }
                        }
                    }
                }
                "Aide" {
                    Clear-Host
                    Write-Host "=== AIDE ===" -ForegroundColor Magenta
                    Write-Host "1. Installer les outils: choisir ton OS pour installer les prerequisites" -ForegroundColor Yellow
                    Write-Host "2. Lancer un provisionnement: local ou cloud selon ton besoin" -ForegroundColor Yellow
                    Write-Host "3. Supprimer un provisionnement: retirer un environnement local ou cloud" -ForegroundColor Yellow
                    Write-Host "4. Quitter: fermer le menu" -ForegroundColor Yellow
                    Write-Host "`nAppuie sur une touche pour revenir au menu..."; $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                "Quitter" { Clear-Host; Write-Host "Sortie. À bientôt !" -ForegroundColor Yellow; break }
            }
        }
        81 { break } # q
    }
}
