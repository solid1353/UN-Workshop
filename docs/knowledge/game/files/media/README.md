# NA2 Media Layout Inventories

## Research coverage

Established: the saved ISO9660 and nested AFS layouts, paths, object types,
extents, offsets, sizes and entry totals for untouched NA2 media. The extraction
and split summaries below report completeness, source attributes and CVM sector
totals. Open: individual member roles and the earlier CVM count discrepancy.

Related code names come from `@annotations/NA2`; this index cites files only.
Human-readable file and family roles belong to
[NA2 Game File Reference](../disc_files.md).

These exact inventories preserve the game-media structure without requiring
repeated ISO, encrypted-CVM, or nested-AFS extraction. This directory owns the
exact structural inventory.

| Durable file | Contents | Entries |
| --- | --- | ---: |
| `na2_iso9660.tsv` | Outer retail NA2 ISO9660 layout: path, object type, extent, byte offset, and size | 36: 32 files, 4 directories |
| `data_cvm_iso9660.tsv` | Decrypted ISO payload layout from `@source_na2/DATA/DATA.CVM` | 2,330: 2,310 files, 20 directories |
| `afs_members.tsv` | Consolidated nested AFS-member layout under `@source_na2` | 9,480 members across 170 AFS containers |

The earlier recorded CVM total was 2,332 entries (2,312 files and 20
directories). The saved TSV contains 2,330 entries, including `GZLIST.TXT` and
`ICON.BIN`; the reason for the two-entry discrepancy is unresolved.

The TSV files are exact copies of the original inventories. Backslash paths inside them are historical extraction-relative paths:

- paths in `na2_iso9660.tsv` are relative to the root of the retail NA2 ISO;
- paths in `data_cvm_iso9660.tsv` are relative to the decrypted ISO payload of `DATA.CVM`;
- paths in `afs_members.tsv` begin with `NA2.iso.files` and are relative to `@source/`.

`DATA.CVM` was split with its ROFS password, yielding a 737,226,752-byte ISO payload with 359,974 sectors and end-of-TOC sector 87. These values came from the associated split summary; the full layout is `data_cvm_iso9660.tsv`.

The extraction covered all four top-level and 166 nested AFS archives, leaving no discovered AFS without a sibling `.files` extraction. Its source-tree inventory contained 12,195 items and found no item missing the Windows read-only attribute; that observation describes the recorded extraction, not later source state.

The inventories describe untouched source extractions.
