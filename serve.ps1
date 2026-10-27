# Minimal static file server for local development.
# Serves this folder over http://localhost so pages get a real origin — which is
# what makes localStorage (and therefore auto-save) work. file:// origins don't.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1 -Port 9000
#
# Stop it with:  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
#                 Where-Object { $_.CommandLine -like '*serve.ps1*' } |
#                 ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

param(
  [int]$Port = 8777,
  [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$rootFull = [System.IO.Path]::GetFullPath($Root)

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".htm"  = "text/html; charset=utf-8"
  ".js"   = "text/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".webp" = "image/webp"
  ".gif"  = "image/gif"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
  ".woff2" = "font/woff2"
  ".mp3"  = "audio/mpeg"
  ".ogg"  = "audio/ogg"
  ".wav"  = "audio/wav"
  ".m4a"  = "audio/mp4"
}

$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback), $Port
$listener.Start()
Write-Host "Serving $rootFull at http://localhost:$Port/"

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $stream.ReadTimeout = 5000
    $buf = New-Object byte[] 8192
    $n = $stream.Read($buf, 0, $buf.Length)
    if ($n -le 0) { continue }

    $req = [System.Text.Encoding]::ASCII.GetString($buf, 0, $n)
    $line = ($req -split "`r`n")[0]
    $parts = $line.Split(' ')
    $path = if ($parts.Length -ge 2) { $parts[1] } else { "/" }
    $path = $path.Split('?')[0]
    if ($path -eq "/" -or $path.EndsWith("/")) { $path += "index.html" }

    $rel = $path.TrimStart('/').Replace('/', '\')
    $full = [System.IO.Path]::GetFullPath((Join-Path $rootFull $rel))

    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      $body = [System.Text.Encoding]::UTF8.GetBytes("403")
      $hdr = "HTTP/1.1 403 Forbidden`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
    }
    elseif (Test-Path -LiteralPath $full -PathType Leaf) {
      $body = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      $ct = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
      $total = $body.Length

      # Range support — audio elements seek with byte ranges, and loop cleanly only if this works
      $m = [regex]::Match($req, '(?im)^Range:\s*bytes=(\d*)-(\d*)\s*$')
      if ($m.Success -and $total -gt 0) {
        $start = if ($m.Groups[1].Value) { [int]$m.Groups[1].Value } else { 0 }
        $end   = if ($m.Groups[2].Value) { [int]$m.Groups[2].Value } else { $total - 1 }
        if ($start -ge $total) {
          $body = [System.Text.Encoding]::UTF8.GetBytes("416")
          $hdr = "HTTP/1.1 416 Range Not Satisfiable`r`nContent-Range: bytes */$total`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
        } else {
          $end = [Math]::Min($end, $total - 1)
          $body = $body[$start..$end]
          $hdr = "HTTP/1.1 206 Partial Content`r`nContent-Type: $ct`r`nContent-Range: bytes $start-$end/$total`r`nAccept-Ranges: bytes`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
        }
      }
      else {
        $hdr = "HTTP/1.1 200 OK`r`nContent-Type: $ct`r`nAccept-Ranges: bytes`r`nContent-Length: $total`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
      }
    }
    else {
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 - not found: $path")
      $hdr = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
    }

    $hb = [System.Text.Encoding]::ASCII.GetBytes($hdr)
    $stream.Write($hb, 0, $hb.Length)
    if ($body.Length -gt 0) { $stream.Write($body, 0, $body.Length) }
    $stream.Flush()
  }
  catch {
    # a dropped connection is not interesting
  }
  finally {
    $client.Close()
  }
}
