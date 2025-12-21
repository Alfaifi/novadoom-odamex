# WAD Download System

This document explains how NovaDoom's WAD file download system works, including the download sources, verification process, and configuration options.

## Overview

When a client connects to a server that requires WAD files the client doesn't have, NovaDoom can automatically download them from configured mirror sites. The system uses HTTP/HTTPS with libcurl and includes security features like MD5 verification and commercial WAD detection.

**Key Files:**
- `client/src/cl_download.cpp` - Download state machine and orchestration
- `client/src/otransfer.cpp` - HTTP transfer implementation using libcurl
- `client/src/cl_main.cpp` - Server connection handling and download triggering
- `client/src/cl_cvarlist.cpp` - Download-related CVARs

## Download Triggers

### Automatic (Server Connection)

When connecting to a server, the client receives:
1. List of required WAD filenames
2. MD5 hash for each WAD

If the client doesn't have a matching WAD (same filename AND hash), `CL_HandleMissingWad()` is called (`cl_main.cpp:1480-1542`).

### Manual (Console Command)

```
download get <filename>
download stop
```

## Download Site Sources

The system combines two sources of download URLs:

### 1. Server-Provided Sites (`sv_downloadsites`)

- Set by the server administrator
- Takes priority over client sites
- Essential for servers running custom content

### 2. Client Default Sites (`cl_downloadsites`)

Built-in list of public WAD mirrors (fallback):
```
https://static.allfearthesentinel.com/wads/
https://doomshack.org/wads/
https://wads.doomleague.org/
https://doom.dogsoft.net/getwad.php?search=
https://doomshack.org/uploads/
https://wads.firestick.games/
... and more
```

### Site Selection Logic

```cpp
// cl_main.cpp:1521-1533
StringTokens serversites = TokenizeString(sv_downloadsites.str(), " ");
StringTokens clientsites = TokenizeString(cl_downloadsites.str(), " ");

// Shuffle both lists to distribute load
std::shuffle(serversites.begin(), serversites.end(), rng);
std::shuffle(clientsites.begin(), clientsites.end(), rng);

// Combine: server sites first, then client sites
downloadsites.insert(downloadsites.end(), serversites.begin(), serversites.end());
downloadsites.insert(downloadsites.end(), clientsites.begin(), clientsites.end());
```

**Order of attempts:**
1. Server-provided sites (shuffled)
2. Client default sites (shuffled)

## URL Construction

URLs are constructed by appending the filename to the base URL:

```
base_url + filename = full_url
```

Example:
```
https://example.com/wads/ + mymap.wad = https://example.com/wads/mymap.wad
```

**URL Requirements** (`cl_download.cpp:159-167`):
- Must start with `http://` or `https://`
- Must end with `/` or `=` (auto-appended if missing)

The `=` ending supports query-string based mirrors like:
```
https://doom.dogsoft.net/getwad.php?search=mymap.wad
```

## Download Process

### State Machine

```
STATE_SHUTDOWN → STATE_READY
STATE_READY → STATE_CHECKING (on CL_StartDownload)
STATE_CHECKING → STATE_DOWNLOADING (when file found)
STATE_DOWNLOADING → STATE_READY (on success or error)
```

### Phase 1: File Existence Check (HEAD Request)

Before downloading, the system checks if the file exists using HTTP HEAD:

```cpp
// otransfer.cpp:173-211 (OTransferCheck)
curl_easy_setopt(curl, CURLOPT_NOBODY, 1);           // HEAD request
curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);   // Follow redirects
curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 5);   // 5 second timeout
```

**Filename variants tried** (`cl_download.cpp:276-287`):
1. Original filename (e.g., `MyMap.wad`)
2. Lowercase (e.g., `mymap.wad`)
3. Uppercase (e.g., `MYMAP.WAD`)

Each site gets 3 attempts (one per variant) before moving to the next site.

### Phase 2: File Download (GET Request)

Once a file is found:

```cpp
// otransfer.cpp:331-370 (OTransfer)
curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, 5);
curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, curlProgress);
```

- Downloads to a `.part` temporary file
- Tracks download progress
- Validates Content-Type header

**Accepted Content-Types** (`otransfer.cpp:42-75`):
- `application/octet-stream`
- `application/x-doom`
- `text/html` (for redirects)

## Verification Process

### Search by Filename, Verify by Checksum

**Important:** The system searches mirrors by filename but verifies downloads by MD5 checksum.

```cpp
// otransfer.cpp:437-442
OMD5Hash actualHash = W_MD5(m_filePart);
if (!m_expectHash.empty() && m_expectHash != actualHash)
{
    remove(m_filePart.c_str());
    m_errorProc("Downloaded file is not the same as the server's file - file removed");
    return false;
}
```

### Verification Flow

```
Download complete
       ↓
Calculate MD5 hash of downloaded file
       ↓
Compare to server's expected hash
       ↓
   Match? ──Yes──→ Keep file, rename from .part, success
       │
      No
       ↓
Delete file, try next mirror
```

### Implications

| Scenario | Result |
|----------|--------|
| Mirror has exact same WAD (same hash) | Success |
| Mirror has same filename, different version | **Rejected** (hash mismatch) |
| Mirror doesn't have file | Tries next mirror |
| No mirror has matching file+hash | Download fails |

**For custom content:** If a server runs custom WADs that public mirrors don't have (or have different versions of), the fallback to `cl_downloadsites` will fail. Server administrators must configure `sv_downloadsites` to point to their own hosting.

## Security Features

### Commercial WAD Detection

Downloads are rejected if the file is a known commercial WAD:

```cpp
// otransfer.cpp:431-435
if (W_IsFilehashCommercialWAD(actualHash))
{
    remove(m_filePart.c_str());
    m_errorProc("Accidentally downloaded a commercial WAD - file removed");
    return false;
}
```

Also checked before download starts (`cl_download.cpp:178-193`):
- By filename: `W_IsFilenameCommercialWAD()`
- By hash: `W_IsFilehashCommercialWAD()`

### Path Traversal Prevention

Filenames are validated to prevent directory escape attacks:

```cpp
// otransfer.cpp:374-381
std::string cleanDest = M_CleanPath(dest);
if (cleanDest.find(dir) != 0)
{
    // Path escapes the download directory - reject
    return false;
}
```

### HTTPS Support

Full TLS/SSL support via libcurl for secure downloads.

### Timeout Protection

5-second connection timeout prevents hanging on unresponsive servers.

## Download Destination

Files are saved to the first writable location (`cl_download.cpp:318-341`):

1. `cl_waddownloaddir` cvar (if set)
2. `M_GetDownloadDir()` (platform-specific default)
3. `-waddir` command-line argument
4. `DOOMWADDIR` environment variable
5. `DOOMWADPATH` environment variable
6. `waddirs` cvar
7. Current working directory

### Fallback Naming

If the target filename already exists or can't be written, a fallback name is used:

```
original: mymap.wad
fallback: mymap.a1b2c3.wad  (first 6 chars of MD5 hash)
```

## Configuration CVARs

| CVAR | Default | Description |
|------|---------|-------------|
| `cl_downloadsites` | (public mirrors) | Space-separated list of download URLs |
| `sv_downloadsites` | (empty) | Server-provided download URLs |
| `cl_waddownloaddir` | (platform default) | Directory to save downloaded WADs |
| `cl_serverdownload` | `1` | Enable/disable automatic downloads |
| `cl_forcedownload` | `0` | Force re-download even if file exists (dev) |

## Server Configuration

For servers hosting custom content, set `sv_downloadsites`:

```cfg
# In server config
set sv_downloadsites "https://yourserver.com/wads/"
```

Multiple sites can be specified (space-separated):
```cfg
set sv_downloadsites "https://primary.com/wads/ https://backup.com/wads/"
```

## Integration with R2/S3 Private Buckets

The download system follows HTTP redirects (`CURLOPT_FOLLOWLOCATION`), enabling secure integration with private cloud storage buckets without exposing credentials to clients.

### Why Private Buckets?

- **Cost Control**: Prevent unauthorized downloads and bandwidth abuse
- **Access Control**: Restrict downloads to authenticated users or specific servers
- **Analytics**: Track download metrics through your API
- **Flexibility**: Dynamically control which files are available

### Option 1: Redirect API (Recommended)

Create an API endpoint that validates requests and redirects to presigned URLs.

**Server Configuration:**
```cfg
set sv_downloadsites "https://novadoom.com/api/wads/"
```

**API Flow:**
```
Client                         Your API                         R2 Bucket
   │                              │                                 │
   │  GET /api/wads/mymap.wad     │                                 │
   │─────────────────────────────>│                                 │
   │                              │                                 │
   │                              │  Generate presigned URL         │
   │                              │  (expires in 5-15 minutes)      │
   │                              │                                 │
   │  302 Redirect                │                                 │
   │  Location: r2.../mymap.wad?X-Amz-Signature=...                 │
   │<─────────────────────────────│                                 │
   │                                                                │
   │  GET /mymap.wad?X-Amz-Signature=...                            │
   │───────────────────────────────────────────────────────────────>│
   │                                                                │
   │  200 OK + file content                                         │
   │<───────────────────────────────────────────────────────────────│
```

**Example API Implementation (Node.js/Cloudflare Workers):**
```typescript
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const R2 = new S3Client({
  region: 'auto',
  endpoint: `https://${ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});

export async function handleWadRequest(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const filename = url.pathname.split('/').pop();

  // Optional: Validate request (API key, rate limiting, etc.)
  // const apiKey = request.headers.get('X-API-Key');
  // if (!isValidApiKey(apiKey)) return new Response('Unauthorized', { status: 401 });

  // Optional: Check if file exists / is allowed
  // if (!isAllowedFile(filename)) return new Response('Not Found', { status: 404 });

  // Generate presigned URL (expires in 15 minutes)
  const command = new GetObjectCommand({
    Bucket: 'novadoom-wads',
    Key: `wads/${filename}`,
  });

  const presignedUrl = await getSignedUrl(R2, command, { expiresIn: 900 });

  // Redirect client to presigned URL
  return Response.redirect(presignedUrl, 302);
}
```

**Advantages:**
- No client code changes required
- Presigned URLs expire (security)
- Can add authentication, rate limiting, logging
- R2 credentials never exposed to clients

### Option 2: Proxy API (Higher Control)

Proxy the download through your API instead of redirecting.

**Server Configuration:**
```cfg
set sv_downloadsites "https://novadoom.com/api/wads/"
```

**API Flow:**
```
Client                         Your API                         R2 Bucket
   │                              │                                 │
   │  GET /api/wads/mymap.wad     │                                 │
   │─────────────────────────────>│                                 │
   │                              │  GET (with R2 credentials)      │
   │                              │────────────────────────────────>│
   │                              │                                 │
   │                              │  200 OK + file content          │
   │                              │<────────────────────────────────│
   │                              │                                 │
   │  200 OK + file content       │                                 │
   │  (streamed through API)      │                                 │
   │<─────────────────────────────│                                 │
```

**Example Implementation:**
```typescript
export async function handleWadRequest(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const filename = url.pathname.split('/').pop();

  // Fetch from R2 using service credentials
  const r2Response = await R2.send(new GetObjectCommand({
    Bucket: 'novadoom-wads',
    Key: `wads/${filename}`,
  }));

  if (!r2Response.Body) {
    return new Response('Not Found', { status: 404 });
  }

  // Stream response to client
  return new Response(r2Response.Body as ReadableStream, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Length': r2Response.ContentLength?.toString() || '',
    },
  });
}
```

**Advantages:**
- Full control over every download
- Can transform/validate content
- Detailed logging and analytics
- Can implement resumable downloads

**Disadvantages:**
- Higher bandwidth costs (data passes through your API)
- Higher latency
- API becomes a bottleneck

### Option 3: Public Bucket with Obfuscated Paths

Use a public bucket but with unpredictable file paths.

**R2 Structure:**
```
novadoom-wads/
  └── wads/
      └── a7b3c9d2e1f4/          # Hash-based directory
          └── mymap.wad
```

**Server Configuration:**
```cfg
set sv_downloadsites "https://pub-xxxxx.r2.dev/wads/a7b3c9d2e1f4/"
```

**Advantages:**
- Simplest implementation
- Direct R2 downloads (fastest)
- No API needed

**Disadvantages:**
- URLs are guessable if hash algorithm is known
- No access control or expiration
- Harder to revoke access

### Option 4: Client Modification (Future)

Modify the client to fetch presigned URLs before downloading.

**New Flow:**
```
1. Client needs mymap.wad (hash: abc123)
2. Client calls: GET https://novadoom.com/api/wad-url?file=mymap.wad&hash=abc123
3. API returns: { "url": "https://r2.../mymap.wad?signature=..." }
4. Client downloads from presigned URL
```

**Required Code Changes:**
- Add API call before download in `cl_download.cpp`
- Parse JSON response
- Use returned URL instead of constructed URL

**Advantages:**
- Most flexible
- Can include additional metadata
- Better error handling

**Disadvantages:**
- Requires client update
- More complex implementation

### Recommended Approach for NovaDoom

**Option 1 (Redirect API)** is recommended because:

1. **No client changes** - Works with existing download code
2. **Secure** - Presigned URLs expire, credentials stay server-side
3. **Scalable** - R2 handles bandwidth, API only handles redirects
4. **Flexible** - Can add auth, rate limiting, analytics later

**Implementation Steps:**

1. Create R2 bucket `novadoom-wads` (private)
2. Upload WAD files to bucket
3. Create API endpoint at `https://novadoom.com/api/wads/`
4. Configure NovaDoom servers:
   ```cfg
   set sv_downloadsites "https://novadoom.com/api/wads/"
   ```

### Security Considerations

| Concern | Mitigation |
|---------|------------|
| URL sharing | Short expiration (5-15 min) |
| Bandwidth abuse | Rate limiting in API |
| Unauthorized access | API authentication (optional) |
| Credential exposure | Credentials only on server-side |
| DDoS | Cloudflare protection on API |

### Content-Type Headers

The client validates `Content-Type` headers. Ensure your API/R2 returns:
- `application/octet-stream` (preferred)
- `application/x-doom`

For R2, set content type when uploading:
```typescript
await R2.send(new PutObjectCommand({
  Bucket: 'novadoom-wads',
  Key: 'wads/mymap.wad',
  Body: fileBuffer,
  ContentType: 'application/octet-stream',
}));
```

## Flow Diagram

```
Server Connection
       │
       ▼
Client receives WAD list + MD5 hashes
       │
       ▼
Check local files
       │
       ▼
Missing WAD? ──No──→ Connect to server
       │
      Yes
       │
       ▼
cl_serverdownload enabled? ──No──→ Disconnect with error
       │
      Yes
       │
       ▼
Gather download sites:
  1. sv_downloadsites (shuffled)
  2. cl_downloadsites (shuffled)
       │
       ▼
For each site:
  ┌─────────────────────────────────┐
  │ Try filename variants:          │
  │   1. Original case              │
  │   2. lowercase                  │
  │   3. UPPERCASE                  │
  │                                 │
  │ HEAD request to check existence │
  └─────────────────────────────────┘
       │
       ▼
File found? ──No──→ Try next site
       │
      Yes
       │
       ▼
Download to .part file
       │
       ▼
Validate:
  • Content-Type header
  • MD5 hash matches server's hash
  • Not a commercial WAD
  • Path doesn't escape directory
       │
       ▼
Valid? ──No──→ Delete file, try next site
       │
      Yes
       │
       ▼
Rename .part to final filename
       │
       ▼
Reconnect to server (if DL_RECONNECT flag)
```
