IDEAL
MODEL small
STACK 256

; ==================================== Макроси ====================================
; ---------------------------------------------------------------------------------
; Призначення: ініціалізація програми
; ---------------------------------------------------------------------------------
MACRO M_init		; Макрос для ініціалізації. Його початок
	mov ax, @data	; @data ідентифікатор, що створюються директивою MODEL
	mov ds, ax		; Завантаження початку сегменту даних в регістр DS
	mov es, ax		; Завантаження початку сегменту даних в регістр ES
	ENDM M_init		; Кінець макросу

; ---------------------------------------------------------------------------------
; Призначення: вихід із програми (із кодом 0)
; ---------------------------------------------------------------------------------
MACRO M_exit
	mov ah, 4ch
	mov al, 0
	int 21h
	ENDM M_exit

; ---------------------------------------------------------------------------------
; Призначення: вихід із програми (із кодом FF)
; ---------------------------------------------------------------------------------
MACRO M_error_exit
	mov ah, 4ch
	mov al, 0FFh
	int 21h
	ENDM M_error_exit

; ---------------------------------------------------------------------------------
; Призначення: запам'ятовування значень регістрів
; ---------------------------------------------------------------------------------
MACRO M_push_all
	push ax
	push bx
	push cx
	push dx
	push bp
	push si
	push di
	
	ENDM M_push_all

; ---------------------------------------------------------------------------------
; Призначення: повернення значень регістрів
; ---------------------------------------------------------------------------------
MACRO M_pop_all
	pop di
	pop si
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ENDM M_pop_all

DATASEG
msg db "Calculator", 10, 13
	db "Type your X", 10, 13
	db "====================", 10, 13
	db "If X > 6, equation will be x^3 - 75", 10, 13
	db "If 1 <= X <= 6, equation will be 35x / (1-x^2)", 10, 13
	db "If X < 1, equation will be x^2", 10, 13
	db "====================", 10, 13
	db "X is allowed only in range from -255 to 40", 10, 13
	db "Division results will be rounded!", 10, 13, "$"
	
x_msg db  10, 13, "Enter your X value: ", "$"

x_str db 5, 0, 0, 0, 0, 0, 0

result_msg db 10, 13, 10, 13, "Result: ", "$"
minus db "-", "$"
result_str db 0, 0, 0, 0, 0

overflow_err db 10, 13, 10, 13, "There is overflow in register!", 10, 13, "$"
wrong_input_err db 10, 13, 10, 13, "Wrong input!", 10, 13, "$"

CODESEG
Start:
	M_init
	; Очистка консоли
	mov al, 2
	mov ah, 0
	int 10h
	; Вступительное сообщение
	mov dx, offset msg
	mov ah, 09h
	int 21h

	; Считывание ввода
	call ask_for_input

	; Парсим X стринг
	mov si, offset x_str+2
	mov bh, [si-1]
	call string2dec		; Результат в АХ

	cmp bp, 1
	je x_is_below_1

	cmp ax, 41
	jb skip

	M_error_exit
	skip:
	cmp ax, 6
	ja x_is_higher_6	; Х > 6

	cmp ax, 1
	JLE x_is_below_1		; X <= 1

	jmp x_is_beetween	; 1 < X <=6

	x_is_higher_6:			; Х > 6
		call calc_x_higher_6		; Вызываем процедуру для подсчета значения
		call print_result	; Вызываем процедуру для вывода результата
		jmp fin

	x_is_below_1:			; X < 1 
		call calc_x_below_1	; Вызываем процедуру для подсчета значения
		call print_result	; Вызываем процедуру для вывода результата
		jmp fin

	x_is_beetween:			; 1 < X <=6
		call calc_x_beetween		; Вызываем процедуру для подсчета значения
		call print_result	; Вызываем процедуру для вывода результата
		jmp fin

	fin:
	M_exit



	; считывание ввода из консоли. Просто упрощение читаемого кода
	proc ask_for_input
		M_push_all

		mov dx, offset x_msg
		mov ah, 09h
		int 21h
		mov dx, offset x_str
		mov ah, 0ah
		int 21h

		M_pop_all
		ret
	endp ask_for_input


	; Выход: AX <- результат,  BL <- 0, если число положительное; 1, если число отрицательное
	proc string2dec
		push cx
		mov ax, 0	; Результат
		mov cx, 0	; Буфер для числа
		mov bp, 0
		Str_parser:
			mov al, [si]	; Считываем чар из стринга

			cmp al, 0dh
			je no_error

			; Проверка на минус
			cmp al, "-"
			jne not_a_minus
			call trim_minus
			jmp Str_parser

			not_a_minus:
			sub al, 30h		; Конвертируем чар в цифру
			
			; Проверяем, цифра ли это
			cmp bl, 0
			jb error
			cmp bl, 9
			ja error

			; Увеличиваем число в зависимости от его разряда
			cmp bh, 3
			je mul_by_100
			cmp bh, 2
			je mul_by_10
			jmp str_continue

			mul_by_100:
			mov dx, 10d
			mul dx
			mul_by_10:
			mov dx, 10d
			mul dx

			str_continue:
			add cx, ax	; Сохраняем число в буфер
			inc si		; Двигаем указатель на следующий чар
			dec bh		; BH == 0 : Конец
			jnz Str_parser	; BH != 0 : Повтор
		mov ax, cx


		cmp ax, 255d
		jna no_error
		
		error:
		mov bx, 1
		call error_manager

		no_error:
		mov ax, cx
		pop cx
		ret
	endp string2dec

		; Предназначение: отрезание минуса в стринге
			; SI <- Указатель на минус в стринге
	proc trim_minus
		push ax
		push bx
		push si
		push cx

		mov bx, 4		; Количство желанных итераций
		trimmer:
			mov ax, [si+1]		; Следующее число
			mov [si], ax		; Пишем его на 1 байт назад
			inc si				; Движемся дальше
			dec bx				; Проверка на конец стринга
			jnz trimmer

		pop cx
		pop si
		pop bx
		pop ax
		dec bh		; Длинна стринга уменьшилась на 1
		mov bp, 1	; Число отрицательное
		ret
	endp trim_minus
	

	; АХ <- результат 
	; BP <- 0, если результат положительный; 1, если результат отрицательный
	proc calc_x_higher_6 
		cmp ax, 4
		JLE x_below_4

		mov cx, ax
		mul cx	; x^2
		mul cx ; x ^ 3
		sub ax, 75
		jmp calc_x_higher_6_end

		
		x_below_4:
		mov cx, ax
		mul ax	; x^2
		mul ax ; x ^ 3
		mov cx, 75
		sub cx, ax
		mov ax, cx
		mov bp, 1 

		calc_x_higher_6_end:
		ret
	endp calc_x_higher_6


	; АХ <- результат подсчета
	; BP <- 0, если результат положительный; 1, если результат отрицательный
	proc calc_x_below_1
		mul ax		; x^2
		mov bp, 0		
		ret
	endp calc_x_below_1

	;АХ <- результат подсчета
	; BP <- 0, если результат положительный; 1, если результат отрицательный
	proc calc_x_beetween
		push ax		; *Stack will remember x*
		mul ax		; x^2

		dec ax  ; x^2 -1

		mov cx, ax ; переносим в делитель
		pop ax;
		mov bx, 35
		mul bx ; 35*x

		call rdiv ; делим с округлением ax/ cx , result -> ax.
		xor bx, bx
		mov bp, 1 ;  число всегда будет отрицательным.
		ret
	endp calc_x_beetween


	; Предназначение: деление с округлением
	; Ввод: АХ <- число, CX <- делитель
	;  Вывод: AX <- результат деления с округлением
	proc rdiv
		push dx

		div cx

		cmp dx, 5
		jnb do_round
		jmp dont_round

		do_round:
		inc ax
		dont_round:

		pop dx
		ret
	endp rdiv


	; Предназначение: вывод числа на консоль с учетом его знака	
	; Ввод: АХ <- число, BP <- 0 if postive, 1 if negative

	proc print_result
		call number2string

		cmp bp, 1
		je PRINT_neg
		jmp PRINT_pos

		PRINT_neg:
			mov ah, 09h
			mov dx, offset result_msg
			int 21h
			mov dx, offset minus
			int 21h
			mov dx, offset result_str
			int 21h
			jmp PRINT_end

		PRINT_pos:
			mov ah, 09h
			mov dx, offset result_msg
			int 21h
			mov dx, offset result_str
			int 21h
			jmp PRINT_end

		PRINT_end:
		ret
	endp print_result


	; Предназначение: Парс десятичного числа в стринг
	; Ввод: AX <- Число для парса
	; Вывод: ---
	proc number2string
		push si
		push bx
		push cx

		mov si, offset result_str	; Ссылка на начало стрина, в который будут писать результат
		mov bx, 10d					; 0 для проверки на последний разряд
		mov cx, 0

		Splitter:
			inc cx
			cmp ax, bx
			xor dx, dx	; Сбрасываем регистр DX, потому что иначе div начинает выкобениваться
			div bx		; Делим АХ на 10
			push dx		; Остаток (последняя цифра числа) записывается в стек. Так мы сможем получать их в правильном порядке потом
			xor dx, dx	; Сбрасываем регистр DX, потому что иначе div начинает выкобениваться
			cmp ax, 0
			jne Splitter
		
		Writer:
			pop dx			; Достаем последний доступный десяток
			add dx, 30h		; Делаем из числа символ цифры
			mov [si], dx	; Заносим цифру в стринг
			inc si
			dec cx
			jnz Writer
		; В конце дописываем доллар, чтобы прерывание для вывода знало, где кончается строка
		mov [si], "$"
		
		pop cx
		pop bx
		pop si
		ret
	endp number2string

	; Предназначение: выбрасывание ошибки про оверфлоу одного из регистров
	proc error_manager
		mov ah, 09h
		cmp bx, 0ffffh	; overflow error
		je overflow_error
		cmp bx, 1		; wrong input error
		je wrong_input_error
		jmp halt

		overflow_error:
			mov dx, offset overflow_err
			int 21h
			jmp halt
		wrong_input_error:
			mov dx, offset wrong_input_err
			int 21h
			jmp halt

		halt:
		M_error_exit
		ret
	endp error_manager


	end Start