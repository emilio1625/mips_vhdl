; Programa de prueba para el mips, ensamblado a mano con <3
; rutina de multiplicacion tomada de
; https://stackoverflow.com/questions/18812319/multiplication-using-logical-shifts-in-mips-assembly
localidad   opcode(bin)                      opcode(hex) code
0x00000000  00000000000000000100000000100000 0x00004020      add    $t0, $zero, $zero          # result
0x00000004                                               mult_loop:
0x00000004  00110010010010100000000000000001 0x324A0001      andi    $t2, $s2, 1
0x00000008  00010001010000000000000000000001 0x11400001      beq     $t2, $zero, bit_clear
                                                             # if (multiplicand & 1) result += multiplier << shift
0x0000000C  00000001000100010100000000100001 0x01114021      addu    $t0, $t0, $s1
0x00000010                                               bit_clear:
0x00000010  00000000000100011000100001000000 0x00118840      sll     $s1, $s1, 1       # multiplier <<= 1
0x00000014  00000000000100101001000001000010 0x00129042      srl     $s2, $s2, 1       # multiplicand >>= 1
0x00000018  00010110010000001111111111111010 0x1640FFFA      bne     $s2, $zero, mult_loop
