"""PSP PGD (DNAS) files, such as Ultimate Ninja Heroes 3's DATA.DNS.

Decryption follows amctrl.prx as reverse engineered in PPSSPP's libkirk
(amctrl.c, kirk_engine.c). The version key is recovered from the header's
MAC, so no game key is needed; the header MAC over its first 0x80 bytes,
checked with the DNAS fixed key, confirms the keys. KIRK's AES-128-CBC
commands 4 and 7 use a zero IV. AES runs through Windows' CNG (bcrypt.dll).

A PGD holds one file. It is written as the PGD's name plus the inner file's
extension (".cpk" for a CPK, otherwise ".bin").

usage: pgd.py <pgd> <out-dir>
"""
from __future__ import annotations

import ctypes
import os
import struct
import sys
from pathlib import Path

MAGIC = b"\0PGD"
KIRK_KEYS = {
    0x38: bytes.fromhex("12468D7E1C42209BBA5426835EB03303"),
    0x39: bytes.fromhex("C43BB6D653EE67493EA95FBC0CED6F8A"),
    0x63: bytes.fromhex("9C9B1372F8C640CF1C62F5D592DDB582"),
}
MAC_XOR = bytes.fromhex("E350ED1D910A1FD029BB1C3EF34077FB")
CIPHER_OUT_XOR = bytes.fromhex("135FA47CAB395BA476B8CCA98F3A0445")
CIPHER_IN_XOR = bytes.fromhex("678D7FA32A9CA0D1508AD8385E4B017E")
DNAS_KEY = bytes.fromhex("EDE25D2DBBF812E53C5C5932FAE3E243")
CHUNK = 1 << 20


def _xor(left: bytes, right: bytes) -> bytes:
    return (int.from_bytes(left, "little") ^ int.from_bytes(right, "little")).to_bytes(len(left), "little")


class _Aes:
    """AES-128 through Windows CNG, in ECB or CBC mode."""

    _bcrypt = None

    def __init__(self, key: bytes, mode: str) -> None:
        if _Aes._bcrypt is None:
            _Aes._bcrypt = ctypes.WinDLL("bcrypt")
        self._b = _Aes._bcrypt
        self._alg = ctypes.c_void_p()
        self._key = ctypes.c_void_p()
        self._check(self._b.BCryptOpenAlgorithmProvider(ctypes.byref(self._alg), "AES", None, 0))
        chaining = ctypes.create_unicode_buffer(f"ChainingMode{mode}")
        self._check(self._b.BCryptSetProperty(
            self._alg, "ChainingMode", chaining, ctypes.sizeof(chaining), 0))
        self._check(self._b.BCryptGenerateSymmetricKey(
            self._alg, ctypes.byref(self._key), None, 0, key, len(key), 0))

    @staticmethod
    def _check(status: int) -> None:
        if status:
            raise RuntimeError(f"CNG call failed: {status & 0xFFFFFFFF:#010x}")

    def _run(self, function, data: bytes, iv: bytes | None) -> bytes:
        out = ctypes.create_string_buffer(len(data))
        done = ctypes.c_ulong()
        iv_buffer = ctypes.create_string_buffer(iv, 16) if iv is not None else None
        self._check(function(
            self._key, data, len(data), None, iv_buffer, 16 if iv is not None else 0,
            out, len(data), ctypes.byref(done), 0))
        return out.raw

    def encrypt(self, data: bytes, iv: bytes | None = None) -> bytes:
        return self._run(self._b.BCryptEncrypt, data, iv)

    def decrypt(self, data: bytes, iv: bytes | None = None) -> bytes:
        return self._run(self._b.BCryptDecrypt, data, iv)

    def close(self) -> None:
        self._b.BCryptDestroyKey(self._key)
        self._b.BCryptCloseAlgorithmProvider(self._alg, 0)


def _double(block: bytes) -> bytes:
    value = int.from_bytes(block, "big") << 1
    if value >> 128:
        value = (value ^ 0x87) & ((1 << 128) - 1)
    return value.to_bytes(16, "big")


def _bbmac(aes38: _Aes, data: bytes, version_key: bytes | None) -> bytes:
    """sceDrmBBMacFinal for MAC type 1: AES-CMAC with KIRK key 0x38, XOR a
    constant, then, with a version key, one more encryption of the XOR."""
    subkey = _double(aes38.encrypt(bytes(16)))
    full = len(data) % 16 == 0 and data
    tail = data[-16:] if full else data[len(data) - len(data) % 16:]
    if not full:
        subkey = _double(subkey)
        tail = tail + b"\x80" + bytes(15 - len(tail))
    body = data[:len(data) - (16 if full else len(data) % 16)]
    chain = bytes(16)
    for start in range(0, len(body), 16):
        chain = aes38.encrypt(_xor(body[start:start + 16], chain))
    mac = _xor(aes38.encrypt(_xor(_xor(tail, subkey), chain)), MAC_XOR)
    if version_key is not None:
        mac = aes38.encrypt(_xor(mac, version_key))
    return mac


class _Keystream:
    """sceDrmBBCipherUpdate for cipher type 1: counter block n (from 1) is
    the derived prefix and n; keystream block n is KIRK 7 (key 0x63) of
    counter n XOR counter n - 1, with zeros before counter 1."""

    def __init__(self, key: bytes) -> None:
        aes39 = _Aes(KIRK_KEYS[0x39], "ECB")
        try:
            self._prefix = _xor(aes39.decrypt(_xor(key, CIPHER_IN_XOR)), CIPHER_OUT_XOR)[:12]
        finally:
            aes39.close()
        self._aes = _Aes(KIRK_KEYS[0x63], "CBC")

    def _counter(self, value: int) -> bytes:
        return self._prefix + struct.pack("<I", value & 0xFFFFFFFF)

    def apply(self, data: bytes, first_block: int) -> bytes:
        count = (len(data) + 15) // 16
        counters = b"".join(self._counter(first_block + 1 + index) for index in range(count))
        previous = bytes(16) if first_block == 0 else self._counter(first_block)
        stream = self._aes.decrypt(counters, previous)[:len(data)]
        return _xor(data, stream)

    def close(self) -> None:
        self._aes.close()


def _open(header: bytes, path: Path) -> tuple[bytes, int, int]:
    """Return the data key, data size and data offset."""
    if header[:4] != MAGIC:
        raise RuntimeError(f"Not a PGD file: {path}")
    key_index, drm_type = struct.unpack_from("<II", header, 4)
    if drm_type != 1 or key_index > 1:
        raise RuntimeError(f"Unsupported PGD key index {key_index} or DRM type {drm_type}: {path}")
    aes38 = _Aes(KIRK_KEYS[0x38], "ECB")
    try:
        if _bbmac(aes38, header[:0x80], DNAS_KEY) != header[0x80:0x90]:
            raise RuntimeError(f"PGD header MAC mismatch: {path}")
        version_key = _xor(_bbmac(aes38, header[:0x70], None), aes38.decrypt(header[0x70:0x80]))
    finally:
        aes38.close()
    stream = _Keystream(_xor(header[0x10:0x20], version_key))
    try:
        descriptor = stream.apply(header[0x30:0x60], 0)
    finally:
        stream.close()
    data_key = _xor(descriptor[:16], version_key)
    data_size, block_size, data_offset = struct.unpack_from("<III", descriptor, 0x14)
    if block_size not in (0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000, 0x10000):
        raise RuntimeError(f"Invalid PGD block size {block_size:#x}: {path}")
    if data_offset + data_size > path.stat().st_size:
        raise RuntimeError(f"PGD data lies outside the file: {path}")
    return data_key, data_size, data_offset


def _decrypted_chunks(path: Path):
    with path.open("rb") as handle:
        data_key, size, offset = _open(handle.read(0x90), path)
        stream = _Keystream(data_key)
        try:
            handle.seek(offset)
            done = 0
            while done < size:
                chunk = handle.read(min(CHUNK, (size - done + 15) & ~15))
                yield stream.apply(chunk, done // 16)[:size - done]
                done += len(chunk)
        finally:
            stream.close()


def _inner_name(path: Path, first: bytes) -> str:
    return path.name + (".cpk" if first[:4] == b"CPK " else ".bin")


def extract(path: Path, out_dir: Path) -> None:
    timestamp = path.stat().st_mtime
    chunks = _decrypted_chunks(path)
    first = next(chunks)
    target = out_dir / _inner_name(path, first)
    with target.open("wb") as out:
        out.write(first)
        for chunk in chunks:
            out.write(chunk)
    os.utime(target, (timestamp, timestamp))


def main() -> int:
    archive, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    if out_dir.exists():
        raise RuntimeError(f"Output already exists: {out_dir}")
    out_dir.mkdir()
    extract(archive, out_dir)
    print(f"Decrypted PGD: {archive.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
