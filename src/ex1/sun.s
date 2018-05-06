;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.export TASK2, SUNSLOT
.import WAIT, BITSOFF, BITSON, TASK_STATE, CURRTASK

SPRITENR = 0
SHAPENR = $A0

.segment "ZEROPAGE":zeropage
SPPTR:   .word 0

.segment "DATA"
SUNSLOT:   .byte 0

.segment "RODATA"
.linecont +
SPRITE1: .byte \
  %00000000,%00111100,%00000000, \
  %00000001,%11111111,%10000000, \
  %00000111,%11111111,%11100000, \
  %00001111,%11111111,%11110000, \
  %00011111,%11111111,%11111000, \
  %00111111,%11111111,%11111100, \
  %01111111,%11111111,%11111110, \
  %01111111,%11111111,%11111110, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %01111111,%11111111,%11111110, \
  %01111111,%11111111,%11111110, \
  %00111111,%11111111,%11111100, \
  %00011111,%11111111,%11111000, \
  %00001111,%11111111,%11110000, \
  %00000111,%11111111,%11100000, \
  %00000001,%11111111,%10000000, \
  %00000000,%00111100,%00000000
.linecont -

BALISTA1: .word 0,220
.word 1,219
.word 2,218
.word 3,216
.word 4,215
.word 5,214
.word 6,213
.word 7,212
.word 8,211
.word 9,210
.word 10,208
.word 11,207
.word 12,206
.word 13,205
.word 14,204
.word 15,203
.word 16,201
.word 17,200
.word 18,199
.word 19,198
.word 20,197
.word 21,196
.word 22,194
.word 23,193
.word 24,192
.word 25,191
.word 26,190
.word 27,189
.word 28,188
.word 29,187
.word 30,185
.word 31,184
.word 32,183
.word 33,182
.word 34,181
.word 35,180
.word 36,179
.word 37,178
.word 38,177
.word 39,175
.word 40,174
.word 41,173
.word 42,172
.word 43,171
.word 44,170
.word 45,169
.word 46,168
.word 47,167
.word 48,166
.word 49,165
.word 50,164
.word 51,163
.word 52,162
.word 53,160
.word 54,159
.word 55,158
.word 56,157
.word 57,156
.word 58,155
.word 59,154
.word 60,153
.word 61,152
.word 62,151
.word 63,150
.word 64,149
.word 65,148
.word 66,147
.word 67,146
.word 68,145
.word 69,145
.word 70,144
.word 71,143
.word 72,142
.word 73,141
.word 74,140
.word 75,139
.word 76,138
.word 77,137
.word 78,136
.word 79,135
.word 80,134
.word 81,134
.word 82,133
.word 83,132
.word 84,131
.word 85,130
.word 86,129
.word 87,128
.word 88,128
.word 89,127
.word 90,126
.word 91,125
.word 92,124
.word 93,124
.word 94,123
.word 95,122
.word 96,121
.word 97,121
.word 98,120
.word 99,119
.word 100,118
.word 101,118
.word 102,117
.word 103,116
.word 104,116
.word 105,115
.word 106,114
.word 107,113
.word 108,113
.word 109,112
.word 110,112
.word 111,111
.word 112,110
.word 113,110
.word 114,109
.word 115,108
.word 116,108
.word 117,107
.word 118,107
.word 119,106
.word 120,106
.word 121,105
.word 122,104
.word 123,104
.word 124,103
.word 125,103
.word 126,102
.word 127,102
.word 128,101
.word 129,101
.word 130,100
.word 131,100
.word 132,100
.word 133,99
.word 134,99
.word 135,98
.word 136,98
.word 137,97
.word 138,97
.word 139,97
.word 140,96
.word 141,96
.word 142,96
.word 143,95
.word 144,95
.word 145,95
.word 146,94
.word 147,94
.word 148,94
.word 149,94
.word 150,93
.word 151,93
.word 152,93
.word 153,93
.word 154,92
.word 155,92
.word 156,92
.word 157,92
.word 158,92
.word 159,91
.word 160,91
.word 161,91
.word 162,91
.word 163,91
.word 164,91
.word 165,91
.word 166,90
.word 167,90
.word 168,90
.word 169,90
.word 170,90
.word 171,90
.word 172,90
.word 173,90
.word 174,90
.word 175,90
.word 176,90
.word 177,90
.word 178,90
.word 179,90
.word 180,90
.word 181,90
.word 182,90
.word 183,90
.word 184,90
.word 185,91
.word 186,91
.word 187,91
.word 188,91
.word 189,91
.word 190,91
.word 191,91
.word 192,92
.word 193,92
.word 194,92
.word 195,92
.word 196,92
.word 197,93
.word 198,93
.word 199,93
.word 200,93
.word 201,94
.word 202,94
.word 203,94
.word 204,94
.word 205,95
.word 206,95
.word 207,95
.word 208,96
.word 209,96
.word 210,96
.word 211,97
.word 212,97
.word 213,97
.word 214,98
.word 215,98
.word 216,99
.word 217,99
.word 218,100
.word 219,100
.word 220,100
.word 221,101
.word 222,101
.word 223,102
.word 224,102
.word 225,103
.word 226,103
.word 227,104
.word 228,104
.word 229,105
.word 230,106
.word 231,106
.word 232,107
.word 233,107
.word 234,108
.word 235,108
.word 236,109
.word 237,110
.word 238,110
.word 239,111
.word 240,112
.word 241,112
.word 242,113
.word 243,113
.word 244,114
.word 245,115
.word 246,116
.word 247,116
.word 248,117
.word 249,118
.word 250,118
.word 251,119
.word 252,120
.word 253,121
.word 254,121
.word 255,122
.word 256,123
.word 257,124
.word 258,124
.word 259,125
.word 260,126
.word 261,127
.word 262,128
.word 263,128
.word 264,129
.word 265,130
.word 266,131
.word 267,132
.word 268,133
.word 269,134
.word 270,134
.word 271,135
.word 272,136
.word 273,137
.word 274,138
.word 275,139
.word 276,140
.word 277,141
.word 278,142
.word 279,143
.word 280,144
.word 281,145
.word 282,145
.word 283,146
.word 284,147
.word 285,148
.word 286,149
.word 287,150
.word 288,151
.word 289,152
.word 290,153
.word 291,154
.word 292,155
.word 293,156
.word 294,157
.word 295,158
.word 296,159
.word 297,160
.word 298,162
.word 299,163
.word 300,164
.word 301,165
.word 302,166
.word 303,167
.word 304,168
.word 305,169
.word 306,170
.word 307,171
.word 308,172
.word 309,173
.word 310,174
.word 311,175
.word 312,177
.word 313,178
.word 314,179
.word 315,180
.word 316,181
.word 317,182
.word 318,183
.word 319,184
.word 320,185
.word 321,187
.word 322,188
.word 323,189
.word 324,190
.word 325,191
.word 326,192
.word 327,193
.word 328,194
.word 329,196
.word 330,197
.word 331,198
.word 332,199
.word 333,200
.word 334,201
.word 335,203
.word 336,204
.word 337,205
.word 338,206
.word 339,207
.word 340,208
.word 341,210
.word 342,211
.word 343,212
.word 344,213
.word 345,214
.word 346,215
.word 347,216
.word 348,218
.word 349,219
.word 350,220


.segment "CODE"
.proc TASK2
    lda CURRTASK
    sta SUNSLOT

    ; init sprite
    ldx #62         ;copy sprite
:   lda SPRITE1,x
    sta $6800,x
    dex
    bpl :-
    ldx #SPRITENR   ;X = sprit number
    lda #SHAPENR    ;kształt pod adresem $2800 w ramach VIC
    sta $63F8,x     ;8 wskźników na definicje sprita
    lda #7          ;sprite color
    sta $D027,x

    lda $D010       ;MSB bit of x coordinate
    and BITSOFF,x
    sta $D010
    lda $D015       ;enable sprite
    ora BITSON,x
    sta $D015
    lda $D01D       ;expand X off
    and BITSOFF,x
    sta $D01D
    lda $D017       ;expand Y off
    and BITSOFF,x
    sta $D017
    lda $D01C       ;Multi-color off
    and BITSOFF,x
    sta $D01C
    lda $D01B       ;sprite 0 protity, MOB in front
    ora BITSON,x
    sta $D01B

    lda #<BALISTA1
    sta SPPTR
    lda #>BALISTA1
    sta SPPTR+1

:   jsr SETSPRITEPOS
    ldy #12
    jsr WAIT

    clc
    lda SPPTR       ;przesuwam wskaźnik do następnej pozycji w tablicy trajektorii
    adc #4
    sta SPPTR
    lda SPPTR+1
    adc #0
    sta SPPTR+1

    sec             ;czy większe od 320+24
    lda SPPTR
    sbc #<(BALISTA1+351*4)
    lda SPPTR+1
    sbc #>(BALISTA1+351*4)
    bcc :+

    lda #<BALISTA1
    sta SPPTR
    lda #>BALISTA1
    sta SPPTR+1

:   ldy SUNSLOT
    lda TASK_STATE,y
    and #$40          ;test stop request
    beq :--

koniec_SUN:
    ldx #SPRITENR   ;X = sprit number
    lda $D015       ;enable sprite
    and BITSOFF,x
    sta $D015

    ldy SUNSLOT
    lda TASK_STATE,y
    ora #$20
    sta TASK_STATE,y
    lda #0
    sta SUNSLOT

:   nop
    jmp :-              ;w przyszłości ta pętla będzie zastąpiona przez event
.endproc

.proc SETSPRITEPOS
    lda #SPRITENR          ; X = 2 * sprite number
    asl
    tax
    ldy #0
    lda (SPPTR),y   ;x position
    sta $D000,x
    iny
    iny
    lda (SPPTR),y   ;y position
    sta $D001,x
    txa
    lsr
    tax
    dey
    lda (SPPTR),y     ;cofam się na starszy bajt x position
    beq :+
    lda $D010
    ora BITSON,x
    sta $D010
    rts

:   lda $D010
    and BITSOFF,x
    sta $D010
    rts
.endproc