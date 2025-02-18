; Disassembled from blank_flop.img

0000: jmp 0x3e
0002: nop 
0003: insw word ptr es:[di], dx
0004: imul sp, word ptr [bp + 0x73], 0x2e
0008: popal 
000a: je 0xc
000c: add al, byte ptr [bx + di]
000e: add word ptr [bx + si], ax
0010: add ah, al
0012: add byte ptr [bx + si + 0xb], al
0015: lock or word ptr [bx + si], ax
0018: adc al, byte ptr [bx + si]
001a: add al, byte ptr [bx + si]
001c: add byte ptr [bx + si], al
001e: add byte ptr [bx + si], al
0020: add byte ptr [bx + si], al
0022: add byte ptr [bx + si], al
0024: add byte ptr [bx + si], al
0026: sub bp, dx
0028: mov ch, 0xe7
002b: dec si
002c: dec di
002d: and byte ptr [bp + 0x41], cl
0030: dec bp
0031: inc bp
0032: and byte ptr [bx + si], ah
0034: and byte ptr [bx + si], ah
0036: inc si
0037: inc cx
0038: push sp
0039: xor word ptr [bp + si], si
003b: and byte ptr [bx + si], ah
003d: and byte ptr [0xbe1f], cl
0041: pop bx
0042: jl 0xfffffff0
0044: and al, al
0046: je 0x53
0048: push si
0049: mov ah, 0xe
004b: mov bx, 7
004e: int 0x10
0050: pop si
0051: jmp 0x43
0053: xor ah, ah
0055: int 0x16
0057: int 0x19
0059: jmp 0x59
005b: push sp
005c: push 0x7369
005f: and byte ptr [bx + di + 0x73], ch
0062: and byte ptr [bp + 0x6f], ch
0065: je 0x87
0067: popaw 
0068: and byte ptr [bp + si + 0x6f], ah
006b: outsw dx, word ptr [si]
006c: je 0xcf
006e: bound bp, dword ptr [si + 0x65]
0071: and byte ptr [si + 0x69], ah
0074: jae 0xe1
0076: and byte ptr cs:[bx + si], ah
0079: push ax
007a: insb byte ptr es:[di], dx
007b: popaw 
007d: jae 0xe4
007f: and byte ptr [bx + di + 0x6e], ch
0082: jae 0xe9
0084: jb 0xfa
0086: and byte ptr [bx + di + 0x20], ah
0089: bound bp, dword ptr [bx + 0x6f]
008c: je 0xef
008e: bound bp, dword ptr [si + 0x65]
0091: and byte ptr [bp + 0x6c], ah
0094: outsw dx, word ptr [si]
0095: jo 0x107
0097: jns 0xb9
0099: popaw 
009a: outsb dx, byte ptr [si]
009b: or ax, 0x700a
009f: jb 0x106
00a1: jae 0x116
00a3: and byte ptr [bx + di + 0x6e], ah
00a6: jns 0xc8
00a8: imul sp, word ptr [di + 0x79], 0x20
00ac: je 0x11d
00ae: and byte ptr [si + 0x72], dh
00b1: jns 0xd3
00b3: popaw 
00b4: popaw 
00b6: imul bp, word ptr [bp + 0x20], 0x2e2e
00bb: and byte ptr cs:[di], cl
00be: or al, byte ptr [bx + si]
00c0: add byte ptr [bx + si], al
00c2: add byte ptr [bx + si], al
00c4: add byte ptr [bx + si], al
00c6: add byte ptr [bx + si], al
00c8: add byte ptr [bx + si], al
00ca: add byte ptr [bx + si], al
00cc: add byte ptr [bx + si], al
00ce: add byte ptr [bx + si], al
00d0: add byte ptr [bx + si], al
00d2: add byte ptr [bx + si], al
00d4: add byte ptr [bx + si], al
00d6: add byte ptr [bx + si], al
00d8: add byte ptr [bx + si], al
00da: add byte ptr [bx + si], al
00dc: add byte ptr [bx + si], al
00de: add byte ptr [bx + si], al
00e0: add byte ptr [bx + si], al
00e2: add byte ptr [bx + si], al
00e4: add byte ptr [bx + si], al
00e6: add byte ptr [bx + si], al
00e8: add byte ptr [bx + si], al
00ea: add byte ptr [bx + si], al
00ec: add byte ptr [bx + si], al
00ee: add byte ptr [bx + si], al
00f0: add byte ptr [bx + si], al
00f2: add byte ptr [bx + si], al
00f4: add byte ptr [bx + si], al
00f6: add byte ptr [bx + si], al
00f8: add byte ptr [bx + si], al
00fa: add byte ptr [bx + si], al
00fc: add byte ptr [bx + si], al
00fe: add byte ptr [bx + si], al
0100: add byte ptr [bx + si], al
0102: add byte ptr [bx + si], al
0104: add byte ptr [bx + si], al
0106: add byte ptr [bx + si], al
0108: add byte ptr [bx + si], al
010a: add byte ptr [bx + si], al
010c: add byte ptr [bx + si], al
010e: add byte ptr [bx + si], al
0110: add byte ptr [bx + si], al
0112: add byte ptr [bx + si], al
0114: add byte ptr [bx + si], al
0116: add byte ptr [bx + si], al
0118: add byte ptr [bx + si], al
011a: add byte ptr [bx + si], al
011c: add byte ptr [bx + si], al
011e: add byte ptr [bx + si], al
0120: add byte ptr [bx + si], al
0122: add byte ptr [bx + si], al
0124: add byte ptr [bx + si], al
0126: add byte ptr [bx + si], al
0128: add byte ptr [bx + si], al
012a: add byte ptr [bx + si], al
012c: add byte ptr [bx + si], al
012e: add byte ptr [bx + si], al
0130: add byte ptr [bx + si], al
0132: add byte ptr [bx + si], al
0134: add byte ptr [bx + si], al
0136: add byte ptr [bx + si], al
0138: add byte ptr [bx + si], al
013a: add byte ptr [bx + si], al
013c: add byte ptr [bx + si], al
013e: add byte ptr [bx + si], al
0140: add byte ptr [bx + si], al
0142: add byte ptr [bx + si], al
0144: add byte ptr [bx + si], al
0146: add byte ptr [bx + si], al
0148: add byte ptr [bx + si], al
014a: add byte ptr [bx + si], al
014c: add byte ptr [bx + si], al
014e: add byte ptr [bx + si], al
0150: add byte ptr [bx + si], al
0152: add byte ptr [bx + si], al
0154: add byte ptr [bx + si], al
0156: add byte ptr [bx + si], al
0158: add byte ptr [bx + si], al
015a: add byte ptr [bx + si], al
015c: add byte ptr [bx + si], al
015e: add byte ptr [bx + si], al
0160: add byte ptr [bx + si], al
0162: add byte ptr [bx + si], al
0164: add byte ptr [bx + si], al
0166: add byte ptr [bx + si], al
0168: add byte ptr [bx + si], al
016a: add byte ptr [bx + si], al
016c: add byte ptr [bx + si], al
016e: add byte ptr [bx + si], al
0170: add byte ptr [bx + si], al
0172: add byte ptr [bx + si], al
0174: add byte ptr [bx + si], al
0176: add byte ptr [bx + si], al
0178: add byte ptr [bx + si], al
017a: add byte ptr [bx + si], al
017c: add byte ptr [bx + si], al
017e: add byte ptr [bx + si], al
0180: add byte ptr [bx + si], al
0182: add byte ptr [bx + si], al
0184: add byte ptr [bx + si], al
0186: add byte ptr [bx + si], al
0188: add byte ptr [bx + si], al
018a: add byte ptr [bx + si], al
018c: add byte ptr [bx + si], al
018e: add byte ptr [bx + si], al
0190: add byte ptr [bx + si], al
0192: add byte ptr [bx + si], al
0194: add byte ptr [bx + si], al
0196: add byte ptr [bx + si], al
0198: add byte ptr [bx + si], al
019a: add byte ptr [bx + si], al
019c: add byte ptr [bx + si], al
019e: add byte ptr [bx + si], al
01a0: add byte ptr [bx + si], al
01a2: add byte ptr [bx + si], al
01a4: add byte ptr [bx + si], al
01a6: add byte ptr [bx + si], al
01a8: add byte ptr [bx + si], al
01aa: add byte ptr [bx + si], al
01ac: add byte ptr [bx + si], al
01ae: add byte ptr [bx + si], al
01b0: add byte ptr [bx + si], al
01b2: add byte ptr [bx + si], al
01b4: add byte ptr [bx + si], al
01b6: add byte ptr [bx + si], al
01b8: add byte ptr [bx + si], al
01ba: add byte ptr [bx + si], al
01bc: add byte ptr [bx + si], al
01be: add byte ptr [bx + si], al
01c0: add byte ptr [bx + si], al
01c2: add byte ptr [bx + si], al
01c4: add byte ptr [bx + si], al
01c6: add byte ptr [bx + si], al
01c8: add byte ptr [bx + si], al
01ca: add byte ptr [bx + si], al
01cc: add byte ptr [bx + si], al
01ce: add byte ptr [bx + si], al
01d0: add byte ptr [bx + si], al
01d2: add byte ptr [bx + si], al
01d4: add byte ptr [bx + si], al
01d6: add byte ptr [bx + si], al
01d8: add byte ptr [bx + si], al
01da: add byte ptr [bx + si], al
01dc: add byte ptr [bx + si], al
01de: add byte ptr [bx + si], al
01e0: add byte ptr [bx + si], al
01e2: add byte ptr [bx + si], al
01e4: add byte ptr [bx + si], al
01e6: add byte ptr [bx + si], al
01e8: add byte ptr [bx + si], al
01ea: add byte ptr [bx + si], al
01ec: add byte ptr [bx + si], al
01ee: add byte ptr [bx + si], al
01f0: add byte ptr [bx + si], al
01f2: add byte ptr [bx + si], al
01f4: add byte ptr [bx + si], al
01f6: add byte ptr [bx + si], al
01f8: add byte ptr [bx + si], al
01fa: add byte ptr [bx + si], al
01fc: add byte ptr [bx + si], al
01fe: push bp
01ff: stosb byte ptr es:[di], al
