---
layout: default
title: ヴァイスシュヴァルツの館
---
## はじめに
このサイトは、サークル活動でプレイするボードゲームのルール・要点をまとめた非公式です。

---

## まずはこちら
- 左のサイドバーから、**人数・時間別**にゲームを探せます
- [ゲーム一覧を見る](games/)

## 最近追加したゲーム（新着）

{% assign games_pages = site.pages | where_exp: "p", "p.path contains 'games/'" | where_exp: "p", "p.path != 'games/index.md'" | sort: "title" %}

{% assign pages_with_date = games_pages | where_exp: "p", "p.date != nil" | sort: "date" | reverse %}
{% assign pages_without_date = games_pages | where_exp: "p", "p.date == nil" | sort: "path" | reverse %}

{% assign max_show = 5 %}
{% assign shown = 0 %}

{% for g in pages_with_date %}
<a href="{{ g.url | relative_url }}">{{ g.title }}</a>
{% assign shown = shown | plus: 1 %}{% if shown >= max_show %}{% break %}{% endif %}
{% endfor %}

{% if shown < max_show %}
  {% for g in pages_without_date %}
    <a href="{{ g.url | relative_url }}">{{ g.title }}</a>
    {% assign shown = shown | plus: 1 %}{% if shown >= max_show %}{% break %}{% endif %}
  {% endfor %}
{% endif %}

---

---