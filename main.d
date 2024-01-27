import std.stdio;
import core.sys.windows.windows;
import core.sys.windows.tlhelp32;
import core.stdc.wchar_;
import std.string;
import std.file;

DWORD findProc (LPWSTR name) {
    PROCESSENTRY32 pe32;
    pe32.dwSize = PROCESSENTRY32.sizeof;
    HANDLE snapshot = CreateToolhelp32Snapshot (TH32CS_SNAPPROCESS , 0);
    Process32First(snapshot , &pe32);

    while (Process32Next(snapshot , &pe32) != 0) {
        if (wcscmp(cast(wchar*)pe32.szExeFile , name) == 0) {
            CloseHandle (snapshot);
            return pe32.th32ProcessID;
        }
    }
    CloseHandle (snapshot);
    return -1;
}

void main () {
    writeln(r" 
    __  ___               ______                    
   /  |/  /__  ____ ___  / ____/___  __  ______ ___ 
  / /|_/ / _ \/ __ `__ \/ __/ / __ \/ / / / __ `__ \
 / /  / /  __/ / / / / / /___/ / / / /_/ / / / / / /
/_/  /_/\___/_/ /_/ /_/_____/_/ /_/\__,_/_/ /_/ /_/                          
                        Memory Enumerator in D.                               
");
    LPWSTR procName = cast(LPWSTR)"target.exe"; // This is the process name , change it to whatever you want.
    DWORD pid = findProc(procName);
    if (pid == -1) {
        writeln("Failed to find process.");
        return;
    }
    HANDLE hProc = OpenProcess (PROCESS_ALL_ACCESS , FALSE , pid);
    if (hProc == null) {
        writeln("Failed to get a handle on the process...");
        return;
    }
    writefln("[+] Got Process ID [ %u ]" , pid);
    writeln("[+] Got a Handle to the Process Successfully!");

    MEMORY_BASIC_INFORMATION memInfo;
    PVOID address = null;
    writeln("[ Copied Memory Buffer Regions ]");
    while (VirtualQueryEx (hProc , address , &memInfo , memInfo.sizeof) != 0) {
        PVOID currentAdd = memInfo.BaseAddress;
        PVOID memBuf = HeapAlloc (GetProcessHeap() , HEAP_ZERO_MEMORY , memInfo.RegionSize);
        if (currentAdd) {
            int memRead = ReadProcessMemory(hProc , currentAdd , memBuf , memInfo.RegionSize , NULL);
            if (memRead == 1 && memBuf != null) {
                writefln("[0x%x] --> [0x%x]",currentAdd,memBuf);
            }
        }
        address = cast(PVOID) (cast(ubyte*)memInfo.BaseAddress + memInfo.RegionSize);
    }
    
    writeln("Paused MemEnumerator to Debug...");
    signal(SIGINT , &handleInterrupt);
    getchar();
}