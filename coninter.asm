			include			D:\masm32\include\masm32rt.inc
			include			D:\masm32\include\winmm.inc
			includelib		D:\masm32\lib\winmm.lib

			.data			
TitleText	db				'Lab8', 0
IFMsg		db				'Enter the name of input file: ', 0
OFMsg		db				'Enter the name of output file: ', 0
EOFMsg		db				'Error opening the file!', 0
ECFMsg		db				'Error creating the file!', 0
ERFMsg		db				'Error reading the file!', 0
EWFMsg		db				'Error writing the file!', 0
EAMMsg		db				'Error allocating the memory!', 0
IDMsg		db				'Enter the delay of processing: ', 0
APSMsg		db				0DH, 0AH, 'The program ended successfully!', 0
APKMsg		db				'Press any key to exit...', 0
SMsg		db				'+', 0
InConsole	dd				?
OutConsole	dd				?
InFile		dd				?
OutFile		dd				?
Buffer		dd				?
FileName	db				255, 0, 255 dup (?)
BytesRead	dd				?
BufSize		dd				128
DelayStr	db				64 dup (0)
DelayInt	dd				?
Timer		dd				?
TimeLeft	dd				1

			.code

HandlerFunc	proc
			dec				dword ptr TimeLeft
			ret				20
HandlerFunc	endp

begin:		call			FreeConsole
			call			AllocConsole
			test			eax, eax
			jz				exitntimer

			invoke			GetStdHandle, STD_INPUT_HANDLE
			mov				InConsole, eax
			invoke			GetStdHandle, STD_OUTPUT_HANDLE
			mov				OutConsole, eax			

			invoke			SetConsoleTitle, offset TitleText			
			test			eax, eax
			jz				exitntimer

open:		invoke			WriteConsole, OutConsole, offset IFMsg, sizeof IFMsg, 0, 0
			invoke			ReadConsole, InConsole, offset FileName, 255, offset BytesRead, 0		;Print the prompt to enter input file name and read the name

			lea				esi, FileName
			add				esi, dword ptr BytesRead
			mov				byte ptr [esi - 2], 0													;filename + cr + lf => filename + 0h

			invoke			CreateFile, offset FileName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
			cmp				eax, INVALID_HANDLE_VALUE
			jne				opened
			invoke			WriteConsole, OutConsole, offset EOFMsg, sizeof EOFMsg, 0, 0
			jmp				open

opened:		mov				dword ptr InFile, eax
			
create:		invoke			WriteConsole, OutConsole, offset OFMsg, sizeof OFMsg, 0, 0
			invoke			ReadConsole, InConsole, offset FileName, 255, offset BytesRead, 0

			lea				esi, FileName
			add				esi, dword ptr BytesRead
			mov				byte ptr [esi - 2], 0

			invoke			CreateFile, offset FileName, GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
			cmp				eax, INVALID_HANDLE_VALUE
			jne				created
			invoke			WriteConsole, OutConsole, offset ECFMsg, sizeof ECFMsg, 0, 0
			jmp				create

created:	mov				dword ptr OutFile, eax

allocate:	invoke			GlobalAlloc, GMEM_FIXED, BufSize
			cmp				eax, 0
			jne				allocated
			invoke			WriteConsole, OutConsole, offset EAMMsg, sizeof EAMMsg, 0, 0
			jmp				exitntimer

allocated:	mov				dword ptr Buffer, eax

enterdelay:	invoke			WriteConsole, OutConsole, offset IDMsg, sizeof IDMsg, 0, 0
			invoke			ReadConsole, InConsole, offset DelayStr, sizeof DelayStr, offset BytesRead, 0
			invoke			atol, offset DelayStr
			cmp				eax, 0
			jle				enterdelay

settimer:	mov				dword ptr DelayInt, eax
			invoke			timeSetEvent, DelayInt, 0, offset HandlerFunc, 0, TIME_PERIODIC
			mov				dword ptr Timer, eax

readfile:	invoke			ReadFile, InFile, Buffer, BufSize, offset BytesRead, 0
			cmp				eax, 0
			jne				readdone
			invoke			WriteConsole, OutConsole, offset ERFMsg, sizeof ERFMsg, 0, 0
			jmp				exittimer

readdone:	cmp				dword ptr BytesRead, 0
			jnz				change
			invoke			WriteConsole, OutConsole, offset APSMsg, sizeof APSMsg, 0, 0
			jmp				exittimer

change:		mov				ecx, dword ptr BytesRead
			mov				esi, dword ptr Buffer

cycle:		cmp				dword ptr TimeLeft, 0
			jg				cycle
			inc				dword ptr TimeLeft

			push			ecx																		;WinAPI stdcall convention states that EAX, ECX and EDX may be used in functions, so the value may be lost
			invoke			WriteConsole, OutConsole, offset SMsg, 1, 0, 0
			pop				ecx

			cmp				byte ptr [esi], 'A'
			jb				skip

			cmp				byte ptr [esi], 'Z'
			ja				skip

			mov				al, 32
			add				al, byte ptr [esi]
			mov				byte ptr [esi], al

skip:		inc				esi
			loop			cycle

writefile:	invoke			WriteFile, OutFile, Buffer, BytesRead, 0, 0
			cmp				eax, 0
			jne				readfile
			invoke			WriteConsole, OutConsole, offset EWFMsg, sizeof EWFMsg, 0, 0

exittimer:	invoke			timeKillEvent, Timer

exitntimer:	invoke			WriteConsole, OutConsole, offset APKMsg, sizeof APKMsg, 0, 0
			invoke			crt__getch
			invoke			CloseHandle, InFile
			invoke			CloseHandle, OutFile
			invoke			CloseHandle, InConsole
			invoke			CloseHandle, OutConsole
			invoke			FreeConsole
			invoke			ExitProcess, 0
			end				begin			