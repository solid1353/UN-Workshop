// Applies <annotation directory>/types.h and the program's symbols.tsv to the current program,
// each symbol row in its own transaction, and prints every row that fails.
// @category UN Workshop

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import ghidra.app.script.GhidraScript;
import ghidrassistmcp.annotations.AnnotationApplier;

public class CheckAnnotations extends GhidraScript {
    @Override
    protected void run() throws Exception {
        Path root = Path.of(getScriptArgs()[0]);
        Path types = root.resolve("types.h");
        Path symbols = root.resolve(currentProgram.getName()).resolve("symbols.tsv");
        String program = currentProgram.getName();
        if (Files.exists(types)) {
            try {
                AnnotationApplier.apply(currentProgram, Files.readString(types, StandardCharsets.UTF_8), List.of());
            }
            catch (Exception exception) {
                println("FAIL " + program + " types.h: " + exception.getMessage());
                return;
            }
        }
        if (!Files.exists(symbols)) {
            println("CHECKED " + program + " rows=0 failures=0");
            return;
        }
        int failures = 0;
        List<AnnotationApplier.SymbolRow> rows =
            AnnotationApplier.parseSymbols(Files.readString(symbols, StandardCharsets.UTF_8));
        for (AnnotationApplier.SymbolRow row : rows) {
            try {
                AnnotationApplier.apply(currentProgram, null, List.of(row));
            }
            catch (Exception exception) {
                failures++;
                println("FAIL " + program + " " + exception.getMessage());
            }
        }
        println("CHECKED " + program + " rows=" + rows.size() + " failures=" + failures);
    }
}
