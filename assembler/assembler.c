#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

// Functia care intoarce opcode-ul pe 6 biti
uint16_t get_opcode(const char* op) {
    // 00xxxx - Memorie
    if (strcmp(op, "LDR") == 0)  return 0x00;
    if (strcmp(op, "STR") == 0) return 0x01;
    if (strcmp(op, "MOV") == 0)   return 0x02;
    
    // 01xxxx - Aritmetice
    if (strcmp(op, "ADD") == 0) return 0x10;
    if (strcmp(op, "SUB") == 0) return 0x11;
    if (strcmp(op, "MUL") == 0) return 0x12;
    if (strcmp(op, "DIV") == 0) return 0x13;
    if (strcmp(op, "MOD") == 0) return 0x14;
    if (strcmp(op, "INC") == 0) return 0x15;
    if (strcmp(op, "DEC") == 0) return 0x16;
    if (strcmp(op, "CMP") == 0) return 0x17;
    
    // 10xxxx - Logice si Shiftari
    if (strcmp(op, "AND") == 0) return 0x20;
    if (strcmp(op, "OR") == 0)  return 0x21;
    if (strcmp(op, "XOR") == 0) return 0x22;
    if (strcmp(op, "NOT") == 0) return 0x23;
    if (strcmp(op, "TST") == 0) return 0x24;
    if (strcmp(op, "LSL") == 0) return 0x25;
    if (strcmp(op, "LSR") == 0) return 0x26;
    if (strcmp(op, "RSL") == 0) return 0x27;
    if (strcmp(op, "RSR") == 0) return 0x28;
    
    // 11xxxx - Control Flow
    if (strcmp(op, "BRZ") == 0) return 0x30;
    if (strcmp(op, "BRN") == 0) return 0x31;
    if (strcmp(op, "BRC") == 0) return 0x32;
    if (strcmp(op, "BRO") == 0) return 0x33;
    if (strcmp(op, "BRA") == 0) return 0x34;
    if (strcmp(op, "JMP") == 0) return 0x35;
    if (strcmp(op, "RET") == 0) return 0x36;
    
    return 0xFFFF;
}

int main() {
    //FILE *input = fopen("cod.txt", "r");
    FILE *input = fopen("test1_paritate.txt", "r");
    //FILE *input = fopen("test1_bucla.txt", "r");
    //FILE *input = fopen("test1_matematica.txt", "r");
    FILE *output = fopen("memorie.hex", "w");

    if (!input) {
        printf("Eroare: Nu am putut deschide fisierul cod.txt\n");
        return 1;
    }
    if (!output) {
        printf("Eroare: Nu am putut crea fisierul memorie.hex\n");
        fclose(input);
        return 1;
    }

    char line[256];
    
    while (fgets(line, sizeof(line), input)) {
        // Ignoram liniile goale sau comentariile (care incep cu ';')
        if (line[0] == '\n' || line[0] == '\r' || line[0] == ';') {
            continue;
        }

        char operatie[20] = {0};
        char arg1[20] = {0};
        int valoare = 0;
        uint16_t masina = 0;

        // Parsam maxim 3 cuvinte/numere pe linie
        int items = sscanf(line, "%19s %19s %d", operatie, arg1, &valoare);

        if (items < 1) continue; 

        // Verificam daca primul token citit e comentariu aflat pe aceeasi linie (in loc de inceput de rand)
        if (operatie[0] == ';') continue; 

        uint16_t opcode = get_opcode(operatie);
        if (opcode == 0xFFFF) {
            printf("Ignorat / Eroare (Opcode necunoscut): %s\n", operatie);
            continue;
        }

        // 1. Instructiuni de salt si proceduri (10 biti adresa)
        if (opcode >= 0x30 && opcode <= 0x35) {
            int adresa = atoi(arg1);
            masina = (opcode << 10) | (adresa & 0x03FF);
        }
        // 2. Return din procedura (fara argumente suplimentare)
        else if (opcode == 0x36) {
            masina = (opcode << 10);
        }
        // 3. Memorie, Aritmetice si Logice (1 bit registru, 9 biti valoare imediata)
        else {
            int len = strlen(arg1);
            if (len > 0 && arg1[len - 1] == ',') {
                arg1[len - 1] = '\0';
            }

            // Validare stricta a registrului: acceptam doar X sau Y.
            if (strcmp(arg1, "X") != 0 && strcmp(arg1, "Y") != 0 && strlen(arg1) > 0) {
                 printf("Eroare sintaxa la registrul '%s'. Folositi doar 'X' sau 'Y'. Linie ignorata.\n", arg1);
                 continue;
            }

            uint16_t reg_bit = (strcmp(arg1, "Y") == 0) ? 1 : 0;
            
            masina = (opcode << 10) | (reg_bit << 9) | (valoare & 0x01FF);
        }

        line[strcspn(line, "\r\n")] = 0; // Curatam linia de enter-uri pt afisare frumoasa in consola
        printf("%-25s -> 0x%04X\n", line, masina);
        
        fprintf(output, "%04X\n", masina);
    }

    fclose(input);
    fclose(output);
    printf("\nGenerare completa in memorie.hex!\n");

    return 0;
}
