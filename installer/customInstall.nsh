!macro customInit
    SetAutoClose false
    ${nsProcess::KillProcess} "VersePC.exe" $R0
    Sleep 500
    ${nsProcess::KillProcess} "VersePC.exe" $R0
    Sleep 500
    ${nsProcess::KillProcess} "VersePC.exe" $R0
    Sleep 300

    ; --- VC++ 运行库自动检测与安装 ---
    IfFileExists "$SYSDIR\vcruntime140.dll" _vcpp_found _vcpp_missing
    _vcpp_missing:
        MessageBox MB_YESNO|MB_ICONQUESTION "检测到系统缺少 VC++ 运行库（Microsoft Visual C++ Redistributable）。$\n$\n这是运行 VersePC 的必要组件，是否现在自动安装？" IDYES _vcpp_install IDNO _vcpp_found
    _vcpp_install:
        DetailPrint "正在下载 VC++ 运行库..."
        inetc::get /QUESTION "N" /RESUME "正在下载 VC++ 运行库..." "https://aka.ms/vs/17/release/vc_redist.x64.exe" "$TEMP\vc_redist.x64.exe"
        Pop $0
        StrCmp $0 "OK" _vcpp_download_ok _vcpp_download_fail
    _vcpp_download_fail:
        MessageBox MB_OK|MB_ICONEXCLAMATION "VC++ 运行库下载失败。$\n$\n请手动安装：https://aka.ms/vs/17/release/vc_redist.x64.exe$\n$\n安装将继续，但启动器可能无法正常运行。"
        Goto _vcpp_found
    _vcpp_download_ok:
        DetailPrint "正在安装 VC++ 运行库（静默安装，请稍候）..."
        nsExec::ExecToLog '"$TEMP\vc_redist.x64.exe" /install /quiet /norestart'
        Pop $1
        ${If} $1 != "0"
            MessageBox MB_OK|MB_ICONEXCLAMATION "VC++ 运行库安装未成功（代码 $1）。$\n$\n请手动安装：https://aka.ms/vs/17/release/vc_redist.x64.exe"
        ${Else}
            DetailPrint "VC++ 运行库安装成功"
        ${EndIf}
        Delete "$TEMP\vc_redist.x64.exe"
    _vcpp_found:
!macroend

!macro customUnInit
    SetAutoClose false
    ${nsProcess::KillProcess} "VersePC.exe" $R0
    Sleep 500
    ${nsProcess::KillProcess} "VersePC.exe" $R0
    Sleep 500
!macroend

!macro customInstallMode
    StrCpy $isForceInstall "1"
!macroend
