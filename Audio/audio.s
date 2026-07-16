# Visão geral dos registradores usados pelo áudio:
# a0 leva a nota MIDI; a1, a duração; a2, o instrumento; a3, o volume.
# a7 escolhe o serviço MIDI. No menu, s1 e s2 percorrem as tabelas e s3 conta as notas.
.data
# Jingle original do menu, andamento ~129 BPM (mesmo da referência menuInicial.mp3)
musica_menu_notas:     .byte  69, 72, 76, 74, 72, 71, 69, 64
musica_menu_duracoes:  .word 465,465,465,233,233,465,465,930
musica_menu_tam:       .word 8

.eqv INSTRUMENTO_8BIT    80    # Lead 1 (square) - música do menu.
.eqv INSTRUMENTO_IMPACTO 116    # Taiko Drum - disparo (parecido com hit.mp3)
.eqv INSTRUMENTO_OGRO  38    # Synth Bass 1 - grunhido grave da morte do ogro.
.eqv INSTRUMENTO_MORTE_MAGO 38    # Synth Bass 1 - queda grave do mago.
.eqv INSTRUMENTO_OLHO    103    # FX 8 (sci-fi) - ataque do olho voador.
.eqv INSTRUMENTO_OLHO_MORTE 12    # Vibraphone - morte do olho, som suave.
.eqv VELOCIDADE_NOTA     100
.eqv TECLA_AUDIO         0xff200004

.text

# Toca a música do menu em loop, nota a nota, até ESPAÇO ser pressionado.
# Cada nota é assíncrona, portanto não bloqueia o jogo. O intervalo entre elas
# usa sleep_ms; a leitura do teclado acontece a cada nota para permitir uma saída rápida.
tocar_musica_menu:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

musica_menu_reinicia:
    la s1, musica_menu_notas
    la s2, musica_menu_duracoes
    la s3, musica_menu_tam
    lw s3, 0(s3)

musica_menu_nota:
    beqz s3, musica_menu_reinicia    # Acabou a frase, toca de novo.

    lb a0, 0(s1)
    lw a1, 0(s2)
    li a2, INSTRUMENTO_8BIT
    li a3, VELOCIDADE_NOTA
    li a7, 31    # MIDI assíncrono.
    ecall

    mv a0, a1
    jal sleep_ms    # Espera a duração da nota.

    li t0, TECLA_AUDIO
    lw t1, 0(t0)
    li t2, ' '
    beq t1, t2, musica_menu_fim    # ESPAÇO pressionado: sai da música.

    addi s1, s1, 1
    addi s2, s2, 4
    addi s3, s3, -1
    j musica_menu_nota

musica_menu_fim:
    lw ra, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 16
    ret

# O disparo usa um som grave, curto e seco. A reprodução é assíncrona para não
# interromper a sequência quando o jogador atira rapidamente.
tocar_som_disparo:
    li a0, 43
    li a1, 150
    li a2, INSTRUMENTO_IMPACTO
    li a3, 120
    li a7, 31
    ecall
    ret

# Som do ogro atacando o mago (parecido com ogro_atack.mp3: rosnado curto).
# síncrono (a3=33): só 2 notas rapidas, a pausa reforca o impacto do hit.
tocar_som_ogro_ataca:
    li a0, 50
    li a1, 150
    li a2, INSTRUMENTO_OGRO
    li a3, 110
    li a7, 33
    ecall

    li a0, 54
    li a1, 180
    li a2, INSTRUMENTO_OGRO
    li a3, 110
    li a7, 33
    ecall
    ret

# Som do ogro morrendo (parecido com ogro_morrendo.mp3: grito agudo caindo).
# assíncrono: morte de inimigo acontece com frequência (ex: ogro na lava),
# um som síncrono aqui travaria o jogo a cada morte.
tocar_som_ogro_morre:
    li a0, 48
    li a1, 110
    li a2, INSTRUMENTO_OGRO
    li a3, 105
    li a7, 31
    ecall

    li a0, 40
    li a1, 250
    li a2, INSTRUMENTO_OGRO
    li a3, 95
    li a7, 31
    ecall
    ret

# Som da morte do mago: queda grave, distinta do dano comum.
tocar_som_mago_morre:
    li a0, 52
    li a1, 140
    li a2, INSTRUMENTO_MORTE_MAGO
    li a3, 110
    li a7, 33
    ecall

    li a0, 40
    li a1, 360
    li a2, INSTRUMENTO_MORTE_MAGO
    li a3, 100
    li a7, 33
    ecall
    ret

# Som de ataque do olho voador: rajada aguda e curta, meio "sobrenatural".
# síncrono, igual aos outros ataques (reforça o impacto do hit).
tocar_som_olho_ataca:
    li a0, 74
    li a1, 90
    li a2, INSTRUMENTO_OLHO
    li a3, 105
    li a7, 33
    ecall

    li a0, 79
    li a1, 90
    li a2, INSTRUMENTO_OLHO
    li a3, 110
    li a7, 33
    ecall

    li a0, 86
    li a1, 150
    li a2, INSTRUMENTO_OLHO
    li a3, 115
    li a7, 33
    ecall
    ret

# Variante assíncrona: preserva o efeito sem interromper o laço principal.
tocar_som_olho_ataca_async:
    li a0, 74
    li a1, 90
    li a2, INSTRUMENTO_OLHO
    li a3, 105
    li a7, 31
    ecall
    li a0, 79
    li a1, 90
    li a2, INSTRUMENTO_OLHO
    li a3, 110
    li a7, 31
    ecall
    li a0, 86
    li a1, 150
    li a2, INSTRUMENTO_OLHO
    li a3, 115
    li a7, 31
    ecall
    ret

# Som de morte do olho voador: queda curta e aguda.
# assíncrono pelo mesmo motivo do ogro: pode morrer com frequência.
tocar_som_olho_morre:
    li a0, 76
    li a1, 140
    li a2, INSTRUMENTO_OLHO_MORTE
    li a3, 55
    li a7, 31
    ecall
    li a0, 69
    li a1, 220
    li a2, INSTRUMENTO_OLHO_MORTE
    li a3, 45
    li a7, 31
    ecall
    ret
