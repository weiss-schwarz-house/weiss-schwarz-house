param(
  [string]$GamesDir = "games"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function ConvertTo-YamlSingleQuoted {
  param([string]$Value)
  return "'" + ($Value -replace "'", "''") + "'"
}

function Set-FrontMatterValue {
  param(
    [string]$FrontMatter,
    [string]$Key,
    [string]$Value
  )

  $line = "$Key`: $(ConvertTo-YamlSingleQuoted $Value)"
  if ($FrontMatter -match "(?m)^$([regex]::Escape($Key)):\s*.*$") {
    return [regex]::Replace($FrontMatter, "(?m)^$([regex]::Escape($Key)):\s*.*$", $line)
  }

  return ($FrontMatter.TrimEnd() + "`n" + $line)
}

function New-ResearchBlock {
  param($Update)

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("<!-- researched-links:start -->")

  if ($Update.ContainsKey("intro_url")) {
    $lines.Add("## 紹介")
    $lines.Add("")
    $lines.Add("- 紹介ページ: [参照ページ]({{ page.intro_url }})")
    $lines.Add("")
  }

  if ($Update.ContainsKey("rulebook_url")) {
    $lines.Add("## ルール")
    $lines.Add("")
    $lines.Add("- ルールブック: [ルールブック]({{ page.rulebook_url }})")
    $lines.Add("")
  }

  if ($Update.ContainsKey("source_url")) {
    $lines.Add("## 公式サイト")
    $lines.Add("")
    $lines.Add("- 公式ページ: [参照ページ]({{ page.source_url }})")
    $lines.Add("")
  }

  $referenceLines = New-Object System.Collections.Generic.List[string]
  if ($Update.ContainsKey("bgg_url")) {
    $referenceLines.Add("- BoardGameGeek: [BGG]({{ page.bgg_url }})")
  }
  if ($Update.ContainsKey("bodoge_url")) {
    $referenceLines.Add("- ボドゲーマ: [紹介ページ]({{ page.bodoge_url }})")
  }
  if ($Update.ContainsKey("wikipedia_url")) {
    $referenceLines.Add("- Wikipedia: [参照ページ]({{ page.wikipedia_url }})")
  }

  if ($referenceLines.Count -gt 0) {
    $lines.Add("## 参考")
    $lines.Add("")
    foreach ($line in $referenceLines) {
      $lines.Add($line)
    }
    $lines.Add("")
  }

  $lines.Add("<!-- researched-links:end -->")
  $lines.Add("")

  return ($lines -join "`n")
}

$updates = @{
  "owned-001.md" = @{
    title = "Unicorn Overlord Original Card Game（ユニコーンオーバーロード オリジナルカードゲーム）"
    source_url = "https://www.atlus.co.jp/news/22357/"
    bodoge_url = "https://bodoge.hoobby.net/games/unicorn-overlord-original-card-game"
  }
  "owned-002-slay-spire-board-game.md" = @{
    title = "Slay the Spire: The Board Game"
    wikipedia_url = "https://en.wikipedia.org/wiki/Slay_the_Spire"
  }
  "owned-012.md" = @{
    title = "Monster Eater: A Delicious in Dungeon Board Game（モンスターイーター ～ダンジョン飯 ボードゲーム～）"
    source_url = "https://arclightgames.jp/product/682mtet/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Delicious_in_Dungeon"
  }
  "owned-013.md" = @{
    title = "Dungeon & Dectet（破宮の十重奏 / デクテット）"
    source_url = "https://www.konami.com/games/jp/ja/products/dectet/"
    intro_url = "https://yofukashiproject.com/dectet/"
    bgg_url = "https://boardgamegeek.com/boardgame/381723/po-gong-noshi-zhong-zou-dungeon-and-dectet"
    bodoge_url = "https://bodoge.hoobby.net/games/dungeon-dectet"
  }
  "owned-019.md" = @{
    title = "Mahjong（麻雀）"
    wikipedia_url = "https://en.wikipedia.org/wiki/Mahjong"
  }
  "owned-027.md" = @{
    title = "Lost Ruins of Arnak（アルナックの失われし遺跡）"
    source_url = "https://czechgames.com/en/lost-ruins-of-arnak/"
    rulebook_url = "https://czechgames.com/files/rules/lost-ruins-of-arnak-rules-en.pdf"
  }
  "owned-032.md" = @{
    title = "Clank!（クランク！）"
    source_url = "https://www.direwolfdigital.com/clank/"
  }
  "owned-033.md" = @{
    title = "Terraforming Mars（テラフォーミング・マーズ ～火星地球化計画～）"
    source_url = "https://arclightgames.jp/product/%e3%83%86%e3%83%a9%e3%83%95%e3%82%a9%e3%83%bc%e3%83%9f%e3%83%b3%e3%82%b0%e3%83%9e%e3%83%bc%e3%82%ba/"
    intro_url = "https://www.fryxgames.se/games/terraforming-mars/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Terraforming_Mars_(board_game)"
  }
  "owned-034.md" = @{
    title = "Shadow Raiders（シャドウレイダーズ）"
  }
  "owned-036.md" = @{
    title = "Aeon's End（イーオンズ・エンド）"
    source_url = "https://arclightgames.jp/product/%e3%82%a4%e3%83%bc%e3%82%aa%e3%83%b3%e3%82%ba%e3%82%a8%e3%83%b3%e3%83%89/"
  }
  "owned-041.md" = @{
    title = "Ark Nova（アークノヴァ）"
    source_url = "https://www.feuerland-spiele.de/spiele/arche-nova/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Ark_Nova"
  }
  "owned-042.md" = @{
    title = "Brass: Lancashire（ブラス：ランカシャー）"
    source_url = "https://www.roxley.com/products/brass-lancashire"
    intro_url = "https://arclightgames.jp/product/%e3%83%96%e3%83%a9%e3%82%b9%e3%83%a9%e3%83%b3%e3%82%ab%e3%82%b7%e3%83%a3%e3%83%bc/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Brass_(board_game)"
  }
  "owned-043.md" = @{
    title = "Brass: Birmingham（ブラス: バーミンガム）"
    source_url = "https://www.roxley.com/products/brass-birmingham"
    intro_url = "https://arclightgames.jp/product/%e3%83%96%e3%83%a9%e3%82%b9%e3%83%90%e3%83%bc%e3%83%9f%e3%83%b3%e3%82%ac%e3%83%a0/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Brass_(board_game)"
  }
  "owned-044.md" = @{
    title = "Jumble Derby（ジャンブルダービー）"
  }
  "owned-047.md" = @{
    title = "Gloomhaven（グルームヘイヴン）"
    source_url = "https://cephalofair.com/pages/gloomhaven"
    rulebook_url = "https://online.flippingbook.com/view/598058/"
    wikipedia_url = "https://en.wikipedia.org/wiki/Gloomhaven"
  }
  "owned-050.md" = @{
    bodoge_url = "https://bodoge.hoobby.net/games/maigo"
  }
  "owned-053.md" = @{
    title = "Wild Hunt Fest（ワイルドハントフェス）"
  }
  "owned-055-9-96.md" = @{
    title = "Cullinan（カリナン ～9つと96粒のダイヤモンド～）"
  }
  "owned-058.md" = @{
    title = "Monster Breeder（モンスターブリーダー）"
  }
  "owned-067.md" = @{
    title = "Nemesis（ネメシス）"
    source_url = "https://arclightgames.jp/product/%e3%83%8d%e3%83%a1%e3%82%b7%e3%82%b9/"
    intro_url = "https://awakenrealms.com/games/nemesis/"
  }
  "owned-068.md" = @{
    title = "Wyrmspan（ワイアームスパン）"
    source_url = "https://www.stonemaiergames.com/games/wyrmspan/"
  }
  "owned-072.md" = @{
    title = "Coffee Rush（コーヒーラッシュ）"
  }
  "owned-073.md" = @{
    title = "Sky Team（スカイチーム）"
    source_url = "https://www.scorpionmasque.com/en/sky-team"
  }
  "owned-074-2023.md" = @{
    title = "Battle Line（バトルライン 日本語版2023 / 新版）"
  }
  "owned-088.md" = @{
    title = "Pokemon Goita（ポケモンごいた）"
  }
  "owned-093.md" = @{
    title = "The Lord of the Rings: Duel for Middle-earth（指輪物語：デュエル 中つ国の決戦 日本語版）"
    source_url = "https://www.rprod.com/en/games/the-lord-of-the-rings-duel-for-middle-earth"
  }
  "owned-099.md" = @{
    title = "Starlit Seven（スターリットセブン）"
  }
}

$changed = New-Object System.Collections.Generic.List[string]

foreach ($fileName in $updates.Keys) {
  $path = Join-Path $GamesDir $fileName
  if (-not (Test-Path -LiteralPath $path)) {
    throw "File not found: $path"
  }

  $update = $updates[$fileName]
  $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
  if ($text -notmatch "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$") {
    throw "Front matter was not found: $path"
  }

  $frontMatter = $matches[1]
  $body = $matches[2]

  foreach ($key in @("title", "source_url", "intro_url", "rulebook_url", "bgg_url", "bodoge_url", "wikipedia_url")) {
    if ($update.ContainsKey($key)) {
      $frontMatter = Set-FrontMatterValue -FrontMatter $frontMatter -Key $key -Value $update[$key]
    }
  }

  $body = [regex]::Replace($body, "(?s)<!-- researched-links:start -->.*?<!-- researched-links:end -->\r?\n?", "")
  $block = New-ResearchBlock -Update $update
  if ($block -match "## ") {
    if ($body -match "(?m)^## 概要メモ") {
      $body = [regex]::Replace($body, "(?m)^## 概要メモ", ($block + "## 概要メモ"), 1)
    } else {
      $body = $block + $body
    }
  }

  $newText = "---`n$frontMatter`n---`n$body"
  [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $path).Path, $newText, [System.Text.UTF8Encoding]::new($false))
  $changed.Add($fileName)
}

"changed_count=$($changed.Count)"
$changed | Sort-Object


