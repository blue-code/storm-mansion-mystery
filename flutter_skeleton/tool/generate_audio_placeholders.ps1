Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$audioDir = Join-Path $root 'assets\audio'

if (!(Test-Path $audioDir)) {
    New-Item -ItemType Directory -Path $audioDir
}

# 1초 분량의 무음 WAV 파일 생성 함수 ( Kent 스타일의 실무적 플레이스홀더 )
function Generate-SilentWav {
    param([string]$name)
    $filePath = Join-Path $audioDir "$name.wav"
    
    # WAV 헤더 (44.1kHz, 16bit, Mono)
    $header = [byte[]](
        0x52, 0x49, 0x46, 0x46, # "RIFF"
        0x24, 0x00, 0x00, 0x00, # Size (placeholder)
        0x57, 0x41, 0x56, 0x45, # "WAVE"
        0x66, 0x6d, 0x74, 0x20, # "fmt "
        0x10, 0x00, 0x00, 0x00, # Subchunk1Size
        0x01, 0x00,             # AudioFormat (PCM)
        0x01, 0x00,             # NumChannels (Mono)
        0x44, 0xAC, 0x00, 0x00, # SampleRate (44100)
        0x88, 0x58, 0x01, 0x00, # ByteRate
        0x02, 0x00,             # BlockAlign
        0x10, 0x00,             # BitsPerSample
        0x64, 0x61, 0x74, 0x61, # "data"
        0x00, 0x00, 0x00, 0x00  # Subchunk2Size (placeholder)
    )
    
    [System.IO.File]::WriteAllBytes($filePath, $header)
    Write-Host "Generated placeholder audio: $name.wav"
}

$audioFiles = @(
    "clock_ticking_office",
    "mansion_morning_eerie",
    "mansion_morning_last_day",
    "rain_and_storm",
    "suspicious_whispers",
    "heartbeat_fast",
    "knife_swing",
    "door_creak",
    "scream_distant"
)

foreach ($file in $audioFiles) {
    Generate-SilentWav -name $file
}
