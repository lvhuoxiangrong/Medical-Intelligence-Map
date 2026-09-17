# ============================================================
# 医智图前端 · 纯 PowerShell 静态文件服务器
# 用途：当电脑上没有可用的 Python 时，用它代替 python -m http.server
# 用法：双击「启动页面.bat」即可，本脚本会被自动调用
# 注意：本文件必须保持 UTF-8 带 BOM 编码（PowerShell 5.1 要求）
# ============================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8000

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".htm"  = "text/html; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".gif"  = "image/gif"
  ".svg"  = "image/svg+xml"
  ".ico"  = "image/x-icon"
  ".md"   = "text/markdown; charset=utf-8"
  ".txt"  = "text/plain; charset=utf-8"
  ".bat"  = "text/plain; charset=utf-8"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
  $listener.Start()
} catch {
  Write-Host ""
  Write-Host "  启动失败：端口 $port 已被占用，或没有权限。" -ForegroundColor Red
  Write-Host "  请关闭其他服务器窗口（如之前启动的黑色窗口）后重试。" -ForegroundColor Yellow
  Write-Host ""
  Read-Host "按回车键退出"
  exit 1
}

Write-Host ""
Write-Host "  医智图前端 · 本地服务器已启动" -ForegroundColor Green
Write-Host "  访问地址：http://localhost:$port/" -ForegroundColor Cyan
Write-Host "  首页：http://localhost:$port/index.html" -ForegroundColor Cyan
Write-Host "  数据浏览：http://localhost:$port/%E6%95%B0%E6%8D%AE%E6%B5%8F%E8%A7%88.html" -ForegroundColor Cyan
Write-Host "  停止方式：关闭本窗口，或按 Ctrl+C" -ForegroundColor Yellow
Write-Host ""

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    try {
      $raw = $ctx.Request.Url.AbsolutePath
      $url = [Uri]::UnescapeDataString($raw)
      if ($url -eq "/") { $url = "/index.html" }
      $rel = $url.TrimStart("/").Replace("/", "\")
      $file = [IO.Path]::GetFullPath((Join-Path $root $rel))
      $rootFull = [IO.Path]::GetFullPath($root)
      # 防目录穿越：只允许访问本文件夹内的文件
      if (-not $file.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) { throw "forbidden" }
      if (Test-Path -LiteralPath $file -PathType Leaf) {
        $bytes = [IO.File]::ReadAllBytes($file)
        $ext = [IO.Path]::GetExtension($file).ToLower()
        if ($mime.ContainsKey($ext)) {
          $ctx.Response.ContentType = $mime[$ext]
        } else {
          $ctx.Response.ContentType = "application/octet-stream"
        }
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
      }
    } catch {
      $ctx.Response.StatusCode = 404
    } finally {
      $ctx.Response.Close()
    }
  } catch {
    # 监听被中断（窗口关闭 / Ctrl+C）时正常退出
    break
  }
}
