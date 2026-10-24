let
  digits = builtins.listToAttrs (builtins.concatLists (builtins.genList (n: [
    { name = builtins.substring n 1 "0123456789abcdef"; value = n; }
    { name = builtins.substring n 1 "0123456789ABCDEF"; value = n; }
  ]) 16));
  channel = color: offset:
    (digits.${builtins.substring offset 1 color} * 16 + digits.${builtins.substring (offset + 1) 1 color}) / 255.0;
  # sRGB's exponent 2.4 is the fifth root of x^12. Newton iteration avoids
  # depending on nixpkgs or an external evaluator for fractional powers.
  linear = value:
    if value <= 0.04045 then value / 12.92 else
    let
      x = (value + 0.055) / 1.055;
      x2 = x * x;
      x4 = x2 * x2;
      x12 = x4 * x4 * x4;
    in builtins.foldl' (root: _: (4 * root + x12 / (root * root * root * root)) / 5) 1.0 (builtins.genList (n: n) 40);
  luminance = color:
    0.2126 * linear (channel color 1) + 0.7152 * linear (channel color 3) + 0.0722 * linear (channel color 5);
in {
  # Stable hue families map catalog colors onto a theme's named palette. Keep
  # the same integer boundaries in the portable adapter.
  role = color:
    let
      r = channel color 1 * 255;
      g = channel color 3 * 255;
      b = channel color 5 * 255;
      maximum = builtins.foldl' (a: v: if a > v then a else v) r [ g b ];
      minimum = builtins.foldl' (a: v: if a < v then a else v) r [ g b ];
      delta = maximum - minimum;
      hue = if maximum == r then (g - b) / delta
        else if maximum == g then 2 + (b - r) / delta
        else 4 + (r - g) / delta;
      normalized = if hue < 0 then hue + 6 else hue;
    in if delta < 32 then "foreground"
      else if normalized < 0.35 then "red"
      else if normalized < 0.8 then "orange"
      else if normalized < 1.5 then "yellow"
      else if normalized < 2.7 then "green"
      else if normalized < 3.3 then "cyan"
      else if normalized < 4.5 then "blue"
      else if normalized < 5.3 then "purple"
      else if normalized < 5.8 then "pink"
      else "red";
  contrast = foreground: background:
    let a = luminance foreground; b = luminance background;
    in if a > b then (a + 0.05) / (b + 0.05) else (b + 0.05) / (a + 0.05);
}
