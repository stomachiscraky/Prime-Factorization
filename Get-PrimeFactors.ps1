<#
.SYNOPSIS
素因数分解します。
.DESCRIPTION
素因数分解します。
入力範囲は 1 ～ 18446744073709551615(2^64-1) です。
素因数分解する数値は引数、パイプ入力またはコンソールからの入力です。
* 解法
2 ～ √n までの数値で試し割りしています。
素数だけで割ればよいのですが素数かどうか判別するのは時間がかかるので 2,3,5,7 の２倍以上の倍数を除外しています。
除外する素数は -Level オプションで指定できます。
.EXAMPLE
Get-PrimeFactors 10,'x',36
結果
10 = 2 * 5
36 = 2^2 * 3^2
'x' は数値に変換できないので無視されます。
.EXAMPLE
10,'x',36 | Get-PrimeFactors 
結果
10 = 2 * 5
36 = 2^2 * 3^2
.EXAMPLE
Get-PrimeFactors 
コンソールから数値を入力します。
.EXAMPLE
Get-PrimeFactors 2,4 -Talk
結果
2 は素数です。
4 = 2^2
.EXAMPLE
Get-PrimeFactors 10,36 -MultiplyOnly
結果
10 = 2 * 5
36 = 2 * 2 * 3 * 3
.EXAMPLE
1..10 | Get-PrimeFactors -PrimeOnly
結果
2
3
5
7
.EXAMPLE
(1..100 | Get-PrimeFactors -PrimeOnly).Count
結果
25
1 ～ 100 の範囲の素数の個数を出力します。
.INPUTS
素因数分解する数値をパイプから入力できます。
'UInt64' の範囲を超える数値や数値に変換できないオブジェクトは無視されます。エラーは発生しません。
引数にもパイプからも数値が指定されなければコンソールから数値を入力します。
素因数分解の結果を表示した後、数値の入力を繰り返します。Enter キーの入力のみで終了します。
.OUTPUTS
素因数分解の結果を 'String' またはそのコレクションとして出力します。
#>
param (
#素因数分解する数値です。
#'UInt64' の範囲を超える数値や数値に変換できないオブジェクトは無視されます。エラーは発生しません。
#引数にもパイプからも数値が指定されなければコンソールから数値を入力します。
#素因数分解の結果を表示した後、数値の入力を繰り返します。Enter キーの入力のみで終了します。
[object[]]$Value,

#除外する素数を指定します。
#1: 2 ～ √n までの数値で試し割りします。素数の倍数で除外しません。
#2: 2 ～ √n までの数値で試し割りします。ただし2の2以上の倍数は除きます。
#3: 2 ～ √n までの数値で試し割りします。ただし2,3の2以上の倍数は除きます。
#5: 2 ～ √n までの数値で試し割りします。ただし2,3,5の2以上の倍数は除きます。
#7: 2 ～ √n までの数値で試し割りします。ただし2,3,5,7の2以上の倍数は除きます。
[ValidateSet(1,2,3,5,7)][int]$Level = 7,

#nが素数のとき'n は素数です。'と表示します。
[switch]$Talk,

#素数のみ表示します。
[switch]$PrimeOnly,

#冪表示ではなく乗算記号のみで表示します。
[switch]$MultiplyOnly
)
begin {
function prmfct
{
    param([UInt64]$number)
    $tb5 = @((2),(1),(2),(2),4,2,4,2,4,6,2,6)
    $tb7 = @( 2,1,2,2,4,
        2,4,2,4,6,2,6,4,2,4,6,6,
        2,6,4,2,6,4,6,8,4,2,4,2,
        4,8,6,4,6,2,4,6,2,6,6,4,
        2,4,6,2,6,4,2,4,2,10,2,10 )
    [UInt64]$number_save = $number
    [UInt64]$prime = 0
    [UInt64]$exponent = 0
    $step = 0
    $step_id = 0
    $rs = '' + $number
    $first = $true

    if ($number -eq 0) {if (!$PrimeOnly) {'0 = 0'}; return}
    if ($number -eq 1) {if (!$PrimeOnly) {'1 = 1'}; return}
    $limit = [UInt64]([Math]::Sqrt([double]$number) * 1.001)
    while ($number -ne 1) {
        switch ($Level) {
            7 {
                $prime += $tb7[$step_id++]
                if ($step_id -eq 53) {$step_id = 5}
            }
            5 {
                $prime += $tb5[$step_id++]
                if ($step_id -eq 12) {$step_id = 4}
            }
            3 {
                if ($prime -gt 5) {$step = (6 - $step)}
                else { if($prime -eq 2) {$step = 1}
                       else {$step = 2} }
                $prime += $step
            }
            2{
                if ($prime -eq 2) {$prime++}
                else {$prime += 2}
            }
            default{
                if ($prime -eq 0) {$prime = 2}
                else {$prime++}
            }
        }
        if ($prime -gt $limit) {$prime = $number}
        for ($exponent = 0; $number % $prime -eq 0; $exponent++) {
            $number /= $prime
        }
        if ($exponent -ge 1) {
            if ($prime -eq $number_save) {
                if ($PrimeOnly) {$prime}
                else {
                    if ($Talk) {$rs += ' は素数です。'}
                    else {$rs += ' = ' + $prime}
                }
            }
            else {
                if ($first) {$rs += ' = '}
                else {$rs += ' * '}
                $first = $false
                $rs += $prime
                if ($exponent -gt 1) {
                    if ($MultiplyOnly) {
                        for ($i = 1; $i -le $exponent-1; $i++) {
                            $rs += ' * ' + $prime
                        }
                    }
                    else {$rs += '^' + $exponent}
                }
                $limit = [UInt64]([Math]::Sqrt([double]$number) * 1.001)
            }
        }
    }
    if (!$PrimeOnly) {$rs}
}

    $specified_value = $false
    foreach ($i in $Value) {
        if ([string]$i -eq '') {continue}
        if (($i -as [UInt64]) -ne $null) {
            prmfct $i
            $specified_value = $true
        }
    }
}
process {
    foreach ($i in $_) {
        if ([string]$i -eq '') {continue}
        if (($i -as [UInt64]) -ne $null) {
            prmfct $i
            $specified_value = $true
        }
    }
}
end {
    if (!$specified_value) {
        '素因数分解する数を入力してください。' | Write-host
        'Enter キーのみで終了します。' | Write-host
        while ($true) {
            $number = Read-Host "`n数値"
            if ($number -eq $null -or $number -eq '') {break}
            if (($number -as [UInt64]) -eq $null) {
                ' 0 ～ ' + [UInt64]::MaxValue +
                ' の範囲の数を入力してください。' | Write-host -NoNewline
                continue
            }
            prmfct $number
        }
    }
}
