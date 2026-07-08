param(
  [string]$WorkbookPath = "D:\WorkDL\ポケかー_files\ボードゲームリスト.xlsm",
  [string]$SheetName = "ボドゲリスト",
  [string]$GamesDir = "games",
  [string]$ThumbnailUrl = "/assets/thumbs/placeholder-board-game.svg",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Add-Type -AssemblyName System.IO.Compression

function Read-ZipEntry {
  param(
    [System.IO.Compression.ZipArchive]$Archive,
    [string]$Name
  )

  $entry = $Archive.GetEntry($Name)
  if (-not $entry) {
    return $null
  }

  $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
  try {
    return $reader.ReadToEnd()
  } finally {
    $reader.Dispose()
  }
}

function Get-SharedStringText {
  param($SharedStringItem)

  $parts = New-Object System.Collections.Generic.List[string]
  foreach ($node in $SharedStringItem.ChildNodes) {
    if ($node.LocalName -eq "t") {
      $parts.Add($node.InnerText)
    } elseif ($node.LocalName -eq "r") {
      foreach ($child in $node.ChildNodes) {
        if ($child.LocalName -eq "t") {
          $parts.Add($child.InnerText)
        }
      }
    }
  }

  return ($parts -join "")
}

function Get-CellColumn {
  param([string]$CellRef)

  if ($CellRef -match "^([A-Z]+)") {
    return $matches[1]
  }

  return ""
}

function Get-CellValue {
  param(
    $Cell,
    [string[]]$SharedStrings
  )

  $raw = ""
  if ($Cell.v) {
    $raw = [string]$Cell.v
  }

  if ($Cell.t -eq "s") {
    $index = [int]$raw
    if ($index -lt $SharedStrings.Count) {
      return $SharedStrings[$index]
    }
  }

  if ($Cell.t -eq "inlineStr") {
    return $Cell.is.InnerText
  }

  return $raw
}

function ConvertTo-Slug {
  param(
    [int]$No,
    [string]$Title
  )

  $normalized = $Title.Normalize([Text.NormalizationForm]::FormKC).ToLowerInvariant()
  $words = [regex]::Matches($normalized, "[a-z0-9]+") | ForEach-Object { $_.Value }
  $words = @($words | Where-Object { $_ -notin @("the", "a", "an") } | Select-Object -First 8)

  if ($words.Count -gt 0) {
    return ("owned-{0:d3}-{1}" -f $No, ($words -join "-"))
  }

  return ("owned-{0:d3}" -f $No)
}

function ConvertTo-YamlSingleQuoted {
  param([string]$Value)

  return "'" + ($Value -replace "'", "''") + "'"
}

function ConvertTo-YamlListItem {
  param([string]$Value)

  return "  - " + (ConvertTo-YamlSingleQuoted $Value)
}

function Get-PlayersMin {
  param(
    [string]$Type,
    [int]$PlayersMax
  )

  if ($PlayersMax -le 1) {
    return 1
  }

  if ($Type -match "ソロ") {
    return 1
  }

  return 2
}

function Get-Tags {
  param(
    [string]$Type,
    [string]$Mechanics
  )

  $tags = New-Object System.Collections.Generic.List[string]
  $tags.Add("ボードゲーム")

  if ($Type -match "ソロ") {
    $tags.Add("ソロ")
  }
  if ($Type -match "協力") {
    $tags.Add("協力ゲーム")
  }
  if ($Type -match "対戦") {
    $tags.Add("対戦")
  }

  $mechanicParts = $Mechanics -split "[/&、,]" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  foreach ($part in $mechanicParts) {
    $tag = $part
    if ($tag -eq "ワーカプレスメント") {
      $tag = "ワーカープレイスメント"
    } elseif ($tag -eq "正体隠匿" -or $tag -eq "隠蔽") {
      $tag = "ヒドゥンロール（正体隠匿）"
    }

    if ($tag -and -not $tags.Contains($tag)) {
      $tags.Add($tag)
    }
  }

  return $tags
}

function New-GamePageContent {
  param($Row)

  $playersMax = [int]$Row.PlayersMax
  $playersMin = Get-PlayersMin -Type $Row.Type -PlayersMax $playersMax
  $time = [int]$Row.Time
  $tags = Get-Tags -Type $Row.Type -Mechanics $Row.Mechanics
  $tagLines = ($tags | ForEach-Object { ConvertTo-YamlListItem $_ }) -join "`n"

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("---")
  $lines.Add("layout: default")
  $lines.Add("title: $(ConvertTo-YamlSingleQuoted $Row.Title)")
  $lines.Add("players_min: $playersMin")
  $lines.Add("players_max: $playersMax")
  $lines.Add("time_min: $time")
  $lines.Add("time_max: $time")
  $lines.Add("tags:")
  $lines.Add($tagLines)
  $lines.Add("thumbnail_url: $(ConvertTo-YamlSingleQuoted $ThumbnailUrl)")
  $lines.Add("thumbnail_alt: $(ConvertTo-YamlSingleQuoted ($Row.Title + ' サムネイル'))")
  $lines.Add("source_note: $(ConvertTo-YamlSingleQuoted 'ボードゲームリスト.xlsm から作成した仮ページ')")
  $lines.Add("---")
  $lines.Add("")
  $lines.Add("## 概要メモ")
  $lines.Add("")
  $lines.Add("- プレイ人数: $playersMin〜$playersMax 人")
  $lines.Add("- プレイ時間: $time 分")
  $lines.Add("- 形式: $($Row.Type)")
  $lines.Add("- メカニクス: $($Row.Mechanics)")

  if (-not [string]::IsNullOrWhiteSpace($Row.Expansion)) {
    $lines.Add("- 拡張: $($Row.Expansion)")
  }

  if (-not [string]::IsNullOrWhiteSpace($Row.ExpansionDetail)) {
    $lines.Add("")
    $lines.Add("## 拡張メモ")
    $lines.Add("")
    foreach ($item in ($Row.ExpansionDetail -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
      $lines.Add("- $item")
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($Row.Notes)) {
    $lines.Add("")
    $lines.Add("## 備考")
    $lines.Add("")
    foreach ($item in ($Row.Notes -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
      $lines.Add("- $item")
    }
  }

  $lines.Add("")
  $lines.Add("参照元: {{ page.source_note }}")
  $lines.Add("")

  return ($lines -join "`n")
}

function Get-WorkbookRows {
  param(
    [string]$Path,
    [string]$TargetSheetName
  )

  $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Read)

  try {
    [xml]$workbook = Read-ZipEntry -Archive $archive -Name "xl/workbook.xml"
    [xml]$relationships = Read-ZipEntry -Archive $archive -Name "xl/_rels/workbook.xml.rels"

    $relationshipTargets = @{}
    foreach ($relationship in $relationships.Relationships.Relationship) {
      $relationshipTargets[$relationship.Id] = $relationship.Target
    }

    $sheetTarget = $null
    foreach ($sheet in $workbook.workbook.sheets.sheet) {
      if ($sheet.name -eq $TargetSheetName) {
        $relationshipId = $sheet.GetAttribute("id", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
        $sheetTarget = $relationshipTargets[$relationshipId]
        break
      }
    }

    if (-not $sheetTarget) {
      throw "Sheet '$TargetSheetName' was not found."
    }

    $sharedStrings = @()
    $sharedStringXml = Read-ZipEntry -Archive $archive -Name "xl/sharedStrings.xml"
    if ($sharedStringXml) {
      [xml]$sharedStringTable = $sharedStringXml
      foreach ($item in $sharedStringTable.sst.si) {
        $sharedStrings += (Get-SharedStringText $item)
      }
    }

    [xml]$sheetXml = Read-ZipEntry -Archive $archive -Name ("xl/" + $sheetTarget)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($row in $sheetXml.worksheet.sheetData.row) {
      $cells = @{}
      foreach ($cell in $row.c) {
        $cells[(Get-CellColumn $cell.r)] = Get-CellValue -Cell $cell -SharedStrings $sharedStrings
      }

      if ($cells["A"] -match "^\d+$" -and -not [string]::IsNullOrWhiteSpace($cells["B"])) {
        $rows.Add([pscustomobject]@{
          No = [int]$cells["A"]
          Title = ([string]$cells["B"]).Trim()
          PlayersMax = ([string]$cells["C"]).Trim()
          Type = ([string]$cells["D"]).Trim()
          Mechanics = ([string]$cells["E"]).Trim()
          Time = ([string]$cells["F"]).Trim()
          Expansion = ([string]$cells["G"]).Trim()
          ExpansionDetail = ([string]$cells["I"]).Trim()
          Notes = ([string]$cells["J"]).Trim()
        })
      }
    }

    return $rows
  } finally {
    $archive.Dispose()
    $stream.Dispose()
  }
}

$knownExistingRows = @(
  7, 8, 28, 29, 38, 39, 40, 46, 59, 63, 65, 69, 70, 71, 75, 77, 78, 80,
  81, 82, 83, 84, 85, 86, 89, 90, 91, 92, 94, 95, 97, 98, 101, 104, 105,
  106, 107
)

$rows = Get-WorkbookRows -Path $WorkbookPath -TargetSheetName $SheetName
$created = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$seenTitles = New-Object System.Collections.Generic.HashSet[string]

foreach ($row in $rows) {
  $titleKey = $row.Title.Normalize([Text.NormalizationForm]::FormKC).ToLowerInvariant()
  if (-not $seenTitles.Add($titleKey)) {
    $skipped.Add(("duplicate title: {0} {1}" -f $row.No, $row.Title))
    continue
  }

  if ($knownExistingRows -contains $row.No) {
    $skipped.Add(("already exists: {0} {1}" -f $row.No, $row.Title))
    continue
  }

  if (-not ($row.PlayersMax -match "^\d+$") -or -not ($row.Time -match "^\d+$")) {
    $skipped.Add(("missing numeric metadata: {0} {1}" -f $row.No, $row.Title))
    continue
  }

  $slug = ConvertTo-Slug -No $row.No -Title $row.Title
  $filePath = Join-Path $GamesDir ($slug + ".md")
  if (Test-Path -LiteralPath $filePath) {
    $skipped.Add(("file exists: {0} {1}" -f $row.No, $filePath))
    continue
  }

  $created.Add(("{0} {1} -> {2}" -f $row.No, $row.Title, $filePath))

  if (-not $DryRun) {
    $content = New-GamePageContent -Row $row
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $GamesDir).Path + [System.IO.Path]::DirectorySeparatorChar + ($slug + ".md"), $content, [System.Text.UTF8Encoding]::new($false))
  }
}

"create_count=$($created.Count)"
$created
"skip_count=$($skipped.Count)"
$skipped

