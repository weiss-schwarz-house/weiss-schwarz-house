# サイト要件定義（ヴァイスシュヴァルツの館）

## 1. 目的
- サークル内でプレイするボードゲームの**ルールブック・要点・注意点を素早く参照できる**ようにする
- 初期段階での検索機能実装

- ルール確認・勘違い防止・FAQ確認を主目的とする
- 将来的に多数（数十〜100以上）のゲーム追加を想定する
- 個人ブログではなく、**共有ナレッジ（簡易Wiki）**として運用する

---

## 2. 想定利用者
- サークルメンバー
### サイト設計書 — ヴァイスシュヴァルツの館

この設計書は、サークル内で使うボードゲーム情報（ルールブックへのリンク、要点、注意点）を手早く参照できるようにするための運用ルールと技術仕様をまとめたものです。

## 目次
- 目的
- 基本ルール（1ゲーム=1ファイル等）
- 必須 front matter（フィールド仕様）
- ファイル構成（概要）
- テンプレート要点
- 運用手順（新規追加・日付補完）
- スクリプト & CI
- 設定値
- 運用チェックリスト

---

## 目的
- ルール確認・勘違い防止・FAQ参照を素早く行える共通リソースを提供する。
- 手作業での運用を最小化しつつ、将来的な自動分類／検索の土台を用意する。

---

## 基本ルール
- 1ゲームにつき1Markdownファイル（`games/` 配下）。
- 表示は Liquid レイアウト（`_layouts/default.html` 等）で統一。
- 分類・検索は front matter のメタ情報で行う（フォルダ分けは行わない）。

---

## 必須 front matter（フィールド仕様）
- 以下は各ゲームファイルで必ず（または推奨して）記載するフィールドです。数値は整数で記載してください。

```yaml
layout: default
title: <ゲーム名>            # 必須
players_min: <整数>          # 必須
players_max: <整数>          # 必須
time_min: <分>               # 必須（分）
time_max: <分>               # 必須（分）
date: YYYY-MM-DD            # 任意（新着ソートに推奨）
updated: YYYY-MM-DD         # 任意（更新日表示に使用）
weight: light|medium|heavy  # 任意（未指定なら time_max から自動判定）
tags: [タグ1, タグ2]        # 任意（日本語タグ推奨）
rulebook_url: <外部PDF URL>
thumbnail_url: <画像URL>
thumbnail_alt: <代替テキスト>
bgg_url: <任意のBGGページ>
```

- 補足:
  - `players_min/max` と `time_min/max` はリスト生成に必須です。
  - `date`/`updated` が無いと「最近追加」表示の安定性が落ちます。スクリプトで補完可能です。

---

## ファイル構成（抜粋）
- `index.md` — トップページ（最近の追加・注目）
- `games/` — 個別ゲームページ（`games/index.md` が一覧テンプレ）
- `lists/` — 人数別・時間別などの一覧ページ（テンプレ的に運用）
- `_layouts/` — Liquid テンプレート（`default.html`, `game_list.html` 等）
- `scripts/` — 運用スクリプト（`update_game_dates.py` 等）
- `.github/workflows/` — CI ワークフロー

---

## テンプレート要点
- `game_list.html`（一覧）:
  - 各カードはサムネ、タイトル、players/time/weight/tags を表示。
  - `weight` 未指定時は `time_max` から `light`/`medium`/`heavy` を自動判定（閾値は `_config.yml` の `weight_thresholds`）。

- `default.html`（個別）:
  - サムネイルは 4:3 固定枠で `object-fit: contain`。（切り抜かずに枠内に収める）
  - ページ下部に `updated`（無ければ `date`）を表示。

- 実装注意:
  - Liquid の比較は文字列扱いになりがちなので、数値比較が必要な箇所では `| plus: 0` を用いる。

---

## 運用手順（新規ゲーム追加）
1. `games/` に `xxx.md` を作成。
2. front matter を記入（`players_min/max`, `time_min/max` は必須）。
3. 本文に要点・ルールブックへのリンク・注意点を記載。
4. プレビュー確認後、`git add/commit/push`。

---

## 日付自動補完スクリプト & CI
- スクリプト: `scripts/update_game_dates.py`
  - git 履歴から `date`（初回追加）と `updated`（最終コミット）を補完します。
  - ローカル実行コマンド:

```bash
python3 scripts/update_game_dates.py
git status --porcelain
git add games/*.md
git commit -m "chore: populate date/updated from git history"
git push
```

- CI ワークフロー: `.github/workflows/update_dates.yml`
  - 手動実行または push トリガーでスクリプトを実行し、差分があれば `GITHUB_TOKEN` でコミットします。
  - 注意: 組織ポリシーで Actions に書き込み制限がある場合は手動実行を推奨します。

---

## 設定（`_config.yml`）
- `weight_thresholds`（例）:
  - `light_max: 30`  # 分未満を軽量と判断
  - `medium_max: 90` # 分未満を中量と判断
- `weight_labels`：表示用ラベル（日本語）
- `new_days`：`NEW` バッジの判定日数（デフォルト 30）

---

## 運用チェックリスト（短縮版）
- [ ] 新規追加時に `players_min/max`, `time_min/max` を必ず記入
- [ ] ルールPDFは外部ストレージに置き `rulebook_url` を指定
- [ ] 可能ならサムネ画像を `assets/thumbs/` に保存
- [ ] `date`/`updated` を補完する場合はスクリプトを実行して差分を確認

---

## 将来の拡張案（任意）
- テンプレ変数一覧（フィールド名と用例）の表を追加
- Markdown lint を CI に導入してフォーマットを強制
- 軽量なフロントエンド検索（JS）を追加してクライアント側フィルタを実装

---

## 変更履歴
- 2026-01-17: ドキュメント全体を再構成。必須フィールドと運用手順を明確化。

---

以上。編集済みの README_設計.md をご確認ください。修正したい箇所があれば指示ください。