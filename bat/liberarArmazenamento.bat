@echo off
setlocal enabledelayedexpansion

:: Resolver problema de acentuação 
chcp 65001 > nul 
:: Configuração
set "MIN_FREE_SPACE_GB=322"
set "CURRENT_DIR=%cd%"
set "EXCLUDE=liberarArmazenamento.bat"  :: Arquivos e padrões a serem ignorados

:CheckSpace
:: Obtém o espaço livre em GB
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
    "(Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=\"C:\"').FreeSpace / 1GB -as [int]"') do set FreeSpace=%%A

echo ===============================================
powershell -Command "Write-Host 'echo Espaço Livre Atual: ' -NoNewline; Write-Host '%FreeSpace% GB' -ForegroundColor Red"
powershell -Command "Write-Host 'Espaço Mínimo Necessário: ' -NoNewline; Write-Host '%MIN_FREE_SPACE_GB% GB' -ForegroundColor Blue"

:: Verifica se o espaço livre já é suficiente
if %FreeSpace% geq %MIN_FREE_SPACE_GB% (
    echo Espaço livre suficiente. Nenhuma ação necessária.
    goto :End
)

set "OldestFile="

:: Encontra o arquivo mais antigo e o apaga
for /f "usebackq delims=" %%F in (`powershell -NoProfile -Command ^
    "$exclude=@('%EXCLUDE:','=','%'); $self='%~nx0'; Get-ChildItem -Path '%CURRENT_DIR%' -Recurse -File | Where-Object {($_.Name -ne $self) -and ($_ -notmatch ($exclude -join '|'))} | Sort-Object CreationTime | Select-Object -First 1 -ExpandProperty FullName"`) do (
    set "OldestFile=%%F"
)

:: Apaga o arquivo mais antigo
if defined OldestFile (
    powershell -Command "Write-Host 'Apagando o arquivo mais antigo: ' -ForegroundColor Red -NoNewline; Write-Host '!OldestFile!' -ForegroundColor White"
    del "!OldestFile!"
    goto :CheckSpace
) else (
    echo Nenhum arquivo encontrado para apagar.
    goto :End
)

:End
powershell -Command "Write-Host 'Processo concluído!' -ForegroundColor Green"
echo ---------x-----------
pause
