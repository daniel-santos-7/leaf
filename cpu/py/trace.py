import sys
import csv

csv_file = sys.argv[1]

def clk_value(row):
    return int(row['clk'], 2)

def rst_value(row):
    return int(row['reset'], 2)

def flush_value(row):
    return int(row['flush_reg'], 2)

def pc_value(row):
    return 0 if row['pc_reg[31:0]'] == 'uuuuuuuu' else int(row['pc_reg[31:0]'], 16)

def instr_value(row):
    return 0 if row['instr_reg[31:0]'] == 'uuuuuuuu' else int(row['instr_reg[31:0]'], 16)

def reg_values(row):
    regs = []
    for i in range(32):
        reg_name = f'regs[{i}][31:0]'
        if row[reg_name] == 'uuuuuuuu':
            regs.append(0)
        else:
            regs.append(int(row[reg_name], 16))
    return regs

def format_regs(regs):
    return ' '.join(f'x{i}: {reg:08x}' for i, reg in enumerate(regs))

with open(csv_file, newline='', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    previous_row = None
    for row in reader:
        if clk_value(row) == 1 and rst_value(row) == 0 and flush_value(row) == 0:
            if previous_row is not None:
                pc = pc_value(previous_row)
                instr = instr_value(previous_row)
                regs = reg_values(row)
                if not (pc == 0 and instr == 0):
                    print(f"{pc:08x} {instr:08x} {format_regs(regs)}")
            previous_row = row