# Feature Request: Custom URL Protocol Handler

## Summary

Implement a custom URL protocol handler (`novadoom://`) in the NovaDoom client
to enable seamless server joining from web browsers. This is a critical feature
for the Nova Doom web platform user experience.

---

## Background

The Nova Doom web platform (novadoom.com) allows users to create, configure, and
manage game servers through a web interface. When users want to join a server,
they currently need to:

1. Copy the server address
2. Open the NovaDoom client
3. Manually enter the server address

This creates friction and a poor user experience. With a custom URL protocol,
clicking "Join Server" on the website would automatically launch NovaDoom and
connect to the server.

---

## Proposed Solution

### URL Scheme

```
novadoom://connect/{host}:{port}[?password={password}]
```

### Examples

```
novadoom://connect/novadoom.com:10666
novadoom://connect/play.novadoom.com:10670
novadoom://connect/192.168.1.100:10666?password=secret123
```

---

## Implementation Details

### Windows

Register the protocol handler in Windows Registry during installation:

```reg
[HKEY_CLASSES_ROOT\novadoom]
@="URL:NovaDoom Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\novadoom\DefaultIcon]
@="\"C:\\Program Files\\NovaDoom\\novadoom.exe\",0"

[HKEY_CLASSES_ROOT\novadoom\shell]

[HKEY_CLASSES_ROOT\novadoom\shell\open]

[HKEY_CLASSES_ROOT\novadoom\shell\open\command]
@="\"C:\\Program Files\\NovaDoom\\novadoom.exe\" \"%1\""
```

Installer (Inno Setup example):

```pascal
[Registry]
Root: HKCR; Subkey: "novadoom"; ValueType: string; ValueData: "URL:NovaDoom Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "novadoom"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCR; Subkey: "novadoom\DefaultIcon"; ValueType: string; ValueData: """{app}\novadoom.exe"",0"
Root: HKCR; Subkey: "novadoom\shell\open\command"; ValueType: string; ValueData: """{app}\novadoom.exe"" ""%1"""
```

### macOS

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>NovaDoom Connect</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>novadoom</string>
    </array>
  </dict>
</array>
```

Handle URL in application delegate:

```objc
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        if ([url.scheme isEqualToString:@"novadoom"]) {
            [self handleNovaDoomURL:url];
        }
    }
}

- (void)handleNovaDoomURL:(NSURL *)url {
    // Parse: novadoom://connect/host:port?password=xxx
    NSString *host = url.host;      // "connect"
    NSString *path = url.path;      // "/host:port"

    // Extract actual host:port from path
    // Connect to server
}
```

### Linux

Create `.desktop` file in `/usr/share/applications/`:

```ini
[Desktop Entry]
Name=NovaDoom
Exec=novadoom %u
Type=Application
MimeType=x-scheme-handler/novadoom;
Categories=Game;
```

Register the handler:

```bash
xdg-mime default novadoom.desktop x-scheme-handler/novadoom
```

---

## Client-Side URL Parsing

The client needs to parse the incoming URL and extract connection parameters:

```cpp
// Pseudo-code for URL parsing
void handleProtocolUrl(const std::string& url) {
    // Expected format: novadoom://connect/host:port?password=xxx

    if (!startsWith(url, "novadoom://connect/")) {
        return; // Invalid URL
    }

    std::string remainder = url.substr(19); // After "novadoom://connect/"

    // Split on '?' for query params
    size_t queryPos = remainder.find('?');
    std::string hostPort = remainder.substr(0, queryPos);
    std::string query = (queryPos != std::string::npos)
        ? remainder.substr(queryPos + 1)
        : "";

    // Parse host:port
    size_t colonPos = hostPort.rfind(':');
    std::string host = hostPort.substr(0, colonPos);
    int port = std::stoi(hostPort.substr(colonPos + 1));

    // Parse password if present
    std::string password = parseQueryParam(query, "password");

    // Connect to server
    connectToServer(host, port, password);
}
```

### Existing Command-Line Connection

If NovaDoom already supports command-line connection parameters:

```bash
# If this works:
novadoom -connect novadoom.com:10666

# Then the protocol handler just needs to translate:
# novadoom://connect/novadoom.com:10666 → novadoom -connect novadoom.com:10666
```

---

## Security Considerations

1. **URL Validation**: Validate all URL components before processing
2. **Hostname Restrictions**: Consider only allowing connections to known/trusted
   hosts (optional)
3. **Password Handling**: Don't log passwords, clear from memory after use
4. **Prompt User**: Consider showing a confirmation dialog before connecting
   (similar to how Discord/Steam handle protocol links)

### Optional Confirmation Dialog

```
┌─────────────────────────────────────────────┐
│ NovaDoom                                    │
├─────────────────────────────────────────────┤
│ A website wants to connect you to:          │
│                                             │
│   Server: novadoom.com:10666                │
│                                             │
│ Do you want to connect?                     │
│                                             │
│              [Cancel]  [Connect]            │
└─────────────────────────────────────────────┘
```

---

## Web Platform Integration

Once implemented, the web platform will use it like this:

```typescript
// Frontend component
const JoinServerButton: React.FC<{ server: Server }> = ({ server }) => {
  const handleJoin = () => {
    const url = server.joinPassword
      ? `novadoom://connect/${server.host}:${
          server.port
        }?password=${encodeURIComponent(server.joinPassword)}`
      : `novadoom://connect/${server.host}:${server.port}`;

    window.location.href = url;
  };

  return <button onClick={handleJoin}>Join Server</button>;
};
```

Browser behavior:

1. User clicks "Join Server"
2. Browser recognizes `novadoom://` protocol
3. Browser prompts: "Open NovaDoom?" (first time only)
4. User clicks "Open"
5. NovaDoom launches with connection parameters
6. Game connects to server automatically

---

## Fallback Behavior

If the client isn't installed, the browser will show an error. The web platform
handles this by:

1. Detecting if the protocol handler succeeded (via focus/blur events)
2. Showing a fallback modal if it fails:

```
┌─────────────────────────────────────────────┐
│ NovaDoom Not Detected                       │
├─────────────────────────────────────────────┤
│ It looks like NovaDoom isn't installed.     │
│                                             │
│ [Download NovaDoom]                         │
│                                             │
│ ─ OR ─                                      │
│                                             │
│ Already installed? Connect manually:        │
│ ┌─────────────────────────────────────────┐ │
│ │ novadoom.com:10666            [Copy]    │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## Testing

### Manual Testing

1. **Windows**: Click `novadoom://connect/localhost:10666` link in browser
2. **macOS**: Same test, verify protocol registered in System Preferences
3. **Linux**: Test with `xdg-open novadoom://connect/localhost:10666`

### Test Cases

| Test Case                   | Expected Result                         |
| --------------------------- | --------------------------------------- |
| Valid URL without password  | Client launches, connects to server     |
| Valid URL with password     | Client launches, connects with password |
| Invalid host                | Client shows connection error           |
| Invalid port                | Client shows error or ignores           |
| Malformed URL               | Client ignores/logs error               |
| URL with special characters | Properly decoded and handled            |

---

## Priority

**High** - This feature significantly improves user experience for the web
platform. Without it, users must manually copy/paste server addresses, which
creates friction and reduces engagement.

---

## References

- [Windows URI Schemes](<https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa767914(v=vs.85)>)
- [macOS URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Linux Desktop Entry Spec](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
- [Steam Protocol Example](steam://connect/ip:port)
- [Discord Protocol Example](discord://invite/xxx)

---

## Questions for Discussion

1. Should we show a confirmation dialog before connecting?
2. Do we want to support additional actions beyond `connect`? (e.g.,
   `novadoom://spectate/...`)
3. Should there be a whitelist of allowed hosts for security?
4. What version should this be targeted for?

---

## Contact

For questions about this feature request or web platform integration, contact
the Nova Doom platform team.
