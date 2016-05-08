TITLE MASM I/O Procedures

; Author: Gabriel Orellana
; Date: 03/13/2016
; Description: Program which displays name and program title on output screen,
; prompts user to enter 10 unsigned decimal integers, reads in numbers as a string,
; converts string to numeric form, validates input, and stores the values in an array.
; The program then displays the integers, their sum, and their average, and finally 
; displays a terminating message.

INCLUDE Irvine32.inc

; Macros for program

;---------------------------------------------------------
; displayString
;
; Displays string parameter OFFSET
; Receives: string offset parameter
; Returns: none
; Preconditions: string offset passed
; Registers Changed: none
;---------------------------------------------------------
displayString	MACRO	stringDisp:REQ
	push	edx ; save edx
	mov		edx, stringDisp 
	call	WriteString
	pop		edx ; restore edx
ENDM

;---------------------------------------------------------
; getString
;
; Displays a prompt, then gets user's keyboard input and
; stores in a memory location passed as reference parameter
; Receives: memory location reference parameter, offset of 
; buffer, and maximum number of characters
; Returns: stores keyboard input in memory parameter 
; Preconditions: parameters passed correctly
; Registers Changed: none
;---------------------------------------------------------
getString	MACRO	prompt:REQ, stringLoc:REQ, stringLength:REQ
	; save registers
	push	edx
	push	ecx
	push	eax
	; display prompt
	mov		edx,  prompt
	call	WriteString
	; get user string
	mov		edx, stringLoc
	mov		ecx, 80
	call	ReadString
	mov		stringLength, eax
	; restore registers
	pop		eax
	pop		ecx
	pop		edx
ENDM



; (insert constant definitions here)
MAXCHAR = 10	; maximum number of characters to fit in DWORD
ASCIICONV = 48		; used to convert char to int
LO = 48	; low end of range for random integers
HI = 57	; high end of range for random integers
ARRAYSIZE = 10 ; size of array holding numbers

.data
; General purpose variables
userNum		BYTE	80 DUP (0)		; holds user number entered as string
numChar		DWORD	0				; holds number of char in user entered string
numArray	DWORD ARRAYSIZE DUP (0)	; array to hold numbers
request		DwORD	?				; number of random numbers to generate entered by user
numOutput	BYTE	12	DUP(0)		; holds string to display user numbers 
counter		DWORD	10				; holds digits in number
sum			DWORD	0				; holds sum of ints
average		DWORD	0				; holds average of ints
;Global string variables

; list titles
unsortTitle	BYTE	"The unsorted random numbers: ", 0
sortedTitle	BYTE	"The sorted random list: ", 0

; string for median output
medOutput	BYTE	"The median is: ", 0
; spaces for displaying output
spaces		BYTE	"   ", 0

; Intros and instructions
intro		BYTE	"Low-level I/O procedures", 0
intro2		BYTE	"Programmed by Gabriel Orellana", 0
instruct1	BYTE	"Please provide 10 unsigned decimal integers.", 0
instruct2	BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0
instruct3	BYTE	"After you have finished inputting the raw numbers I will display", 0
instruct4	BYTE	"a list of the integers, their sum, and their average value.", 0
; prompts
prompt1		BYTE	"Please enter an unsigned integer: ", 0
; fail message
inputFail	BYTE	"ERROR: You did not enter an unsigned number or your number was too big.", 0
; output messages
output1		BYTE	"You entered the following numbers: ", 0
sumOutput	BYTE	"The sum of these numbers is: ", 0
averageOut	BYTE	"The average is: ", 0
; farewell
goodBye		BYTE	"Results certified by Gabriel Orellana", 0
goodBye2	BYTE	"Goodbye ", 0

.code
   main PROC
; seed random number generator
    call	Randomize
; introduction

	; push intro and instruction offsets to stack
	push	OFFSET intro
	push	OFFSET intro2
	push	OFFSET instruct1
	push	OFFSET instruct2
	push	OFFSET instruct3
	push	OFFSET instruct4

	call	introd
	
; get user integers
	push	OFFSET numArray
	push	OFFSET inputFail
	push	OFFSET numChar
	push	OFFSET userNum
	push	OFFSET prompt1
	call	readVal
	call	CrLf

; display user numbers
	push	counter
	push	OFFSET output1
	push	OFFSET numArray
	push	OFFSET numOutput
	call	writeVal
	call	Crlf
	
; calculate sum and average
	push	ARRAYSIZE
	push	OFFSET numArray
	push	OFFSET sum
	push	oFFSET average
	call	sumAndAve

; display sum
	push	1
	push	OFFSET sumOutput
	push	OFFSET sum
	push	OFFSET numOutput
	call	writeVal
	call	Crlf

; display average
	push	1
	push	OFFSET averageOut
	push	OFFSET average
	push	OFFSET numOutput
	call	writeVal
	call	Crlf
	

; farewell
	; push message offsets to stack
	call	CrLf
	push	OFFSET goodBye
	push	OFFSET goodBye2
	call	farewell

   exit
main ENDP


;---------------------------------------------------------
; intro
;
; Displays intro message, prompts for user name and 
; displays personalized greeting.
; Receives: six string parameters by reference on stack
; Returns: none
; Preconditions: variables declared
; Registers Changed: none
;---------------------------------------------------------
introd	PROC
	push	ebp
	mov		ebp, esp

; Display program name and author
	displayString [ebp+28]
	call	CrLf
	displayString [ebp+24]
	call	CrLf
	call	Crlf

	; display instructions
	displayString [ebp+20]
	call	Crlf
	displayString [ebp+16]
	call	Crlf
	displayString [ebp+12]
	call	Crlf
	displayString [ebp+8]
	call	Crlf
	call	Crlf

	pop		ebp
	; remove parameters from stack
	ret		24

introd	ENDP

;---------------------------------------------------------
; readVal
;
; Prompts user to enter unsigned integer, takes in integer 
; as a string, validates input, converts string to int,
; and stores in array until 10 have been stored.
; Receives: reference parameters on stack for prompt and fail
; message strings, array to hold user number as string, 
; parameter to hold number of characters in string, and array
; to hold user numbers converted to integers. 
; Returns: user numbers stored in parameter array as integers
; Preconditions: parameters passed on stack correctly
; Registers Changed: none
;---------------------------------------------------------
readVal PROC 
; set up/save registers
	push	ebp
	mov		ebp, esp
	pushad
	
	; display instructions
	mov		ecx, ARRAYSIZE
	mov		edi, [ebp+24]	; move array to hold user number converted to int

Get:
	; get user string
	getString [ebp+8], [ebp+12], [ebp+16] 
	push	ecx ; save counter for outer loop
	mov		eax, [ebp+16]
	cmp		eax, MAXCHAR
	jg		Fail ; if string has more than 10 char, it is too big

; convert string to int
	mov		esi, [ebp+12]	; move user number array into esi to characters
	mov		ecx, [ebp+16]	; use size of user string as loop counter
	add		esi, ecx
	dec		esi
	mov		ebx, 1			; used to multiply number for place
	
L1:	
	xor		eax, eax		; clear out eax
	std		; start with lsb
	lodsb
	; validate char is an integer
	cmp		al, LO
	jl		Fail
	cmp		al, HI
	jg		Fail

Convert: ; convert char to int
	sub		al, ASCIICONV
	mul		ebx
	jc		Fail	; if number exceeds 32 bit unsigned int, jump to fail
	mov		edx, [edi]
	add		eax, edx
	jc		Fail	; if number exceeds 32 bit unsigned int, jump to fail
	mov		[edi], eax
	mov		eax, ebx
	mov		ebx, 10
	mul		ebx
	mov		ebx, eax
	;mov		eax, [edi]
	
	loop	L1
	;call	WriteDec

	add		edi, 4 ; move edi to address for next user number
	pop		ecx
	loop	Get ; loop to get next user number
	
	jmp		Done

Fail:
	call	Crlf
	displayString [ebp+20]	; display bad input message
	mov		eax, 0
	mov		[edi], eax	; clear values out of current array loc
	pop		ecx	
	call	Crlf
	jmp		Get
	
Done:
	; restore registers
	popad
	pop		ebp

	ret		20	; remove parameter from stack

readVal ENDP

;---------------------------------------------------------
; writeVal
;
; Coverts array of integers into a string one at a time and
; displays them with a message.
; Receives: string reference parameters on stack, offset
; of array of integers from stack, and offset of string
; to hold converted integer. Value parameter for number of
; integers to convert
; Returns: none
; Preconditions: parameters passed correctly
; Registers Changed: none
;---------------------------------------------------------
writeVal	PROC
	; setup and save registers
	push	ebp
	mov		ebp, esp
	pushad

	displayString [ebp+16] ; display output message
	mov		esi, [ebp+12]	; move offset of array of ints into esi
	mov		ecx, [ebp+20]	; number of ints to be converted
ConvertInt:
	push	ecx
	; setup to get digits to user for conversion
	mov		ebx, [esi]
	; check if 0
	cmp		ebx, 0
	mov		ecx, 0
	je		Next1
	mov		eax, 1
	dec		ecx

GetDigits:
	; get number of digits
	cmp		eax, ebx
	jg		Next1
	mov		edx, 10
	mul		edx
	inc		ecx
	jmp		GetDigits


Next1: 
	mov		edi, [ebp+8]	; move offset of output string to edi
	add		edi, ecx		; specify where to add first byte
	;mov		ecx, ARRAYSIZE	; set up loop counter
	mov		ebx, 10	; used to divided to get digits
	xor		eax, eax
	mov		eax, [esi]
	cmp		eax, 0			; check if number is zero
	je		CaseZero
	
Conv:	
	std
	; convert integers to string
	cdq
	div		ebx		; get first digit of number
	cmp		edx, 0
	je		AddZero	; if number is zero it gets treated differently
	push	eax
	mov		eax, edx
	add		eax, ASCIICONV	; convert to ASCII 
	stosb
	pop		eax		; restore remainder
	cmp		eax, 0	; if no quotient, conversion is done
	je		EndConv
	jmp		Conv

Step:
	loop	ConvertInt

CaseZero:	; used if user entered 0
	mov		al, ASCIICONV	; move '0' to al
	stosb
	jmp		EndConv

AddZero:
	cmp		eax, 0			; if no remainder and no quotient, conversion is done
	je		EndConv
	push	eax
	mov		al, ASCIICONV	; move '0' to al
	stosb
	pop		eax
	jmp		Conv
	
EndConv:
	; display number
	displayString [ebp+8]
	mov		eax, 0
	mov		[edi], eax
	mov		[edi+4], eax
	mov		[edi+8], eax
	pop		ecx
	cmp		ecx, 1	; check if last number
	je		EndDisp
	; format output
	mov		al, ','
	call	WriteChar
	mov		al, ' '
	call	WriteChar
	add		esi, 4
	jmp		Step	; used because top of loop is too far away


EndDisp:
	; restore registers
	popad
	pop		ebp
	ret		16

writeVal	ENDP

;---------------------------------------------------------
; sumAndAve
;
; Calculates sum and average of an array of integers. 
; Receives: Reference parameters for array of ints, variable
; to store sum, variable to store average, and number of 
; ints in array by value
; Returns: sum and average stored in parameters
; Preconditions: parameters passed correctly
; Registers Changed: none
;---------------------------------------------------------
sumAndAve PROC

	push	ebp
	mov		ebp, esp
	pushad

	mov		ecx, [ebp+20]	; size of array
	mov		esi, [ebp+16]	; array offset
	mov		eax, 0

	; loop through to get sum
sumLoop:
	add		eax, [esi]
	add		esi, 4
	loop	sumLoop

	; store sum
	mov		ebx, [ebp+12]
	mov		[ebx], eax
	
	; calculate average rounded down to nearest int
	mov		ebx, [ebp+20]
	cdq
	div		ebx
	
	; store average
	mov		ebx, [ebp+8]
	mov		[ebx], eax

	popad
	pop		ebp

	ret		16
sumAndAve ENDP

;---------------------------------------------------------
; farewell
;
; Displays farewell message
; Receives: two string reference parameters on stack
; Returns: none
; Preconditions: parameters passed correctly
; Registers Changed: none
;---------------------------------------------------------
farewell	PROC
	push	ebp
	mov		ebp, esp

	; Display farewell messages
	displayString [ebp+12]
	call	CrLf
	
	displayString [ebp+8]
	call	CrLf
	call	CrLf

	pop		ebp
	; remove parameters from stack
	ret		8

farewell	ENDP


END main
