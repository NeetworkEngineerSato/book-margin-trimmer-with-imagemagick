# ImageMagick で自炊書籍画像の余白をトリミングする PowerShell

## 概要

- トリミングする画像があるフォルダを選択する
- フォルダ内の画像の余白をトリミングする
- 画像の幅と高さをトリミング後の画像の中で最大のものに揃える
- 画像を上下左右中央に移動する (1 行だけのページは 1 行目が中央に移動する)

## 備考

- 未テスト、使用は自己責任
- 実行コマンド: `powershell -NoProfile -ExecutionPolicy Bypass ./TrimBookMargin.ps1`
- 実行できない場合: <https://www.google.com/>
- 「.jpg」のみ対応
- 処理の一部は「settings.json」で変更可能
- 「TrimBookMargin.ps1」と同じフォルダに一時ファイルが画像の数と同じ回数生成される

## 動作環境

- OS: Windows 10 Home
- PowerShell: 7.1.3  
  <https://github.com/powershell/powershell#get-powershell>
- ImageMagick: ImageMagick 7.0.11-10 Q16 x64 2021-04-28  
  <https://imagemagick.org/script/download.php#windows>

## ダウンロード

<https://github.com/NeetworkEngineerSato/book-margin-trimmer-with-imagemagick/archive/refs/tags/v1.0.0.zip>

## settings.json

### fuzz, fuzzInterval

fuzz は画像をトリミングする際に使用されるしきい値です。
0 から 100 の整数が指定できます。  
この値が低すぎると汚れ等のノイズがある場所でトリミングが止まり、
この値が高すぎると必要な部分もトリミングされます。

ImageMagick は 0 から 100 以外の値も使用できますが、
この PowerShell では前述の値を使用した%値での指定に制限しています。

fuzz の値を「"50-60"」の様に範囲で指定すると fuzz 毎にフォルダを作成し、
それに応じた値でトリミングした画像を生成します。

例えば、fuzz: "50-60", fuzzInterval: 3 であれば、
fuzz を 50, 53, 56, 59 でトリミングした画像が生成されます。

### trimColor

トリミングする余白の色です。未指定("")の場合はコーナーピクセルの色で余白をトリミングします。  
aqua, black, blue, fuchsia, gray, green, lime, maroon, navy, olive, purple, red, silver, teal, white, yellow 等が指定できます。  
<https://imagemagick.org/script/color.php>

### quality

画像の品質です。0 から 100 の整数が指定できます。  
1 は最低値、100 は最高値、0 はデフォルト値です。

### marginWidth

追加する余白の幅です。ピクセル単位で整数が指定できます。  
marginWidth: 100 の場合、トリミング後の画像の左右に余白が 100 ピクセルずつ追加されます。

### marginHeight

追加する余白の高さです。ピクセル単位で整数が指定できます。  
marginHeight: 100 の場合、トリミング後の画像の上下に余白が 100 ピクセルずつ追加されます。

### background

追加する余白の色です。aqua, black, blue, fuchsia, gray, green, lime, maroon, navy, olive, purple, red, silver, teal, white, yellow 等が指定できます。  
<https://imagemagick.org/script/color.php>

### gravity

余白追加前の配置方向です。NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast が指定できます。  
<https://imagemagick.org/script/command-line-options.php#gravity>

### offsetX

画像を x 方向にずらす値です。ピクセル単位で整数が指定できます。

### offsetY

画像を y 方向にずらす値です。ピクセル単位で整数が指定できます。
