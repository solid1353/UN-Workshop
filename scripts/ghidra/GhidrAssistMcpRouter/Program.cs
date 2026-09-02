using System.Collections.Concurrent;
using System.Diagnostics;
using System.Globalization;
using System.IO.Pipes;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Sockets;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace GhidrAssistMcpRouter;

internal static class Program
{
    private const string ServerName = "ghidrassist";
    private const string ServerVersion = "1.0.0";
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = false,
    };

    private static async Task<int> Main(string[] args)
    {
        try
        {
            if (args.Contains("--supervisor", StringComparer.OrdinalIgnoreCase))
            {
                var options = SupervisorOptions.Parse(args);
                return await new Supervisor(options).RunAsync();
            }

            return await RunBridgeAsync();
        }
        catch (Exception exception)
        {
            await Console.Error.WriteLineAsync(exception.ToString());
            return 1;
        }
    }

    private static async Task<int> RunBridgeAsync()
    {
        using var input = new StreamReader(
            Console.OpenStandardInput(),
            new UTF8Encoding(false),
            detectEncodingFromByteOrderMarks: false,
            bufferSize: 4096,
            leaveOpen: false);
        using var output = new StreamWriter(
            Console.OpenStandardOutput(),
            new UTF8Encoding(false),
            bufferSize: 4096,
            leaveOpen: false)
        {
            AutoFlush = true,
            NewLine = "\n",
        };

        while (await input.ReadLineAsync() is { } line)
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            JsonObject? request = null;
            try
            {
                request = JsonNode.Parse(line)?.AsObject()
                    ?? throw new InvalidDataException("MCP request is not a JSON object.");
                var response = await HandleBridgeRequestAsync(request);
                if (response is not null)
                {
                    await output.WriteLineAsync(response.ToJsonString(JsonOptions));
                }
            }
            catch (Exception exception)
            {
                if (request?["id"] is not null)
                {
                    await output.WriteLineAsync(JsonRpc.Error(
                        request["id"],
                        -32000,
                        exception.Message).ToJsonString(JsonOptions));
                }
                else
                {
                    await Console.Error.WriteLineAsync(exception.Message);
                }
            }
        }

        return 0;
    }

    private static async Task<JsonObject?> HandleBridgeRequestAsync(JsonObject request)
    {
        var method = request["method"]?.GetValue<string>()
            ?? throw new InvalidDataException("MCP request has no method.");
        var id = request["id"];

        if (method.StartsWith("notifications/", StringComparison.Ordinal))
        {
            return null;
        }

        return method switch
        {
            "initialize" => JsonRpc.Success(id, new JsonObject
            {
                ["protocolVersion"] = request["params"]?["protocolVersion"]?.GetValue<string>()
                    ?? "2025-03-26",
                ["capabilities"] = new JsonObject
                {
                    ["tools"] = new JsonObject { ["listChanged"] = false },
                    ["resources"] = new JsonObject
                    {
                        ["subscribe"] = false,
                        ["listChanged"] = false,
                    },
                    ["prompts"] = new JsonObject { ["listChanged"] = false },
                },
                ["serverInfo"] = new JsonObject
                {
                    ["name"] = ServerName,
                    ["version"] = ServerVersion,
                },
            }),
            "ping" => JsonRpc.Success(id, new JsonObject()),
            "resources/list" => JsonRpc.Success(id, new JsonObject
            {
                ["resources"] = new JsonArray(),
            }),
            "prompts/list" => JsonRpc.Success(id, new JsonObject
            {
                ["prompts"] = new JsonArray(),
            }),
            "tools/list" or "tools/call" => await SendPipeRequestAsync(request),
            _ => JsonRpc.Error(id, -32601, $"Unsupported MCP method: {method}"),
        };
    }

    private static async Task<JsonObject> SendPipeRequestAsync(JsonObject request)
    {
        await using var pipe = new NamedPipeClientStream(
            ".",
            GetPipeName(),
            PipeDirection.InOut,
            PipeOptions.Asynchronous | PipeOptions.CurrentUserOnly);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        try
        {
            await pipe.ConnectAsync(timeout.Token);
        }
        catch (OperationCanceledException)
        {
            throw new InvalidOperationException(
                "The hidden UN Workshop GhidrAssist MCP supervisor is not running.");
        }

        using var reader = new StreamReader(
            pipe,
            new UTF8Encoding(false),
            detectEncodingFromByteOrderMarks: false,
            bufferSize: 4096,
            leaveOpen: true);
        using var writer = new StreamWriter(
            pipe,
            new UTF8Encoding(false),
            bufferSize: 4096,
            leaveOpen: true)
        {
            AutoFlush = true,
            NewLine = "\n",
        };
        await writer.WriteLineAsync(request.ToJsonString(JsonOptions));
        var response = await reader.ReadLineAsync(timeout.Token)
            ?? throw new InvalidDataException("The MCP supervisor closed its pipe without a response.");
        return JsonNode.Parse(response)?.AsObject()
            ?? throw new InvalidDataException("The MCP supervisor returned invalid JSON.");
    }

    internal static string GetPipeName()
    {
        var sid = WindowsIdentity.GetCurrent().User?.Value
            ?? throw new InvalidOperationException("The current Windows user has no SID.");
        return $"UNWorkshop-GhidrAssistMCP-{sid}";
    }

    private sealed record SupervisorOptions(
        string DisassemblyRoot,
        string RuntimeRoot,
        string HostScript,
        string PowerShell)
    {
        internal static SupervisorOptions Parse(string[] args)
        {
            string Required(string name)
            {
                var index = Array.FindIndex(args, value =>
                    value.Equals(name, StringComparison.OrdinalIgnoreCase));
                if (index < 0 || index + 1 >= args.Length ||
                    string.IsNullOrWhiteSpace(args[index + 1]))
                {
                    throw new ArgumentException($"Missing required supervisor option: {name}");
                }
                return Path.GetFullPath(args[index + 1]);
            }

            return new SupervisorOptions(
                Required("--disassembly"),
                Required("--runtime"),
                Required("--host-script"),
                Required("--pwsh"));
        }
    }

    private sealed class Supervisor
    {
        private readonly SupervisorOptions _options;
        private readonly ConcurrentDictionary<string, Backend> _backends =
            new(StringComparer.OrdinalIgnoreCase);
        private readonly SemaphoreSlim _stateLock = new(1, 1);
        private readonly CancellationTokenSource _stopping = new();
        private readonly string _controlRoot;
        private readonly string _logsRoot;
        private readonly string _readyFile;
        private readonly string _stopFile;
        private readonly string _pidFile;
        private readonly string _stateFile;
        private readonly string _logFile;

        internal Supervisor(SupervisorOptions options)
        {
            _options = options;
            _controlRoot = Path.Combine(options.RuntimeRoot, "control");
            _logsRoot = Path.Combine(options.RuntimeRoot, "logs");
            _readyFile = Path.Combine(_controlRoot, "ready");
            _stopFile = Path.Combine(_controlRoot, "stop");
            _pidFile = Path.Combine(_controlRoot, "supervisor.pid");
            _stateFile = Path.Combine(_controlRoot, "backends.json");
            _logFile = Path.Combine(_logsRoot, "supervisor.log");
        }

        internal async Task<int> RunAsync()
        {
            Directory.CreateDirectory(_controlRoot);
            Directory.CreateDirectory(_logsRoot);
            RotateLog();

            using var mutex = new Mutex(
                initiallyOwned: true,
                $"Local\\{GetPipeName()}",
                out var createdNew);
            if (!createdNew)
            {
                return 0;
            }

            try
            {
                DeleteIfPresent(_stopFile);
                DeleteIfPresent(_readyFile);
                File.WriteAllText(_pidFile, Environment.ProcessId.ToString(CultureInfo.InvariantCulture));
                Log("Discovering maintained Ghidra projects.");

                foreach (var target in DiscoverTargets())
                {
                    _backends[target.Name] = new Backend(this, target);
                }
                if (_backends.IsEmpty)
                {
                    throw new InvalidOperationException(
                        $"No Ghidra projects were found below {_options.DisassemblyRoot}.");
                }

                await Task.WhenAll(_backends.Values.Select(backend =>
                    backend.EnsureStartedAsync(_stopping.Token)));
                await WriteStateAsync();
                File.WriteAllText(_readyFile, string.Empty);
                Log($"Ready with targets: {string.Join(", ", _backends.Keys.Order())}");

                var stopMonitor = MonitorStopFileAsync();
                await ServePipeAsync(_stopping.Token);
                await stopMonitor;
                return 0;
            }
            catch (OperationCanceledException) when (_stopping.IsCancellationRequested)
            {
                return 0;
            }
            catch (Exception exception)
            {
                Log(exception.ToString());
                return 1;
            }
            finally
            {
                _stopping.Cancel();
                await Task.WhenAll(_backends.Values.Select(backend => backend.StopAsync()));
                DeleteIfPresent(_readyFile);
                DeleteIfPresent(_pidFile);
                DeleteIfPresent(_stateFile);
                DeleteIfPresent(_stopFile);
                try
                {
                    mutex.ReleaseMutex();
                }
                catch (ApplicationException)
                {
                }
            }
        }

        private IReadOnlyList<Target> DiscoverTargets()
        {
            if (!Directory.Exists(_options.DisassemblyRoot))
            {
                throw new DirectoryNotFoundException(
                    $"Disassembly root was not found: {_options.DisassemblyRoot}");
            }

            var targets = new List<Target>();
            foreach (var targetRoot in Directory.GetDirectories(_options.DisassemblyRoot)
                         .Order(StringComparer.OrdinalIgnoreCase))
            {
                var name = Path.GetFileName(targetRoot);
                var projectLocation = Path.Combine(targetRoot, "ghidra");
                if (!Directory.Exists(projectLocation))
                {
                    continue;
                }
                var projects = Directory.GetFiles(projectLocation, "*.gpr");
                if (projects.Length == 0)
                {
                    continue;
                }
                if (projects.Length != 1)
                {
                    throw new InvalidDataException(
                        $"Target '{name}' must contain exactly one Ghidra project.");
                }

                var projectName = Path.GetFileNameWithoutExtension(projects[0]);
                var programs = ReadPrograms(targetRoot, projectLocation, projectName);
                if (programs.Count == 0)
                {
                    throw new InvalidDataException(
                        $"Ghidra project '{name}' does not contain a discoverable program.");
                }
                targets.Add(new Target(name, projectName, programs));
            }
            return targets;
        }

        private static IReadOnlyList<string> ReadPrograms(
            string targetRoot,
            string projectLocation,
            string projectName)
        {
            var manifestPath = Path.Combine(targetRoot, "manifest.tsv");
            if (File.Exists(manifestPath))
            {
                var lines = File.ReadAllLines(manifestPath);
                if (lines.Length > 1)
                {
                    var headers = lines[0].Split('\t')
                        .Select(value => value.Trim().Trim('"'))
                        .ToArray();
                    var programIndex = Array.FindIndex(headers, value =>
                        value.Equals("program", StringComparison.OrdinalIgnoreCase));
                    if (programIndex >= 0)
                    {
                        return lines.Skip(1)
                            .Select(line => line.Split('\t'))
                            .Where(fields => programIndex < fields.Length)
                            .Select(fields => fields[programIndex].Trim().Trim('"'))
                            .Where(value => !string.IsNullOrWhiteSpace(value))
                            .Distinct(StringComparer.OrdinalIgnoreCase)
                            .ToArray();
                    }
                }
            }

            var indexPath = Path.Combine(
                projectLocation,
                $"{projectName}.rep",
                "idata",
                "~index.dat");
            if (!File.Exists(indexPath))
            {
                return Array.Empty<string>();
            }
            var pattern = new Regex(@"^\s+\d+:([^:]+):", RegexOptions.CultureInvariant);
            return File.ReadLines(indexPath)
                .Select(line => pattern.Match(line))
                .Where(match => match.Success)
                .Select(match => match.Groups[1].Value)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }

        private async Task MonitorStopFileAsync()
        {
            while (!_stopping.IsCancellationRequested)
            {
                if (File.Exists(_stopFile))
                {
                    Log("Stop requested.");
                    _stopping.Cancel();
                    return;
                }
                await Task.Delay(250);
            }
        }

        private async Task ServePipeAsync(CancellationToken cancellationToken)
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                var pipe = new NamedPipeServerStream(
                    GetPipeName(),
                    PipeDirection.InOut,
                    NamedPipeServerStream.MaxAllowedServerInstances,
                    PipeTransmissionMode.Byte,
                    PipeOptions.Asynchronous | PipeOptions.CurrentUserOnly);
                try
                {
                    await pipe.WaitForConnectionAsync(cancellationToken);
                }
                catch
                {
                    await pipe.DisposeAsync();
                    throw;
                }

                _ = HandlePipeConnectionAsync(pipe, cancellationToken);
            }
        }

        private async Task HandlePipeConnectionAsync(
            NamedPipeServerStream pipe,
            CancellationToken cancellationToken)
        {
            await using (pipe)
            using (var reader = new StreamReader(
                       pipe,
                       new UTF8Encoding(false),
                       detectEncodingFromByteOrderMarks: false,
                       bufferSize: 4096,
                       leaveOpen: true))
            using (var writer = new StreamWriter(
                       pipe,
                       new UTF8Encoding(false),
                       bufferSize: 4096,
                       leaveOpen: true)
                   {
                       AutoFlush = true,
                       NewLine = "\n",
                   })
            {
                JsonObject? request = null;
                JsonObject response;
                try
                {
                    var line = await reader.ReadLineAsync(cancellationToken)
                        ?? throw new InvalidDataException("Pipe request is empty.");
                    request = JsonNode.Parse(line)?.AsObject()
                        ?? throw new InvalidDataException("Pipe request is not a JSON object.");
                    response = await HandleMcpRequestAsync(request, cancellationToken);
                }
                catch (Exception exception)
                {
                    Log(exception.ToString());
                    response = JsonRpc.Error(request?["id"], -32000, exception.Message);
                }
                await writer.WriteLineAsync(response.ToJsonString(JsonOptions));
            }
        }

        private async Task<JsonObject> HandleMcpRequestAsync(
            JsonObject request,
            CancellationToken cancellationToken)
        {
            var method = request["method"]?.GetValue<string>()
                ?? throw new InvalidDataException("MCP request has no method.");
            return method switch
            {
                "tools/list" => await ListToolsAsync(request["id"], cancellationToken),
                "tools/call" => await CallToolAsync(request, cancellationToken),
                _ => JsonRpc.Error(request["id"], -32601, $"Unsupported routed method: {method}"),
            };
        }

        private async Task<JsonObject> ListToolsAsync(
            JsonNode? id,
            CancellationToken cancellationToken)
        {
            var first = _backends.Values.OrderBy(backend => backend.Target.Name).First();
            var sourceResponse = await first.SendAsync(new JsonObject
            {
                ["jsonrpc"] = "2.0",
                ["id"] = 1,
                ["method"] = "tools/list",
                ["params"] = new JsonObject(),
            }, cancellationToken);
            if (sourceResponse["error"] is not null)
            {
                return JsonRpc.Error(id, -32000, sourceResponse["error"]!.ToJsonString());
            }

            var sourceTools = sourceResponse["result"]?["tools"]?.AsArray()
                ?? throw new InvalidDataException("Backend tools/list returned no tools.");
            var targets = new JsonArray(_backends.Keys
                .Order(StringComparer.OrdinalIgnoreCase)
                .Select(name => (JsonNode?)name)
                .ToArray());
            var tools = new JsonArray();
            foreach (var sourceToolNode in sourceTools)
            {
                var tool = sourceToolNode!.DeepClone().AsObject();
                var name = tool["name"]!.GetValue<string>();
                if (name == "list_binaries")
                {
                    tool["description"] =
                        "List programs across every maintained disassembly tree, or one target.";
                    tool["inputSchema"] = new JsonObject
                    {
                        ["type"] = "object",
                        ["properties"] = new JsonObject
                        {
                            ["target"] = new JsonObject
                            {
                                ["type"] = "string",
                                ["enum"] = targets.DeepClone(),
                                ["description"] = "Optional disassembly tree; omit to list all trees.",
                            },
                        },
                        ["required"] = new JsonArray(),
                    };
                }
                else
                {
                    var schema = tool["inputSchema"]!.AsObject();
                    var properties = schema["properties"]?.AsObject() ?? new JsonObject();
                    schema["properties"] = properties;
                    properties["target"] = new JsonObject
                    {
                        ["type"] = "string",
                        ["enum"] = targets.DeepClone(),
                        ["description"] = "Maintained disassembly tree containing the program.",
                    };
                    var required = schema["required"]?.AsArray() ?? new JsonArray();
                    schema["required"] = required;
                    AddRequired(required, "target");
                    AddRequired(required, "program_name");
                }
                tools.Add(tool);
            }

            return JsonRpc.Success(id, new JsonObject { ["tools"] = tools });
        }

        private async Task<JsonObject> CallToolAsync(
            JsonObject request,
            CancellationToken cancellationToken)
        {
            var parameters = request["params"]?.AsObject()
                ?? throw new InvalidDataException("tools/call has no parameters.");
            var name = parameters["name"]?.GetValue<string>()
                ?? throw new InvalidDataException("tools/call has no tool name.");
            var arguments = parameters["arguments"]?.AsObject() ?? new JsonObject();
            if (name == "list_binaries")
            {
                return await ListBinariesAsync(request["id"], arguments, cancellationToken);
            }

            var targetName = arguments["target"]?.GetValue<string>();
            var programName = arguments["program_name"]?.GetValue<string>();
            if (string.IsNullOrWhiteSpace(targetName) || string.IsNullOrWhiteSpace(programName))
            {
                return ToolError(request["id"],
                    "Every analysis call requires target and program_name.");
            }
            if (!_backends.TryGetValue(targetName, out var backend))
            {
                return ToolError(request["id"],
                    $"Unknown disassembly target '{targetName}'. Available targets: " +
                    string.Join(", ", _backends.Keys.Order()));
            }
            if (!backend.Target.MatchesProgram(programName))
            {
                return ToolError(request["id"],
                    $"Program '{programName}' is not in target '{backend.Target.Name}'. " +
                    $"Available programs: {string.Join(", ", backend.Target.Programs)}");
            }

            var forwarded = request.DeepClone().AsObject();
            forwarded["params"]!["arguments"]!.AsObject().Remove("target");
            return await backend.SendAsync(forwarded, cancellationToken);
        }

        private async Task<JsonObject> ListBinariesAsync(
            JsonNode? id,
            JsonObject arguments,
            CancellationToken cancellationToken)
        {
            var requestedTarget = arguments["target"]?.GetValue<string>();
            IReadOnlyList<Backend> selected;
            if (string.IsNullOrWhiteSpace(requestedTarget))
            {
                selected = _backends.Values.OrderBy(backend => backend.Target.Name).ToArray();
            }
            else if (_backends.TryGetValue(requestedTarget, out var backend))
            {
                selected = new[] { backend };
            }
            else
            {
                return ToolError(id,
                    $"Unknown disassembly target '{requestedTarget}'. Available targets: " +
                    string.Join(", ", _backends.Keys.Order()));
            }

            var text = new StringBuilder();
            foreach (var backend in selected)
            {
                var response = await backend.SendAsync(new JsonObject
                {
                    ["jsonrpc"] = "2.0",
                    ["id"] = 1,
                    ["method"] = "tools/call",
                    ["params"] = new JsonObject
                    {
                        ["name"] = "list_binaries",
                        ["arguments"] = new JsonObject(),
                    },
                }, cancellationToken);
                if (response["error"] is not null)
                {
                    throw new InvalidOperationException(response["error"]!.ToJsonString());
                }
                text.Append("Target: ").AppendLine(backend.Target.Name);
                foreach (var content in response["result"]?["content"]?.AsArray() ?? new JsonArray())
                {
                    if (content?["type"]?.GetValue<string>() == "text")
                    {
                        text.AppendLine(content["text"]?.GetValue<string>() ?? string.Empty);
                    }
                }
            }
            return JsonRpc.Success(id, new JsonObject
            {
                ["content"] = new JsonArray
                {
                    new JsonObject
                    {
                        ["type"] = "text",
                        ["text"] = text.ToString().TrimEnd(),
                    },
                },
                ["isError"] = false,
            });
        }

        private static JsonObject ToolError(JsonNode? id, string message) =>
            JsonRpc.Success(id, new JsonObject
            {
                ["content"] = new JsonArray
                {
                    new JsonObject { ["type"] = "text", ["text"] = message },
                },
                ["isError"] = true,
            });

        private static void AddRequired(JsonArray required, string name)
        {
            if (!required.Any(node => node?.GetValue<string>() == name))
            {
                required.Add(name);
            }
        }

        internal async Task WriteStateAsync()
        {
            await _stateLock.WaitAsync();
            try
            {
                var states = new JsonArray(_backends.Values
                    .OrderBy(backend => backend.Target.Name)
                    .Select(backend => (JsonNode?)backend.GetState())
                    .ToArray());
                var temporary = _stateFile + ".new";
                await File.WriteAllTextAsync(temporary, states.ToJsonString(
                    new JsonSerializerOptions { WriteIndented = true }));
                File.Move(temporary, _stateFile, overwrite: true);
            }
            finally
            {
                _stateLock.Release();
            }
        }

        internal void Log(string message)
        {
            try
            {
                File.AppendAllText(
                    _logFile,
                    $"{DateTimeOffset.Now:O} {message}{Environment.NewLine}",
                    new UTF8Encoding(false));
            }
            catch
            {
            }
        }

        private void RotateLog()
        {
            var previous = _logFile + ".previous";
            DeleteIfPresent(previous);
            if (File.Exists(_logFile))
            {
                File.Move(_logFile, previous);
            }
        }

        private static void DeleteIfPresent(string path)
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        private sealed record Target(
            string Name,
            string ProjectName,
            IReadOnlyList<string> Programs)
        {
            internal bool MatchesProgram(string candidate)
            {
                var normalized = candidate.Replace('\\', '/').Trim('/');
                return Programs.Any(program =>
                    normalized.Equals(program, StringComparison.OrdinalIgnoreCase) ||
                    normalized.EndsWith('/' + program, StringComparison.OrdinalIgnoreCase));
            }
        }

        private sealed class Backend
        {
            private readonly Supervisor _owner;
            private readonly SemaphoreSlim _lifecycleLock = new(1, 1);
            private Process? _process;
            private BackendClient? _client;
            private int _port;

            internal Backend(Supervisor owner, Target target)
            {
                _owner = owner;
                Target = target;
            }

            internal Target Target { get; }

            internal async Task EnsureStartedAsync(CancellationToken cancellationToken)
            {
                await _lifecycleLock.WaitAsync(cancellationToken);
                try
                {
                    if (_process is { HasExited: false } && _client is not null)
                    {
                        return;
                    }

                    _process?.Dispose();
                    _client?.Dispose();
                    _port = AllocateLoopbackPort();
                    var startInfo = new ProcessStartInfo(_owner._options.PowerShell)
                    {
                        UseShellExecute = false,
                        CreateNoWindow = true,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        WorkingDirectory = Path.GetDirectoryName(_owner._options.HostScript)!,
                    };
                    foreach (var argument in new[]
                             {
                                 "-NoProfile",
                                 "-NonInteractive",
                                 "-ExecutionPolicy",
                                 "Bypass",
                                 "-File",
                                 _owner._options.HostScript,
                                 "-Target",
                                 Target.Name,
                                 "-Program",
                                 Target.Programs[0],
                                 "-Port",
                                 _port.ToString(CultureInfo.InvariantCulture),
                             })
                    {
                        startInfo.ArgumentList.Add(argument);
                    }
                    _process = Process.Start(startInfo)
                        ?? throw new InvalidOperationException(
                            $"Failed to start the Ghidra backend for {Target.Name}.");
                    _process.OutputDataReceived += (_, eventArgs) =>
                    {
                        if (!string.IsNullOrWhiteSpace(eventArgs.Data))
                        {
                            _owner.Log($"{Target.Name} stdout: {eventArgs.Data}");
                        }
                    };
                    _process.ErrorDataReceived += (_, eventArgs) =>
                    {
                        if (!string.IsNullOrWhiteSpace(eventArgs.Data))
                        {
                            _owner.Log($"{Target.Name} stderr: {eventArgs.Data}");
                        }
                    };
                    _process.BeginOutputReadLine();
                    _process.BeginErrorReadLine();
                    _owner.Log(
                        $"Started {Target.Name} backend pid={_process.Id} port={_port}.");

                    var deadline = DateTime.UtcNow.AddSeconds(120);
                    while (DateTime.UtcNow < deadline)
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                        if (_process.HasExited)
                        {
                            throw new InvalidOperationException(
                                $"The {Target.Name} backend exited with code {_process.ExitCode}.");
                        }
                        if (await CanConnectAsync(_port))
                        {
                            _client = new BackendClient(_port);
                            await _client.InitializeAsync(cancellationToken);
                            await _owner.WriteStateAsync();
                            return;
                        }
                        await Task.Delay(250, cancellationToken);
                    }
                    throw new TimeoutException(
                        $"The {Target.Name} backend did not start within 120 seconds.");
                }
                finally
                {
                    _lifecycleLock.Release();
                }
            }

            internal async Task<JsonObject> SendAsync(
                JsonObject request,
                CancellationToken cancellationToken)
            {
                await EnsureStartedAsync(cancellationToken);
                return await _client!.SendAsync(request, cancellationToken);
            }

            internal JsonObject GetState() => new()
            {
                ["target"] = Target.Name,
                ["programs"] = new JsonArray(Target.Programs.Select(value => (JsonNode?)value).ToArray()),
                ["port"] = _port,
                ["pid"] = _process is { HasExited: false } ? _process.Id : null,
            };

            internal async Task StopAsync()
            {
                await _lifecycleLock.WaitAsync();
                try
                {
                    _client?.Dispose();
                    _client = null;
                    if (_process is not { HasExited: false })
                    {
                        _process?.Dispose();
                        _process = null;
                        return;
                    }

                    var completion = Path.Combine(
                        _owner._options.RuntimeRoot,
                        Target.Name,
                        "control",
                        "complete");
                    Directory.CreateDirectory(Path.GetDirectoryName(completion)!);
                    await File.WriteAllTextAsync(completion, string.Empty);
                    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                    try
                    {
                        await _process.WaitForExitAsync(timeout.Token);
                    }
                    catch (OperationCanceledException)
                    {
                        _process.Kill(entireProcessTree: true);
                        await _process.WaitForExitAsync();
                    }
                    _process.Dispose();
                    _process = null;
                }
                catch (Exception exception)
                {
                    _owner.Log($"Failed to stop {Target.Name}: {exception}");
                }
                finally
                {
                    _lifecycleLock.Release();
                }
            }

            private static int AllocateLoopbackPort()
            {
                var listener = new TcpListener(IPAddress.Loopback, 0);
                listener.Start();
                try
                {
                    return ((IPEndPoint)listener.LocalEndpoint).Port;
                }
                finally
                {
                    listener.Stop();
                }
            }

            private static async Task<bool> CanConnectAsync(int port)
            {
                using var client = new TcpClient();
                using var timeout = new CancellationTokenSource(TimeSpan.FromMilliseconds(500));
                try
                {
                    await client.ConnectAsync(IPAddress.Loopback, port, timeout.Token);
                    return client.Connected;
                }
                catch
                {
                    return false;
                }
            }
        }

        private sealed class BackendClient : IDisposable
        {
            private readonly HttpClient _http = new()
            {
                Timeout = TimeSpan.FromSeconds(120),
            };
            private readonly Uri _endpoint;
            private readonly SemaphoreSlim _requestLock = new(1, 1);
            private string? _sessionId;

            internal BackendClient(int port)
            {
                _endpoint = new Uri($"http://127.0.0.1:{port}/mcp");
            }

            internal async Task InitializeAsync(CancellationToken cancellationToken)
            {
                await _requestLock.WaitAsync(cancellationToken);
                try
                {
                    await InitializeCoreAsync(cancellationToken);
                }
                finally
                {
                    _requestLock.Release();
                }
            }

            internal async Task<JsonObject> SendAsync(
                JsonObject request,
                CancellationToken cancellationToken)
            {
                await _requestLock.WaitAsync(cancellationToken);
                try
                {
                    if (_sessionId is null)
                    {
                        await InitializeCoreAsync(cancellationToken);
                    }
                    return await PostAsync(request, includeSession: true, cancellationToken)
                        ?? throw new InvalidDataException("GhidrAssistMCP returned an empty response.");
                }
                finally
                {
                    _requestLock.Release();
                }
            }

            private async Task InitializeCoreAsync(CancellationToken cancellationToken)
            {
                var request = new JsonObject
                {
                    ["jsonrpc"] = "2.0",
                    ["id"] = 1,
                    ["method"] = "initialize",
                    ["params"] = new JsonObject
                    {
                        ["protocolVersion"] = "2025-03-26",
                        ["capabilities"] = new JsonObject(),
                        ["clientInfo"] = new JsonObject
                        {
                            ["name"] = "un-workshop-router",
                            ["version"] = ServerVersion,
                        },
                    },
                };
                var response = await PostWithResponseAsync(
                    request,
                    includeSession: false,
                    cancellationToken);
                _sessionId = response.SessionId
                    ?? throw new InvalidDataException("GhidrAssistMCP returned no session ID.");
                await PostAsync(new JsonObject
                {
                    ["jsonrpc"] = "2.0",
                    ["method"] = "notifications/initialized",
                    ["params"] = new JsonObject(),
                }, includeSession: true, cancellationToken);
            }

            private async Task<JsonObject?> PostAsync(
                JsonObject body,
                bool includeSession,
                CancellationToken cancellationToken) =>
                (await PostWithResponseAsync(body, includeSession, cancellationToken)).Body;

            private async Task<HttpResult> PostWithResponseAsync(
                JsonObject body,
                bool includeSession,
                CancellationToken cancellationToken)
            {
                using var request = new HttpRequestMessage(HttpMethod.Post, _endpoint);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("text/event-stream"));
                if (includeSession)
                {
                    request.Headers.Add("mcp-session-id", _sessionId);
                }
                request.Content = new StringContent(
                    body.ToJsonString(JsonOptions),
                    new UTF8Encoding(false),
                    "application/json");
                using var response = await _http.SendAsync(request, cancellationToken);
                var text = await response.Content.ReadAsStringAsync(cancellationToken);
                response.EnsureSuccessStatusCode();
                var sessionId = response.Headers.TryGetValues("mcp-session-id", out var values)
                    ? values.FirstOrDefault()
                    : null;
                return new HttpResult(sessionId, ParseResponse(text));
            }

            private static JsonObject? ParseResponse(string text)
            {
                if (string.IsNullOrWhiteSpace(text))
                {
                    return null;
                }
                if (text.TrimStart().StartsWith('{'))
                {
                    return JsonNode.Parse(text)?.AsObject();
                }
                foreach (var line in text.Split('\n'))
                {
                    if (line.StartsWith("data:", StringComparison.Ordinal))
                    {
                        return JsonNode.Parse(line[5..].Trim())?.AsObject();
                    }
                }
                throw new InvalidDataException("GhidrAssistMCP returned an unsupported response.");
            }

            public void Dispose()
            {
                _requestLock.Dispose();
                _http.Dispose();
            }

            private sealed record HttpResult(string? SessionId, JsonObject? Body);
        }
    }

    private static class JsonRpc
    {
        internal static JsonObject Success(JsonNode? id, JsonNode result) => new()
        {
            ["jsonrpc"] = "2.0",
            ["id"] = id?.DeepClone(),
            ["result"] = result,
        };

        internal static JsonObject Error(JsonNode? id, int code, string message) => new()
        {
            ["jsonrpc"] = "2.0",
            ["id"] = id?.DeepClone(),
            ["error"] = new JsonObject
            {
                ["code"] = code,
                ["message"] = message,
            },
        };
    }
}
