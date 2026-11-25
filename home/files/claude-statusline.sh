#!/bin/bash
# Claude Code status line
# Shows: model + effort/thinking, context window usage, session cost

input=$(cat)

jq -r '
  def esc: "\u001b[";
  def fg($n): "\(esc)38;5;\($n)m";
  def reset: "\(esc)0m";
  def money: (. * 100 + 0.5 | floor) as $c
    | "$\($c / 100 | floor).\($c % 100 | tostring | if length < 2 then "0" + . else . end)";
  def tokens: if . >= 1000000 then "\(. / 1000000 | round)M"
    elif . >= 1000 then "\(. / 1000 | floor)k" else tostring end;

  # Palette: green below 50%, amber below 80%, red above.
  def zone: if . < 50 then 114 elif . < 80 then 214 else 203 end;
  def bar($pct): ([($pct / 100 * 8 | round), 0] | max | [., 8] | min) as $f
    | ([range($f)] | map("▉") | join("")) + ([range(8 - $f)] | map("░") | join(""));

  ((.model.id // "") | ascii_downcase) as $mid
  | (if ($mid | test("fable|mythos")) then 141
     elif ($mid | contains("sonnet")) then 75
     elif ($mid | contains("haiku")) then 114
     elif ($mid | contains("opus")) then 209
     else 180 end) as $model_color
  | ((.model.display_name // "unknown")
      | sub("\\s*\\([^)]*(1m|context)[^)]*\\)\\s*$"; ""; "i")) as $model
  | (if (.effort.level // "") != "" then " (\(.effort.level))" else "" end)
    + (if (.thinking.enabled // false) == true then " +think" else "" end) as $extras

  | (.context_window.used_percentage) as $pct
  | (.context_window.total_input_tokens) as $used
  | (.context_window.context_window_size) as $total
  | (if $pct == null then "\(fg(245))ctx n/a\(reset)"
     else "\(fg($pct | zone))ctx \(bar($pct)) \($pct | round)%\(reset)"
       + (if $used != null and $total != null
          then " \(fg(245))\($used | tokens)/\($total | tokens)\(reset)" else "" end)
     end) as $ctx_info

  | (.cost.total_cost_usd) as $main
  | (if $main == null then ""
     else "\(fg(150))\($main | money)\(reset)" end) as $cost_info

  | "\(fg($model_color))\($model)\(reset)\(fg(245))\($extras)\(reset)  \($ctx_info)"
    + (if $cost_info != "" then "  \($cost_info)" else "" end)
' <<<"$input"
