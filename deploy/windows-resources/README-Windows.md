# MongoDB Search Community Edition on Windows

This bundle runs `mongot` on Windows x86_64 (Windows 11 / Windows Server 2019 or newer). It ships
its own Java 21 runtime, so no separate Java installation is required.

**Note:** 
Windows is not an officially supported MongoDB Search platform yet. This build is intended for
development and testing. Do not use it for production deployments.

## Contents

| Path                              | Purpose                                                                              |
|-----------------------------------|--------------------------------------------------------------------------------------|
| `mongot.cmd`                      | Starts mongot in the foreground                                                      |
| `config.default.yml`              | Sample configuration with Windows paths                                              |
| `install-service.ps1`             | Installs mongot as the Windows service `mongot`                                      |
| `uninstall-service.ps1`           | Removes the service (keeps data and configuration)                                   |
| `mongot-service.exe` / `.xml`     | Service wrapper ([WinSW](https://github.com/winsw/winsw), MIT) and its configuration |
| `bin\jdk`                         | Bundled Eclipse Temurin JDK 21                                                       |
| `bin\mongot_community_deploy.jar` | mongot itself                                                                        |
| `lib\`                            | FIPS crypto jars and `mongot_vecsim.dll` (SIMD vector scoring)                       |

## Prerequisites

- A MongoDB 8.2+ replica set (`mongod`) reachable from this machine. mongod is configured to use
  mongot via `setParameter` (`mongotHost`, `searchIndexManagementHostAndPort`, ...), exactly as on
  Linux; see the MongoDB Search Community documentation.
- A mongod user with the `searchCoordinator` role for mongot to connect with.

## Quick start (foreground)

1. Unzip the bundle, for example to `C:\Program Files\mongot`.
2. Create the directories and the password file (PowerShell):

   ```powershell
   New-Item -ItemType Directory -Force C:\ProgramData\mongot\data, C:\ProgramData\mongot\secrets
   Copy-Item "C:\Program Files\mongot\config.default.yml" C:\ProgramData\mongot\config.yml
   [IO.File]::WriteAllText('C:\ProgramData\mongot\secrets\passwordFile', 'your-password')
   ```

3. Adjust `C:\ProgramData\mongot\config.yml` to your mongod deployment.
4. Start mongot:

   ```bat
   "C:\Program Files\mongot\mongot.cmd" --config C:\ProgramData\mongot\config.yml
   ```

   JVM options can be passed with `--jvm-flags "-Xmx4g"` or via the `MONGOT_JVM_FLAGS`
   environment variable. Stop mongot with `Ctrl+C`.

## Running as a Windows service

From an elevated PowerShell in the installation directory:

```powershell
.\install-service.ps1          # creates C:\ProgramData\mongot\{data,logs,secrets} and config.yml
# edit C:\ProgramData\mongot\config.yml and create secrets\passwordFile
Start-Service mongot
```

- The service runs as `LocalSystem`, starts automatically (delayed) and is restarted on failure.
- `install-service.ps1` restricts `C:\ProgramData\mongot` to SYSTEM and Administrators, because
  the POSIX "owner only" permission check mongot performs for secret files on Linux does not exist
  on NTFS.
- Logs are written and rotated by the service wrapper in `C:\ProgramData\mongot\logs`
  (`mongot-service.out.log`). Leave `logging.logPath` unset in `config.yml` when running as a
  service.
- JVM options (heap size etc.) are set in the `<arguments>` element of `mongot-service.xml`.
  Reinstall the service after changing the XML (`uninstall-service.ps1`, then `install-service.ps1`).
- If mongod runs on the same machine as the Windows service `MongoDB`, uncomment
  `<depend>MongoDB</depend>` in `mongot-service.xml`.

## Windows-specific notes

- Paths in `config.yml`: use single quotes (`'C:\ProgramData\mongot\data'`) or forward slashes.
- Keep `dataPath` on a local NTFS volume and exclude it from real-time virus scanning; scanners
  that hold index files open slow down indexing and can make file renames fail.
- Secret files may be saved with or without a UTF-8 byte order mark.
- `mongot_vecsim.dll` accelerates int8 vector scoring on CPUs with AVX-512 VNNI. Without it (or on
  older CPUs) mongot falls back to the Java implementation automatically.
