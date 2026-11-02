Procesor General Purpose (16-bit)

Descriere proiect
Acest proiect reprezintă implementarea în echipă a unui procesor de uz general (GP) pe 16 biți, extins cu un co-procesor (ASIP) pentru sarcini specifice. Procesorul execută un set propriu de instrucțiuni (ISA) de 16 biți, care va fi tradus în cod mașină prin intermediul unui assembler și rulat din memorie.

Specificații Hardware

Dimensiune instrucțiune și cuvânt: 16-bit

Acumulator (A): 16-bit

Registre de uz general: X și Y (16-bit)

Program Counter (PC) și Stack Pointer (SP): 16-bit (stiva crește invers)

Flag Register: 4-bit (Zero, Negative, Carry, Overflow). Doar instrucțiunile aritmetice și logice modifică flag-urile.

Setul de instrucțiuni (ISA)

00xxxx - Memorie și Transfer
LDR (000000) - Încarcă date în X sau Y
STR (000001) - Salvează din X/Y în memorie
MOV (000010) - Transferă date

01xxxx - Aritmetică
ADD (010000) - Adunare
SUB (010001) - Scădere
MUL (010010) - Înmulțire
DIV (010011) - Împărțire
MOD (010100) - Rest
INC (010101) - Incrementare
DEC (010110) - Decrementare
CMP (010111) - Comparare (actualizează flag-urile)

10xxxx - Logică și Shiftări
AND (100000) - ȘI logic
OR (100001) - SAU logic
XOR (100010) - SAU exclusiv
NOT (100011) - Negare
TST (100100) - Testare biți
LSL (100101) - Logical Shift Left
LSR (100110) - Logical Shift Right
RSL (100111) - Rotate Shift Left
RSR (101000) - Rotate Shift Right

11xxxx - Salturi și Proceduri
BRZ (110000) - Salt dacă e Zero
BRN (110001) - Salt dacă e Negativ
BRC (110010) - Salt dacă e Carry
BRO (110011) - Salt dacă e Overflow
BRA (110100) - Salt necondiționat
JMP (110101) - Apel procedură (pune PC pe stivă, parametrii trec prin stivă)
RET (110110) - Return (scoate PC de pe stivă, valoarea returnată trece prin stivă)


// DE ADAUGAT FCT DE HALT, MOV CU 2 REG, DE VZ DC FIECARE INSTR DA 2 OUTPUTURI IN SIM