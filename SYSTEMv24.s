# -----------------------------------------------------------------------------
# Rotina de tratamento de exceções e interrupções		v2.4
# Observação: os ecalls originais do RARS têm precedência sobre
# estes definidos aqui
# Os ecalls 1XX usam o BitMap Display e Keyboard Display MMIO Tools
# Usar o RARS16_Custom1	(misa)
# Marcus Vinicius Lamar
# 2024/1
# -----------------------------------------------------------------------------

# Incluir o MACROSv24.s no início do seu programa!!!!

.data
.align 2

# Tabela de caracteres desenhados segundo a fonte 8x8 pixels do ZX-Spectrum
LabelTabChar:
.word 	0x00000000, 0x00000000, 0x10101010, 0x00100010, 0x00002828, 0x00000000, 0x28FE2828, 0x002828FE, 
	0x38503C10, 0x00107814, 0x10686400, 0x00004C2C, 0x28102818, 0x003A4446, 0x00001010, 0x00000000, 
	0x20201008, 0x00081020, 0x08081020, 0x00201008, 0x38549210, 0x00109254, 0xFE101010, 0x00101010, 
	0x00000000, 0x10081818, 0xFE000000, 0x00000000, 0x00000000, 0x18180000, 0x10080402, 0x00804020, 
	0x54444438, 0x00384444, 0x10103010, 0x00381010, 0x08044438, 0x007C2010, 0x18044438, 0x00384404, 
	0x7C482818, 0x001C0808, 0x7840407C, 0x00384404, 0x78404438, 0x00384444, 0x1008047C, 0x00202020, 
	0x38444438, 0x00384444, 0x3C444438, 0x00384404, 0x00181800, 0x00001818, 0x00181800, 0x10081818, 
	0x20100804, 0x00040810, 0x00FE0000, 0x000000FE, 0x04081020, 0x00201008, 0x08044438, 0x00100010, 
	0x545C4438, 0x0038405C, 0x7C444438, 0x00444444, 0x78444478, 0x00784444, 0x40404438, 0x00384440,
	0x44444478, 0x00784444, 0x7840407C, 0x007C4040, 0x7C40407C, 0x00404040, 0x5C404438, 0x00384444, 
	0x7C444444, 0x00444444, 0x10101038, 0x00381010, 0x0808081C, 0x00304848, 0x70484444, 0x00444448, 
	0x20202020, 0x003C2020, 0x92AAC682, 0x00828282, 0x54546444, 0x0044444C, 0x44444438, 0x00384444, 
	0x38242438, 0x00202020, 0x44444438, 0x0C384444, 0x78444478, 0x00444850, 0x38404438, 0x00384404, 
	0x1010107C, 0x00101010, 0x44444444, 0x00384444, 0x28444444, 0x00101028, 0x54828282, 0x00282854, 
	0x10284444, 0x00444428, 0x10284444, 0x00101010, 0x1008047C, 0x007C4020, 0x20202038, 0x00382020, 
	0x10204080, 0x00020408, 0x08080838, 0x00380808, 0x00442810, 0x00000000, 0x00000000, 0xFE000000, 
	0x00000810, 0x00000000, 0x3C043800, 0x003A4444, 0x24382020, 0x00582424, 0x201C0000, 0x001C2020, 
	0x48380808, 0x00344848, 0x44380000, 0x0038407C, 0x70202418, 0x00202020, 0x443A0000, 0x38043C44, 
	0x64584040, 0x00444444, 0x10001000, 0x00101010, 0x10001000, 0x60101010, 0x28242020, 0x00242830, 
	0x08080818, 0x00080808, 0x49B60000, 0x00414149, 0x24580000, 0x00242424, 0x44380000, 0x00384444, 
	0x24580000, 0x20203824, 0x48340000, 0x08083848, 0x302C0000, 0x00202020, 0x201C0000, 0x00380418, 
	0x10381000, 0x00101010, 0x48480000, 0x00344848, 0x44440000, 0x00102844, 0x82820000, 0x0044AA92, 
	0x28440000, 0x00442810, 0x24240000, 0x38041C24, 0x043C0000, 0x003C1008, 0x2010100C, 0x000C1010, 
	0x10101010, 0x00101010, 0x04080830, 0x00300808, 0x92600000, 0x0000000C, 0x243C1818, 0xA55A7E3C, 
	0x99FF5A81, 0x99663CFF, 0x10280000, 0x00000028, 0x10081020, 0x00081020

# Scancode -> ascii
LabelScanCode:
# 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
.byte 	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,    # 00 a 0F.
	0x00, 0x00, 0x00, 0x00, 0x00, 0x71, 0x31, 0x00, 0x00, 0x00, 0x7a, 0x73, 0x61, 0x77, 0x32, 0x00,    # 10 a 1F.
	0x00, 0x63, 0x78, 0x64, 0x65, 0x34, 0x33, 0x00, 0x00, 0x20, 0x76, 0x66, 0x74, 0x72, 0x35, 0x00,    # 20 a 2F; o código 29 representa espaço (0x20).
	0x00, 0x6e, 0x62, 0x68, 0x67, 0x79, 0x36, 0x00, 0x00, 0x00, 0x6d, 0x6a, 0x75, 0x37, 0x38, 0x00,    # 30 a 3F.
	0x00, 0x2c, 0x6b, 0x69, 0x6f, 0x30, 0x39, 0x00, 0x00, 0x2e, 0x2f, 0x6c, 0x3b, 0x70, 0x2d, 0x00,    # 40 a 4F.
	0x00, 0x00, 0x27, 0x00, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x5b, 0x00, 0x5d, 0x00, 0x00,    # 50 a 5F   5A Enter => 0A (= ao Rars)
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x31, 0x00, 0x34, 0x37, 0x00, 0x00, 0x00,    # 60 a 6F   66 Backspace => 08.
	0x30, 0x2e, 0x32, 0x35, 0x36, 0x38, 0x00, 0x00,	0x00, 0x2b, 0x33, 0x2d, 0x2a, 0x39, 0x00, 0x00,    # 70 a 7F.
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00    # 80 a 85.
# Scancode -> ascii (com shift)
LabelScanCodeShift:
.byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x51, 0x21, 0x00, 0x00, 0x00, 0x5a, 0x53, 0x41, 0x57, 0x40, 0x00, 
	0x00, 0x43, 0x58, 0x44, 0x45, 0x24, 0x23, 0x00, 0x00, 0x00, 0x56, 0x46, 0x54, 0x52, 0x25, 0x00, 
	0x00, 0x4e, 0x42, 0x48, 0x47, 0x59, 0x5e, 0x00, 0x00, 0x00, 0x4d, 0x4a, 0x55, 0x26, 0x2a, 0x00, 
	0x00, 0x3c, 0x4b, 0x49, 0x4f, 0x29, 0x28, 0x00, 0x00, 0x3e, 0x3f, 0x4c, 0x3a, 0x50, 0x5f, 0x00, 
	0x00, 0x00, 0x22, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7b, 0x00, 0x7d, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00

.align 2

# Buffer do ReadString, ReadFloat, SDread, etc. 512 caracteres/bytes
TempBuffer:
.space 512

# Tabela de conversao hexa para ascii
TabelaHexASCII:		.string "0123456789ABCDEF  "
NumDesnormP:		.string "+desnorm"
NumDesnormN:		.string "-desnorm"
NumZero:		.string "0.00000000"
NumInfP:		.string "+Infinity"
NumInfN:		.string "-Infinity"
NumNaN:			.string "NaN"

# Tabela de causa de exceções
Cause0: 		.string "Error: 0 Instruction address misaligned "
Cause1: 		.string "Error: 1 Instruction access fault "
Cause2: 		.string "Error: 2 Ilegal Instruction "
Cause4: 		.string "Error: 4 Load address misaligned "
Cause5:			.string "Error: 5 Load access fault "
Cause6: 		.string "Error: 6 Store address misaligned "
Cause7: 		.string "Error: 7 Store access fault "
CauseD:			.string "Error: Unknown "
CauseE:			.string "Error: Ecall "

PC:     		.string "PC: "
Addrs:  		.string "Addrs: "
Instr:  		.string "Instr: "

# -----------------------------------------------------------------------------
# Obs.: a forma 'LABEL: instrução' embora fique feio facilita o debug no Rars, por favor não reformatar!!!
# -----------------------------------------------------------------------------
.text


# --- Devem ser colocadas aqui as identificações das interrupções e exceções ---

	csrwi ucause,1    # Caso ocorra dropdown vai gerar exceção de instrução inválida.

ExceptionHandling:	addi 	sp, sp, -8    # Preserva 2 registradores utilizados para comparar ucause.
	sw 	t0, 0(sp)
	sw 	s10, 4(sp)

	csrr	s10,ucause    # Lê o ucause e salva em s10.
	
	li 	t0, 8
	bne 	t0, s10, errorExceptions    # Não é ecall - nem precisa arrumar a pilha!

	lw 	t0, 0(sp)    # É ecall.
    	lw 	s10, 4(sp)    # Recupera registradores usados.
    	addi 	sp, sp, 8			
	j 	ecallException
	
# -----------------------------------------------------------------------------
# --- Exceções de Erros ---
# -----------------------------------------------------------------------------

errorExceptions: csrr 	s11, utval    # Lê o utval da exceção e salva em s11.
	addi 	a0, zero, 0xc0    # Printa tela de azul.
	addi 	a1, zero, 0
	addi 	a7, zero, 148
	jal 	clsCLS
	
# Instruction address misaligned
End_Cause0:	li 	t0, 0
		bne 	t0, s10, End_Cause1
		la 	a0, Cause0
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal	printString
		j	End_uepc
	
# Instruction access fault
End_Cause1:	li 	t0, 1
		bne 	t0, s10, End_Cause2
		la 	a0, Cause1
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString	
		j	End_uepc
			
# Ilegal Instruction
End_Cause2:	li 	t0, 2
		bne 	t0, s10, End_Cause4
		la 	a0, Cause2
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString
		
		la 	a0, Instr
		j	End_utval
	
# Load address misaligned
End_Cause4:	addi 	t0, zero, 4
		bne	t0, s10, End_Cause5
		la 	a0, Cause4
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal	printString
		
		la 	a0, Addrs
		j	End_utval
		
# Load access fault
End_Cause5:	li 	t0, 5
		bne 	t0, s10, End_Cause6
		la 	a0, Cause5
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString	
		
		la 	a0, Addrs
		j	End_utval
		
# Store address misaligned
End_Cause6:	li 	t0, 6
		bne 	t0, s10, End_Cause7
		la 	a0, Cause6
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString
		
		la 	a0, Addrs
		j	End_utval
	
# Store access fault
End_Cause7:	li 	t0, 7
		bne 	t0, s10, End_CauseD
		la 	a0, Cause7
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString
		
		la 	a0, Addrs
		j	End_utval

# Exception Unknown
End_CauseD: 	la 	a0, CauseD
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString
		
		la 	a0, Addrs


End_utval:	li 	a1, 0
		li 	a2, 24
		li 	a3, 0x000c0ff
		jal	printString
		
		mv 	a0, s11
		li 	a1, 56
		li 	a2, 24
		li 	a3, 0x0000c0ff
		jal 	printHex
	

End_uepc: 	la 	a0, PC    # Imprime o pc em que a exceção ocorreu.
		li 	a1, 0
		li 	a2, 12
		li 	a3, 0x000c0ff
		jal 	printString
		
		csrr 	a0, uepc    # Lê uepc.
		li	a1, 28
		li 	a2, 12
		li 	a3, 0x0000c0ff
		jal 	printHex	
		
		j goToExit    # Encerra execução.



# -----------------------------------------------------------------------------
# --- exceção de ECALL ---
# -----------------------------------------------------------------------------
ecallException:   addi    sp, sp, -264    # Preserva todos os registradores na pilha.
    sw     x1,    0(sp)
    sw     x2,    4(sp)
    sw     x3,    8(sp)
    sw     x4,   12(sp)
    sw     x5,   16(sp)
    sw     x6,   20(sp)
    sw     x7,   24(sp)
    sw     x8,   28(sp)
    sw     x9,   32(sp)
    sw     x10,  36(sp)
    sw     x11,  40(sp)
    sw     x12,  44(sp)
    sw     x13,  48(sp)
    sw     x14,  52(sp)
    sw     x15,  56(sp)
    sw     x16,  60(sp)
    sw     x17,  64(sp)
    sw     x18,  68(sp)
    sw     x19,  72(sp)
    sw     x20,  76(sp)
    sw     x21,  80(sp)
    sw     x22,  84(sp)
    sw     x23,  88(sp)
    sw     x24,  92(sp)
    sw     x25,  96(sp)
    sw     x26, 100(sp)
    sw     x27, 104(sp)
    sw     x28, 108(sp)
    sw     x29, 112(sp)
    sw     x30, 116(sp)
    sw     x31, 120(sp)
    NAOTEM_F(s8,ecallException.pula)
    fsw    f0,  124(sp)
    fsw    f1,  128(sp)
    fsw    f2,  132(sp)
    fsw    f3,  136(sp)
    fsw    f4,  140(sp)
    fsw    f5,  144(sp)
    fsw    f6,  148(sp)
    fsw    f7,  152(sp)
    fsw    f8,  156(sp)
    fsw    f9,  160(sp)
    fsw    f10, 164(sp)
    fsw    f11, 168(sp)
    fsw    f12, 172(sp)
    fsw    f13, 176(sp)
    fsw    f14, 180(sp)
    fsw    f15, 184(sp)
    fsw    f16, 188(sp)
    fsw    f17, 192(sp)
    fsw    f18, 196(sp)
    fsw    f19, 200(sp)
    fsw    f20, 204(sp)
    fsw    f21, 208(sp)
    fsw    f22, 212(sp)
    fsw    f23, 216(sp)
    fsw    f24, 220(sp)
    fsw    f25, 224(sp)
    fsw    f26, 228(sp)
    fsw    f27, 232(sp)
    fsw    f28, 236(sp)
    fsw    f29, 240(sp)
    fsw    f30, 244(sp)
    fsw    f31, 248(sp)
 ecallException.pula:   
    # Zera os valores dos registradores temporários
    add     t0, zero, zero
    add     t1, zero, zero
    add     t2, zero, zero
    add     t3, zero, zero
    add     t4, zero, zero
    add     t5, zero, zero
    add     t6, zero, zero



    # Verifica o número da chamada do sistema
    addi    t0, zero, 10
    beq     t0, a7, goToExit    # Ecall exit.
    addi    t0, zero, 110
    beq     t0, a7, goToExit    # Ecall exit.
    
    addi    t0, zero, 1    # Ecall 1 = print int.
    beq     t0, a7, goToPrintInt
    addi    t0, zero, 101    # Ecall 1 = print int.
    beq     t0, a7, goToPrintInt

    addi    t0, zero, 2    # Ecall 2 = print float.
    beq     t0, a7, goToPrintFloat
    addi    t0, zero, 102    # Ecall 2 = print float.
    beq     t0, a7, goToPrintFloat

    addi    t0, zero, 3    # Ecall 3 = print double.
    beq     t0, a7, goToPrintDouble
    addi    t0, zero, 103    # Ecall 2 = print double.
    beq     t0, a7, goToPrintDouble

    addi    t0, zero, 4    # Ecall 4 = print string.
    beq     t0, a7, goToPrintString
    addi    t0, zero, 104    # Ecall 4 = print string.
    beq     t0, a7, goToPrintString

    addi    t0, zero, 5    # Ecall 5 = read int.
    beq     t0, a7, goToReadInt
    addi    t0, zero, 105    # Ecall 5 = read int.
    beq     t0, a7, goToReadInt

    addi    t0, zero, 6    # Ecall 6 = read float.
    beq     t0, a7, goToReadFloat
    addi    t0, zero, 106    # Ecall 6 = read float.
    beq     t0, a7, goToReadFloat

    addi    t0, zero, 7    # Ecall 7 = read Double.
    beq     t0, a7, goToReadDouble
    addi    t0, zero, 107    # Ecall 7 = read Double.
    beq     t0, a7, goToReadDouble

    addi    t0, zero, 8    # Ecall 8 = read string.
    beq     t0, a7, goToReadString
    addi    t0, zero, 108    # Ecall 8 = read string.
    beq     t0, a7, goToReadString

    addi    t0, zero, 11    # Ecall 11 = print char.
    beq     t0, a7, goToPrintChar
    addi    t0, zero, 111    # Ecall 11 = print char.
    beq     t0, a7, goToPrintChar

    addi    t0, zero, 12    # Ecall 12 = read char.
    beq     t0, a7, goToReadChar
    addi    t0, zero, 112    # Ecall 12 = read char.
    beq     t0, a7, goToReadChar


    addi    t0, zero, 30    # Ecall 30 = time.
    beq     t0, a7, goToTime
    addi    t0, zero, 130    # Ecall 30 = time.
    beq     t0, a7, goToTime
    
    addi    t0, zero, 31    # Ecall 31 = MIDI out.
    beq     t0, a7, goToMidiOut    # Generate tone and return immediately.
    addi    t0, zero, 131    # Ecall 31 = MIDI out.
    beq     t0, a7, goToMidiOut
    
    addi    t0, zero, 32    # Ecall 32 = sleep.
    beq     t0, a7, goToSleep
    addi    t0, zero, 132    # Ecall 32 = sleep.
    beq     t0, a7, goToSleep
    
    addi    t0, zero, 33    # Ecall 33 = MIDI out synchronous.
    beq     t0, a7, goToMidiOutSync    # Generate tone and return upon tone completion.
    addi    t0, zero, 133    # Ecall 33 = MIDI out synchronous.
    beq     t0, a7, goToMidiOutSync
   
    addi    t0, zero, 34    # Ecall 34 = print hex.
    beq     t0, a7, goToPrintHex
    addi    t0, zero, 134    # Ecall 34 = print hex.
    beq     t0, a7, goToPrintHex
   
# Print Bin não implementado ainda
# Trecho desativado, mantido para consulta: addi    t0, zero, 35       	# ecall 35 = print bin
# Trecho desativado, mantido para consulta: beq     t0, a7, goToPrintBin
# Trecho desativado, mantido para consulta: addi    t0, zero, 134		# ecall 35 = print bin
# Trecho desativado, mantido para consulta: beq     t0, a7, goToPrintBin
   
    addi    t0, zero, 36    # Ecall 36 = PrintIntUnsigned.
    beq     t0, a7, goToPrintIntUnsigned
    addi    t0, zero, 136    # Ecall 36 = PrintIntUnsigned.
    beq     t0, a7, goToPrintIntUnsigned
    

    addi    t0, zero, 41    # Ecall 41 = random.
    beq     t0, a7, goToRandom
    addi    t0, zero, 141    # Ecall 41 = random.
    beq     t0, a7, goToRandom

    addi    t0, zero, 42    # Ecall 41 = random.
    beq     t0, a7, goToRandom2
    addi    t0, zero, 142    # Ecall 41 = random.
    beq     t0, a7, goToRandom2


    addi    t0, zero, 47    # Ecall 47 = DrawLine.
    beq     t0, a7, goToBRES
    addi    t0, zero, 147    # Ecall 47 = DrawLine.
    beq     t0, a7, goToBRES    

    addi    t0, zero, 48    # Ecall 48 = CLS.
    beq     t0, a7, goToCLS
    addi    t0, zero, 148    # Ecall 48 = CLS.
    beq     t0, a7, goToCLS




    jal NaoExisteEcall    # Ecall inexistente.

	# End execution
	goToExit:   	DE1(s8,goToExitDE2)    # Se for a DE1 pula.
			li 	a7, 10    # Chama o ecall normal do Rars.
			ecall    # Exit ecall.
	goToExitDE2:	j 	goToExitDE2    # Trava o processador : Não tem sistema operacional!

	goToPrintInt:	jal     printInt    # Chama printInt.
			j       endEcall

	goToPrintString: jal     printString    # Chama printString.
			 j       endEcall

	goToPrintChar:	jal     printChar    # Chama printChar.
			j       endEcall

	goToPrintFloat: NAOTEM_F(s8,NaoExisteEcall)
			jal     printFloat    # Chama printFloat.
			j       endEcall

	goToPrintDouble: NAOTEM_F(s8,NaoExisteEcall)
			jal     printDouble    # Chama printDuble.
			j       endEcall


	goToReadChar:	jal     readChar    # Chama readChar.
			j       endEcall

	goToReadInt:   	jal     readInt    # Chama readInt.
			j       endEcall

	goToReadString:	jal     readString    # Chama readString.
			j       endEcall

	goToReadFloat:	NAOTEM_F(s8,NaoExisteEcall)
			jal     readFloat    # Chama readFloat.
			j       endEcall

	goToReadDouble:	NAOTEM_F(s8,NaoExisteEcall)
			jal     readDouble    # Chama readDouble.
			j       endEcall


	goToPrintHex:	jal     printHex    # Chama printHex.
			j       endEcall

	goToPrintIntUnsigned: 	jal	printIntUnsigned    # Chama Print Unsigned Int.
				j	endEcall  
					
	goToMidiOut:	jal     midiOut    # Chama MIDIout.
			j       endEcall

	goToMidiOutSync: jal     midiOutSync    # Chama MIDIoutSync.
			 j       endEcall

	goToTime:	jal     Time    # Chama time.
			j       endEcall

	goToSleep:	jal     Sleep    # Chama sleep.
			j       endEcall

	goToRandom:	jal     Random    # Chama random.
			j       endEcall

	goToRandom2:	jal     Random2    # Chama random2.
			j       endEcall

	goToCLS:	jal     clsCLS    # Chama CLS.
			j       endEcall

	goToBRES:	jal     BRESENHAM    # Chama BRESENHAM.
			j       endEcall    	
  		    				    		    				    		    		
		

endEcall:  	lw	x1,   0(sp)    # Recupera QUASE todos os registradores na pilha.
		lw	x2,   4(sp)	
		lw	x3,   8(sp)	
		lw	x4,  12(sp)      	
		lw	x5,  16(sp)      	
		lw	x6,  20(sp)	
		lw	x7,  24(sp)
		lw	x8,  28(sp)
		lw	x9,  32(sp)
	# Trecho desativado, mantido para consulta: lw      x10, 36(sp)	# a0 retorno de valor
	# Trecho desativado, mantido para consulta: lw     x11, 40(sp)	# a1 retorno de valor
		lw     x12, 44(sp)
		lw     x13, 48(sp)
		lw     x14, 52(sp)
		lw     x15, 56(sp)
		lw     x16, 60(sp)
		lw     x17, 64(sp)
		lw     x18, 68(sp)
		lw     x19, 72(sp)
		lw     x20, 76(sp)
		lw     x21, 80(sp)
		lw     x22, 84(sp)
		lw     x23, 88(sp)
		lw     x24, 92(sp)
		lw     x25, 96(sp)
		lw     x26, 100(sp)
		lw     x27, 104(sp)
		lw     x28, 108(sp)
		lw     x29, 112(sp)
		lw     x30, 116(sp)
		lw     x31, 120(sp)
		NAOTEM_F(s8,endEcall.pula)
		flw    f0,  124(sp)
		flw    f1,  128(sp)
		flw    f2,  132(sp)
		flw    f3,  136(sp)
		flw    f4,  140(sp)
		flw    f5,  144(sp)
		flw    f6,  148(sp)
		flw    f7,  152(sp)
		flw    f8,  156(sp)
		flw    f9,  160(sp)
	# Trecho desativado, mantido para consulta: flw    f10, 164(sp)		# fa0 retorno de valor
	# Trecho desativado, mantido para consulta: flw    f11, 168(sp)		# fa1 retorno de valor
		flw    f12, 172(sp)
		flw    f13, 176(sp)
		flw    f14, 180(sp)
		flw    f15, 184(sp)
		flw    f16, 188(sp)
		flw    f17, 192(sp)
		flw    f18, 196(sp)
		flw    f19, 200(sp)
		flw    f20, 204(sp)
		flw    f21, 208(sp)
		flw    f22, 212(sp)
		flw    f23, 216(sp)
		flw    f24, 220(sp)
		flw    f25, 224(sp)
		flw    f26, 228(sp)
		flw    f27, 232(sp)
		flw    f28, 236(sp)
		flw    f29, 240(sp)
		flw    f30, 244(sp)
		flw    f31, 248(sp)

endEcall.pula:	addi    sp, sp, 264

		csrr 	tp, uepc    # Lê o valor de EPC salvo no registrador uepc (reg 65)
		addi 	tp, tp, 4    # Soma 4 para obter a instrução seguinte ao ecall.
		csrw 	tp, uepc    # Coloca no registrador uepc.
		uret    # Retorna PC=uepc.


# -----------------------------------------------------------------------------
# não Existe Ecall
# Para o caso de ecalls de fp mas ISA RV32I e RV32IM
# -----------------------------------------------------------------------------

NaoExisteEcall: addi 	a0, zero, 0xc0    # Printa tela de azul.
		addi 	a1, zero, 0
		mv 	a6, a7
		addi 	a7, zero, 148
		jal 	clsCLS
  		la 	a0, CauseE
		li 	a1, 0
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printString
		mv 	a0, a6
		li 	a1, 104
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printInt
		csrr	a0,uepc
		li 	a1, 136
		li 	a2, 1
		li 	a3, 0x0000c0ff
		jal 	printHex		
		j 	goToExit

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# PrintInt
# a0    =    valor inteiro
# a1    =    x
# a2    =    y
# a3    =    cor
# -----------------------------------------------------------------------------

printInt:	addi 	sp, sp, -4    # Reserva espaço na pilha.
		sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		la 	t0, TempBuffer    # Carrega o endereço do Buffer da String.
		
		bge 	a0, zero, ehposprintInt    # Se é positvo.
		li 	t1, '-'    # Carrega o sinal -.
		sb 	t1, 0(t0)    # Coloca no buffer.
		addi 	t0, t0, 1    # Incrementa endereço do buffer.
		sub 	a0, zero, a0    # Torna o número positivo.
		
ehposprintInt:  li 	t2, 10    # Carrega número 10.
		li 	t1, 0    # Carrega número de digitos com 0.
		
loop1printInt:	TEM_M(s8,printInt.pula1)
		DIV10(t4,a0)
		REM10(t3,a0)
		j 	printInt.pula1d
printInt.pula1:	div 	t4, a0, t2    # Divide por 10 (quociente)
		rem 	t3, a0, t2    # Resto.
printInt.pula1d:addi 	sp, sp, -4    # Reserva espaço na pilha na pilha.
		sw 	t3, 0(sp)    # Coloca resto na pilha.
		mv 	a0, t4    # Atualiza o número com o quociente.
		addi 	t1, t1, 1    # Incrementa o contador de digitos.
		bne 	a0, zero, loop1printInt    # Verifica se o número é zero.
				
loop2printInt:	lw 	t2, 0(sp)    # Lê digito da pilha.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
		addi 	t2, t2, 48    # Converte o digito para ascii.
		sb 	t2, 0(t0)    # Coloca caractere no buffer.
		addi 	t0, t0, 1    # Incrementa endereço do buffer.
		addi 	t1, t1, -1    # Decrementa contador de digitos.
		bne 	t1, zero, loop2printInt    # É o último?
		sb 	zero, 0(t0)    # Insere \NULL na string.
		
		la 	a0, TempBuffer    # Endereço do buffer da srting.
		jal 	printString    # Chama o print string.
				
		lw 	ra, 0(sp)    # Recupera a.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
fimprintInt:	ret    # Retorna.
		


# -----------------------------------------------------------------------------
# PrintHex
# a0    =    valor inteiro
# a1    =    x
# a2    =    y
# a3    =    cor
# -----------------------------------------------------------------------------

printHex:	addi    sp, sp, -4    # Reserva espaço na pilha.
    		sw      ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		mv 	t0, a0    # Inteiro de 32 bits a ser impresso em Hexa.
		la 	t1, TabelaHexASCII    # Endereço da tabela HEX->ASCII.
		la 	t2, TempBuffer    # Onde a string será montada.

		li 	t3,'0'    # Caractere '0'.
		sb 	t3,0(t2)    # Escreve '0' no Buffer da String.
		li 	t3,'x'    # Caractere 'x'.
		sb 	t3,1(t2)    # Escreve 'x' no Buffer da String.
		addi 	t2,t2,2    # Novo endereço inicial da string.

		li 	t3, 28    # Contador de nibble   início = 28.
loopprintHex:	blt 	t3, zero, fimloopprintHex    # Terminou? t3<0?
		srl 	t4, t0, t3    # Desloca o nibble para direita.
		andi 	t4, t4, 0x000F    # Mascara o nibble.
		add 	t4, t1, t4    # Endereço do ascii do nibble.
		lb 	t4, 0(t4)    # Lê ascii do nibble.
		sb 	t4, 0(t2)    # Armazena o ascii do nibble no buffer da string.
		addi 	t2, t2, 1    # Incrementa o endereço do buffer.
		addi 	t3, t3, -4    # Decrementa o número do nibble.
		j 	loopprintHex
		
fimloopprintHex: sb 	zero,0(t2)    # Grava \null na string.
		la 	a0, TempBuffer    # Argumento do print String.
    		jal	printString    # Chama o print string.
    			
		lw 	ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
fimprintHex:	ret    # Retorna.


# -----------------------------------------------------------------------------
# PrintSring
# a0    =  endereço da string
# a1    =  x
# a2    =  y
# a3    =  cor
# -----------------------------------------------------------------------------

printString:	addi	sp, sp, -8    # Reserva espaço na pilha.
    		sw	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
    		sw	s0, 4(sp)    # Preserva s0.
    		mv	s0, a0    # S0 = endereço do caractere na string.

loopprintString:lb	a0, 0(s0)    # Lê em a0 o caracter a ser impresso.

    		beq     a0, zero, fimloopprintString    # String ASCIIZ termina com NULL.

    		jal     printChar    # Imprime char.
    		
		addi    a1, a1, 8    # Incrementa a coluna.
		li 	t6, 313		
		blt	a1, t6, NaoPulaLinha    # Se ainda tiver lugar na linha.
    		addi    a2, a2, 8    # Incrementa a linha.
    		mv    	a1, zero    # Volta a coluna zero.

NaoPulaLinha:	addi    s0, s0, 1    # Próximo caractere.
    		j       loopprintString    # Volta ao loop.

fimloopprintString:	lw      ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
			lw 	s0, 0(sp)    # Recupera s0 original.
    			addi    sp, sp, 8    # Libera o espaço reservado na pilha.
fimprintString:	ret    # Retorna.


# -----------------------------------------------------------------------------
# PrintChar
# a0 = char(ASCII)
# a1 = x
# a2 = y
# a3 = cores (0x0000bbff) 	b = fundo, f = frente
# a4 = frame (0 ou 1)
# -----------------------------------------------------------------------------
# t0 = i
# t1 = j
# t2 = endereço do char na memória
# t3 = metade do char (2a e depois 1a)
# t4 = endereço para impressao
# t5 = background color
# t6 = foreground color
# -----------------------------------------------------------------------------
# t9 foi convertido para s9 pois não ha registradores temporários sobrando dentro desta função


printChar:	li 	t4, 0xFF    # T4 temporário.
		slli 	t4, t4, 8    # T4 = 0x0000FF00 (no RARS, não podemos fazer diretamente "andi rd, rs1, 0xFF00")
		and    	t5, a3, t4    # T5 obtem cor de fundo.
    		srli	t5, t5, 8    # Número da cor de fundo.
		andi   	t6, a3, 0xFF    # T6 obtem cor de frente.

		li 	tp, ' '
		blt 	a0, tp, printChar.NAOIMPRIMIVEL    # Ascii menor que 32 não é imprimivel.
		li 	tp, '~'
		bgt	a0, tp, printChar.NAOIMPRIMIVEL    # Ascii Maior que 126  não é imprimivel.
    		j       printChar.IMPRIMIVEL
    
printChar.NAOIMPRIMIVEL: li      a0, 32    # a0 recebe o caractere de espaço usado como substituto.

printChar.IMPRIMIVEL:	li	tp, NUMCOLUNAS    # Num colunas 320.
			TEM_M(s8,printChar.mul1)
			MULTIPLY(t4,tp,a2)
			j printChar.mul1d
printChar.mul1:		mul     t4, tp, a2    # Multiplica a2x320  t4 = coordenada y.
printChar.mul1d:	add     t4, t4, a1    # T4 = 320*y + x.
			addi    t4, t4, 7    # T4 = 320*y + (x+7)
			li      tp, VGAADDRESSINI0    # Endereço de início da memória VGA0.
			beq 	a4, zero, printChar.PULAFRAME    # Verifica qual o frame a ser usado em a4.
			li      tp, VGAADDRESSINI1    # Endereço de início da memória VGA1.
printChar.PULAFRAME:	add     t4, t4, tp    # T4 = endereço de impressao do último pixel da primeira linha do char.
			addi    t2, a0, -32    # Indice do char na memória.
			slli    t2, t2, 3    # Offset em bytes em relacao ao endereço inicial.
			la      t3, LabelTabChar    # Endereço dos caracteres na memória.
			add     t2, t2, t3    # Endereço do caractere na memória.
			lw      t3, 0(t2)    # Carrega a primeira word do char.
			li 	t0, 4    # I=4.

printChar.forChar1I:	beq     t0, zero, printChar.endForChar1I    # If(i == 0) end for i.
    			addi    t1, zero, 8    # Trecho desativado, mantido para consulta: j = 8.

printChar.forChar1J:	beq     t1, zero, printChar.endForChar1J    # If(j == 0) end for j.
        		andi    s9, t3, 0x001    # Primeiro bit do caracter.
        		srli    t3, t3, 1    # Retira o primeiro bit.
        		beq     s9, zero, printChar.printCharPixelbg1    # Pixel é fundo?
        		sb      t6, 0(t4)    # Imprime pixel com cor de frente.
        		j       printChar.endCharPixel1
printChar.printCharPixelbg1:	sb      t5, 0(t4)    # Imprime pixel com cor de fundo.
printChar.endCharPixel1: addi    t1, t1, -1    # Trecho desativado, mantido para consulta: j--.
    			addi    t4, t4, -1    # T4 aponta um pixel para a esquerda.
    			j       printChar.forChar1J    # Vollta novo pixel.

printChar.endForChar1J: addi    t0, t0, -1    # I--.
    			addi    t4, t4, 328    # 2**12 + 8.
    			j       printChar.forChar1I    # Volta ao loop.

printChar.endForChar1I:	lw      t3, 4(t2)    # Carrega a segunda word do char.
			li 	t0, 4    # I = 4.
printChar.forChar2I:    beq     t0, zero, printChar.endForChar2I    # If(i == 0) end for i.
    			addi    t1, zero, 8    # Trecho desativado, mantido para consulta: j = 8.

printChar.forChar2J:	beq	t1, zero, printChar.endForChar2J    # If(j == 0) end for j.
        		andi    s9, t3, 0x001    # Pixel a ser impresso.
        		srli    t3, t3, 1    # Desloca para o próximo.
        		beq     s9, zero, printChar.printCharPixelbg2    # Pixel é fundo?
        		sb      t6, 0(t4)    # Imprime cor frente.
        		j       printChar.endCharPixel2    # Volta ao loop.

printChar.printCharPixelbg2:	sb      t5, 0(t4)    # Imprime cor de fundo.

printChar.endCharPixel2:	addi    t1, t1, -1    # Trecho desativado, mantido para consulta: j--.
    				addi    t4, t4, -1    # T4 aponta um pixel para a esquerda.
    				j       printChar.forChar2J

printChar.endForChar2J:	addi	t0, t0, -1    # I--.
    			addi    t4, t4, 328    # Separador visual.
    			j       printChar.forChar2I    # Volta ao loop.

printChar.endForChar2I:	ret    # Retorna.


# -----------------------------------------------------------------------------
# ReadChar
# a0 = valor ascii da tecla
# 2017/2
# -----------------------------------------------------------------------------

readChar: 		nop
# DE1(s8,readCharDE2)   # é necessario mesmo???

# Tratamento para uso com o Keyboard Display MMIO Tool do Rars
readCharKDMMIO:		li 	t0, KDMMIO_Ctrl    # Execução com Polling do KD MMIO.

loopReadCharKDMMIO:  	lw     	a0, 0(t0)    # Lê o bit de flag do teclado.
			andi 	a0, a0, 0x0001    # Mascara bit 0.
			beqz    a0, loopReadCharKDMMIO    # Testa se uma tecla foi pressionada.
   			lw 	a0, 4(t0)    # Lê o ascii da tecla pressionada.
			j fimreadChar    # Fim Read Char.

										
# Tratamento para uso com o teclado PS2 da DE2 usando Buffer0 teclado
# muda a0, t0,t1,t2,t3 e s0
# --- Cuidar: ao entrar s0 já deve conter o endereço la s0,LabelScanCode ---
readCharDE2:  	li      t0, Buffer0Teclado    # Endereço buffer0.
    		lw     	t1, 0(t0)    # Conteudo inicial do buffer.
	
loopReadChar:  	lw     	t2, 0(t0)    # Lê buffer teclado.
		bne     t2, t1, buffermodificadoChar    # Testa se o buffer foi modificado.

atualizaBufferChar:  mv t1, t2    # Atualiza o buffer com o novo valor.
    		j       loopReadChar    # Loop de principal de leitura.

buffermodificadoChar:	li t5, 0xFF
	slli 	t5, t5, 8    # T5 = 0x0000FF00.
	and    	t3, t2, t5    # Mascara o 2o scancode.
	li 	tp, 0x0000F000
	beq     t3, tp, teclasoltaChar    # É 0xF0 no 2o scancode? tecla foi solta.
	li	tp, 0x000000FF
	and	t3, t2, tp    # Mascara 1o scancode	(essa podemos fazer diretamente)
	li	tp, 0x00000012
    	bne 	t3, tp, atualizaBufferChar    # Não é o SHIFT que esta pressionado ? volta a ler.
	la      s0, LabelScanCodeShift    # Se for SHIFT que esta pressionado atualiza o endereço da tabel.
    	j       atualizaBufferChar    # Volta a ler.

teclasoltaChar:		andi t3, t2, 0x00FF    # Mascara o 1o scancode.
	li	tp, 0x00000080
  	bgt	t3, tp, atualizaBufferChar    # Se o scancode for > 0x80 entao não é imprimivel!
  	li	tp, 0x00000012
	bne 	t3, tp, naoehshiftChar    # Não foi o shift que foi solto? entao processa.
	la 	s0, LabelScanCode    # Shift foi solto atualiza o endereço da tabela.
	j 	atualizaBufferChar    # Volta a ler.
	
naoehshiftChar:	   	add     t3, s0, t3    # Endereço na tabela de scancode da tecla com ou sem shift.
    	lb      a0, 0(t3)    # Lê o ascii do caracter para a0.
    	beq     a0, zero, atualizaBufferChar    # Se for caractere não imprimivel volta a ler.
    	
fimreadChar: 	ret    # Retorna.
	
# -----------------------------------------------------------------------------
# ReadString
# a0 = end início
# a1 = tam Max String
# a2 = end do último caractere
# a3 = num de caracteres digitados
# 2018/1     2019/2
# -----------------------------------------------------------------------------
# muda a2, a3, s2 e s0

readString: 	addi 	sp, sp, -8    # Reserva espaco na pilha.
		sw 	s0, 4(sp)    # Preserva s0.
		sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		li 	a3, 0    # Zera o contador de caracteres digitados.
		mv 	s2, a0    # Preserva o endereço inicial.
    		la      s0, LabelScanCode    # Endereço da tabela de scancode inicial para readChar.
    		
loopreadString: beq 	a1, a3, fimreadString    # Buffer cheio fim.
	
		addi 	sp, sp, -8
		sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		sw 	a0, 4(sp)    # Preserva a0 pois ele será reescrito em readChar.
		jal 	readChar    # Lê um caracter do teclado (retorno em a0)
		mv 	t6, a0    # T6 é a letra lida em readChar.
		lw 	ra, 0(sp)
		lw 	a0, 4(sp)
		addi 	sp, sp, 8

		li 	tp, 0x08			
		bne	t6, tp, PulaBackSpace    # Se não for BACKSPACE.
		beq	zero, a3, loopreadString    # Se não tem nenhum caractere no buffer apenas volta a ler.
		addi	a3, a3, -1    # Diminui contador.
		addi 	a0, a0, -1    # Diminui endereço do buffer.
		sb 	zero, 0(a0)    # Coloca zero no caractere anterior.
		j loopreadString
		
PulaBackSpace:	li	tp, 0x0A
		beq 	t6, tp, fimreadString    # Se for tecla ENTER fim.
		sb 	t6, 0(a0)    # Grava no buffer.
		addi 	a3, a3, 1    # Incrementa contador.
		addi 	a0, a0, 1    # Incrementa endereço no buffer.
		j loopreadString    # Volta a ler outro caractere.
	
fimreadString: 	sb 	zero, 0(a0)    # Grava NULL no buffer.
		addi 	a2, a0, -1    # Para que a2 tenha o endereço do último caractere digitado.
		mv	a0, s2    # A0 volta a ter o endereço inicial da string.
		lw 	ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
		lw	s0, 4(sp)    # Recupera s0.
		addi 	sp, sp, 8    # Libera o espaço reservado na pilha.
		ret    # Retorna.
	
	
# -----------------------------------------------------------------------------
# ReadInt
# a0 = valor do inteiro
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

readInt: 	addi 	sp,sp,-4    # Reserva espaco na pilha.
	sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
	la 	a0, TempBuffer    # Endereço do buffer de string.
	li 	a1, 10    # Número máximo de digitos.
	jal 	readString    # Lê uma string de até 10 digitos, a3 número de digitos.
	mv 	t0, a2    # Copia endereço do último digito.
	li 	t2, 10    # Dez.
	li 	t3, 1    # Dezenas, centenas, etc.
	mv 	a0, zero    # Zera o número.
	
loopReadInt: 	beq	a3,zero, fimReadInt    # Leu todos os digitos.
	lb 	t1, (t0)    # Lê um digito.
	li	tp, 0x0000002D
	beq 	t1, tp, ehnegReadInt    # = '-'.
	li	tp, 0x0000002B
	beq 	t1, tp, ehposReadInt    # = '+'.
	li	tp, 0x00000030
	blt 	t1, tp, naoehReadInt    # <'0'.
	li	tp, 0x00000039
	bgt 	t1, tp, naoehReadInt    # >'9'.
	addi 	t1, t1, -48    # Transforma ascii em número.
	TEM_M(s8,readInt.mul1)
	MULTIPLY(t1,t1,t3)
	j readInt.mul1d
readInt.mul1: 	mul 	t1, t1, t3    # Multiplica por dezenas/centenas.
readInt.mul1d:	add 	a0, a0, t1    # Soma no número.
	TEM_M(s8,readInt.mul2)
	MULTIPLY(t3,t3,t2)
	j readInt.mul2d
readInt.mul2: 	mul 	t3, t3, t2    # Proxima dezena/centena.
readInt.mul2d:	addi 	t0, t0, -1    # Busca o digito anterior.
	addi	a3, a3, -1    # Reduz o contador de digitos.
	j 	loopReadInt    # Volta para buscar próximo digito.

naoehReadInt:    # Trecho desativado, mantido para consulta: j instructionException		# gera erro "instrução invalida".
		j fimReadInt    # Como não esta implmentado apenas retorna.

ehnegReadInt:	sub a0,zero,a0    # Se for negativo.

ehposReadInt:    # Se for positivo só retorna.

fimReadInt:	lw 	ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
		ret    # Fim ReadInt.


# -----------------------------------------------------------------------------
# MidiOut 31 (2015/1)
# a0 = pitch (0-127)
# a1 = duration in milliseconds
# a2 = instrument (0-15)
# a3 = volume (0-127)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Note Data           = 32 bits     |   1'b - Melody   |   4'b - Instrument   |   7'b - Volume   |   7'b - Pitch   |   1'b - End   |   1'b - Repeat   |   11'b - Duration   |
# -----------------------------------------------------------------------------
# Note Data (ecall) = 32 bits     |   1'b - Melody   |   4'b - Instrument   |   7'b - Volume   |   7'b - Pitch   |   13'b - Duration   |
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
midiOut:
	DE1(s8,midiOutDE2)
	
	li a7,31    # Chama o ecall normal.
	ecall
	j fimmidiOut

midiOutDE2:	li      t0, NoteData
    		add     t1, zero, zero

    		# Melody = 0

    		# Definição do Instrumento
   	 	andi    t2, a2, 0x0000000F
    		slli    t2, t2, 27
    		or      t1, t1, t2

    		# Definição do Volume
    		andi    t2, a3, 0x0000007F
    		slli    t2, t2, 20
    		or      t1, t1, t2

    		# Definição do Pitch
    		andi    t2, a0, 0x0000007F
    		slli    t2, t2, 13
    		or      t1, t1, t2

    		# Definição da duração
		li 	t4, 0x1FF
		slli 	t4, t4, 4
		addi 	t4, t4, 0x00F    # T4 = 0x00001FFF.
    		and    	t2, a1, t4
    		or      t1, t1, t2

    		# Guarda a definição da duração da nota na Word 1
    		j       SintMidOut

SintMidOut:	sw	t1, 0(t0)

	    		# Verifica a subida do clock AUD_DACLRCK para o sintetizador receber as definicoes
	    		li      t2, NoteClock
Check_AUD_DACLRCK:     	lw      t3, 0(t2)
    			beq     t3, zero, Check_AUD_DACLRCK

fimmidiOut:    		ret

# -----------------------------------------------------------------------------
# MidiOut 33 (2015/1)
# a0 = pitch (0-127)
# a1 = duration in milliseconds
# a2 = instrument (0-127)
# a3 = volume (0-127)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Note Data             = 32 bits     |   1'b - Melody   |   4'b - Instrument   |   7'b - Volume   |   7'b - Pitch   |   1'b - End   |   1'b - Repeat   |   8'b - Duration   |
# -----------------------------------------------------------------------------
# Note Data (ecall)   	= 32 bits     |   1'b - Melody   |   4'b - Instrument   |   7'b - Volume   |   7'b - Pitch   |   13'b - Duration   |
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
midiOutSync:
	DE1(s8,midiOutSyncDE2)
	
	li a7,33    # Chama o ecall normal.
	ecall
	j fimmidiOutSync
	
midiOutSyncDE2:	li      t0, NoteData
    		add     t1, zero, zero

    		# Melody = 1
    		lui    	t1, 0x08000
		slli	t1,t1,4
		
    		# Definição do Instrumento
    		andi    t2, a2, 0x00F
    		slli    t2, t2, 27
    		or      t1, t1, t2

    		# Definição do Volume
    		andi    t2, a3, 0x07F
    		slli    t2, t2, 20
    		or      t1, t1, t2

    		# Definição do Pitch
    		andi    t2, a0, 0x07F
    		slli    t2, t2, 13
    		or      t1, t1, t2

    		# Definição da duração
		li 	t4, 0x1FF
		slli 	t4, t4, 4
		addi 	t4, t4, 0x00F    # T4 = 0x00001FFF.
    		and    	t2, a1, t4
    		or      t1, t1, t2

    		# Guarda a definição da duração da nota na Word 1
    		j       SintMidOutSync

SintMidOutSync:	sw	t1, 0(t0)

    		# Verifica a subida do clock AUD_DACLRCK para o sintetizador receber as definicoes
    		li      t2, NoteClock
    		li      t4, NoteMelody

Check_AUD_DACLRCKSync:	lw      t3, 0(t2)
    			beq     t3, zero, Check_AUD_DACLRCKSync

Melody:     	lw      t5, 0(t4)
    		bne     t5, zero, Melody

fimmidiOutSync:	ret


# -----------------------------------------------------------------------------
# printFloat
# imprime Float em fa0
# na posição (a1,a2)	cor a3
# -----------------------------------------------------------------------------
# muda s0, s1

printFloat:	addi 	sp, sp, -4
		sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		la 	s0, TempBuffer

		# Encontra o sinal do número e coloca no Buffer
		li 	t0, '+'    # Define sinal '+'.
		fmv.x.s s1, fa0    # Recupera o número float sem conversao.
		srli	s1, s1, 31    # Bit 31(sinal) em bit 0, número é negativo s1=1.
		beq 	s1, zero, ehposprintFloat    # É positivo s1=0.
		li 	t0, '-'    # Define sinal '-'.
ehposprintFloat: sb 	t0, 0(s0)    # Coloca sinal no buffer.
		addi 	s0, s0, 1    # Incrementa o endereço do buffer.

		# Encontra o expoente em t0
		 fmv.x.s t0, fa0    # Recupera o número float sem conversao.
		 lui	t1, 0x7F800
		 and 	t0, t0, t1    # Mascara com 0111 1111 1000 0000 0000 0000...
		 slli 	t0, t0, 1    # Tira o sinal do número.
		 srli 	t0, t0, 24    # Recupera o expoente.

		# Encontra a fracao em t1
		fmv.x.s t1, fa0    # Recupera o número float sem conversao.
		li 	t2, 0x007FFFFF    # T2 = 0x007FFFFF.
		and 	t1, t1, t2    # Mascara com 0000 0000 0111 1111 1111...
			 
		beq 	t0, zero, ehExp0printFloat    # Expoente = 0.
		li	tp, 0x000000FF    # TP = 255.
		beq 	t0, tp, ehExp255printFloat    # Expoente = 255.
		
		# É um número float normal  t0 é o expoente e t1 é a fracao!
		# Encontra o E tal que 10^E <= x <10^(E+1)
		fabs.s 		ft0, fa0    # Ft0 recebe o modulo  de x.
		li		tp, 1
		fcvt.s.w 	ft1, tp    # Ft1 recebe o número 1.0.
		li		tp, 10
		fcvt.s.w 	ft6, tp    # Ft6 recebe o número 10.0.
		li		tp, 2
		fcvt.s.w 	ft8, tp
		fdiv.s		ft7, ft1, ft8    # Ft7 recebe o número 0.5.
		
		flt.s 	t4, ft0, ft1    # Ft0 < 1.0 ? Se sim, E deve ser negativo.
		bnez	t4, menor1printFloat    # Se a comparação deu true (1), pula.
		fmv.s 	ft2, ft6    # Ft2  fator de multiplicação = 10.
		j 	cont2printFloat    # Vai para expoente positivo.
menor1printFloat: fdiv.s ft2,ft1,ft6    # Ft2 fator multiplicativo = 0.1.

			# Calcula o expoente negativo de 10
cont1printFloat: 	fmv.s 	ft4, ft0    # Inicia com o número x.
		 	fmv.s 	ft3, ft1    # Contador comeca em 1.
loop1printFloat: 	fdiv.s 	ft4, ft4, ft2    # Divide o número pelo fator multiplicativo.
		 	fle.s 	t3, ft4, ft1    # O número é > que 1? entao fim.
		 	beq 	t3,zero, fimloop1printFloat
		 	fadd.s 	ft3, ft3, ft1    # Incrementa o contador.
		 	j 	loop1printFloat    # Volta ao loop.
		 	
fimloop1printFloat: 	fdiv.s 	ft4, ft4, ft2    # Ajusta o número.
		 	j 	intprintFloat    # Vai para imprimir a parte inteira.

			# Calcula o expoente positivo de 10
cont2printFloat:	fmv.s 	 ft4, ft0    # Inicia com o número x.
		 	fcvt.s.w ft3, zero    # Contador comeca em 0.
loop2printFloat:  	flt.s 	 t3, ft4, ft6    # Resultado é < que 10? entao fim.
			fdiv.s 	 ft4, ft4, ft2    # Divide o número pelo fator multiplicativo.
			bne 	 t3, zero, intprintFloat
		 	fadd.s 	 ft3, ft3, ft1    # Incrementa o contador.
		 	j 	 loop2printFloat

		# Neste ponto tem-se em t4 se ft0<1, em ft3 o expoente de 10 e ft0 0 modulo do número e s1 o sinal
		# e em ft4 um número entre 1 e 10 que multiplicado por Ef3 deve voltar ao número
		
	  		# Imprime parte inteira (o sinal já esta no buffer)
intprintFloat:		fmul.s 		ft4, ft4, ft2    # Ajusta o número.
			fsub.s		ft4, ft4, ft7    # Tira 0.5, dessa forma sempre ao converter estaremos fazendo floor.
		  	fcvt.w.s	t0, ft4    # Coloca floor de ft4 em t0.
			fadd.s		ft4, ft4, ft7    # Readiciona 0.5.
			bnez		t0, pulaeh1print    # Para corrigir multiplos inteiros de 10!
			li 		t0, 1
pulaeh1print:		addi 		t0, t0, 48    # Converte para ascii.
			sb 		t0, 0(s0)    # Coloca no buffer.
		  	addi 		s0, s0, 1    # Incrementta o buffer.
		  
		  	# Imprime parte fracionaria
		  	li 	t0, '.'    # Carrega o '.'.
		  	sb 	t0, 0(s0)    # Coloca no buffer.
		  	addi 	s0, s0, 1    # Incrementa o buffer.
		  
		  	# Ft4 contem a mantissa com 1 casa não decimal
		  	li 		t1, 8    # Contador de digitos  -  8 casas decimais.
loopfracprintFloat:  	beq 		t1, zero, fimfracprintFloat    # Fim dos digitos?
			fsub.s		ft4, ft4, ft7    # Tira 0.5.
			fcvt.w.s 	t5, ft4    # Floor de ft4.
			fadd.s		ft4, ft4, ft7    # Readiciona 0.5.
			fcvt.s.w	ft5, t5    # Reconverte em float só com a parte inteira.
		  	fsub.s 		ft5, ft4, ft5    # Parte fracionaria.
		  	fmul.s 		ft5, ft5, ft6    # Mult x 10.
			fsub.s		ft5, ft5, ft7    # Tira 0.5.
			fcvt.w.s	t0, ft5    # Coloca floor de ft5 em 10.
		  	addi 		t0, t0, 48    # Converte para ascii.
		  	
			li 		tp, 48
			blt		t0, tp, pulaprtFloat1    # Testa se é menor que '0'.
			li		tp, 57
			ble		t0, tp, pulaprtFloat2    # Testa se é menor ou igual que '9'.
pulaprtFloat1:		li		t0, 48    # Define como '0'.
		  	
pulaprtFloat2:	  	sb 		t0, 0(s0)    # Coloca no buffer.
		  	addi 		s0, s0, 1    # Incrementa endereço.
		  	addi 		t1, t1, -1    # Decrementa contador.
			fadd.s		ft5, ft5, ft7    # Reincrementa 0.5.
		  	fmv.s 		ft4, ft5    # Coloca o número em ft4.
		  	j 		loopfracprintFloat    # Volta ao loop.
		  
		  	# Imprime 'E'
fimfracprintFloat: 	li 	t0,'E'    # Carrega 'E'.
			sb 	t0, 0(s0)    # Coloca no buffer.
			addi 	s0, s0, 1    # Incrementa endereço.
			
		  	# Imprime sinal do expoente
		  	li 	t0, '+'    # Carrega '+'.
		  	beqz 	t4, expposprintFloat    # Não é negativo?
		  	li 	t0, '-'    # Carrega '-'.
expposprintFloat: 	sb 	t0, 0(s0)    # Coloca no buffer.
		  	addi 	s0, s0, 1    # Incrementa endereço.
				    
		  	# Imprimeo expoente com 2 digitos (máximo E+38)
			li 	t1, 10    # Carrega 10.
			fcvt.w.s  tp, ft3    # Passa ft3 para t0.
			div 	t0, tp, t1    # Divide por 10 (dezena)
			rem	t2, tp, t1    # T0 = quociente, t2 = resto.
			addi 	t0, t0, 48    # Converte para ascii.
			sb 	t0, 0(s0)    # Coloca no buffer.
			addi 	t2, t2, 48    # Converte para ascii.
			sb 	t2, 1(s0)    # Coloca no buffer.
			sb 	zero, 2(s0)    # Insere \NULL da string.
			la 	a0, TempBuffer    # Endereço do Buffer.
	  		j 	fimprintFloat    # Imprime a string.
								
ehExp0printFloat: 	beq 	t1, zero, eh0printFloat    # Verifica se é zero.
		
ehDesnormprintFloat: 	la 	a0, NumDesnormP    # String número desnormalizado positivo.
			beq 	s1, zero, fimprintFloat    # O sinal é 1? entao é negativo.
		 	la 	a0, NumDesnormN    # String número desnormalizado negativo.
			j 	fimprintFloat    # Imprime a string.

eh0printFloat:		la 	a0, NumZero    # String do zero.
			j 	fimprintFloat    # Imprime a string.
		 		 		 		 
ehExp255printFloat: 	beq 	t1, zero, ehInfprintFloat    # Se mantissa é zero entao é Infinito.

ehNaNprintfFloat:	la 	a0, NumNaN    # String do NaN.
			j 	fimprintFloat    # Imprime string.

ehInfprintFloat:	la 	a0, NumInfP    # String do infinito positivo.
			beq 	s1, zero, fimprintFloat    # O sinal é 1? entao é negativo.
			la 	a0, NumInfN    # String do infinito negativo.
								# Imprime string
		
fimprintFloat:		jal 	printString    # Imprime a string em a0.
			lw 	ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
			addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
			ret    # Retorna.

# -----------------------------------------------------------------------------
# printDouble
# imprime Double em fa0
# na posição (a1,a2)	cor a3
# -----------------------------------------------------------------------------
# muda s0, s1

printDouble: 






fimprintDouble:

			ret


# -----------------------------------------------------------------------------
# readDouble
# fa0 = Double digitado
# 2017/2
# -----------------------------------------------------------------------------

readDouble: 






fimreadDouble:

			ret




# -----------------------------------------------------------------------------
# readFloat
# fa0 = float digitado
# 2017/2
# -----------------------------------------------------------------------------

readFloat: addi sp, sp, -4    # Reserva espaço na pilha.
	sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
	la 	a0, TempBuffer    # Endereço do FloatBuffer.
	li 	a1, 32    # Número máximo de caracteres.
	jal	readString    # Lê string, retorna a2 último endereço e a3 número de caracteres.
	mv 	s0, a2    # Último endereço da string (antes do \0)
	mv 	s1, a3    # Número de caracteres digitados.
	la	s7, TempBuffer    # Endereço do primeiro caractere.
	
lePrimeiroreadFloat:	mv 	t0, s7    # Endereço de início.
	lb 	t1, 0(t0)    # Lê primeiro caractere.
	li	tp, 'e'    # TP = 101 = 'e'.
	beq 	t1, tp, insere0AreadFloat    # Insere '0' antes.
	li 	tp, 'E'    # TP = 69 = 'E'.
	beq 	t1, tp, insere0AreadFloat    # Insere '0' antes.
	li	tp, '.'    # TP = 46 = '.'.
	beq 	t1, tp, insere0AreadFloat    # Insere '0' antes.
	li	tp, '+'    # TP = 43 = '+'.
	beq 	t1, tp, pulaPrimreadChar    # Pula o primeiro caractere.
	li	tp, '-'    # TP = 45 = '-'.
	beq 	t1, tp, pulaPrimreadChar
	j leUltimoreadFloat

pulaPrimreadChar: addi s7,s7,1    # Incrementa o endereço inicial.
		  j lePrimeiroreadFloat    # Volta a testar o novo primeiro caractere.
		  
insere0AreadFloat: mv t0, s0    # Endereço do último caractere.
		   addi s0, s0, 1    # Desloca o último endereço para o próximo.
	   	   addi s1, s1, 1    # Incrementa o num. caracteres.
	   	   sb 	zero, 1(s0)    # \NULL do final de string.
	   	   mv t5, s7    # Primeiro caractere.
insere0Aloop:	   beq 	t0, t5, saiinsere0AreadFloat    # Chegou no início entao fim.
		   lb 	t1, 0(t0)    # Lê caractere.
		   sb 	t1, 1(t0)    # Escreve no próximo.
		   addi t0, t0, -1    # Decrementa endereço.
		   j insere0Aloop    # Volta ao loop.
saiinsere0AreadFloat: li t1, '0'    # Ascii '0'.
		   sb t1, 0(t0)    # Escreve '0' no primeiro caractere.

leUltimoreadFloat: lb  	t1, 0(s0)    # Lê último caractere.
		li	tp, 'e'    # TP = 101 = 'e'.
		beq 	t1, tp, insere0PreadFloat    # Insere '0' depois.
		li 	tp, 'E'    # TP = 69 = 'E'.
		beq 	t1, tp, insere0PreadFloat    # Insere '0' depois.
		li	tp, '.'    # TP = 46 = '.'.
		beq 	t1, tp, insere0PreadFloat    # Insere '0' depois.
		j 	inicioreadFloat
	
insere0PreadFloat: addi	s0, s0, 1    # Desloca o último endereço para o próximo.
	   	   addi	s1, s1, 1    # Incrementa o num. caracteres.
		   li 	t1,'0'    # Ascii '0'.
		   sb 	t1,0(s0)    # Escreve '0' no último.
		   sb 	zero,1(s0)    # \null do final de string.

inicioreadFloat:  fcvt.s.w 	fa0, zero    # Fa0 Resultado inicialmente zero.
		li 	t0, 10    # Inteiro 10.
		fcvt.s.w 	ft6, t0    # Ft6 contem sempre o número cte 10.0000.
		li 	t0, 1    # Inteiro 1.
		fcvt.s.w 	ft1, t0    # Ft1 contem sempre o número cte 1.0000.
	
# Verifica se tem 'e' ou 'E' na string  resultado em s3
procuraEreadFloat:	addi 	s3, s0, 1    # Inicialmente não tem 'e' ou 'E' na string (fora da string)
			mv 	t0, s7    # Endereço inicial.
loopEreadFloat: 	beq 	t0, s0, naotemEreadFloat    # Sai se não encontrou 'e'.
			lb 	t1, 0(t0)    # Lê o caractere.
			li	tp, 'e'    # TP = 101 = 'e'.
			beq 	t1, tp, ehEreadFloat    # Tem 'e'.
			li 	tp, 'E'    # TP = 69 = 'E'.
			beq	t1, tp, ehEreadFloat    # Tem 'E'.
			addi 	t0, t0, 1    # Incrementa endereço.
			j 	loopEreadFloat    # Volta ao loop.
ehEreadFloat: 		mv 	s3, t0    # Endereço do 'e' ou 'E' na string.
naotemEreadFloat:    # Não tem 'e' ou 'E' s3 é o endereço do \0 da string.

# Verifica se tem '.' na string resultado em s2 espera-se que não exista ponto no expoente
procuraPontoreadFloat:	mv 	s2, s3    # Local inicial do ponto na string (='e' se existir) ou fora da string.
			mv 	t0, s7    # Endereço inicial.
loopPontoreadFloat: 	beq 	t0, s0, naotemPontoreadFloat    # Sai se não encontrou '.'.
			lb 	t1, 0(t0)    # Lê o caractere.
			li	tp, '.'    # TP = 46 = '.'.
			beq 	t1, tp, ehPontoreadFloat    # Tem '.'.
			addi 	t0, t0, 1    # Incrementa endereço.
			j 	loopPontoreadFloat    # Volta ao loop.
ehPontoreadFloat: 	mv 	s2, t0    # Endereço do '.' na string.
naotemPontoreadFloat:    # Não tem '.' s2 = local do 'e' ou \0 da string.

# Encontra a parte inteira em fa0
intreadFloat:		fcvt.s.w 	ft2, zero    # Zera parte inteira.
			addi 	t0, s2, -1    # Endereço do caractere antes do ponto.
			fmv.s 	ft3, ft1    # Ft3 contem unidade/dezenas/centenas.
			mv 	t5, s7    # Primeiro endereço.
loopintreadFloat: 	blt 	t0, t5, fimintreadFloat    # Sai se o endereço for < início da string.
			lb 	t1, 0(t0)    # Lê o caracter.
			li	tp, '0'    # TP = 48 = '0'.
			blt 	t1, tp, erroreadFloat    # Não é caractere valido para número.
			li	tp, '9'    # TP = 57 = '9'.
			bgt 	t1, tp, erroreadFloat    # Não é caractere valido para número.
			addi 	t1, t1, -48    # Converte ascii para decimal.
			fcvt.s.w  ft2, t1    # Digito lido em float.

			fmul.s 	ft2,ft2,ft3    # Multiplica por un/dezena/centena.
			fadd.s 	fa0,fa0,ft2    # Soma no resultado.
			fmul.s 	ft3,ft3,ft6    # Proxima dezena/centena.

			addi 	t0,t0,-1    # Endereço anterior.
			j 	loopintreadFloat    # Volta ao loop.
fimintreadFloat:

# Encontra a parte fracionaria  já em fa0
fracreadFloat:		fcvt.s.w 	ft2, zero    # Zera parte fracionaria.
			addi 	t0, s2, 1    # Endereço depois do ponto.
			fdiv.s 	ft3, ft1, ft6    # Ft3 inicial 0.1.
	
loopfracreadFloat: 	bge 	t0, s3, fimfracreadFloat    # Endereço é 'e' 'E' ou >último.
			lb 	t1, 0(t0)    # Lê o caracter.
			li	tp, '0'    # TP = 48 = '0'.
			blt 	t1, tp, erroreadFloat    # Não é valido.
			li	tp, '9'    # TP = 57 = '9'.
			bgt 	t1, tp, erroreadFloat    # Não é valido.
			addi 	t1, t1, -48    # Converte ascii para decimal.
			fcvt.s.w 	ft2, t1    # Digito lido em float.

			fmul.s 	ft2, ft2, ft3    # Multiplica por ezena/centena.
			fadd.s 	fa0, fa0, ft2    # Soma no resultado.
			fdiv.s 	ft3, ft3, ft6    # Proxima frac un/dezena/centena.
	
			addi 	t0, t0, 1    # Próximo endereço.
			j 	loopfracreadFloat    # Volta ao loop.
fimfracreadFloat:

# Encontra a potencia em ft2

potreadFloat:		fcvt.s.w 	ft2, zero    # Zera potencia.
			addi 	t0, s3, 1    # Endereço seguinte ao 'e'.
			li 	s4, 0    # Sinal do expoente positivo.
			lb 	t1, 0(t0)    # Lê o caractere seguinte ao 'e'.
			li	tp, '-'    # TP = 45 = '-'.
			beq	t1, tp, potsinalnegreadFloat    # Sinal do expoente esta escrito e é positivo.
			li	tp, '+'    # TP = 43 = '+'.
			beq 	t1, tp, potsinalposreadFloat    # Sinal do expoente é negativo.
			j 	pulapotsinalreadFloat    # Não esta escrito o sinal do expoente.
potsinalnegreadFloat:	li 	s4, 1    # S4=1 expoente negativo.
potsinalposreadFloat:	addi 	t0, t0, 1    # Se tiver '-' ou '+' avanca para o próximo endereço.
pulapotsinalreadFloat:	mv 	s5, t0    # Neste ponto s5 contem o endereço do primeiro digito da pot e s4 o sinal do expoente.

			fmv.s 	ft3, ft1    # Ft3 un/dez/cen = 1.
	
# Encontra o expoente inteiro em t2
expreadFloat:		li 	t2, 0    # Zera expoente.
			mv 	t0, s0    # Endereço do último caractere da string.
			li 	t3, 10    # Número dez.
			li 	t4, 1    # Und/dez/cent.
				
loopexpreadFloat:	blt 	t0, s5, fimexpreadFloat    # Ainda não é o endereço do primeiro digito?
			lb 	t1, 0(t0)    # Lê o caracter.
			addi 	t1, t1, -48    # Converte ascii para decimal.
			mul 	t1, t1, t4    # Mul digito.
			add 	t2, t2, t1    # Soma ao exp.
			mul 	t4, t4, t3    # Proxima casa decimal.
			addi 	t0, t0, -1    # Endereço anterior.
			j loopexpreadFloat    # Volta ao loop.
fimexpreadFloat:
																																																								
# Calcula o número em ft2 o número 10^exp
			fmv.s 	ft2, ft1    # Número 10^exp  inicial=1.
			fmv.s 	ft3, ft6    # Se o sinal for + ft3 é 10.
			li	tp, 0x00000000    # TP = ZERO.
			beq 	s4, tp, sinalexpPosreadFloat    # Se sinal exp positivo.
			fdiv.s 	ft3, ft1, ft6    # Se o final for - ft3 é 0.1.
sinalexpPosreadFloat:	li 	t0, 0    # Contador.
sinalexpreadFloat: 	beq 	t0, t2, fimsinalexpreadFloat    # Se chegou ao fim.
			fmul.s 	ft2, ft2, ft3    # Multiplica pelo fator 10 ou 0.1.
			addi 	t0, t0, 1    # Incrementa o contador.
			j 	sinalexpreadFloat
fimsinalexpreadFloat:

		fmul.s 	fa0, fa0, ft2    # Multiplicação final!
	
		la 	t0, TempBuffer    # Ajuste final do sinal do número.
		lb 	t1, 0(t0)    # Lê primeiro caractere.
		li	tp, '-'    # TP = 45 = '-'.
		bne 	t1, tp, fimreadFloat    # Não é '-' entao fim.
		fneg.s 	fa0, fa0    # Nega o número float.

erroreadFloat:		
fimreadFloat: 	lw 	ra, 0(sp)    # Recupera ra antes de voltar ao chamador.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
		ret    # Retorna.


# -----------------------------------------------------------------------------
# Time
# a0    =    TimeLOW
# a1    =    TimeHIGH
# -----------------------------------------------------------------------------
Time:  	DE1(s8,Time.DE1)
	li 	a7, 30    # Chama o ecall do Rars.
	ecall
	ret    # Saida.
	
Time.DE1:	csrr a0, time    # Lê time LOW.
		csrr a1, timeh    # Lê time HIGH.
		ret


# -----------------------------------------------------------------------------
# Sleep
# a0    =    Tempo em ms
# -----------------------------------------------------------------------------
Sleep:  DE1(s8,Sleep.DE1)
	li 	a7, 32    # Chama o ecall do Rars.
	ecall
	ret    # Saida.

Sleep.DE1:	csrr 	t0, time    # Lê o tempo do sistema.
		add 	t1, t0, a0    # Soma com o tempo solicitado.
Sleep.Loop:	csrr	t0, time    # Lê o tempo do sistema.
		bltu	t0, t1, Sleep.Loop    # T0<t1 ?
		ret


# -----------------------------------------------------------------------------
# Random         41
# a0    =    número randomico
# -----------------------------------------------------------------------------

Random:	 DE1(s8,Random.DE1)
	li 	a7,41    # Chama o ecall do Rars.
	ecall	
	ret    # Saida.
	
Random.DE1: 	li 	t0, LFSR    # Carrega endereço do LFSR.
		lw 	a0, 0(t0)    # Lê a word em a0.
		ret    # Retorna.


# -----------------------------------------------------------------------------
# Random 42
# -----------------------------------------------------------------------------
# a1    =    Valor máximo
# output a0 = número randomico
# -----------------------------------------------------------------------------

Random2:	DE1(s8,Random2.DE1)
		li 	a7,42    # Chama o ecall do Rars.
		ecall	
		ret    # Saida.
	
Random2.DE1: 	li 	t0, LFSR    # Carrega endereço do LFSR.
		lw 	a0, 0(t0)    # Lê a word em a0.
		jal 	__umodsi3
		# Remu 	a0,a0,a1	# número entre 0 e a1
		ret    # Retorna.



# -----------------------------------------------------------------------------
# CLS
# Clear Screen
# a0 = cor
# a1 = frame
# -----------------------------------------------------------------------------

clsCLS:	beq 	a1, zero, CLS.frame0
	li      t1, VGAADDRESSINI1    # Memória VGA 1.
   	li      t2, VGAADDRESSFIM1
   	j 	CLS.pula
CLS.frame0: 	li      t1, VGAADDRESSINI0    # Memória VGA 0.
   	    	li      t2, VGAADDRESSFIM0   	
CLS.pula:	andi    a0, a0, 0x00FF
# Trecho desativado, mantido para consulta: li 	 t0, 0x01010101
# mul	 a0, t0, a0
 		mv 	t0, a0
 		slli 	a0, a0, 8
 		or 	t0, t0, a0
 		slli 	a0, a0, 8
 		or 	t0, t0, a0
 		slli 	a0, a0, 8
 		or 	t0, t0, a0
 		
CLS.for:	beq     t1, t2, CLS.fim
		sw      t0, 0(t1)
    		addi    t1, t1, 4
    		j       CLS.for
CLS.fim:	ret


# -----------------------------------------------------------------------------
# Draw Line
# Desenha uma linha do ponto (a0,a1) ao ponto (a2,a3) com a cor a4
# na Frame a5 (0 ou 1)
# -----------------------------------------------------------------------------

BRESENHAM: 	li	a6, VGAADDRESSINI0    # Memória VGA 0.
	   	beq	a5, zero, pulaBRES
	   	li 	a6, VGAADDRESSINI1    # Memória VGA 1.
	   	
pulaBRES: 	li 	a7, 320
	  	sub 	t0, a3, a1
	  	bge 	t0, zero, PULAABRES
	  	sub 	t0, zero, t0
PULAABRES:	sub 	t1, a2, a0
	   	bge  	t1, zero, PULABBRES
	   	sub  	t1, zero, t1	
PULABBRES: 	bge  	t0, t1, PULACBRES
	   	ble  	a0, a2, PULAC1BRES
	   	mv 	a5, a0
	   	mv 	a0, a2
	   	mv 	a2, a5
	   	mv	a5, a1
	   	mv 	a1, a3
	   	mv 	a3, a5
PULAC1BRES:	j PLOTLOWBRES

PULACBRES: 	ble  	a1, a3, PULAC2BRES
	   	mv 	a5, a0
	   	mv 	a0, a2
	   	mv 	a2, a5
	   	mv 	a5, a1
	   	mv 	a1, a3
	   	mv 	a3, a5
PULAC2BRES:	j PLOTHIGHBRES

PLOTLOWBRES:	sub 	t0, a2, a0    # Dx=x1-x0.
	 	sub 	t1, a3, a1    # Dy y1-y0.
	 	li  	t2, 1    # Yi=1.
	 	bge 	t1, zero, PULA1BRES    # Dy>=0 PULA.
	 	li  	t2, -1    # Yi=-1.
	 	sub 	t1, zero, t1    # Dy=-dy.
PULA1BRES:	slli 	t3, t1, 1    # 2*dy.
		sub 	t3, t3, t0    # D=2*dy-dx.
		mv 	t4, a1    # Y=y0.
		mv 	t5, a0    # X=x0.
	
LOOPx1BRES:	TEM_M(s8,BRESENHAM.mul1)
		MULTIPLY(t6, t4, a7)
		j BRESENHAM.mul1d
BRESENHAM.mul1:	mul 	t6, t4, a7    # Y*320.
BRESENHAM.mul1d:add 	t6, t6, t5    # Y*320+x.
		add 	t6, t6, a6    # 0xFF000000+y*320+x.
		sb 	a4, 0(t6)    # Plot com cor a4.
	
		ble 	t3, zero, PULA2BRES    # D<=0.
		add 	t4, t4, t2    # Y=y+yi.
		slli 	t6, t0, 1    # 2*dx.
		sub 	t3, t3, t6    # D=D-2dx.
PULA2BRES:	slli 	t6, t1, 1    # 2*dy.
		add 	t3, t3, t6    # D=D+2dx.
		addi	t5, t5, 1
		bne 	t5, a2, LOOPx1BRES
		ret
		
PLOTHIGHBRES: 	sub 	t0, a2, a0    # Dx=x1-x0.
	 	sub 	t1, a3, a1    # Dy y1-y0.
	 	li 	t2, 1    # Xi=1.
	 	bge 	t0, zero, PULA3BRES    # Dy>=0 PULA.
	 	li 	t2, -1    # Xi=-1.
	 	sub 	t0, zero, t0    # Dx=-dx.
PULA3BRES:	slli 	t3, t0, 1    # 2*dx.
		sub 	t3, t3, t1    # D=2*dx-d1.
		mv 	t4, a0    # X=x0.
		mv 	t5, a1    # Y=y0.
	
LOOPx2BRES:	TEM_M(s8,BRESENHAM.mul2)
		MULTIPLY(t6, t5, a7)
		j BRESENHAM.mul2d
BRESENHAM.mul2:	mul 	t6, t5, a7    # Y*320.
BRESENHAM.mul2d:add 	t6, t6, t4    # Y*320+x.
		add 	t6, t6, a6    # 0xFF000000+y*320+x.
		sb 	a4, 0(t6)    # Plot com cor a4.
	
		ble 	t3, zero, PULA4BRES    # D<=0.
		add 	t4, t4, t2    # X=x+xi.
		slli 	t6, t1, 1    # 2*dy.
		sub 	t3, t3, t6    # D=D-2dy.
PULA4BRES: 	slli 	t6, t0, 1    # 2*dy.
		add 	t3, t3, t6    # D=D+2dx.
		addi 	t5, t5, 1
		bne 	t5, a3, LOOPx2BRES
		ret		


# Sugestao para nomes de loops: Sempre comecar com o nome da sub-rotina, então adicionar um '.', seguido do nome do loop . Garante que o nome do loop será único, se as sub-rotinas
# tiverem nomes diferentes.

# -----------------------------------------------------------------------------
# PrintIntUnsigned
# a0    =    valor inteiro
# a1    =    x
# a2    =    y
# a3    =    cor
# a4    =    frame
# -----------------------------------------------------------------------------

printIntUnsigned:	addi 	sp, sp, -4    # Reserva espaço na pilha.
		sw 	ra, 0(sp)    # Preserva ra, que contém o endereço de retorno.
		la 	t0, TempBuffer    # Carrega o endereço do Buffer da String.
		
		li 	t2, 10    # Carrega número 10.
		li 	t1, 0    # Carrega número de digitos com 0.

printIntUnsigned.loop1:	TEM_M(s8,printIntUnsigned.pula1)
			DIVU10(t4,a0)
			REMU10(t3,a0)
			j	printIntUnsigned.pula1d
printIntUnsigned.pula1:	divu 	t4, a0, t2    # Divide por 10 (quociente)
			remu 	t3, a0, t2    # Resto.
printIntUnsigned.pula1d:addi 	sp, sp, -4    # Reserva espaço na pilha na pilha.
		sw 	t3, 0(sp)    # Coloca resto na pilha.
		mv 	a0, t4    # Atualiza o número com o quociente.
		addi 	t1, t1, 1    # Incrementa o contador de digitos.
		bne 	a0, zero, printIntUnsigned.loop1    # Verifica se o número é zero.
				
printIntUnsigned.loop2:	lw 	t2, 0(sp)    # Lê digito da pilha.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
		addi 	t2, t2, 48    # Converte o digito para ascii.
		sb 	t2, 0(t0)    # Coloca caractere no buffer.
		addi 	t0, t0, 1    # Incrementa endereço do buffer.
		addi 	t1, t1, -1    # Decrementa contador de digitos.
		bne 	t1, zero, printIntUnsigned.loop2    # É o último?
		sb 	zero, 0(t0)    # Insere \NULL na string.
		
		la 	a0, TempBuffer    # Endereço do buffer da srting.
		jal 	printString    # Chama o print string.
				
		lw 	ra, 0(sp)    # Recupera a.
		addi 	sp, sp, 4    # Libera o espaço reservado na pilha.
printIntUnsigned.fim:	ret




# -----------------------------------------------------------------------------
# lib de operações multiplicação, divisão e resto para a ISA RV32I
# Nomenclatura usada pelo gcc
# -----------------------------------------------------------------------------

# Multiplicação signed em a0 e a1  retorno em a0
# https://github.com/gcc-mirror/gcc/tree/master/libgcc/config/epiphany
__mulsi3:	addi 	sp,sp,-12
		sw 	a1,0(sp)
		sw 	a4,4(sp)
		sw	a5,8(sp)
	
	 	mv      a5,a0
        	li      a0,0
mulsi3.L4: 	beqz    a5,mulsi3.L1
        	andi    a4,a5,1
        	beqz    a4,mulsi3.L3
        	add     a0,a0,a1
mulsi3.L3: 	srli    a5,a5,1
        	slli    a1,a1,1
        	j       mulsi3.L4
        	
mulsi3.L1: 	lw 	a1,0(sp)
		lw	a4,4(sp)
		lw	a5,8(sp)
		addi 	sp,sp,12
		ret
        
# Divisão unsigned em a0 e a1 retorno em a0
# https://stackoverflow.com/questions/34457575/integer-division-algorithm-analysis
__udivsi3:	addi 	sp,sp,-16
		sw 	a1,0(sp)
		sw	a3,4(sp)
		sw 	a4,8(sp)
		sw	a5,12(sp)
		
 		mv      a4,a0
        	srli    a3,a0,1
        	li      a5,1
udivsi3.L3:    	bltu    a3,a1,udivsi3.L6
        	slli    a5,a5,1
        	slli    a1,a1,1
        	j       udivsi3.L3
udivsi3.L6:    	li      a0,0
udivsi3.L2:   	beqz    a5,udivsi3.L1
        	bltu    a4,a1,udivsi3.L5
        	sub     a4,a4,a1
        	add     a0,a0,a5
udivsi3.L5:    	srli    a5,a5,1
        	srli    a1,a1,1
        	j       udivsi3.L2
        	
udivsi3.L1: 	lw 	a1,0(sp)
		lw	a3,4(sp)
		lw	a4,8(sp)
		lw	a5,12(sp)
		addi 	sp,sp,16
    		ret

# Resto unsigned em a0 e a1
__umodsi3:	addi	sp, sp, -12
		sw 	t0, 0(sp)
		sw 	t1, 4(sp)
		sw 	ra, 8(sp)
	 	mv 	t0, a0    # Dividendo.
		mv 	t1, a1    # Divisor.
		jal 	__udivsi3
		mv 	a1, t1    # Quociente * divisor.
		jal 	__mulsi3
		sub 	a0, t0, a0    # Dividendo-quociente*divisor.
		lw 	t0, 0(sp)
		lw 	t1, 4(sp)
		lw 	ra, 8(sp)
		addi 	sp, sp, 12
		ret
		
# Divisão signed em a0 e a1
__divsi3:	addi	sp, sp, -16
		sw 	t0, 0(sp)
		sw 	t1, 4(sp)
		sw 	t2, 8(sp)
		sw 	ra, 12(sp)
		srai	t0,a0,31    # Indica se a0 é pos(0) ou neg (2^32-1)
		srai 	t1,a1,31    # Indica se a1 é pos(0) ou neg (2^32-1)
		xor	t2,t0,t1    # Indica se deve(!=0) ou não(==0) inverter o sinal do resultado.
		beqz 	t0,divsi3.pula1
		neg	a0,a0    # Nega.
divsi3.pula1:	beqz 	t1,divsi3.pula2
		neg	a1,a1    # Nega.
divsi3.pula2:	jal 	__udivsi3    # Divisão unsigned.
		beqz	t2, divsi3.pula3	
		neg	a0,a0    # Nega.
divsi3.pula3:	lw 	t0, 0(sp)
		lw 	t1, 4(sp)
		lw 	t2, 8(sp)
		lw 	ra, 12(sp)
		addi 	sp, sp, 16
		ret
						
# Resto signed em a0 e a1
__modsi3:	addi	sp, sp, -12
		sw 	t0, 0(sp)
		sw 	t1, 4(sp)
		sw 	ra, 8(sp)
		srai	t0,a0,31    # Indica se a0 é pos(0) ou neg (2^32-1)
		srai 	t1,a1,31    # Indica se a1 é pos(0) ou neg (2^32-1)
		beqz 	t0,modsi3.pula1
		neg	a0,a0    # Nega.
modsi3.pula1:	beqz 	t1,modsi3.pula2
		neg	a1,a1    # Nega.
modsi3.pula2:	jal 	__umodsi3    # Resto unsigned.
		beqz	t0, modsi3.pula3    # Sinal do dividendo.
		neg	a0,a0    # Nega.
modsi3.pula3:	lw 	t0, 0(sp)
		lw 	t1, 4(sp)
		lw 	ra, 8(sp)
		addi 	sp, sp, 12
		ret																				
		
