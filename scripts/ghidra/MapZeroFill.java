// Maps zero-filled load regions that have no file bytes as uninitialized memory.
// @category UN Workshop

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;

public class MapZeroFill extends GhidraScript {
    @Override
    protected void run() throws Exception {
        String[] args = getScriptArgs();
        Memory memory = currentProgram.getMemory();
        int index = 0;
        for (String range : args) {
            String[] parts = range.split(":");
            if (parts.length != 2) {
                throw new IllegalArgumentException("Expected start:length, got " + range);
            }
            Address start = toAddr(Long.decode(parts[0]));
            long length = Long.decode(parts[1]);
            if (length <= 0) {
                continue;
            }
            Address end = start.add(length - 1);
            if (memory.intersects(start, end)) {
                println("Zero-fill range already mapped: " + start + "-" + end);
                continue;
            }
            MemoryBlock block = memory.createUninitializedBlock(
                index == 0 ? "bss" : "bss" + index, start, length, false);
            block.setRead(true);
            block.setWrite(true);
            block.setExecute(false);
            index++;
            println("Mapped zero-fill " + start + "-" + end);
        }
    }
}
