# Durante os laços, os registradores s guardam o inimigo atual, os limites e os contadores.
# a0-a2 transportam parâmetros e retornos; t0-t6 ficam com cálculos que não precisam ser preservados.
.data
.include "vilao.data"
.include "eyeofrah.data"

.eqv OGRE_INTERVALO 5
.eqv SPAWN_INTERVALO 30    # Frames entre nascimentos graduais (mais frequente)
.eqv INIMIGOS_POR_FASE 4    # Quantos do tipo da fase ficam em campo ao mesmo tempo.
.eqv OLHO_INTERVALO 3
.eqv OGRE_DIST_MIN 140    # Mantém o nascimento longe do mago, mesmo com reposição mais rápida.
.eqv META_INIMIGOS_FASE 20    # Meta de abates na fase 1.
.eqv META_INIMIGOS_FASE2 30    # Abates necessários na fase 2 para liberar o chefão.
.eqv TIPO_OGRO 1
.eqv TIPO_OLHO 2

inimigos_mortos: .word 0
ogro_anim_frame: .word 0    # 0/1 - alterna a cada passo, dando o efeito de caminhada.
spawn_timer: .word 0

.text

# Fase 1 (nível 0): só ogros. Fase 2 (nível 1): só olhos.
# Fase 3 (chefe) não cria inimigos comuns.
spawn_inimigos:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    la t0, nivel_atual
    lw t0, 0(t0)
    li t1, 1
    li s2, TIPO_OGRO
    beq t0, t1, spawn_ini_olho
    li t1, 2
    beq t0, t1, spawn_inimigos_fim    # Fase do chefe: não nasce nada.
    j spawn_ini_vai
spawn_ini_olho:
    li s2, TIPO_OLHO
spawn_ini_vai:
    la s1, inimigos
    li s3, INIMIGOS_POR_FASE    # Contador em registrador salvo (spawn_tipo usa t3 por dentro)
spawn_ini_loop:
    beqz s3, spawn_inimigos_fim
    mv a0, s1
    mv a1, s2
    jal spawn_tipo
    addi s1, s1, TAM_INIMIGO
    addi s3, s3, -1
    j spawn_ini_loop

spawn_inimigos_fim:
    li t0, SPAWN_INTERVALO
    la t1, spawn_timer
    sw t0, 0(t1)
    lw ra, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 16
    ret

# Reaparece gradualmente, sempre só do tipo da fase atual, até o teto
# INIMIGOS_POR_FASE. Fase do chefe (nível 2) nunca nasce nada.
atualiza_spawn_inimigos:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    la t0, nivel_atual
    lw t0, 0(t0)
    li t2, 2
    bge t0, t2, spawn_atualiza_fim

    li s2, TIPO_OGRO
    beqz t0, spawn_grad_tipo_ok
    li s2, TIPO_OLHO
spawn_grad_tipo_ok:

    la t2, spawn_timer
    lw s3, 0(t2)    # Guardado em registrador salvo: conta_tipo/spawn_tipo usam t1 por dentro.
    addi s3, s3, -1
    bgtz s3, spawn_guarda
    li s3, SPAWN_INTERVALO

    mv a0, s2
    jal conta_tipo
    li t2, INIMIGOS_POR_FASE
    bge a0, t2, spawn_guarda    # Campo já cheio desse tipo, espera.

    la s1, inimigos
    li t2, MAX_INIMIGOS
spawn_vaga_loop:
    beqz t2, spawn_guarda
    lw t3, 8(s1)
    beqz t3, spawn_vaga_achou
    addi s1, s1, TAM_INIMIGO
    addi t2, t2, -1
    j spawn_vaga_loop
spawn_vaga_achou:
    mv a0, s1
    mv a1, s2
    jal spawn_tipo

spawn_guarda:
    la t0, spawn_timer
    sw s3, 0(t0)
spawn_atualiza_fim:
    lw ra, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 16
    ret

# a0 indica o slot e a1 informa o tipo. A rotina sorteia uma posição distante e ativa o registro.
spawn_tipo:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    mv s1, a0
    mv s2, a1
    li s3, 10
spawn_tenta:
    li a7, 42
    li a1, 264
    ecall
    addi t0, a0, 16
    li a7, 42
    li a1, 184
    ecall
    addi t1, a0, 16
    la t2, posicao_x_mago
    lw t2, 0(t2)
    la t3, posicao_y_mago
    lw t3, 0(t3)
    sub t4, t0, t2
    bgez t4, spawn_dx_ok
    neg t4, t4
spawn_dx_ok:
    sub t5, t1, t3
    bgez t5, spawn_dy_ok
    neg t5, t5
spawn_dy_ok:
    add t4, t4, t5
    li t5, OGRE_DIST_MIN
    bge t4, t5, spawn_aceita
    addi s3, s3, -1
    bgtz s3, spawn_tenta
spawn_aceita:
    sw t0, 0(s1)
    sw t1, 4(s1)
    li t0, 1
    sw t0, 8(s1)
    sw zero, 12(s1)
    li t0, OGRE_INTERVALO
    li t1, TIPO_OLHO
    bne s2, t1, spawn_timer_ok
    li t0, OLHO_INTERVALO
spawn_timer_ok:
    sw t0, 16(s1)
    sw s2, 20(s1)
    lw ra, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 16
    ret

# a0 recebe o tipo procurado e, na volta, contém a quantidade ativa.
conta_tipo:
    mv t3, a0
    la t0, inimigos
    li t1, MAX_INIMIGOS
    li a0, 0
conta_tipo_loop:
    beqz t1, conta_tipo_fim
    lw t2, 8(t0)
    beqz t2, conta_tipo_prox
    lw t2, 20(t0)
    bne t2, t3, conta_tipo_prox
    addi a0, a0, 1
conta_tipo_prox:
    addi t0, t0, TAM_INIMIGO
    addi t1, t1, -1
    j conta_tipo_loop
conta_tipo_fim:
    ret

atualiza_inimigos:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)
    la s1, inimigos
    li t6, MAX_INIMIGOS
atualiza_loop:
    beqz t6, atualiza_fim
    lw t0, 8(s1)
    beqz t0, atualiza_prox
    lw t0, 16(s1)
    addi t0, t0, -1
    bgtz t0, atualiza_guarda
    lw t1, 20(s1)
    li t2, TIPO_OLHO
    beq t1, t2, olho_move
    li t0, OGRE_INTERVALO
    li t5, TIPO_OGRO
    la t2, ogro_anim_frame    # Alterna o quadro de caminhada a cada passo dado.
    lw t3, 0(t2)
    xori t3, t3, 1
    sw t3, 0(t2)
    j inimigo_calcula
olho_move:
    li t0, OLHO_INTERVALO
    li t5, TIPO_OLHO
inimigo_calcula:
    lw s2, 0(s1)
    lw s3, 4(s1)
    la t3, posicao_x_mago
    lw t3, 0(t3)
    la t4, posicao_y_mago
    lw t4, 0(t4)
    blt s2, t3, inimigo_dir
    bgt s2, t3, inimigo_esq
    j inimigo_x_ok
inimigo_dir:
    addi s2, s2, 2
    li t1, 1
    sw t1, 12(s1)
    j inimigo_x_ok
inimigo_esq:
    addi s2, s2, -2
    sw zero, 12(s1)
inimigo_x_ok:
    blt s3, t4, inimigo_desce
    bgt s3, t4, inimigo_sobe
    j inimigo_y_ok
inimigo_desce:
    addi s3, s3, 2
    j inimigo_y_ok
inimigo_sobe:
    addi s3, s3, -2
inimigo_y_ok:
    # Ogros e olhos podem atravessar a lava.

inimigo_grava:
    sw s2, 0(s1)
    sw s3, 4(s1)
    lw t1, 20(s1)
    li t2, TIPO_OGRO
    bne t1, t2, atualiza_guarda
    jal ogro_checa_lava
    li t0, OGRE_INTERVALO
atualiza_guarda:
    sw t0, 16(s1)
atualiza_prox:
    addi s1, s1, TAM_INIMIGO
    addi t6, t6, -1
    j atualiza_loop
atualiza_fim:
    lw ra, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 16
    ret

# Impede o ogro de entrar nos quatro pocos de lava da fase 2 (nível 1).
# a0=x candidato, a1=y candidato; devolve a0=1 quando a posição e segura.
ogro_pode_andar:
    la t0, nivel_atual
    lw t0, 0(t0)
    li t1, 1
    bne t0, t1, ogro_pos_livre
    li t2, 46
    ble a0, t2, ogro_poco2
    li t2, 102
    bge a0, t2, ogro_poco2
    li t2, 36
    ble a1, t2, ogro_poco2
    li t2, 86
    blt a1, t2, ogro_pos_bloqueada
ogro_poco2:
    li t2, 176
    ble a0, t2, ogro_poco3
    li t2, 232
    bge a0, t2, ogro_poco3
    li t2, 41
    ble a1, t2, ogro_poco3
    li t2, 91
    blt a1, t2, ogro_pos_bloqueada
ogro_poco3:
    li t2, 176
    ble a0, t2, ogro_poco4
    li t2, 232
    bge a0, t2, ogro_poco4
    li t2, 108
    ble a1, t2, ogro_poco4
    li t2, 158
    blt a1, t2, ogro_pos_bloqueada
ogro_poco4:
    li t2, 46
    ble a0, t2, ogro_pos_livre
    li t2, 102
    bge a0, t2, ogro_pos_livre
    li t2, 108
    ble a1, t2, ogro_pos_livre
    li t2, 158
    blt a1, t2, ogro_pos_bloqueada
ogro_pos_livre:
    li a0, 1
    ret
ogro_pos_bloqueada:
    li a0, 0
    ret

ogro_checa_lava:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, nivel_atual
    lw t0, 0(t0)
    li t2, 1
    bne t0, t2, ogro_lava_fim
    lw t0, 0(s1)
    lw t1, 4(s1)
    li t2, 46
    ble t0, t2, lava_poco2
    li t2, 102
    bge t0, t2, lava_poco2
    li t2, 36
    ble t1, t2, lava_poco2
    li t2, 86
    blt t1, t2, lava_mata
lava_poco2:
    li t2, 176
    ble t0, t2, lava_poco3
    li t2, 232
    bge t0, t2, lava_poco3
    li t2, 41
    ble t1, t2, lava_poco3
    li t2, 91
    blt t1, t2, lava_mata
lava_poco3:
    li t2, 176
    ble t0, t2, lava_poco4
    li t2, 232
    bge t0, t2, lava_poco4
    li t2, 108
    ble t1, t2, lava_poco4
    li t2, 158
    blt t1, t2, lava_mata
lava_poco4:
    li t2, 46
    ble t0, t2, ogro_lava_fim
    li t2, 102
    bge t0, t2, ogro_lava_fim
    li t2, 108
    ble t1, t2, ogro_lava_fim
    li t2, 158
    bge t1, t2, ogro_lava_fim
lava_mata:
    mv a0, s1
    jal mata_inimigo
ogro_lava_fim:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

draw_inimigos:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)
    la s1, inimigos
    li s2, MAX_INIMIGOS
draw_inimigos_loop:
    beqz s2, draw_inimigos_fim
    lw t0, 8(s1)
    beqz t0, draw_inimigos_prox
    lw a1, 0(s1)
    lw a2, 4(s1)
    lw t0, 20(s1)
    li t1, TIPO_OLHO
    beq t0, t1, draw_olho
    la a0, vilao
    addi a0, a0, 8
    la t0, ogro_anim_frame
    lw t0, 0(t0)
    li t1, 1024
    mul t0, t0, t1
    add a0, a0, t0
    jal draw_sprite32
    j draw_inimigos_prox
draw_olho:
    la a0, eyeofrah
    addi a0, a0, 8
    jal draw_sprite32
draw_inimigos_prox:
    addi s1, s1, TAM_INIMIGO
    addi s2, s2, -1
    j draw_inimigos_loop
draw_inimigos_fim:
    lw ra, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 12
    ret

# A0=pixels (32x32), a1=x, a2=y
draw_sprite32:
    la t0, base_frame_A
    lw t0, 0(t0)
    li t1, 320
    mul t2, a2, t1
    add t0, t0, t2
    add t0, t0, a1
    li t3, 0
draw32_linha:
    li t4, 32
    beq t3, t4, draw32_fim
    mv t5, t0
    li t6, 0
draw32_coluna:
    li t4, 32
    beq t6, t4, draw32_prox_linha
    lb t4, 0(a0)
    beqz t4, draw32_pula
    sb t4, 0(t5)
draw32_pula:
    addi a0, a0, 1
    addi t5, t5, 1
    addi t6, t6, 1
    j draw32_coluna
draw32_prox_linha:
    addi t0, t0, 320
    addi t3, t3, 1
    j draw32_linha
draw32_fim:
    ret

# a0 aponta para o registro do inimigo. A rotina contabiliza a morte e toca o áudio adequado.
mata_inimigo:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s1, 0(sp)
    mv s1, a0
    lw t0, 20(s1)
    sw zero, 8(s1)
    li t1, TIPO_OLHO
    beq t0, t1, mata_olho
    jal tocar_som_ogro_morre
    j mata_conta
mata_olho:
    jal tocar_som_olho_morre
mata_conta:
    la t0, inimigos_mortos
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    lw ra, 4(sp)
    lw s1, 0(sp)
    addi sp, sp, 8
    ret
