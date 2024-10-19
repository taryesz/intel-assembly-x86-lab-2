.686
.model flat

extern _MessageBoxA@16 : PROC
extern _ExitProcess@4 : PROC
extern __read : PROC 

public _main

.data

	temp					db ' '

	information_caption		db 'Result',0

	user_input				db 80 dup (?)	; symbols in Latin 2 -> Windows 1250

	user_output				db 80 dup (?)

	polish_small			db 'a','z','c','n','l','o','e','s','A','Z','C','N','L','O','E','S'					; symbols in Latin 2

	polish_big				db 0B9h,0BFh,0E6h,0F1h,0B3h,0F3h,0EAh,9Ch,0A5h,0AFh,0C6h,0D1h,0A3h,0D3h,0CAh,8Ch,0	; symbols in Windows 1250

.code

_main PROC

	comment | Read user's input: |

	push 80
	push OFFSET user_input
	push 0
	call __read
	add esp, 12

	comment | --- Check symbols: |

	mov ecx, eax		; Set the loop counter to the amount of symbols input by the user
	mov esi, 0			; The index which will be used to traverse the user_input array
	mov edi, 0
	mov al, 0			; The register will be used to store the converted symbol

	convert:
		
		mov al, user_input[esi]			; Get the esi-th symbol from the "user_input" array

		cmp al, '/'						; Compare the symbol with a slash
		jne check						; If it's not a slash, save the symbol as is
		
		comment | --- If the symbol is a slash: |

		cmp temp, '/'					; If the variable holds '/'
		je save							; It means there are several slashes in a row, which means we have to save them

		mov temp, al					; If there is no slash in "temp", and a slash was detected, save it to "temp"

		inc esi							; Move to the next symbol from "user_input"
		
		sub ecx, 1						; Decrement loop counter
		jnz convert						; If there are loops to complete left, parse the next symbol

		jmp finish						; Otherwise, write the result

	check:

		cmp temp, '/'					; If a letter was detected and there is a slash already in "temp"
		je replace						; Replace the "/.." combination with a Polish letter

	save:

		mov user_output[edi], al		; Save the symbol
		inc edi							; Move to the next symbol in "user_output"
		inc esi							; Move to the next symbol in "user_input"

		sub ecx, 1						; Decrement loop counter
		jnz convert						; If there are loops to complete left, parse the next symbol

		jmp finish						; Otherwise, write the result

	replace:

		mov temp, ' '					; Clear the "temp" if a "/.." combination was found

		push ecx						; Save registries
		push esi

		mov esi, 0												; Reset the index
		mov ecx, (OFFSET polish_big) - (OFFSET polish_small)	; Determine the amount of loops

		is_polish:

			cmp al, polish_small[esi]	; Compare the symbol with one of the predefined letters
			jne skip					; If the symbol is not the esi-th predefined symbol, jump

			mov al, polish_big[esi]		; Otherwise, replace it with its correspondent symbol
			pop esi						; Restore registries
			pop ecx
			jmp save					; Save the replaced symbol

			skip:
			
				inc esi					; Move to the next symbol in the predefined letters

				dec ecx					; Decrement loop counter
				jnz is_polish			; If there are loops to complete left, compare with the next predefined symbol

				pop esi					; Otherwise, restore registries
				pop ecx
				jmp save				; Save the symbol as is since it doesn't have a correspondent one

	finish:

		push 40h
		push OFFSET information_caption
		push OFFSET user_output
		push 0
		call _MessageBoxA@16

		comment | Exit the program: |

		push 0
		call _ExitProcess@4			

_main ENDP
  
END