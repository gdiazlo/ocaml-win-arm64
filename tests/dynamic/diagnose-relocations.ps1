foreach ($name in @('hello.exe', 'hello-unix.exe')) {
  $data = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $name))
  $pe = [BitConverter]::ToInt32($data,60)
  $opt = $pe+24
  $n = [BitConverter]::ToUInt16($data,$pe+6)
  $sh = $opt+[BitConverter]::ToUInt16($data,$pe+20)
  $rva = [BitConverter]::ToUInt32($data,$opt+112+5*8)
  $size = [BitConverter]::ToUInt32($data,$opt+116+5*8)
  $raw = 0
  for ($i=0; $i -lt $n; $i++) {
    $s=$sh+$i*40
    $base=[BitConverter]::ToUInt32($data,$s+12)
    $len=[BitConverter]::ToUInt32($data,$s+16)
    if ($rva -ge $base -and $rva -lt $base+$len) { $raw=[BitConverter]::ToUInt32($data,$s+20)+$rva-$base }
  }
  "${name}: rva=$rva size=$size raw=$raw"
  $p=$raw; $count=0; $unaligned=0; $cross=0; $seen=@{}; $last=0; $dup=0
  while ($p -lt $raw+$size) {
    $page=[BitConverter]::ToUInt32($data,$p)
    $len=[BitConverter]::ToUInt32($data,$p+4)
    if ($len -lt 8 -or $p+$len -gt $raw+$size) { "BAD BLOCK: page=$page len=$len p=$p"; break }
    if ($page -lt $last) { "UNSORTED: page=$page last=$last" }; $last=$page
    if (($page % 4096) -ne 0 -or ($len % 4) -ne 0) { "BAD ALIGN: page=$page len=$len" }
    for ($q=$p+8; $q -lt $p+$len; $q+=2) {
      $entry=[BitConverter]::ToUInt16($data,$q)
      $type=$entry -shr 12
      $ofs=$entry -band 4095
      if ($type -eq 10) {
        $count++
        if ($seen.ContainsKey($page+$ofs)) { $dup++; "DUPLICATE: page=$page ofs=$ofs entryOffset=$q" }; $seen[$page+$ofs]=1
        if (($ofs % 8) -ne 0) { $unaligned++ }
        if ($ofs -gt 4088) { $cross++; "CROSS PAGE: page=$page ofs=$ofs" }
      } elseif ($type -ne 0) { "TYPE: page=$page type=$type ofs=$ofs" }
    }
    $p+=$len
  }
  "duplicates=$dup count=$count unaligned=$unaligned crossing=$cross end=$p expected=$($raw+$size)"
}
