.include "MACROSv24.s"

.data
.include "tela.data"
.include "mago.data"
.include "colisao.s"
.include "jogador.s"
.data

base_frame_A:    .word 0xFF000000
cd_frame_A:      .word 0
posicao_y_mago:  .word 20
posicao_x_mago:  .word 24
tamanho_mago:    .word 24
tempo_inicio:    .word 0
tempo_final:     .word 0

.text

.eqv VGA_BASE      0xFF000000
.eqv VGA_END       0xFF012C00
.eqv VGA_FRAME_SEL 0xFF200604
.eqv FRAME_TARGET_MS 40

.globl main
main:
    li t0, VGA_BASE
    sw zero, 0(t0)
    li s0, VGA_BASE

    la t0, inimigos
    li t1, MAX_INIMIGOS
    li t2, TAM_INIMIGO
init_inimigos:
    beqz t1, init_inimigos_fim
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)
    add t0, t0, t2
    addi t1, t1, -1
    j init_inimigos
init_inimigos_fim:

    jal draw_image
    jal draw_square
    jal draw_hearts
    jal draw_mana_bar

loop:
    li a7, 30
    ecall
    mv t1, a0
    la t0, tempo_inicio
    sw t1, 0(t0)

    jal read_key

    li t0, 'p'
    beq a0, t0, exit_program
    li t0, 'w'
    beq a0, t0, move_up
    li t0, 'a'
    beq a0, t0, move_left
    li t0, 's'
    beq a0, t0, move_down
    li t0, 'd'
    beq a0, t0, move_right
    j after_move

move_up:
    la t0, posicao_y_mago
    lw s2, 0(t0)
    addi t0, s2, -8
    bltz t0, after_move
    addi s2, s2, -2
    j after_move

move_left:
    la t0, posicao_x_mago
    lw s1, 0(t0)
    addi t0, s1, -8
    bltz t0, after_move
    addi s1, s1, -2
    j after_move

move_down:
    la t0, posicao_y_mago
    lw s2, 0(t0)
    li t0, 208
    bgt s2, t0, after_move
    addi s2, s2, 2
    j after_move

move_right:
    la t0, posicao_x_mago
    lw s1, 0(t0)
    li t0, 288
    bgt s1, t0, after_move
    addi s1, s1, 2
    j after_move

after_move:
    la t0, posicao_x_mago
    sw s1, 0(t0)
    la t0, posicao_y_mago
    sw s2, 0(t0)

    jal checar_colisao_mago_inimigos

    la t0, cd_frame_A
    lw s6, 0(t0)
    beqz s6, frame0
    j frame1

frame0:
    li s0, VGA_BASE
    la t0, base_frame_A
    sw s0, 0(t0)
    j draw_frame

frame1:
    li s0, 0xFF100000
    la t0, base_frame_A
    sw s0, 0(t0)

draw_frame:
    jal draw_image
    jal draw_square
    jal draw_hearts
    jal draw_mana_bar
    li t0, VGA_FRAME_SEL
    sw s6, 0(t0)
    xori s6, s6, 0x1
    la t0, cd_frame_A
    sw s6, 0(t0)

    la t0, tempo_inicio
    lw t1, 0(t0)
    li a7, 30
    ecall
    mv t2, a0
    li t3, FRAME_TARGET_MS
    sub a0, t2, t1
    sub a0, t3, a0
    bltz a0, no_sleep
    li a7, 32
    ecall
no_sleep:
    j loop

exit_program:
    li a7, 10
    ecall

read_key:
    li t0, 0xff200000
    lb a0, 4(t0)
    ret

# Copia o mapa da memória pra tela
draw_image:
    la t0, base_frame_A
    lw s0, 0(t0)
    la t0, map_pixels
    mv t1, s0
    li t6, 0x12C00
    add t2, s0, t6
image_loop:
    beq t1, t2, image_done
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j image_loop
image_done:
    ret

# Desenha o mago 24x24 na tela
draw_square:
    la t0, base_frame_A
    lw s0, 0(t0)
    la t0, posicao_x_mago
    lw s1, 0(t0)
    la t0, posicao_y_mago
    lw s2, 0(t0)
    la t0, tamanho_mago
    lw s3, 0(t0)
    mv t0, s0
    li t1, 320
    mul t2, s2, t1
    add t2, t2, s1
    add t0, t0, t2

    la t2, mago
    addi t2, t2, 8
    li t3, 0
    li t6, 320
square_row:
    beq t3, s3, square_done
    mv t4, t0
    li t5, 0
square_col:
    beq t5, s3, square_next_row
    lb t1, 0(t2)
    sb t1, 0(t4)
    addi t2, t2, 1
    addi t4, t4, 1
    addi t5, t5, 1
    j square_col
square_next_row:
    add t0, t0, t6
    addi t3, t3, 1
    j square_row
square_done:
    ret
