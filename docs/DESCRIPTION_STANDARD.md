# Description Standard (DRAFT)

Goal: every part description is predictable, so people can search it and ERP/ACADE can sort it.

## 1. Structure: noun, modifier, attributes

```
NOUN, MODIFIER: ATTR1, ATTR2, ATTR3, ...
```

- **NOUN:** the basic item name, singular (`RELAY`, `BREAKER`, `TERMINAL BLOCK`).
- **MODIFIER:** narrows the noun (`GENERAL PURPOSE`, `MINIATURE CIRCUIT`, `FEED-THROUGH`).
- **Attributes:** in the fixed order defined per category, with values and units.

### Examples
These are **long** descriptions. The short form (40 characters) is made by dropping "short-optional" attributes from the end, see rule 6. For example, the relay's short form is `RELAY, GENERAL PURPOSE: 24VDC COIL, 4PDT` (40 characters).

| Category | Generated description (long) |
|---|---|
| Relay | `RELAY, GENERAL PURPOSE: 24VDC COIL, 4PDT, 5A, PLUG-IN` |
| Circuit breaker | `BREAKER, MINIATURE CIRCUIT: 1P, 10A, C CURVE, 10KA, DIN RAIL` |
| Terminal block | `TERMINAL BLOCK, FEED-THROUGH: 2.5MM2, SCREW, GRAY, DIN RAIL` |
| Push button | `PUSH BUTTON, FLUSH: 22MM, GREEN, 1NO, MOMENTARY` |

## 2. Formatting rules
1. UPPER CASE.
2. Comma + space between attributes. Colon + space after the modifier.
3. No manufacturer name or MPN in the description. Those are separate fields.
4. Units directly attached, no space: `24VDC`, `10A`, `2.5MM2`, `22MM`.
5. Use only abbreviations from the controlled list (in the shared settings file). No ad-hoc abbreviations.
6. Max length: **40 characters for a short description** (verify the ERP and ACADE `DESCRIPTION` field limits, Q-007) and 255 for the long description. If the generated short description is too long, attributes marked "short-optional" are dropped from the end.
7. No special characters other than `- . / , :` and `%`. Write `UF` for microfarad, not `µF`.
8. Fractions as decimals (`0.25IN`) unless the category template says otherwise.

## 3. Attribute dictionary
Each category defines its attributes in the shared settings file:

| Field | Example |
|---|---|
| Name | Coil Voltage |
| DataType | Text / Number / Enum / Boolean |
| Unit | VDC |
| AllowedValues | 12, 24, 48, 120 (for Enum) |
| Required | Yes |
| DescOrder | 1 |
| ShortOptional | No |
| Format | `{value}{unit} COIL` |
| AcadeColumn | `RATING1` (optional; also writes the value to this catalog column, verify per table) |

## 4. Starter abbreviations
| Term | Abbrev. |
|---|---|
| Alternating current | AC |
| Direct current | DC |
| Normally open / closed | NO / NC |
| Single/double pole, single/double throw | SPST, SPDT, DPDT, 4PDT |
| Pole | P (e.g. 3P) |
| Kiloampere interrupting | KA |
| Square millimetre | MM2 |
| American wire gauge | AWG |
| Stainless steel | SS |
| With / without | W/ / W/O |

## 5. Manufacturer data
- Manufacturer comes from the controlled list (in the shared settings file). Aliases map to the canonical name ("A-B", "Allen Bradley" → `ALLEN-BRADLEY`).
- MPN is stored **as printed by the manufacturer** *and* in normalized form (upper case, spaces/dashes/dots removed) for duplicate checks.
