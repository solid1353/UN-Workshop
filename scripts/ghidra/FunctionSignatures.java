// Writes address-independent instruction fingerprints of every R5900 function in the program
// to <output directory>/<program>.tsv.
// @category UN Workshop

import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;

public class FunctionSignatures extends GhidraScript {
    private static final int GP = 28;

    @Override
    protected void run() throws Exception {
        String[] args = getScriptArgs();
        List<Function> functions = new ArrayList<>();
        currentProgram.getFunctionManager().getFunctions(true).forEach(functions::add);
        Path output = Path.of(args[0], currentProgram.getName() + ".tsv");
        try (PrintWriter out = new PrintWriter(Files.newBufferedWriter(output, StandardCharsets.UTF_8))) {
            out.println("address\tinstructions\thash");
            for (Function function : functions) {
                String[] fingerprint = fingerprint(function);
                if (fingerprint != null) {
                    out.println("0x" + function.getEntryPoint().toString().toUpperCase()
                        + "\t" + fingerprint[0] + "\t" + fingerprint[1]);
                }
            }
        }
    }

    // Masks jump targets, lui immediates, gp-relative offsets and offsets from registers that
    // hold a lui-formed address, so relocated copies of the same code fingerprint equally.
    private String[] fingerprint(Function function) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-1");
        Set<Integer> addressRegisters = new HashSet<>();
        int count = 0;
        for (Instruction instruction : currentProgram.getListing()
                .getInstructions(function.getBody(), true)) {
            byte[] bytes = instruction.getBytes();
            if (bytes.length != 4) {
                return null;
            }
            int word = (bytes[0] & 0xFF) | (bytes[1] & 0xFF) << 8 | (bytes[2] & 0xFF) << 16
                | (bytes[3] & 0xFF) << 24;
            int opcode = word >>> 26;
            int rs = (word >>> 21) & 0x1F;
            int rt = (word >>> 16) & 0x1F;
            if (opcode == 2 || opcode == 3) {
                word &= 0xFC000000;
            }
            else if (opcode == 0x0F) {
                word &= 0xFFFF0000;
                addressRegisters.add(rt);
            }
            else if (opcode >= 0x08 && (rs == GP || addressRegisters.contains(rs))) {
                word &= 0xFFFF0000;
                if (opcode == 0x09 || opcode == 0x0D || opcode == 0x19) {
                    addressRegisters.add(rt);
                }
                else if (opcode >= 0x20 && opcode < 0x28 || opcode == 0x37 || opcode == 0x1E) {
                    addressRegisters.remove(rt);
                }
            }
            else if (opcode == 0) {
                addressRegisters.remove((word >>> 11) & 0x1F);
            }
            else if (opcode >= 0x08) {
                addressRegisters.remove(rt);
            }
            digest.update(new byte[] {(byte) word, (byte) (word >>> 8), (byte) (word >>> 16),
                (byte) (word >>> 24)});
            count++;
        }
        return new String[] {Integer.toString(count), HexFormat.of().formatHex(digest.digest())};
    }
}
