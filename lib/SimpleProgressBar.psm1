class SimpleProgressBar {
    hidden [long] $step
    hidden [long] $maxStep
    hidden [long] $startTime
    hidden [hashtable] $params

    SimpleProgressBar([long] $maxStep) {
        $this.Init($maxStep, @{})
    }

    SimpleProgressBar([long] $maxStep, [hashtable] $params) {
        $this.Init($maxStep, $params)
    }

    hidden [void] Init([long] $maxStep, [hashtable] $params) {
        $this.step = 1
        $this.maxStep = [Math]::Max($maxStep, 1)
        $this.params = $params.Clone()
        $this.startTime = (Get-Date).Ticks

        [hashtable] $initialParams = @{Status = "0 % complete." }
        $this.MergeHashtable($initialParams, $this.params)
        $this.WriteProgress($initialParams)
    }

    [void] PerformStep() {
        $this.WriteProgress($this.params)
        $this.step++
    }

    hidden [void] WriteProgress([hashtable] $params) {
        [hashtable] $baseParams = @{
            Activity = " "
            Status   = $this.GetStatus()
        }
        if ($this.step -ge $this.maxStep) {
            $baseParams.Add("Completed", $true) # 値不要のパラメータは$trueを使う
        }
        $this.MergeHashtable($baseParams, $params)
        Write-Progress @baseParams
    }

    hidden [string] GetStatus() {
        return $this.GetPercentageMessage() + " " + $this.GetTimeLeftMessage()
    }

    hidden [string] GetPercentageMessage() {
        return $this.GetPercentage().ToString() + " % complete."
    }

    hidden [int] GetPercentage() {
        return 100 * $this.step / $this.maxStep
    }

    hidden [string] GetTimeLeftMessage() {
        [TimeSpan] $timeLeft = [TimeSpan]::FromTicks($this.GetTimeLeft())
        return "{0:0} hr {1:00} min {2:00} sec remaining." -f `
            $timeLeft.TotalHours, $timeLeft.Minutes, $timeLeft.Seconds
    }

    hidden [long] GetTimeLeft() {
        # TimeSpan型を直接乗算とするとVSCodeではエラーがでないがPowerShellで実行するとエラーになる
        try {
            return $this.GetElapsedTime() * ($this.maxStep - $this.step) / $this.step
        }
        catch {
            # 堅牢性優先でプログレスバーのエラーは全て無視したいが、とりあえずここだけ無視
            return [long]::MaxValue
        }
    }

    hidden [long] GetElapsedTime() {
        return (Get-Date).Ticks - $this.startTime
    }

    hidden [void] MergeHashtable([hashtable] $base, [hashtable] $new) {
        $new.Keys.ForEach{ $base[$_] = $new[$_] }
    }

    [void] SetParams([hashtable] $params) {
        $this.params = $params.Clone()
    }

    [hashtable] GetParams() {
        return $this.params.Clone()
    }
}
