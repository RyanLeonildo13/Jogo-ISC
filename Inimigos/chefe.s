# As rotinas do chefe usam os registradores s para conservar estado entre chamadas e laços.
# Os registradores a levam parâmetros; os t servem para posições, limites e comparações locais.
.eqv BOSS_HP_INI      100
.eqv BOSS_X           97    # Topo, centralizado (320-125)/2.
.eqv BOSS_Y           28    # Acima do rio de lava.
.eqv BOSS_W           125
.eqv BOSS_H           60
.eqv BOSS_FIRE_X      159    # Centro-baixo da bruxa.
.eqv BOSS_FIRE_Y      88    # Base da bruxa (ossos descem)
.eqv MAX_OSSOS        16
.eqv TAM_OSSO         20    # X, y, ativo, vx, vy.
.eqv OSSO_PX          15
.eqv INTERVALO        67    # ~2 s entre ataques (30 ms/frame alvo)
.eqv GAP_RAJADA       10    # Frames entre os tiros da rajada.
.eqv HP_FURIA         50
.eqv MANA_POR_ACERTO  10    # 100 em 10 acertos.
.eqv DANO_SUPER       5
.eqv ANIM_ATAQUE      12    # Frames mostrando a textura atacando.
.eqv HP_BARR1         75    # 1a onda de barreiras.
.eqv HP_BARR2         25    # 2a onda de barreiras.
.eqv MAX_BARREIRAS    3
.eqv TAM_BARREIRA     12    # Y, gap_x, ativo.
.eqv BARREIRA_VEL     1    # Descida (px/frame) - lento para dar para desviar.
.eqv BARREIRA_ESPACO  120    # Distância vertical entre as três barreiras.
.eqv BARREIRA_H       15
.eqv GAP_W            48    # Largura do buraco (mago tem 24)
.eqv IFRAMES_BARR     45    # Imunidade breve após hit de barreira.
.eqv PAREDE_Y         92    # Parede imovel de ossos na frente da bruxa.
.eqv PAREDE_X0        92
.eqv PAREDE_X1        227

.data
boss_hp:      .word 100
boss_timer:   .word 0
boss_anim:    .word 0    # >0 = mostrando textura atacando.
boss_burst:   .word 0    # Tiros restantes na rajada atual.
boss_burst_timer: .word 0    # Contagem entre tiros da rajada.
barreira_ativo:   .word 0    # >0 durante o ataque de barreiras (bruxa imune)
barreira_75_feita: .word 0    # Gatilhos de uma vez só.
barreira_25_feita: .word 0
barreiras:        .space 36    # MAX_BARREIRAS * TAM_BARREIRA.
ossos:        .space 320    # MAX_OSSOS * TAM_OSSO.
titulo_bruxa: .string "BRUXA DESPEDACADA"

.include "../Mecanicas/fonte8x8.data"
.include "bruxa.data"
.include "bruxa_atacando.data"
.include "osso.data"

.text

# Init_chefe - reinicia o chefe (só age na fase 3 / nível 2)
init_chefe:
    la   t0, nivel_atual
    lw   t0, 0(t0)
    li   t1, 2
    bne  t0, t1, ich_fim
    la   t0, boss_hp
    li   t1, BOSS_HP_INI
    sw   t1, 0(t0)
    la   t0, boss_timer
    li   t1, INTERVALO
    sw   t1, 0(t0)
    la   t0, boss_anim
    sw   zero, 0(t0)
    la   t0, boss_burst
    sw   zero, 0(t0)
    la   t0, boss_burst_timer
    sw   zero, 0(t0)
    la   t0, barreira_ativo
    sw   zero, 0(t0)
    la   t0, barreira_75_feita
    sw   zero, 0(t0)
    la   t0, barreira_25_feita
    sw   zero, 0(t0)
    la   t0, ossos
    li   t1, MAX_OSSOS
ich_clr:
    beqz t1, ich_fim
    sw   zero, 8(t0)
    addi t0, t0, TAM_OSSO
    addi t1, t1, -1
    j    ich_clr
ich_fim:
    ret

# Atualiza_chefe - anima, ataca no tempo certo, move ossos e checa tiros
atualiza_chefe:
    la   t0, nivel_atual
    lw   t0, 0(t0)
    li   t1, 2
    bne  t0, t1, ach_fim_direto
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, boss_anim    # Conta a animacao de ataque.
    lw   t1, 0(t0)
    blez t1, ach_anim_ok
    addi t1, t1, -1
    sw   t1, 0(t0)
ach_anim_ok:
    la   t0, barreira_ativo    # Ataque de barreira em andamento?
    lw   t0, 0(t0)
    bgtz t0, ach_barreira
    jal  checa_gatilho_barreira    # Cruzou 75 ou 25 de vida?
    la   t0, barreira_ativo
    lw   t0, 0(t0)
    bgtz t0, ach_barreira
    la   t0, boss_timer    # O timer principal sempre conta.
    lw   t1, 0(t0)
    addi t1, t1, -1
    sw   t1, 0(t0)
    la   t0, boss_burst    # t0 aponta para o contador que indica uma rajada em andamento.
    lw   t2, 0(t0)
    bgtz t2, ach_rajada
    bgtz t1, ach_pos    # Timer principal ainda não zerou.
    li   t2, INTERVALO    # Reinicia os ~2 s.
    la   t0, boss_timer
    sw   t2, 0(t0)
    la   t2, boss_hp
    lw   t2, 0(t2)
    li   t3, HP_FURIA
    bge  t2, t3, ach_um_tiro    # HP >= 50: 1 tiro.
    jal  dispara_osso    # HP < 50: inicia rajada (1o tiro agora)
    jal  set_anim_ataque
    la   t0, boss_burst
    li   t2, 2    # Faltam mais 2 tiros.
    sw   t2, 0(t0)
    la   t0, boss_burst_timer
    li   t2, GAP_RAJADA
    sw   t2, 0(t0)
    j    ach_pos
ach_um_tiro:
    jal  dispara_osso
    jal  set_anim_ataque
    j    ach_pos
ach_rajada:
    la   t0, boss_burst_timer    # Conta o intervalo entre os tiros.
    lw   t3, 0(t0)
    addi t3, t3, -1
    bgtz t3, ach_rajada_espera
    jal  dispara_osso    # Próximo tiro, mirando a posição ATUAL do mago.
    jal  set_anim_ataque
    la   t0, boss_burst
    lw   t2, 0(t0)
    addi t2, t2, -1
    sw   t2, 0(t0)
    li   t3, GAP_RAJADA
    la   t0, boss_burst_timer
    sw   t3, 0(t0)
    j    ach_pos
ach_rajada_espera:
    la   t0, boss_burst_timer
    sw   t3, 0(t0)
ach_pos:
    jal  atualiza_ossos
    jal  checa_tiros_chefe
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
ach_barreira:
    jal  atualiza_barreiras    # Move barreiras + colisao com o mago.
    jal  atualiza_ossos    # Ossos já lancados continuam caindo.
    jal  bloqueia_tiros    # Tiros somem na parede (bruxa não toma dano)
    lw   ra, 0(sp)
    addi sp, sp, 4
ach_fim_direto:
    ret

# Set_anim_ataque - liga a textura "atacando" por alguns frames
set_anim_ataque:
    la   t0, boss_anim
    li   t1, ANIM_ATAQUE
    sw   t1, 0(t0)
    ret

# Computa_aim -> a0 = vx256, a1 = vy256 (subpixel). direção EXATA até a
# posição atual do mago; velocidade baixa (chega em ~64 frames). Reta.
computa_aim:
    la   t0, posicao_x_mago
    lw   t0, 0(t0)
    li   t1, BOSS_FIRE_X
    sub  t0, t0, t1    # Dx.
    la   t1, posicao_y_mago
    lw   t1, 0(t1)
    li   t2, BOSS_FIRE_Y
    sub  t1, t1, t2    # Dy (positivo: mago abaixo)
    slli a0, t0, 2    # Vx256 = dx*4 (direção exata, ~64 frames)
    slli a1, t1, 2    # Vy256 = dy*4.
    bgtz a1, ca_ok    # Garante que desce.
    li   a1, 256    # 1 px/frame (fallback)
ca_ok:
    ret

# Spawn_osso_dir (a0 = vx256, a1 = vy256) - cria um osso na origem
spawn_osso_dir:
    la   t0, ossos
    li   t1, MAX_OSSOS
sod_find:
    beqz t1, sod_fim
    lw   t2, 8(t0)
    beqz t2, sod_achou
    addi t0, t0, TAM_OSSO
    addi t1, t1, -1
    j    sod_find
sod_achou:
    li   t2, BOSS_FIRE_X
    slli t2, t2, 8    # X em subpixel (x256)
    sw   t2, 0(t0)
    li   t2, BOSS_FIRE_Y
    slli t2, t2, 8    # Y256.
    sw   t2, 4(t0)
    li   t2, 1
    sw   t2, 8(t0)
    sw   a0, 12(t0)    # Vx256.
    sw   a1, 16(t0)    # Vy256.
sod_fim:
    ret

# Dispara_osso - 1 osso mirado na posição atual do mago
dispara_osso:
    addi sp, sp, -4
    sw   ra, 0(sp)
    jal  computa_aim
    jal  spawn_osso_dir
    jal  tocar_som_disparo    # Mesmo som do disparo do mago.
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Atualiza_ossos - move cada osso; sai da tela ou acerta o mago -> some
atualiza_ossos:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)
    la   s1, ossos
    li   s2, MAX_OSSOS
aos_loop:
    beqz s2, aos_fim
    lw   t0, 8(s1)
    beqz t0, aos_prox
    lw   t0, 0(s1)
    lw   t1, 12(s1)
    add  t0, t0, t1
    sw   t0, 0(s1)    # X256 += vx256.
    lw   t2, 4(s1)
    lw   t3, 16(s1)
    add  t2, t2, t3
    sw   t2, 4(s1)    # Y256 += vy256.
    srai t0, t0, 8    # X na tela.
    srai t2, t2, 8    # Y na tela.
    bltz t0, aos_mata
    li   t4, 319
    bgt  t0, t4, aos_mata
    bltz t2, aos_mata
    li   t4, 239
    bgt  t2, t4, aos_mata
    mv   a0, t0
    mv   a1, t2
    li   a2, OSSO_PX
    li   a3, OSSO_PX
    la   t4, posicao_x_mago
    lw   a4, 0(t4)
    la   t4, posicao_y_mago
    lw   a5, 0(t4)
    la   t4, tamanho_mago
    lw   a6, 0(t4)
    mv   a7, a6
    jal  check_collision
    beqz a0, aos_prox
    jal  mago_atingido
    j    aos_mata
aos_mata:
    sw   zero, 8(s1)
aos_prox:
    addi s1, s1, TAM_OSSO
    addi s2, s2, -1
    j    aos_loop
aos_fim:
    lw   ra, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 12
    ret

# Checa_tiros_chefe - disparos (dano 1) e supergolpes (dano 5) na bruxa
checa_tiros_chefe:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)
    la   s1, disparos
    li   s2, MAX_DISPAROS
ctc_d:
    beqz s2, ctc_super
    lw   t0, 8(s1)
    beqz t0, ctc_d_prox
    lw   a0, 0(s1)
    lw   a1, 4(s1)
    li   a2, TAM_PX_DISPARO
    li   a3, TAM_PX_DISPARO
    li   a4, BOSS_X
    li   a5, BOSS_Y
    li   a6, BOSS_W
    li   a7, BOSS_H
    jal  check_collision
    beqz a0, ctc_d_prox
    li   a0, 1
    jal  chefe_leva_dano
    sw   zero, 8(s1)
ctc_d_prox:
    addi s1, s1, TAM_DISPARO
    addi s2, s2, -1
    j    ctc_d
ctc_super:
    la   s1, superdisparos
    li   s2, MAX_SUPER
ctc_s:
    beqz s2, ctc_fim
    lw   t0, 8(s1)
    beqz t0, ctc_s_prox
    lw   a0, 0(s1)
    lw   a1, 4(s1)
    li   a2, TAM_PX_SUPER
    li   a3, TAM_PX_SUPER
    li   a4, BOSS_X
    li   a5, BOSS_Y
    li   a6, BOSS_W
    li   a7, BOSS_H
    jal  check_collision
    beqz a0, ctc_s_prox
    li   a0, DANO_SUPER
    jal  chefe_leva_dano
    sw   zero, 8(s1)
ctc_s_prox:
    addi s1, s1, TAM_SUPER
    addi s2, s2, -1
    j    ctc_s
ctc_fim:
    lw   ra, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 12
    ret

# Chefe_leva_dano (a0 = dano) - tira HP e enche +10 de mana
chefe_leva_dano:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, boss_hp
    lw   t1, 0(t0)
    sub  t1, t1, a0
    sw   t1, 0(t0)
    li   a0, MANA_POR_ACERTO
    jal  ganha_mana
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Draw_chefe - sprite (parada/atacando) + ossos + barra + titulo
draw_chefe:
    la   t0, nivel_atual
    lw   t0, 0(t0)
    li   t1, 2
    bne  t0, t1, dch_fim
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, bruxa    # Textura parada por padrão.
    la   t0, boss_anim
    lw   t0, 0(t0)
    blez t0, dch_tex_ok
    la   a0, bruxa_atacando    # Atacando.
dch_tex_ok:
    li   a1, BOSS_X
    li   a2, BOSS_Y
    jal  draw_sprite_wh
    jal  draw_ossos
    jal  draw_barreiras
    jal  draw_barra_chefe
    lw   ra, 0(sp)
    addi sp, sp, 4
dch_fim:
    ret

# Draw_ossos
draw_ossos:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)
    la   s1, ossos
    li   s2, MAX_OSSOS
dos_loop:
    beqz s2, dos_fim
    lw   t0, 8(s1)
    beqz t0, dos_prox
    la   a0, osso
    lw   a1, 0(s1)
    srai a1, a1, 8    # X na tela.
    lw   a2, 4(s1)
    srai a2, a2, 8    # Y na tela.
    jal  draw_sprite_wh
dos_prox:
    addi s1, s1, TAM_OSSO
    addi s2, s2, -1
    j    dos_loop
dos_fim:
    lw   ra, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 12
    ret

# Draw_sprite_wh (a0 = sprite com header .word W,H ; a1 = x ; a2 = y)
draw_sprite_wh:
    lw   t0, 0(a0)    # W.
    lw   t1, 4(a0)    # H.
    addi a0, a0, 8
    la   t2, base_frame_A
    lw   t2, 0(t2)
    li   t5, 320
    mul  t5, a2, t5
    add  t5, t5, a1
    add  t2, t2, t5    # Canto (pode ficar fora se y<0)
    li   t3, 0
dsw_row:
    beq  t3, t1, dsw_done
    add  a3, a2, t3    # Cur_y.
    bltz a3, dsw_row_skip    # Linha acima da tela -> pula.
    li   a4, 240
    bge  a3, a4, dsw_done    # Linha abaixo da tela -> acabou.
    mv   t5, t2
    li   t4, 0
dsw_col:
    beq  t4, t0, dsw_row_end
    add  a3, a1, t4    # Cur_x.
    bltz a3, dsw_skip    # Fora a esquerda.
    li   a4, 320
    bge  a3, a4, dsw_skip    # Fora a direita.
    lb   t6, 0(a0)
    beqz t6, dsw_skip
    sb   t6, 0(t5)
dsw_skip:
    addi a0, a0, 1
    addi t5, t5, 1
    addi t4, t4, 1
    j    dsw_col
dsw_row_end:
    addi t2, t2, 320
    addi t3, t3, 1
    j    dsw_row
dsw_row_skip:
    add  a0, a0, t0    # Pula os bytes desta linha.
    addi t2, t2, 320
    addi t3, t3, 1
    j    dsw_row
dsw_done:
    ret

# Draw_barra_chefe - titulo + barra de HP (200px, hp*2)
draw_barra_chefe:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, titulo_bruxa
    li   a1, 92
    li   a2, 6
    li   a3, 0xFF
    jal  draw_texto_8x8
    li   a0, 60
    li   a1, 16
    li   a2, 200
    li   a3, 6
    li   a4, 0x49
    jal  preenche_ret
    la   t0, boss_hp
    lw   t0, 0(t0)
    blez t0, dbc_fim
    slli a2, t0, 1
    li   a0, 60
    li   a1, 16
    li   a3, 6
    li   a4, 0x07
    jal  preenche_ret
dbc_fim:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Preenche_ret (a0=x, a1=y, a2=w, a3=h, a4=cor)
preenche_ret:
    la   t0, base_frame_A
    lw   t0, 0(t0)
    li   t1, 320
    mul  t2, a1, t1
    add  t2, t2, a0
    add  t0, t0, t2
    li   t3, 0
pr_row:
    beq  t3, a3, pr_done
    mv   t4, t0
    li   t5, 0
pr_col:
    beq  t5, a2, pr_row_end
    sb   a4, 0(t4)
    addi t4, t4, 1
    addi t5, t5, 1
    j    pr_col
pr_row_end:
    addi t0, t0, 320
    addi t3, t3, 1
    j    pr_row
pr_done:
    ret

# Draw_texto_8x8 (a0 = string 0-terminada, a1 = x, a2 = y, a3 = cor)
draw_texto_8x8:
    addi sp, sp, -20
    sw   ra, 16(sp)
    sw   s1, 12(sp)
    sw   s2, 8(sp)
    sw   s3, 4(sp)
    sw   s4, 0(sp)
    mv   s1, a0
    mv   s2, a1
    mv   s3, a2
    mv   s4, a3
dt_loop:
    lb   a0, 0(s1)
    beqz a0, dt_fim
    mv   a1, s2
    mv   a2, s3
    mv   a3, s4
    jal  draw_char_8x8
    addi s1, s1, 1
    addi s2, s2, 8
    j    dt_loop
dt_fim:
    lw   ra, 16(sp)
    lw   s1, 12(sp)
    lw   s2, 8(sp)
    lw   s3, 4(sp)
    lw   s4, 0(sp)
    addi sp, sp, 20
    ret

# Draw_char_8x8 (a0 = ascii, a1 = x, a2 = y, a3 = cor)
draw_char_8x8:
    la   t0, base_frame_A
    lw   t0, 0(t0)
    li   t1, 320
    mul  t2, a2, t1
    add  t2, t2, a1
    addi t2, t2, 7
    add  t4, t0, t2
    addi t2, a0, -32
    slli t2, t2, 3
    la   t3, LabelTabChar
    add  t2, t2, t3
    lw   t5, 0(t2)
    li   t0, 4
dc_r1:
    beqz t0, dc_w2
    li   t1, 8
dc_c1:
    beqz t1, dc_r1e
    andi t6, t5, 1
    srli t5, t5, 1
    beqz t6, dc_s1
    sb   a3, 0(t4)
dc_s1:
    addi t4, t4, -1
    addi t1, t1, -1
    j    dc_c1
dc_r1e:
    addi t4, t4, 328
    addi t0, t0, -1
    j    dc_r1
dc_w2:
    lw   t5, 4(t2)
    li   t0, 4
dc_r2:
    beqz t0, dc_done
    li   t1, 8
dc_c2:
    beqz t1, dc_r2e
    andi t6, t5, 1
    srli t5, t5, 1
    beqz t6, dc_s2
    sb   a3, 0(t4)
dc_s2:
    addi t4, t4, -1
    addi t1, t1, -1
    j    dc_c2
dc_r2e:
    addi t4, t4, 328
    addi t0, t0, -1
    j    dc_r2
dc_done:
    ret

# -----------------------------------------------------------------------------
# Ataque de barreiras (estilo "Block Party"): paredes de ossos com um
# buraco descem o mapa; o mago desvia correndo entre os buracos.
# Dispara ao cruzar 75 e 25 de vida. Durante o ataque a bruxa fica imune
# (parede imovel de ossos na frente dela) até a ultima barreira sair.
# -----------------------------------------------------------------------------

# Checa_gatilho_barreira - inicia o ataque ao cruzar 75 ou 25 de vida
checa_gatilho_barreira:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, boss_hp
    lw   t0, 0(t0)
    li   t1, HP_BARR1
    bgt  t0, t1, cgb_25
    la   t2, barreira_75_feita
    lw   t3, 0(t2)
    bnez t3, cgb_25
    li   t3, 1
    sw   t3, 0(t2)
    jal  inicia_barreiras
    j    cgb_fim
cgb_25:
    li   t1, HP_BARR2
    bgt  t0, t1, cgb_fim
    la   t2, barreira_25_feita
    lw   t3, 0(t2)
    bnez t3, cgb_fim
    li   t3, 1
    sw   t3, 0(t2)
    jal  inicia_barreiras
cgb_fim:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Inicia_barreiras - cria 3 barreiras escalonadas acima da tela, buracos sorteados
inicia_barreiras:
    la   t0, barreira_ativo
    li   t1, 1
    sw   t1, 0(t0)
    la   t0, barreiras
    li   t1, 0    # Indice.
ib_loop:
    li   t2, MAX_BARREIRAS
    bge  t1, t2, ib_fim
    li   t3, BARREIRA_ESPACO    # Y = -(15 + i*ESPAÇO)
    mul  t3, t1, t3
    addi t3, t3, 15
    sub  t4, zero, t3
    sw   t4, 0(t0)
    li   a7, 42    # Gap_x aleatorio em [0, 275)
    li   a1, 275
    ecall
    sw   a0, 4(t0)
    li   t3, 1
    sw   t3, 8(t0)    # Ativo.
    addi t0, t0, TAM_BARREIRA
    addi t1, t1, 1
    j    ib_loop
ib_fim:
    ret

# Atualiza_barreiras - desce as barreiras, colide com o mago, encerra o ataque
atualiza_barreiras:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s1, 8(sp)
    sw   s2, 4(sp)
    sw   s3, 0(sp)
    la   s1, barreiras
    li   s2, MAX_BARREIRAS
    li   s3, 0    # Conta barreiras ainda na tela.
ab_loop:
    beqz s2, ab_fim
    lw   t0, 8(s1)
    beqz t0, ab_prox
    lw   t0, 0(s1)    # Y += VEL.
    addi t0, t0, BARREIRA_VEL
    sw   t0, 0(s1)
    li   t1, 240    # Saiu por baixo?
    blt  t0, t1, ab_dentro
    sw   zero, 8(s1)
    j    ab_prox
ab_dentro:
    addi s3, s3, 1
    la   t1, posicao_y_mago    # Overlap vertical com o mago?
    lw   t1, 0(t1)
    addi t2, t1, 24
    ble  t2, t0, ab_prox    # Mago acima da barreira.
    addi t3, t0, BARREIRA_H
    bge  t1, t3, ab_prox    # Mago abaixo da barreira.
    la   t2, posicao_x_mago    # t2 recebe o endereço usado para conferir se o mago está no vão.
    lw   t2, 0(t2)
    lw   t3, 4(s1)    # Gap_x.
    blt  t2, t3, ab_hit    # Mago_x < gap_x -> em cima de osso.
    addi t4, t2, 24
    addi t5, t3, GAP_W
    bgt  t4, t5, ab_hit    # Mago_x+24 > gap_x+GAP_W -> osso.
    j    ab_prox    # Totalmente no buraco: seguro.
ab_hit:
    jal  mago_atingido
    la   t0, escudo_timer    # I-frames para não morrer em cadeia no respawn.
    li   t1, IFRAMES_BARR
    sw   t1, 0(t0)
ab_prox:
    addi s1, s1, TAM_BARREIRA
    addi s2, s2, -1
    j    ab_loop
ab_fim:
    bnez s3, ab_ret    # Ainda ha barreira na tela.
    la   t0, barreira_ativo    # Ultima saiu -> bruxa volta a tomar dano.
    sw   zero, 0(t0)
ab_ret:
    lw   ra, 12(sp)
    lw   s1, 8(sp)
    lw   s2, 4(sp)
    lw   s3, 0(sp)
    addi sp, sp, 16
    ret

# Draw_barreiras - parede protetora + as 3 barreiras (ossos menos o buraco)
draw_barreiras:
    addi sp, sp, -24
    sw   ra, 20(sp)
    sw   s1, 16(sp)
    sw   s2, 12(sp)
    sw   s3, 8(sp)
    sw   s4, 4(sp)
    sw   s5, 0(sp)
    la   t0, barreira_ativo
    lw   t0, 0(t0)
    beqz t0, dbr_fim
    li   s4, PAREDE_X0    # Parede imovel na frente da bruxa.
dbr_parede:
    li   t0, PAREDE_X1
    bge  s4, t0, dbr_barreiras
    la   a0, osso
    mv   a1, s4
    li   a2, PAREDE_Y
    jal  draw_sprite_wh
    addi s4, s4, 15
    j    dbr_parede
dbr_barreiras:
    la   s1, barreiras
    li   s2, MAX_BARREIRAS
dbr_loop:
    beqz s2, dbr_fim
    lw   t0, 8(s1)
    beqz t0, dbr_prox
    lw   s3, 0(s1)    # Y.
    lw   s5, 4(s1)    # Gap_x.
    li   s4, 0    # X.
dbr_linha:
    li   t0, 320
    bge  s4, t0, dbr_prox
    addi t0, s5, -15    # Osso [x,x+15] invade o buraco?
    ble  s4, t0, dbr_desenha    # X <= gap_x-15 -> esquerda, desenha.
    addi t0, s5, GAP_W
    bge  s4, t0, dbr_desenha    # X >= gap_x+GAP_W -> direita, desenha.
    j    dbr_pula    # Senao invade o buraco -> pula.
dbr_desenha:
    la   a0, osso
    mv   a1, s4
    mv   a2, s3
    jal  draw_sprite_wh
dbr_pula:
    addi s4, s4, 15
    j    dbr_linha
dbr_prox:
    addi s1, s1, TAM_BARREIRA
    addi s2, s2, -1
    j    dbr_loop
dbr_fim:
    lw   ra, 20(sp)
    lw   s1, 16(sp)
    lw   s2, 12(sp)
    lw   s3, 8(sp)
    lw   s4, 4(sp)
    lw   s5, 0(sp)
    addi sp, sp, 24
    ret

# Bloqueia_tiros - some com os tiros que batem na parede (sem dano/mana)
bloqueia_tiros:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)
    la   s1, disparos
    li   s2, MAX_DISPAROS
bt_d:
    beqz s2, bt_super
    lw   t0, 8(s1)
    beqz t0, bt_d_prox
    lw   a0, 0(s1)
    lw   a1, 4(s1)
    li   a2, TAM_PX_DISPARO
    li   a3, TAM_PX_DISPARO
    li   a4, PAREDE_X0
    li   a5, BOSS_Y
    li   a6, 135
    li   a7, 79    # Da bruxa até a parede (28..107)
    jal  check_collision
    beqz a0, bt_d_prox
    sw   zero, 8(s1)
bt_d_prox:
    addi s1, s1, TAM_DISPARO
    addi s2, s2, -1
    j    bt_d
bt_super:
    la   s1, superdisparos
    li   s2, MAX_SUPER
bt_s:
    beqz s2, bt_fim
    lw   t0, 8(s1)
    beqz t0, bt_s_prox
    lw   a0, 0(s1)
    lw   a1, 4(s1)
    li   a2, TAM_PX_SUPER
    li   a3, TAM_PX_SUPER
    li   a4, PAREDE_X0
    li   a5, BOSS_Y
    li   a6, 135
    li   a7, 79    # Da bruxa até a parede (28..107)
    jal  check_collision
    beqz a0, bt_s_prox
    sw   zero, 8(s1)
bt_s_prox:
    addi s1, s1, TAM_SUPER
    addi s2, s2, -1
    j    bt_s
bt_fim:
    lw   ra, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 12
    ret
