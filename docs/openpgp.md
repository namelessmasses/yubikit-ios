# OpenPGP SmartCard Implementation

Based on the [Functional Specification of the OpenPGP Appliation on ISO Smart Card Operating Systems v3.4.1](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) (_The Functional Specification_).

# Nomenclature

This document assumes a familiarity with [_The Specification_](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) and as such uses terms and abbreviations from [_The Specification_](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) without further explanation. 

# ASN.1 BER-TLV

## size

`sz = [81 | [82 xx]] xx` is the number of bytes that follow the tag and length bytes.

# Minimal Use-Cases

- Required to achieve minimal OpenPGP operations. 
- Based on the basic flow charts in section 9 of _The Functional Specification_.
- Do not support logical channels.
  - Uses `CLA=X0` for all commands.

## Interpreting SW1/SW2

The implementation shall correctly interpret the `SW1` and `SW2` bytes in order to correctly process responses from the card.

## Application Selection

| Command  | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`              | `Le` |
| ---      | ---   | ---   | ---  | ---  | ---  | ---                 | ---  |
| `SELECT` | `00`  | `A4`  | `04` | `00` | `06` | `D2 76 00 01 24 01` | `00` |

| Response Body | Tag  | Description  |
| ---           | ---  | ---   |
| `FCI`         | `6F` | When `P2=00` none returned; `SW1/SW2=9000` |
| `FCP`         | `62` | When `P2=04` none returned; `SW1/SW2=6D00` |
| `FMD`         | `64` | When `P2=08` none returned; `SW1/SW2=6D00` |

| Status   | `SW1` | `SW2` | Description  |
| ---      | ---   | ---   | ---          |
|          | `90`  | `00`  | Success - no other information    |
|          | `62`  | `83`  | Selceted file invalidated         |
|          |       | `84`  | FCI not formatted according to ISO 7816-4 |
|          | `6A`  | `81`  | Function not supported |
|          |       | `82`  | File not found |
|          |       | `86`  | Incorrect parameters P1-P2 |
|          |       | `87`  | Lc inconsistent with P1-P2 |
|          | `6D`  | `00`  | Instruction code not supported or invalid |


## Reading main DOs

## PW Authentication

The following minimal use-cases require authentication of `PW1` or `PW3`. Due to likelihood that YubiKeys are shipped with KDF enabled - I do not recall enabling it and it's enabled on both my primary (5Ci) and backup keys (5 NFC) - the initial use-cases shall support authentication of `PW1` and `PW3` using both plain format as S2K depending on the key's KDF configuration.

## Compute Digital Signature

## Decrypt Message

# Further Use-Cases

## Reading optional DOs

## Generate Private Key

## Client/Server Authentication

