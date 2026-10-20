#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path

# Espino Core utiliza RV32E: registros x0-x15.
# La RAM configurada en pochoco_soc tiene 512 palabras.
MAX_WORDS = 512

ALIASES = {
    "zero": 0,
    "ra": 1,
    "sp": 2,
    "gp": 3,
    "tp": 4,
    "t0": 5,
    "t1": 6,
    "t2": 7,
    "s0": 8,
    "fp": 8,
    "s1": 9,
    "a0": 10,
    "a1": 11,
    "a2": 12,
    "a3": 13,
    "a4": 14,
    "a5": 15,
}

R_OPS = {
    "add": (0b000, 0b0000000),
    "sub": (0b000, 0b0100000),
    "slt": (0b010, 0b0000000),
    "sltu": (0b011, 0b0000000),
    "xor": (0b100, 0b0000000),
    "or": (0b110, 0b0000000),
    "and": (0b111, 0b0000000),
}

I_OPS = {
    "addi": 0b000,
    "slti": 0b010,
    "sltiu": 0b011,
    "xori": 0b100,
    "ori": 0b110,
    "andi": 0b111,
}

BRANCH_OPS = {
    "beq": 0b000,
    "bne": 0b001,
    "blt": 0b100,
    "bge": 0b101,
    "bltu": 0b110,
    "bgeu": 0b111,
}

LOAD_OPS = {
    "lb": 0b000,
    "lh": 0b001,
    "lw": 0b010,
    "lbu": 0b100,
    "lhu": 0b101,
}

STORE_OPS = {
    "sb": 0b000,
    "sh": 0b001,
    "sw": 0b010,
}


class AssemblyError(Exception):
    pass


def register(name):
    name = name.lower()

    if name in ALIASES:
        return ALIASES[name]

    if re.fullmatch(r"x\d+", name):
        number = int(name[1:])

        if 0 <= number <= 15:
            return number

    raise AssemblyError(f"Registro inválido para RV32E: {name}")


def number(value, constants=None):
    constants = constants or {}

    if value in constants:
        return constants[value]

    try:
        return int(value, 0)
    except ValueError:
        raise AssemblyError(f"Valor inválido: {value}")


def check_range(value, bits, signed=True):
    if signed:
        minimum = -(1 << (bits - 1))
        maximum = (1 << (bits - 1)) - 1
    else:
        minimum = 0
        maximum = (1 << bits) - 1

    if not minimum <= value <= maximum:
        raise AssemblyError(
            f"Valor {value} fuera de rango de {bits} bits"
        )

    return value & ((1 << bits) - 1)


def encode_r(rd, rs1, rs2, funct3, funct7):
    return (
        (funct7 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | 0x33
    )


def encode_i(rd, rs1, imm, funct3, opcode):
    imm = check_range(imm, 12)

    return (
        (imm << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | opcode
    )


def encode_s(rs2, rs1, imm, funct3):
    imm = check_range(imm, 12)

    return (
        ((imm >> 5) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | ((imm & 0x1F) << 7)
        | 0x23
    )


def encode_b(rs1, rs2, offset, funct3):
    if offset % 2:
        raise AssemblyError("Salto branch desalineado")

    imm = check_range(offset, 13)

    return (
        (((imm >> 12) & 1) << 31)
        | (((imm >> 5) & 0x3F) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (((imm >> 1) & 0xF) << 8)
        | (((imm >> 11) & 1) << 7)
        | 0x63
    )


def encode_u(rd, imm, opcode):
    return (
        (imm & 0xFFFFF000)
        | (rd << 7)
        | opcode
    )


def encode_j(rd, offset):
    if offset % 2:
        raise AssemblyError("Salto JAL desalineado")

    imm = check_range(offset, 21)

    return (
        (((imm >> 20) & 1) << 31)
        | (((imm >> 1) & 0x3FF) << 21)
        | (((imm >> 11) & 1) << 20)
        | (((imm >> 12) & 0xFF) << 12)
        | (rd << 7)
        | 0x6F
    )


def parse_memory(operand, constants):
    match = re.fullmatch(
        r"(.+)\(([^()]+)\)",
        operand.replace(" ", "")
    )

    if not match:
        raise AssemblyError(
            f"Operando de memoria inválido: {operand}"
        )

    imm = number(match.group(1), constants)
    rs1 = register(match.group(2))

    return imm, rs1


def parse_line(line):
    line = line.split("#", 1)[0]
    line = line.split("//", 1)[0]
    line = line.strip()

    if not line:
        return None

    parts = re.split(r"[\s,]+", line, maxsplit=1)

    op = parts[0].lower()

    args = []

    if len(parts) > 1:
        args = [
            arg.strip()
            for arg in parts[1].split(",")
        ]

    return op, args


def instruction_size(op, args, constants):
    if op == "li":
        if len(args) != 2:
            raise AssemblyError("li requiere 2 operandos")

        value = number(args[1], constants)

        if not -(1 << 31) <= value <= (1 << 32) - 1:
            raise AssemblyError("Constante li fuera de 32 bits")

        signed = value if value < (1 << 31) else value - (1 << 32)

        return 1 if -2048 <= signed <= 2047 else 2

    return 1


def first_pass(lines):
    labels = {}
    constants = {}
    instructions = []

    pc = 0

    for line_number, original in enumerate(lines, 1):
        line = original.split("#", 1)[0]
        line = line.split("//", 1)[0].strip()

        if not line:
            continue

        try:
            if line.startswith(".equ "):
                definition = line[5:].split(",", 1)

                if len(definition) != 2:
                    raise AssemblyError(".equ requiere nombre y valor")

                name = definition[0].strip()
                value = number(definition[1].strip(), constants)

                if name in constants or name in labels:
                    raise AssemblyError(f"Símbolo duplicado: {name}")

                constants[name] = value
                continue

            while ":" in line:
                match = re.match(
                    r"^([A-Za-z_][\w]*):",
                    line
                )

                if not match:
                    break

                label = match.group(1)

                if label in labels or label in constants:
                    raise AssemblyError(f"Etiqueta duplicada: {label}")

                labels[label] = pc

                line = line[match.end():].strip()

                if not line:
                    break

            if not line:
                continue

            if line.startswith("."):
                if line in (".text", ".globl _start"):
                    continue

                raise AssemblyError(
                    f"Directiva no soportada: {line}"
                )

            parsed = parse_line(line)

            if parsed is None:
                continue

            op, args = parsed

            instructions.append(
                (line_number, pc, op, args)
            )

            pc += instruction_size(op, args, constants) * 4

        except AssemblyError as error:
            raise AssemblyError(
                f"Línea {line_number}: {error}"
            )

    if pc // 4 > MAX_WORDS:
        raise AssemblyError(
            f"Programa demasiado grande: {pc // 4} palabras; "
            f"máximo {MAX_WORDS}"
        )

    return labels, constants, instructions


def assemble_instruction(op, args, pc, labels, constants):
    def require(count):
        if len(args) != count:
            raise AssemblyError(
                f"{op} requiere {count} operandos; "
                f"recibidos {len(args)}"
            )

    def imm(value):
        return number(value, constants)

    def target(value):
        if value in labels:
            return labels[value] - pc

        return imm(value)

    if op == "nop":
        require(0)
        return [encode_i(0, 0, 0, 0, 0x13)]

    if op == "mv":
        require(2)
        return [
            encode_i(
                register(args[0]),
                register(args[1]),
                0,
                0,
                0x13
            )
        ]

    if op == "j":
        require(1)
        return [encode_j(0, target(args[0]))]

    if op == "ret":
        require(0)
        return [encode_i(0, 1, 0, 0, 0x67)]

    if op == "li":
        require(2)

        rd = register(args[0])
        value = imm(args[1])

        if not -(1 << 31) <= value <= (1 << 32) - 1:
            raise AssemblyError("Constante li fuera de 32 bits")

        value &= 0xFFFFFFFF

        signed = value if value < 0x80000000 else value - 0x100000000

        if -2048 <= signed <= 2047:
            return [encode_i(rd, 0, signed, 0, 0x13)]

        upper = ((value + 0x800) >> 12) & 0xFFFFF
        lower = value & 0xFFF

        if lower >= 0x800:
            lower -= 0x1000

        return [
            encode_u(rd, upper << 12, 0x37),
            encode_i(rd, rd, lower, 0, 0x13)
        ]

    if op in R_OPS:
        require(3)

        funct3, funct7 = R_OPS[op]

        return [
            encode_r(
                register(args[0]),
                register(args[1]),
                register(args[2]),
                funct3,
                funct7
            )
        ]

    if op in I_OPS:
        require(3)

        return [
            encode_i(
                register(args[0]),
                register(args[1]),
                imm(args[2]),
                I_OPS[op],
                0x13
            )
        ]

    if op in LOAD_OPS:
        require(2)

        offset, rs1 = parse_memory(args[1], constants)

        return [
            encode_i(
                register(args[0]),
                rs1,
                offset,
                LOAD_OPS[op],
                0x03
            )
        ]

    if op in STORE_OPS:
        require(2)

        offset, rs1 = parse_memory(args[1], constants)

        return [
            encode_s(
                register(args[0]),
                rs1,
                offset,
                STORE_OPS[op]
            )
        ]

    if op in BRANCH_OPS:
        require(3)

        return [
            encode_b(
                register(args[0]),
                register(args[1]),
                target(args[2]),
                BRANCH_OPS[op]
            )
        ]

    if op == "lui":
        require(2)

        value = imm(args[1])

        if not 0 <= value <= 0xFFFFF:
            raise AssemblyError("Inmediato LUI fuera de rango")

        return [
            encode_u(
                register(args[0]),
                value << 12,
                0x37
            )
        ]

    if op == "auipc":
        require(2)

        value = imm(args[1])

        if not 0 <= value <= 0xFFFFF:
            raise AssemblyError("Inmediato AUIPC fuera de rango")

        return [
            encode_u(
                register(args[0]),
                value << 12,
                0x17
            )
        ]

    if op == "jal":
        if len(args) == 1:
            return [encode_j(1, target(args[0]))]

        require(2)

        return [
            encode_j(
                register(args[0]),
                target(args[1])
            )
        ]

    if op == "jalr":
        require(3)

        return [
            encode_i(
                register(args[0]),
                register(args[1]),
                imm(args[2]),
                0,
                0x67
            )
        ]

    raise AssemblyError(
        f"Instrucción no soportada: {op}"
    )


def assemble(source):
    lines = source.splitlines()

    labels, constants, instructions = first_pass(lines)

    words = []

    for line_number, pc, op, args in instructions:
        try:
            encoded = assemble_instruction(
                op,
                args,
                pc,
                labels,
                constants
            )

            words.extend(encoded)

        except AssemblyError as error:
            raise AssemblyError(
                f"Línea {line_number}: {error}"
            )

    if len(words) > MAX_WORDS:
        raise AssemblyError("Programa excede la RAM")

    return words


def main():
    parser = argparse.ArgumentParser(
        description="Assembler RV32E para Pochoco SoC"
    )

    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)

    args = parser.parse_args()

    try:
        source = args.input.read_text(encoding="utf-8")
        words = assemble(source)

        args.output.parent.mkdir(
            parents=True,
            exist_ok=True
        )

        args.output.write_text(
            "".join(f"{word:08x}\n" for word in words),
            encoding="utf-8"
        )

        print(
            f"OK: {len(words)} instrucciones generadas "
            f"en {args.output}"
        )

    except (AssemblyError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
