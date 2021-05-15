using module "./SimpleProgressBar.psm1"

$outer = [SimpleProgressBar]::new(3, @{Activity = "outer"; Id = 1 })
for ($i = 0; $i -lt 3; $i++) {

    $inner1 = [SimpleProgressBar]::new(10, @{Activity = "inner1"; ParentId = 1 })
    for ($j = 0; $j -lt 10; $j++) {
        Start-Sleep -Milliseconds 1000
        $inner1.PerformStep()
    }

    $inner2 = [SimpleProgressBar]::new(100, @{Activity = "inner2"; ParentId = 1 })
    for ($j = 0; $j -lt 100; $j++) {
        Start-Sleep -Milliseconds 100
        $inner2.PerformStep()
    }

    $outer.PerformStep()
}
