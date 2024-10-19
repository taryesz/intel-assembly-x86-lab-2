.686
.model flat

extern __read : PROC
extern __write : PROC
extern _ExitProcess@4 : PROC

public _main

.data

	polish_small	db 0A5h, 86h, 0A9h, 88h, 0E4h, 0A2h, 98h, 0ABh, 0BEh		; small letters in Latin 2

	polish_big		db 0A4h, 08Fh, 0A8h, 09Dh, 0E3h, 0E0h, 97h, 8Dh, 0BDh		; big letters in Latin 2

	slash_set		db 0

	replacement		db '_','_','_','_'

	user_input		db 85 dup (?)

	user_output		db 85 dup (?)

.code
_main PROC

	comment | REAR USER TEXT: |

	push 85
	push OFFSET user_input
	push 0
	call __read
	add esp, 12

	comment | CONVERT TO BIG LETTERS: |

	mov ecx, eax					; Set the loop counter to the number of symbols the user input (saved in EAX)
	mov esi, 0						; The index used to iterate through the "user_input"
	mov edi, 0						; The index used to iterate through the "user_output"

	convert:

		cmp user_input[esi], 'a'
		jb skip						; Not a letter (or a big letter which has to be ignored) - leave as is

		cmp user_input[esi], 'z'
		ja skip						; Not a letter (or a big letter which has to be ignored) - leave as is

		mov slash_set, 0			; If the letter is found, let the new slashes be detected (set the flag)

		mov al, user_input[esi]		; Get the symbol
		sub al, 20h					; Convert to its bigger version
		mov user_output[edi], al	; Save the converted symbol

		jmp update

	skip:

		cmp user_input[esi], '\'	; Compare the symbol with '\'
		je replace					; If same, jump

		comment | CHECK FOR A POLISH LETTER: |

		mov dl, user_input[esi]		; Get the esi-th symbol from "user_input"

		push ecx					; Save the original loop counter
		push esi					; Save the original index

		mov ecx, (OFFSET polish_big) - (OFFSET polish_small)	; Set the loop counter to the number of Polish symbols
		mov esi, 0												; Set the traverse index to 0

		is_polish:

			cmp dl, polish_small[esi]	; Compare the read symbol with the esi-th Polish letter
			jne continue				; If differs, compare with the next one

			mov dl, polish_big[esi]		; Otherwise, replace with its bigger version
			mov user_output[edi], dl	; Save to the "user_output" 

			mov slash_set, 0			; If the letter is found, let the new slashes be detected (set the flag)
			pop esi						; Revert original values
			pop ecx						;

			jmp update					; Keep iterating through "user_input"

			continue:

				inc esi					; Get the next Polish letter
				loop is_polish			; Repeat

		pop esi						; Revert original values
		pop ecx						;
		
		mov slash_set, 0			; If the letter is found, let the new slashes be detected (set the flag)

		mov al, user_input[esi]		; Get the symbol
		mov user_output[edi], al	; Save the ignored symbol

	update:

		inc esi						; Move to the next symbol
		inc edi
		loop convert				; Repeat ECX-times

		jmp finish

	replace:

		cmp slash_set, '\'			; Add this comparison not to update EBX (keep the original index of the first '\' of the sequence)
		je ignore

		mov ebx, dword PTR replacement
		mov dword PTR user_output[edi], ebx		; Replace '\' with 4 spaces
		add edi, 4								; Update the index

	ignore:

		mov slash_set, '\'			; Set the flag that a slash was already found earlier

		inc esi						; Move to the next symbol

		dec ecx
		jnz convert			

	comment | PRINT THE RESULT: |

	finish:

		push edi						; EDI has the index of the lastly put symbol in "user_output", so by adding 1 we get the new text length of "user_output"
		push OFFSET user_output
		push 1
		call __write
		add esp, 12

		push 0
		call _ExitProcess@4

_main ENDP
END