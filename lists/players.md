---
layout: default
title: 人数別
---

{% assign games_pages = site.pages | where_exp: "item", "item.path contains 'games/'" | where_exp: "item", "item.path != 'games/index.md'" | sort: "title" %}

{% assign missing_count = 0 %}
{% for g in games_pages %}
  {% if g.players_min == nil or g.players_max == nil %}
    {% assign missing_count = missing_count | plus: 1 %}
  {% endif %}
{% endfor %}

{% if missing_count > 0 %}
<div style="padding:10px 12px; border:1px solid #f59e0b; background:#fffbeb; border-radius:10px; margin: 10px 0 18px;">

  <strong>メタ情報未設定のゲームがあります</strong><br />
  人数別の振り分けには <code>players_min</code> / <code>players_max</code> が必要です。

</div>
{% endif %}

## 2人で遊べるゲーム

{% assign found = 0 %}
{% for g in games_pages %}

  {% if g.players_min and g.players_max %}
    {% assign pmin = g.players_min | plus: 0 %}
    {% assign pmax = g.players_max | plus: 0 %}
    {% if 2 >= pmin and 2 <= pmax %}
      {% assign found = found | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.players_min }}{% if g.players_max != g.players_min %}〜{{ g.players_max }}{% endif %}人）

    {% endif %}
  {% endif %}

{% endfor %}

{% if found == 0 %}
（該当なし）
{% endif %}

---

## 4人以上で遊べるゲーム

{% assign found = 0 %}
{% for g in games_pages %}

  {% if g.players_min and g.players_max %}
    {% assign pmin = g.players_min | plus: 0 %}
    {% assign pmax = g.players_max | plus: 0 %}
    {% if 4 >= pmin and 4 <= pmax %}
      {% assign found = found | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.players_min }}{% if g.players_max != g.players_min %}〜{{ g.players_max }}{% endif %}人）

    {% endif %}
  {% endif %}

{% endfor %}

{% if found == 0 %}
（該当なし）
{% endif %}

---

{% comment %}「3人以上だけ（2人不可）」が存在する場合の逃がし先{% endcomment %}
{% assign found = 0 %}
{% for g in games_pages %}
  {% if g.players_min and g.players_max %}
    {% assign pmin = g.players_min | plus: 0 %}
    {% assign pmax = g.players_max | plus: 0 %}
    {% assign can2 = false %}
    {% assign can3 = false %}
    {% if 2 >= pmin and 2 <= pmax %}{% assign can2 = true %}{% endif %}
    {% if 3 >= pmin and 3 <= pmax %}{% assign can3 = true %}{% endif %}
    {% if can3 and can2 == false %}
      {% assign found = found | plus: 1 %}
    {% endif %}
  {% endif %}
{% endfor %}

{% if found > 0 %}
## 3人以上で遊べる（2人不可）

{% assign shown = 0 %}
{% for g in games_pages %}
  {% if g.players_min and g.players_max %}
    {% assign pmin = g.players_min | plus: 0 %}
    {% assign pmax = g.players_max | plus: 0 %}
    {% assign can2 = false %}
    {% assign can3 = false %}
    {% if 2 >= pmin and 2 <= pmax %}{% assign can2 = true %}{% endif %}
    {% if 3 >= pmin and 3 <= pmax %}{% assign can3 = true %}{% endif %}
    {% if can3 and can2 == false %}
      {% assign shown = shown | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.players_min }}{% if g.players_max != g.players_min %}〜{{ g.players_max }}{% endif %}人）
    {% endif %}
  {% endif %}
{% endfor %}

---
{% endif %}

## 未設定

{% if missing_count == 0 %}
（未設定なし）
{% else %}
{% for g in games_pages %}
  {% if g.players_min == nil or g.players_max == nil %}
- [{{ g.title }}]({{ g.url | relative_url }})
  {% endif %}
{% endfor %}
{% endif %}