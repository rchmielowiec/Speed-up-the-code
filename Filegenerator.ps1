Measure-Command {
    $bigFileName = "plc_log.txt"
    $plcNames = 'PLC_A', 'PLC_B', 'PLC_C', 'PLC_D'
    $errorTypes = @(
        'Sandextrator overload',
        'Conveyor misalignment',
        'Valve stuck',
        'Temperature warning'
    )
    $statusCodes = 'OK', 'WARN', 'ERR'
    $logLines = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $logLinesCount = 50000
    $throttleLimit = 5

    $step = $logLinesCount / $throttleLimit
    $split = [System.Collections.Generic.List[int[]]]::new() 
    for ($i = 0; $i -lt $throttleLimit; $i++) { $start = $i * $step; $stop = $($i * $step) + $step - 1; $split.Add(@($start..$stop)) }
    
    $split | Foreach-Object -ThrottleLimit $throttleLimit -Parallel {
        $numbers = $_
        foreach ($i in $numbers) {
            $logLines = $using:logLines
            $timestamp = (Get-Date).AddSeconds(-$i).ToString("yyyy-MM-dd HH:mm:ss")
            $plc = $using:plcNames | Get-Random
            $operator = Get-Random -Minimum 101 -Maximum 121
            $batch = Get-Random -Minimum 1000 -Maximum 1101
            $status = $using:statusCodes | Get-Random
            $machineTemp = [math]::Round((Get-Random -Minimum 60 -Maximum 110) + (Get-Random), 2)
            $load = Get-Random -Minimum 0 -Maximum 101
 
            if ((Get-Random -Minimum 1 -Maximum 8) -eq 4) {
                $errorType = $using:errorTypes | Get-Random
                if ($errorType -eq 'Sandextrator overload') {
                    $value = (Get-Random -Minimum 1 -Maximum 11)
                    $msg = "ERROR; $timestamp; $plc; $errorType; $value; $status; $operator; $batch; $machineTemp; $load"
                }
                else {
                    $msg = "ERROR; $timestamp; $plc; $errorType; ; $status; $operator; $batch; $machineTemp; $load"

                }
            }
            else {
                $msg = "INFO; $timestamp; $plc; System running normally; ; $status; $operator; $batch; $machineTemp; $load"
            }

            $null = $logLines.TryAdd($msg)
        }
        
    }

    Set-Content -Path $bigFileName -Value $logLines.ToArray()
    Write-Output "PLC log file generated."
}