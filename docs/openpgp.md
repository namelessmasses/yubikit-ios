# OpenPGP SmartCard Implementation

Based on the [Functional Specification of the OpenPGP Application on ISO Smart Card Operating Systems v3.4.1](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) (_The Functional Specification_).

---

- [OpenPGP SmartCard Implementation](#openpgp-smartcard-implementation)
- [Nomenclature](#nomenclature)
- [ASN.1 BER-TLV](#asn1-ber-tlv)
  - [size](#size)
- [Interpreting SW1/SW2](#interpreting-sw1sw2)
- [Minimal Use-Cases](#minimal-use-cases)
  - [Application Selection](#application-selection)
  - [Reading main DOs](#reading-main-dos)
    - [Application Related Data - Tag `6E`](#application-related-data---tag-6e)
    - [Card Capabilities - Historical bytes - Tag `73`](#card-capabilities---historical-bytes---tag-73)
    - [Card service data - Historical bytes - Tag `31`](#card-service-data---historical-bytes---tag-31)
    - [Extended legnth information - Tag `7F66`](#extended-legnth-information---tag-7f66)
      - [Single DO](#single-do)
    - [General Feature Management Data - Tag `7F74`](#general-feature-management-data---tag-7f74)
      - [Single DO](#single-do-1)
  - [PW Authentication](#pw-authentication)
    - [Verification](#verification)
  - [Compute Digital Signature](#compute-digital-signature)
  - [Decrypt Message](#decrypt-message)
    - [RSA](#rsa)
- [Expanded Use-Cases](#expanded-use-cases)
  - [PW Authentication](#pw-authentication-1)
    - [Interpreting Extended Capabilities for KDF capabilities](#interpreting-extended-capabilities-for-kdf-capabilities)
    - [KDF-DO - Tag `F9`](#kdf-do---tag-f9)
    - [PW Authentication using OpenPGP S2K Function](#pw-authentication-using-openpgp-s2k-function)
  - [Extended Length APDUs](#extended-length-apdus)
  - [Reading optional DOs](#reading-optional-dos)
    - [Cardholder related data - Tag `65`](#cardholder-related-data---tag-65)
    - [Public keys URL - Tag `5F50`](#public-keys-url---tag-5f50)
  - [Generate Private Key](#generate-private-key)
  - [Client/Server Authentication](#clientserver-authentication)


# Nomenclature

This document assumes a familiarity with [_The Specification_](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) and as such uses terms and abbreviations from [_The Specification_](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) without further explanation. 

---

# ASN.1 BER-TLV

## size

`sz = [81 | [82 xx]] xx` is the number of bytes that follow the tag and length bytes.

---

# Interpreting SW1/SW2

The implementation shall correctly interpret the `SW1` and `SW2` bytes in order to correctly process responses from the card.

---

# Minimal Use-Cases

- Required to achieve minimally functional OpenPGP operations. 
- Based on the basic flow charts in section 9 of _The Functional Specification_.
- Do not support logical channels.
  - Uses `CLA=X0` for all commands.
- Do not support extended length APDUs.
- Do not support KDF.

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

### Application Related Data - Tag `6E`

| Command    | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data` | `Le` |
| ---        | ---   | ---   | ---  | ---  | ---  | ---    | ---  |
| `GET DATA` | `00`  | `CA`  | `00` | `6E` | -    | -      | `00` |

| Response Body                       | Tag    | Size | Description |
| ---                                 | ---    | ---  | ---         |
| Application related data            | `6E`   | `sz` | Followed by any of, |
|                                     |        |      | |
| Application identifier (AID)        | `4F`   | `sz` | Full application identifier.    |
| Historical bytes                    | `5F52` | `sz` | First byte is _category indicator byte_; the OpenPGP application assumes `00`. Includes card service data (`31`) and card capabilities (`73`). Last 3 bytes are status indicator byte, and processing status bytes. |
| Extended length information         | `7F66` | `08` | |
| General feature management data     | `7F74` | `03` | |
| Discretionary data objects          | `73`   | `sz` | Followed by any of, |
|                                     |        |      | |
| Extended Capabilities               | `C0`   | `0A` | |
| Algorithm attributes signature      | `C1`   | `sz` | |
| Algorithm attributes decryption     | `C2`   | `sz` | |
| Algorithm attributes authentication | `C3`   | `sz` | |
| PW status bytes                     | `C4`   | `07` | |
| Fingerprints                        | `C5`   | `3C` | 3x20 bytes; signature, decryption, authentication in that order. Zero bytes indicates not present. |
| CA-Fingerprints                     | `C6`   | `3C` | 3x20 bytes; signature, decryption, authentication in that order. Zero bytes indicates not present. |
| Key generation date                 | `CD`   | `0C` | 3x4 bytes; UNIX epoch time. Zero bytes indicates not specified. |
| Key information                     | `DE`   | `06` | 3x2 bytes; `<key ref> <status>` |
| UIF signature                       | `D6`   | `02` | `{00=disabled,01=enabled,02=permanently enabled,03/04=reserved} {20=button/keypad}` |
| UIF decryption                      | `D7`   | `02` | `{00=disabled,01=enabled,02=permanently enabled,03/04=reserved} {20=button/keypad}` |
| UIF authentication                  | `D8`   | `02` | `{00=disabled,01=enabled,02=permanently enabled,03/04=reserved} {20=button/keypad}` |
| Reserved UIF attestation            | `D9`   | `02` | Reserved |

### Card Capabilities - Historical bytes - Tag `73`

- Extended `Lc` and `Le` supported.
- Extended length APDUs supported.

### Card service data - Historical bytes - Tag `31`

- Application selection by full DF name supported.
- Application selection by partial DF name supported.
- DOs in `EF.ATR/INFO`.
  - 1 if Extended length supported.
- `EF.DIR` and `EF.ATR/INFO` access services by the `GET DATA` command (`BER-TLV`).
  - Should be `010` if extended length supported.
- Card with(out) `MF`.

### Extended legnth information - Tag `7F66`

#### Single DO

- In the case that it is not provided in the `6E` response.

| Command    | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data` | `Le` |
| ---        | ---   | ---   | ---  | ---  | ---  | ---    | ---  |
| `GET DATA` | `00`  | `CA`  | `7F` | `66` | -    | -      | `00` |

| Response Body | Tag  | Size | Description |
| ---           | ---  | ---  | ---         |
| Extended length information | `0202 <nn> <nn> 0202 <nn> <nn>` | | Maximum number of bytes in command APDU. Maximum number of bytes in response APDU. Both big-endian. |

### General Feature Management Data - Tag `7F74`

#### Single DO

- In the case that it is not provided in the `6E` response.

| Command    | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data` | `Le` |
| ---        | ---   | ---   | ---  | ---  | ---  | ---    | ---  |
| `GET DATA` | `00`  | `CA`  | `7F` | `74` | -    | -      | `00` |

| Response Body | Tag  | Size | Description |
| ---           | ---  | ---  | ---         |
| General feature management data | `sz <nn>` | | Bitmask of supported features. The OpenPGP application defines only the the behavior for `<nn>=20` (Button). |


## PW Authentication

The following minimal use-cases require authentication of `PW1` or `PW3`. Minimal use-cases shall support only passwords in plain format.

### Verification

| Command      | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`                    | `Le` | Description |
| ---          | ---   | ---   | ---  | ---  | ---  | ---                       | ---  | ---         |
| Verify PW1   | `00`  | `20`  | `00` | `81` | `06` | `xx xx xx xx xx xx`       | -    | Verifies PW1 for a PSO:CDS command only. Valid for one or serveral attempts based on PW1 status byte in extended capabilities. |
| Verify PW1   | `00`  | `20`  | `00` | `82` | `06` | `xx xx xx xx xx xx`       | -    | Verifies PW1 for other functions and remains valid until the next reset or `SELECT` of another application. |
| Query PW1    | `00`  | `20`  | `00` | `81` | -    | -                         | -    | Access status returned in `SW1/SW2`. **YUBIKEY RETURNS `6A80`.** |
| Unverify PW1 | `00`  | `20`  | `FF` | `81` | -    | -                         | -    | **YUBIKEY RETURNS `6A80`.** |
| Verify PW3   | `00`  | `20`  | `00` | `83` | `08` | `xx xx xx xx xx xx xx xx` | -    | Verifies PW3. |
| Query PW3    | `00`  | `20`  | `00` | `83` | -    | -                         | -    | Access status returned in `SW1/SW2`. **YUBIKEY RETURNS `6A80`.** |
| Unverify PW3 | `00`  | `20`  | `FF` | `83` | -    | -                         | -    | **YUBIKEY RETURNS `6A80`.** |

| Response   | `SW1` | `SW2` | Description  |
| ---        | ---   | ---   | ---          |
|            | `90`  | `00`  | Success - no other information    |
|            | `63`  | `CX`  | Not verified. `X` denotes number of allowed retries. |
|            | `69`  | `82`  | Security status not satisified. PW wrong. PW not checked (command not allowed). |
|            | `69`  | `83`  | Authentication method blocked. PW blocked (error counter zero). |
|            | `6A`  | `80`  | Incorrect parameters in command data field. |
|            |       | `86`  | Incorrect parameteres P1-P2. |
|            |       | `88`  | Referenced data not found. |
|            | `6B`  | `00`  | Wrong parameters P1-P2. |

## Compute Digital Signature

| Command   | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`              | `Le` |
| ---       | ---   | ---   | ---  | ---  | ---  | ---                 | ---  |
| `PSO:CDS` | `00`  | `2A`  | `9E` | `9A` | `xx` | `xx xx xx xx xx xx` | `00` |

| Response | `SW1` | `SW2` | Description  |
| ---      | ---   | ---   | ---          |
|          | `90`  | `00`  | Success - no other information    |
|          | `69`  | `82`  | Security status not satisified. PW wrong. PW not checked (command not allowed). |


## Decrypt Message

| Command   | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`              | `Le` |
| ---       | ---   | ---   | ---  | ---  | ---  | ---                 | ---  |
| `PSO:DEC` | `00`  | `2A`  | `80` | `86` | `xx` | `xx xx xx xx xx xx` | `00` |

### RSA

- Data field is padded with `00` padding indicator byte.
- **Some questions regarding the `section 7.2.11 PSO:DECIPHER` statement**

> In case of the RSA algorithm the command input (except padding indicator byte) shall be formatted according to PCKS#1 before encryption. 

| Description         | Length   | Value |
| ---                 | ---      | ---   |
| Start byte          | 1        | `00` |
| Block type          | 1        | `02` |
| Padding string (PS) | N -3 - L | Non-zero random bytes |
| Separator           | 1        | `00` |
| Data                | L        | Message |

> ...The card decrypts all bytes after the padding indicator byte, checks the conformance of correct PKCS#1 padding and returns the plain text (length = message) in the response.

**I'm unsure if this means that the above table is how content must be provided to `PSO:DECIPHER`, or what?**

---

# Expanded Use-Cases

## PW Authentication
 
Expanded use-cases shall support authentication of `PW1` and `PW3` using S2K depending on the key's KDF configuration.

### Interpreting Extended Capabilities for KDF capabilities

| Command    | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`              | `Le` |
| ---        | ---   | ---   | ---  | ---  | ---  | ---                 | ---  |
| `GET DATA` | `00`  | `CA`  | `00` | `6E` | -    | -                   | `00` |


| Response Body | Tag  | Size  | Description |
| ---           | ---  | ---   | ---         |
| Discretionary data objects | `73` | 'sz' | Followed by |
| Extended capabilities | `C0` | `0A` | |

| Bit | Description |
| --- | ---         |
| 0   | KDF-DO (Tag `F9`) and related functionality available. |

### KDF-DO - Tag `F9`

Read the KDF-DO to determine the KDF configuration.

| Command    | `CLA` | `INS` | `P1` | `P2` | `Lc` | `Data`              | `Le` |
| ---        | ---   | ---   | ---  | ---  | ---  | ---                 | ---  |
| `GET DATA` | `00`  | `CA`  | `00` | `F9` | -    | -                   | `00` |

| Response Body    | Tag  | Size  | Description |
| ---              | ---  | ---   | ---         |
| KDF-DO           | `F9` | `sz`  | Followed by |
|                  |      |       | |
| KDF algorithm    | `81` | `01`  | `00` for no KDF, `03` for OpenPGP S2K. |
| Hash algorithm   | `82` | `01`  | `08` for SHA-256, `0A` for SHA-512.    |
| Iteration count  | `83` | `04`  | long integer. Big-endian. |
| Salt - PW1       | `84` | `xx`  | | 
| Salt - reset PW1 | `85` | `xx`  | |
| Salt - PW3       | `86` | `xx`  | |
| Initial hash PW1 | `87` | `xx`  | |
| Initial hash PW3 | `88` | `xx`  | |

### PW Authentication using OpenPGP S2K Function

Section 4.3.2 of [_The Specification_](https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.1.pdf) specifies RFC-4880 for the S2K function. At the time of authoring, RFC-4880 has obseleted by [RFC-9580](https://www.rfc-editor.org/rfc/rfc9580#name-string-to-key-s2k-specifier).

## Extended Length APDUs

- `2F01` contains *Extended lengthh information" if extended length is announced in the Historical bytes `5F52`.
- `7F66` contains *Extended length information* if extended length is announced in the Historical bytes `5F52`.

## Reading optional DOs

### Cardholder related data - Tag `65`

- Name

### Public keys URL - Tag `5F50`

## Generate Private Key

## Client/Server Authentication

