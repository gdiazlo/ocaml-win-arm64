$data=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'hello-unix.exe'))
$pe=[BitConverter]::ToInt32($data,60); $opt=$pe+24
$size=[BitConverter]::ToUInt32($data,$opt+116+5*8)
# Raw offset determined by diagnose-relocations.ps1.
$raw=1578496; $p=$raw; $last=0
while ($p -lt $raw+$size) {
  $page=[BitConverter]::ToUInt32($data,$p)
  $len=[BitConverter]::ToUInt32($data,$p+4)
  if ($page -lt $last) {
    [BitConverter]::GetBytes([uint32]($p-$raw)).CopyTo($data,$opt+116+5*8)
    [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'diag-trim.exe'),$data)
    "trimmed last block: p=$p page=$page last=$last size=$($p-$raw)"
    break
  }
  $last=$page; $p+=$len
}
