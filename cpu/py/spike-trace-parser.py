import sys
import re
import json

file_path = sys.argv[1]

def parse_line(line):
    values = {
        "hart": None,
        "priv": None,
        "pc": None,
        "inst": None,
        "reg_writes": [],
        "csr_writes": [],
        "mem_accesses": []
    }

    parts = line.strip().split()
    size = len(parts)

    if size < 5: raise ValueError("Invalid line format")
    if parts[0] != "core": raise ValueError("Invalid line format")

    values["hart"] = parts[1].rstrip(":")
    values["priv"] = parts[2]
    values["pc"] = parts[3]
    values["inst"] = parts[4].lstrip('(').rstrip(')')

    if size == 5: return values
    i = 5
    while i < size:
        if parts[i].startswith("x"):
            values["reg_writes"].append({ "reg": parts[i], "value": parts[i+1] })
            i += 2
            continue
        elif parts[i].startswith("c"):
            values["csr_writes"].append({ "reg": parts[i], "value": parts[i+1] })
            i += 2
            continue
        elif parts[i].startswith("mem"):
            if (i+2) >= size or parts[i+2].startswith("x") or parts[i+2].startswith("c"):
                values["mem_accesses"].append({ "type": "load", "addr": parts[i+1], "value": None })
                i += 2
                continue
            else:
                values["mem_accesses"].append({ "type": "store", "addr": parts[i+1], "value": parts[i+2] })
                i += 3
                continue
            continue
        else:
            raise ValueError("Invalid line format")

    return values

values = []
with open(file_path, "r", encoding="utf-8") as file:
    for line in file:
        values.append(parse_line(line))

print(json.dumps(values))
