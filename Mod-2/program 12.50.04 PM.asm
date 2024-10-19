.686
.model flat

extern _ExitProcess@4 : PROC
extern __write	: PROC
extern __read	: PROC 

public _main

.data

	replacement				db '-','-','-','-'

	number_of_new_symbols	dd 0

	user_input				db 80 dup (?)	

	polish_small			db 0A5h, 86h, 0A9h, 88h, 0E4h, 0A2h, 98h, 0ABh, 0BEh		; small symbols in Latin 2

	polish_big				db 0A4h, 08Fh, 0A8h, 09Dh, 0E3h, 0E0h, 97h, 8Dh, 0BDh		; big symbols in Latin 2

.code

_main PROC

	comment | Read user's input: |

	push 80
	push OFFSET user_input
	push 0
	call __read
	add esp, 12

	comment | --- Check symbols: |

	push eax			; Save the number of symbols read from user
	mov ecx, eax		; Set the loop counter to the amount of symbols input by the user
	mov esi, 0			; The index which will be used to traverse the user_input array
	mov al, 0			; The register will be used to store the converted symbol

	convert:
		
		mov al, user_input[esi]			; Get the esi-th symbol from the "user_input" array

		cmp al, 'a'						; Compare the symbol with 'a'
		jb check_for_a_big_letter		; If the symbol has lower ASCII, it might be a bigger version of a letter

		cmp al, 'z'						; Compare the symbol with 'z'
		ja check_if_polish				; If the symbol has greater ASCII, it might be a Polish letter

		sub al, 20h						; Otherwise, if the symbol is a small letter, replace it with a big one
		jmp save						; Save the big letter 

	check_for_a_big_letter:

		cmp al, 'A'						; Compare the symbol with 'A'
		jb save							; If the symbol has lower ASCII, write it as is (not a letter)

		cmp al, 'Z'						; Compare the symbol with 'Z'
		ja save							; If the symbol has lower ASCII, write it as is (not a letter)

		add al, 20h						; Otherwise, if the symbol is a big letter, replace it with a small one
		jmp save						; Save the small letter

	check_if_polish:

	push ecx							; Save original loop counter
	mov ebx, 0							; Use EBX as an index through the table of Polish symbols

	mov ecx, (OFFSET polish_big) - (OFFSET polish_small)	; New loop counter used to traverse the Polish symbols

	is_polish:

			cmp al, polish_small[ebx]			; If the symbol is not one of the Polish ones
			jne ignore							; Leave it as is

			mov al, polish_big[ebx]				; Save the chosen big Polish letter in Windows 1250 
				
			pop ecx								; Revert original loop counter
			jmp	save							; Manually stop the loop and continue

			ignore:

				inc ebx							; Increment the index which will take the next Polish symbol to compare with
				loop is_polish					; Repeat the process ECX-times

	pop ecx								; Revert original loop counter

	save:

		mov user_input[esi], al			; Place the replaced letter under the esi-th index in "user_input"
		inc esi							; Move to the next byte
		loop convert					; Repeat ECX-times

	comment | 'A' & '2' to '----' replacement: |

	mov esi, 0							; Index used to get esi-th symbol from "user_input"
	pop eax								; Revert the original value of EAX (number of symbols)
	mov ecx, eax						; Number of loops to complete
	dec eax								; Length of the text

	look_for_A:

		cmp user_input[esi], 'a'		; Compare the esi-th symbol with 'a'
		jne skip						; If differs, jump

		comment | 'A' or '2' found: |

		found:

		push ecx						; Save the loop counter (we will use it for the inner loop)
		push eax						; Save the original text length

		mov ecx, eax					; Text lenght - ('A' or '2')'s index - 1 = number of movements of the letters
		sub ecx, esi					; found AFTER ('A' or '2')
		dec ecx							;

		move_symbols_further:

			mov bl, user_input[eax-1]		; Get the last symbol of the text
			mov user_input[eax+2], bl		; Save under new spot

			dec eax							; Move to the previous symbol
			loop move_symbols_further		; Repeat until ('A' or '2') (ECX times)

		mov edx, dword PTR replacement		; Place '----' under ('A' or '2')'s spot
		mov dword PTR user_input[esi], edx	;

		add number_of_new_symbols, 3		; The text length is increased by 3

		pop eax								; Revert original EAX (text length)
		pop ecx								; Revert original ECX (loop counter)

		add eax, number_of_new_symbols		; Update text length
		inc eax								;
				
		add esi, 3							; Move the index by 3 to avoid '---' (In Situ moment)

		skip:

			cmp user_input[esi], '2'		; Compare if the skipped symbol is '2'
			je found						; If so, do the same stuff as if it was an 'A'

			inc esi							; Otherwise, move to the next byte from "user_input"
			loop look_for_A					; Repeat 
		
	finish:

		push eax
		push OFFSET user_input
		push 1
		call __write

		comment | Exit the program: |

		push 0
		call _ExitProcess@4			

_main ENDP
  
END