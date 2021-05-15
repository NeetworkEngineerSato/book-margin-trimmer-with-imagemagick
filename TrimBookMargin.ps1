using module "./lib/SimpleProgressBar.psm1"
using namespace System.Collections.Generic
using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = "Stop"

# 一時ファイルはこのPowerShellと同じフォルダに保存し、
# トリミング後の画像のwidthとheightの取得のみに使用する
[string] $thisPsFileFolderPath = $PSScriptRoot
[string] $tmpFilePath = Join-Path `
    $thisPsFileFolderPath "tmp-z303hifszh7d029naxzsshotqd2o9a.jpg" # 重複防止乱数

# このPowerShellと同じフォルダにあるsettings.jsonを読み込む
[string] $settingsFilePath = Join-Path $thisPsFileFolderPath "settings.json"
[PSCustomObject] $settings = Get-Content $settingsFilePath | ConvertFrom-Json

# fuzzは「50-60」の様な範囲または「50」の様な単一の値が指定される
[string] $fuzzRange = $settings.fuzz
[int] $FIRST_FUZZ = 0
[int] $LAST_FUZZ = 0
if ($fuzzRange.Contains("-")) {
    $FIRST_FUZZ, $LAST_FUZZ = $fuzzRange.Split("-")
}
else {
    $FIRST_FUZZ, $LAST_FUZZ = $fuzzRange, $fuzzRange
}

[int] $FUZZ_INTERVAL = [Math]::Max($settings.fuzzInterval, 1)
[int] $QUALITY = $settings.quality
[int] $MARGIN_WIDTH = $settings.marginWidth
[int] $MARGIN_HEIGHT = $settings.marginHeight
[string] $BACKGROUND = $settings.background
[string] $GRAVITY = $settings.gravity
[int] $OFFSET_X = $settings.offsetX
[int] $OFFSET_Y = $settings.offsetY

# -trimはコーナーピクセルの色で余白を判断するので
# 余白の色の指定があればその色の余白を付けてからトリミングする
[string] $FRAME_SIZE = "1x0"
[string] $TRIM_COLOR = $settings.trimColor
if ([string]::IsNullOrEmpty($TRIM_COLOR)) {
    $FRAME_SIZE = "0x0"
    $TRIM_COLOR = "white" # 余白サイズが"0x0"なので色に意味はない
}

[FolderBrowserDialog] $dialog = [FolderBrowserDialog]::new()

# OKボタンが押されなければ処理を中断する
if ($dialog.ShowDialog() -ne [DialogResult]::OK) {
    exit
}

[string] $inputFileFolderPath = $dialog.SelectedPath
[Object[]] $inputFileList = Get-ChildItem $inputFileFolderPath -File | `
    Where-Object { $_.Name -match "\.(jpg|jpeg)$" } # 拡張子の大文字小文字は区別しない
[string[]] $inputFilePathList = $inputFileList.FullName # 絶対パスの取得

# 主要処理の数はファイル数 * (前処理+主処理) * fuzzの数
[int] $fuzzCount = 1 + [Math]::Truncate(($LAST_FUZZ - $FIRST_FUZZ) / $FUZZ_INTERVAL)
[SimpleProgressBar] $progressBar = [SimpleProgressBar]::new( `
        $inputFilePathList.Length * 2 * $fuzzCount)

for ([int] $fuzz = $FIRST_FUZZ; $fuzz -le $LAST_FUZZ; $fuzz += $FUZZ_INTERVAL) {

    # トリミング後のwidthとheight等を保存しログファイルとして出力する
    [List[PSCustomObject]] $logList = [List[PSCustomObject]]::new()

    # 空白のページのファイル名を保存し、トリミング後の画像の生成を行う際に
    # 空白のページをトリミングする代わりに空白のページを生成する
    [HashSet[string]] $blankPageFileNameSet = [HashSet[string]]::new()

    # トリミング後の画像のwidthとheightの最大値を取得する
    [int] $maxWidth = 0
    [int] $maxHeight = 0
    foreach ($inputFilePath in $inputFilePathList) {

        # 一時ファイルの生成
        # トリミング後の画像のサイズが0の場合は警告が表示され、1x1ドットの画像が生成される
        # トリミング後のサイズはqualityに影響されないのでqualityは最小の1にする
        # トリミングする余白の色の指定があればその色の余白を付けてからトリミングする
        # TODO 「miff:-」で中間ファイルの生成をなくせそうだができなかった
        magick `
            `( `
            $inputFilePath `
            -mattecolor $TRIM_COLOR `
            -frame $FRAME_SIZE `
            `) `
            -fuzz $fuzz% `
            -trim `
            -quality 1 `
            $tmpFilePath

        [int] $tmpFileWidth = identify -format "%[width]" $tmpFilePath
        [int] $tmpFileHeight = identify -format "%[height]" $tmpFilePath

        [string] $fileName = Split-Path $inputFilePath -Leaf

        # トリミング後のサイズが1x1ピクセルになるものは空白とみなす
        if ($tmpFileWidth -eq 1 -and $tmpFileHeight -eq 1 ) {
            [void] $blankPageFileNameSet.Add($fileName)
        }
        else {
            $maxWidth = [Math]::Max($maxWidth, $tmpFileWidth)
            $maxHeight = [Math]::Max($maxHeight, $tmpFileHeight)
        }

        $logList.Add([PSCustomObject]@{
                file_name             = $fileName
                width_after_trimming  = $tmpFileWidth
                height_after_trimming = $tmpFileHeight
                fuzz                  = $fuzz
                # fuzz_interval         = $FUZZ_INTERVAL
                trim_color            = $TRIM_COLOR
                quality               = $QUALITY
                margin_width          = $MARGIN_WIDTH
                margin_height         = $MARGIN_HEIGHT
                background            = $BACKGROUND
                gravity               = $GRAVITY
                offset_x              = $OFFSET_X
                offset_y              = $OFFSET_Y
            })

        $progressBar.PerformStep()
    }

    [int] $outputFileWidth = $maxWidth + $MARGIN_WIDTH * 2 # 左右に余白を追加するので2倍する
    [int] $outputFileHeight = $maxHeight + $MARGIN_HEIGHT * 2 # 上下に余白を追加するので2倍する

    # トリミング後の画像を保存するフォルダの作成
    [string] $dateTime = (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
    [string] $formattedFuzz = $fuzz.ToString("000") # 3桁揃え
    [string] $formattedQuality = $QUALITY.ToString("000")
    [string] $outputFolderName = [string]::Concat( `
            "${dateTime}", `
            "-quality(${formattedQuality})", `
            "-fuzz(${formattedFuzz})", `
            "-resolution(${outputFileWidth}x${outputFileHeight})" `
    )
    [string] $outputFolderPath = Join-Path $inputFileFolderPath $outputFolderName
    [void] (New-Item -ItemType Directory $outputFolderPath)

    # トリミング後の画像の生成
    foreach ($inputFilePath in $inputFilePathList) {
        [string] $inputFileName = Split-Path $inputFilePath -Leaf
        [string] $outputFilePath = Join-Path $outputFolderPath $inputFileName

        # 空白のページはトリミングせずに空白の画像を生成する
        if ($blankPageFileNameSet.Contains($inputFileName)) {
            magick -size ${outputFileWidth}x${outputFileHeight} `
                xc:$BACKGROUND `
                $outputFilePath
        }
        else {
            # 「余白を追加したサイズの白紙の画像」、「トリミング後の画像」を作成し、
            # 前者の上下左右中央に後者の画像を重ねる
            magick `
                `( `
                -size ${outputFileWidth}x${outputFileHeight} `
                xc:$BACKGROUND `
                `) `
                `( `
                `( `
                $inputFilePath `
                -mattecolor $TRIM_COLOR `
                -frame $FRAME_SIZE `
                `) `
                -fuzz $fuzz% `
                -trim `
                -gravity $GRAVITY `
                -background $BACKGROUND `
                -extent ${maxWidth}x${maxHeight} `
                `) `
                -gravity center `
                -geometry +${OFFSET_X}+${OFFSET_Y} `
                -composite `
                -quality $QUALITY `
                $outputFilePath
        }

        $progressBar.PerformStep()
    }

    [string] $outputLogFilePath = Join-Path $outputFolderPath "log.csv"
    $logList | Export-Csv -NoTypeInformation -LiteralPath $outputLogFilePath
}

Remove-Item $tmpFilePath

[void] [System.Windows.Forms.MessageBox]::Show("finished.")

trap {
    [void] [System.Windows.Forms.MessageBox]::Show($_)
}
