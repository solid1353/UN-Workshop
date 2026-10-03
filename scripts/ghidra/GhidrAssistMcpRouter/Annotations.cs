using System.Globalization;
using System.Text;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace GhidrAssistMcpRouter;

// @annotations/<game>/types.h and @annotations/<game>/<program>/symbols.tsv are the
// recorded source of every annotation; the router applies them when a <game> backend starts.
internal sealed class Annotations
{
    internal const string ApplyTool = "apply_annotations";
    internal const string SymbolTool = "annotate_symbol";
    internal const string TypeTool = "annotate_type";
    private const string Header = "address\tkind\tname\ttype\tcomment";
    private static readonly Regex Identifier = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.CultureInvariant);
    private static readonly UTF8Encoding Utf8 = new(false);

    private readonly string _root;

    internal Annotations(string annotationsRoot, string game)
    {
        _root = Path.Combine(annotationsRoot, game);
    }

    internal sealed record SymbolRow(uint Address, string Kind, string Name, string Type, string Comment)
    {
        internal string Line() =>
            $"0x{Address:X8}\t{Kind}\t{Name}\t{Type}\t{Comment}";

        internal static SymbolRow From(JsonObject arguments)
        {
            string Text(string field, bool required)
            {
                var value = arguments[field]?.GetValue<string>()?.Trim() ?? string.Empty;
                if (required && value.Length == 0)
                {
                    throw new ArgumentException($"{field} is required.");
                }
                if (value.IndexOfAny(new[] { '\t', '\r', '\n' }) >= 0)
                {
                    throw new ArgumentException($"{field} must be one line without tabs.");
                }
                return value;
            }

            var address = Text("address", true);
            var digits = address.StartsWith("0x", StringComparison.OrdinalIgnoreCase) ? address[2..] : address;
            if (!uint.TryParse(digits, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out var value))
            {
                throw new ArgumentException($"address must be a live hexadecimal address: {address}");
            }
            var kind = Text("kind", true);
            if (kind is not ("function" or "label" or "data"))
            {
                throw new ArgumentException("kind must be function, label, or data.");
            }
            var name = Text("name", true);
            if (!Identifier.IsMatch(name))
            {
                throw new ArgumentException($"name must be a C identifier: {name}");
            }
            return new SymbolRow(value, kind, name, Text("type", false), Text("comment", false));
        }

        /// <summary>The rows of one call: the rows array, or the fields of a single row.</summary>
        internal static IReadOnlyList<SymbolRow> Rows(JsonObject arguments)
        {
            if (arguments["rows"] is not JsonArray array)
            {
                return new[] { From(arguments) };
            }
            var rows = array.Select(item => From(item as JsonObject
                ?? throw new ArgumentException("Every rows entry must be an object."))).ToList();
            if (rows.Count == 0)
            {
                throw new ArgumentException("rows must not be empty.");
            }
            var repeated = rows.GroupBy(row => row.Address).FirstOrDefault(group => group.Count() > 1);
            if (repeated is not null)
            {
                throw new ArgumentException($"rows repeat address 0x{repeated.Key:X8}.");
            }
            return rows;
        }

        internal static SymbolRow Parse(string line, string path)
        {
            var fields = line.Split('\t');
            if (fields.Length != 5 || !fields[0].StartsWith("0x", StringComparison.Ordinal) ||
                !uint.TryParse(fields[0][2..], NumberStyles.HexNumber, CultureInfo.InvariantCulture, out var address))
            {
                throw new InvalidDataException($"{path} has an invalid row: {line}");
            }
            return new SymbolRow(address, fields[1], fields[2], fields[3], fields[4]);
        }
    }

    internal static string SymbolText(IEnumerable<SymbolRow> rows) =>
        string.Join("\n", new[] { Header }.Concat(rows.Select(row => row.Line()))) + "\n";

    /// <summary>The types and each program's symbols, as apply_annotations arguments.</summary>
    internal IEnumerable<(string Program, JsonObject Arguments)> StartupApplications(
        IReadOnlyList<string> programs)
    {
        var typesPath = Path.Combine(_root, "types.h");
        var types = File.Exists(typesPath) ? File.ReadAllText(typesPath, Utf8) : null;
        foreach (var program in programs)
        {
            var symbolsPath = Path.Combine(_root, program, "symbols.tsv");
            var arguments = new JsonObject();
            if (types is not null)
            {
                arguments["types"] = types;
            }
            if (File.Exists(symbolsPath))
            {
                arguments["symbols"] = File.ReadAllText(symbolsPath, Utf8);
            }
            if (arguments.Count != 0)
            {
                yield return (program, arguments);
            }
        }
    }

    /// <summary>Upsert rows by address; returns an action that restores the file.</summary>
    internal Action RecordSymbols(string program, IReadOnlyList<SymbolRow> added)
    {
        var path = Path.Combine(_root, program, "symbols.tsv");
        var previous = File.Exists(path) ? File.ReadAllText(path, Utf8) : null;
        var rows = new List<SymbolRow>();
        if (previous is not null)
        {
            var lines = previous.Replace("\r", string.Empty).Split('\n', StringSplitOptions.RemoveEmptyEntries);
            if (lines.Length == 0 || lines[0] != Header)
            {
                throw new InvalidDataException($"{path} must start with: {Header.Replace('\t', ' ')}");
            }
            rows.AddRange(lines.Skip(1).Select(line => SymbolRow.Parse(line, path)));
        }
        rows.RemoveAll(existing => added.Any(row => row.Address == existing.Address));
        rows.AddRange(added);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path, SymbolText(rows.OrderBy(item => item.Address)), Utf8);
        return () => Restore(path, previous);
    }

    /// <summary>Upsert the declarations by name; returns the complete types.h text.</summary>
    internal Action RecordType(string declaration, out string types)
    {
        var path = Path.Combine(_root, "types.h");
        var previous = File.Exists(path) ? File.ReadAllText(path, Utf8) : null;
        var declarations = SplitDeclarations(previous ?? string.Empty)
            .Select(text => (Name: DeclarationName(text), Text: text))
            .ToList();
        var added = SplitDeclarations(declaration);
        if (added.Count == 0)
        {
            throw new ArgumentException("declaration must contain a C declaration ending in ';'.");
        }
        foreach (var text in added)
        {
            var name = DeclarationName(text);
            var index = declarations.FindIndex(item => item.Name == name);
            if (index >= 0)
            {
                declarations[index] = (name, text);
            }
            else
            {
                declarations.Add((name, text));
            }
        }
        types = string.Join("\n\n", declarations.Select(item => item.Text)) + "\n";
        Directory.CreateDirectory(_root);
        File.WriteAllText(path, types, Utf8);
        return () => Restore(path, previous);
    }

    private static void Restore(string path, string? previous)
    {
        if (previous is null)
        {
            File.Delete(path);
        }
        else
        {
            File.WriteAllText(path, previous, Utf8);
        }
    }

    /// <summary>Top-level declarations, each with the comments that precede it.</summary>
    private static List<string> SplitDeclarations(string text)
    {
        var result = new List<string>();
        var current = new StringBuilder();
        var depth = 0;
        for (var index = 0; index < text.Length; index++)
        {
            var character = text[index];
            if (character == '/' && index + 1 < text.Length && text[index + 1] is '/' or '*')
            {
                var end = text[index + 1] == '/'
                    ? text.IndexOf('\n', index)
                    : text.IndexOf("*/", index + 2, StringComparison.Ordinal) + 1;
                end = end <= 0 ? text.Length - 1 : end;
                current.Append(text, index, end - index + 1);
                index = end;
                continue;
            }
            current.Append(character);
            if (character == '{')
            {
                depth++;
            }
            else if (character == '}')
            {
                depth--;
            }
            else if (character == ';' && depth == 0)
            {
                result.Add(current.ToString().Trim());
                current.Clear();
            }
        }
        if (current.ToString().Trim().Length != 0 &&
            Regex.Replace(current.ToString(), @"//[^\n]*|/\*.*?\*/", string.Empty, RegexOptions.Singleline).Trim().Length != 0)
        {
            throw new ArgumentException("Every declaration must end with ';'.");
        }
        return result;
    }

    private static string DeclarationName(string declaration)
    {
        var code = Regex.Replace(declaration, @"//[^\n]*|/\*.*?\*/", string.Empty, RegexOptions.Singleline).Trim();
        while (code.Contains('{'))
        {
            code = Regex.Replace(code, @"\{[^{}]*\}", " ");
        }
        if (code.StartsWith("typedef", StringComparison.Ordinal))
        {
            var pointer = Regex.Match(code, @"\(\s*\*\s*([A-Za-z_]\w*)\s*\)");
            if (pointer.Success)
            {
                return pointer.Groups[1].Value;
            }
            var last = Regex.Match(code, @"([A-Za-z_]\w*)\s*(\[[^\]]*\]\s*)*;$");
            if (last.Success)
            {
                return last.Groups[1].Value;
            }
        }
        var tagged = Regex.Match(code, @"^(?:struct|union|enum)\s+([A-Za-z_]\w*)");
        if (tagged.Success)
        {
            return tagged.Groups[1].Value;
        }
        throw new ArgumentException($"Cannot find the declared name in: {code}");
    }

    internal static IEnumerable<JsonObject> Tools(JsonArray annotatedTargets)
    {
        JsonObject Target() => new()
        {
            ["type"] = "string",
            ["enum"] = annotatedTargets.DeepClone(),
            ["description"] = "Game target that carries the annotations.",
        };
        JsonObject Text(string description) => new() { ["type"] = "string", ["description"] = description };
        JsonObject Kind() => new()
        {
            ["type"] = "string",
            ["enum"] = new JsonArray("function", "label", "data"),
        };

        yield return new JsonObject
        {
            ["name"] = SymbolTool,
            ["description"] =
                "Record and apply names, types, and comments at live addresses of one program. " +
                "Give one row's fields, or rows for several. Replaces any annotation at those " +
                "addresses; all rows apply or none do.",
            ["inputSchema"] = new JsonObject
            {
                ["type"] = "object",
                ["properties"] = new JsonObject
                {
                    ["target"] = Target(),
                    ["program_name"] = Text("Program in the target, such as BTL.BIN."),
                    ["address"] = Text("Live runtime address, such as 0x00878860."),
                    ["kind"] = Kind(),
                    ["name"] = Text("C identifier."),
                    ["type"] = Text("Function prototype for a function, or data type for data; optional."),
                    ["comment"] = Text("One-line comment; optional."),
                    ["rows"] = new JsonObject
                    {
                        ["type"] = "array",
                        ["description"] = "Several rows instead of the single-row fields.",
                        ["items"] = new JsonObject
                        {
                            ["type"] = "object",
                            ["properties"] = new JsonObject
                            {
                                ["address"] = Text("Live runtime address."),
                                ["kind"] = Kind(),
                                ["name"] = Text("C identifier."),
                                ["type"] = Text("Prototype or data type; optional."),
                                ["comment"] = Text("One-line comment; optional."),
                            },
                            ["required"] = new JsonArray("address", "kind", "name"),
                        },
                    },
                },
                ["required"] = new JsonArray("target", "program_name"),
            },
        };
        yield return new JsonObject
        {
            ["name"] = TypeTool,
            ["description"] =
                "Record and apply C struct, union, enum, or typedef declarations for every program of " +
                "an annotated game. Replaces declarations of the same name.",
            ["inputSchema"] = new JsonObject
            {
                ["type"] = "object",
                ["properties"] = new JsonObject
                {
                    ["target"] = Target(),
                    ["declaration"] = Text("One or more C declarations, each ending in ';'."),
                },
                ["required"] = new JsonArray("target", "declaration"),
            },
        };
    }
}
