---
layout: default
title: 時間別
---

{% assign games_pages = site.pages | where_exp: "item", "item.path contains 'games/'" | where_exp: "item", "item.path != 'games/index.md'" | sort: "title" %}

{% assign light_max = site.weight_thresholds.light_max | default: 30 | plus: 0 %}
{% assign medium_max = site.weight_thresholds.medium_max | default: 90 | plus: 0 %}

{% assign missing_count = 0 %}
{% for g in games_pages %}
	{% if g.time_min == nil or g.time_max == nil %}
		{% assign missing_count = missing_count | plus: 1 %}
	{% endif %}
{% endfor %}

{% if missing_count > 0 %}
<div style="padding:10px 12px; border:1px solid #f59e0b; background:#fffbeb; border-radius:10px; margin: 10px 0 18px;">
	<strong>メタ情報未設定のゲームがあります</strong><br />
	時間別の振り分けには <code>time_min</code> / <code>time_max</code> が必要です。
</div>
{% endif %}

## 軽量（〜{{ light_max }}分）

{% assign found = 0 %}
{% for g in games_pages %}
	{% assign tmax_raw = g.time_max | default: g.time_min %}
	{% if tmax_raw %}
		{% assign tmax = tmax_raw | plus: 0 %}
	{% endif %}
	{% if tmax_raw and tmax <= light_max %}
		{% assign found = found | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.time_min }}{% if g.time_max != g.time_min %}〜{{ g.time_max }}{% endif %}分）
	{% endif %}
{% endfor %}
{% if found == 0 %}
（該当なし）
{% endif %}

---

## 中量級（{{ light_max | plus: 1 }}〜{{ medium_max }}分）

{% assign found = 0 %}
{% for g in games_pages %}
	{% assign tmax_raw = g.time_max | default: g.time_min %}
	{% if tmax_raw %}
		{% assign tmax = tmax_raw | plus: 0 %}
	{% endif %}
	{% if tmax_raw and tmax > light_max and tmax <= medium_max %}
		{% assign found = found | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.time_min }}{% if g.time_max != g.time_min %}〜{{ g.time_max }}{% endif %}分）
	{% endif %}
{% endfor %}
{% if found == 0 %}
（該当なし）
{% endif %}

---

## 重量級（{{ medium_max | plus: 1 }}分〜）

{% assign found = 0 %}
{% for g in games_pages %}
	{% assign tmax_raw = g.time_max | default: g.time_min %}
	{% if tmax_raw %}
		{% assign tmax = tmax_raw | plus: 0 %}
	{% endif %}
	{% if tmax_raw and tmax > medium_max %}
		{% assign found = found | plus: 1 %}
- [{{ g.title }}]({{ g.url | relative_url }})（{{ g.time_min }}{% if g.time_max != g.time_min %}〜{{ g.time_max }}{% endif %}分）
	{% endif %}
{% endfor %}
{% if found == 0 %}
（該当なし）
{% endif %}

---

## 未設定

{% if missing_count == 0 %}
（未設定なし）
{% else %}
{% for g in games_pages %}
	{% if g.time_min == nil or g.time_max == nil %}
- [{{ g.title }}]({{ g.url | relative_url }})
	{% endif %}
{% endfor %}
{% endif %}