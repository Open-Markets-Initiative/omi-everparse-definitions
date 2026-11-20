# Agent Notes

Every file in this repository is generated from the Open Markets Initiative binary data
models. Editing one here is lost on the next generation: the change belongs in the generator
or in the model it reads.

## What is here

- `<organization>/<division>/<protocol>/<Name>.3d` — one definition per protocol framing: the
  whole packet in 3d, a struct per group, a casetype per choice, lengths and counts framing what
  they measure. Where 3d cannot state some shape of the packet, the records alone, and the
  header says why. Each definition is self contained, so everparse reads one on its own.
- `check.sh`, `Makefile` — what a check runs.

## Checking it

```sh
export EVERPARSE=/path/to/everparse/everparse.sh   # of an unpacked everparse release
sh ./check.sh                           # every definition
sh ./check.sh nasdaq                    # the ones under a directory
sh ./check.sh path/to/Definition.3d     # one
```

Each definition is tried in a directory of its own and several are tried at once. A large
definition can take several gigabytes while it is verified; set `JOBS` lower on a small
machine.

A definition that does not verify is a generator defect, not a file to patch.

## What a definition here claims

Everparse writes a C validator for the packet and proves of it that:

- it reads no byte outside the buffer it is given;
- it reads no byte twice;
- it accepts exactly the byte strings the packet describes.

An integer is read at its width and in its byte order; 3d has unsigned integers only, so a
signed field is declared unsigned and marked. Every other field is the bytes it occupies.

A field's listed values are `#define` constants named for the field and the value. They
document the codes and do not constrain them: an unlisted code is still accepted.

A definition's header says what it reads more loosely than its model states — a count it
cannot check, say — or, where it states records alone, which shape stopped the packet.

## The same protocols, elsewhere

The Open Markets Initiative provides protocol definitions in several formats:

- [Kaitai Struct Definitions][Kaitai.Definitions.Repository] — Cross language binary parsers with the kaitai struct compiler
- [DFDL Definitions][Dfdl.Definitions.Repository] — Declarative DFDL schemas for cross language parsing
- [P4 Definitions][P4.Definitions.Repository] — P4 programs for software and hardware data planes
- [Spicy Definitions][Spicy.Definitions.Repository] — Declarative Spicy grammars for the spicy toolchain and the zeek network security monitor
- [Lean Definitions][Lean.Definitions.Repository] — Lean 4 definitions with machine checked encode and decode proofs
- [Rocq Definitions][Rocq.Definitions.Repository] — Rocq Prover definitions whose encode and decode proofs the prover checks
- [TLA+ Definitions][Tla.Definitions.Repository] — TLA+ modules whose encode and decode are model checked with TLC
- [Promela Definitions][Promela.Definitions.Repository] — Promela models whose encode and decode are checked by the spin model checker
- [FIX Dictionaries][Fix.Dictionaries.Repository] — QuickFIX format xml data dictionaries, one per FIX version
- [Xml Specifications][Xml.Specifications.Repository] — Formatted exchange specification xmls

[Kaitai.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-kaitai-struct-definitions "Omi Kaitai Struct Definitions"
[Dfdl.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-dfdl-definitions "Omi DFDL Definitions"
[P4.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-p4-definitions "Omi P4 Definitions"
[Spicy.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-spicy-definitions "Omi Spicy Definitions"
[Lean.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-lean4-definitions "Omi Lean Definitions"
[Rocq.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-rocq-definitions "Omi Rocq Definitions"
[Tla.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions "Omi TLA+ Definitions"
[Promela.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-promela-definitions "Omi Promela Definitions"
[Fix.Dictionaries.Repository]: https://github.com/Open-Markets-Initiative/omi-fix-dictionaries "Omi FIX Dictionaries"
[Xml.Specifications.Repository]: https://github.com/Open-Markets-Initiative/omi-xml-specifications "Omi Xml Specifications"
