"""Validate signed release ZIPs before admitting files to a container build."""
import hashlib, json, pathlib, subprocess, sys, zipfile
root = pathlib.Path(__file__).resolve().parents[1]
downloads = pathlib.Path(sys.argv[1]).resolve()
subprocess.run(['openssl', 'dgst', '-sha256', '-verify', str(root/'release-public.pem'),
                '-signature', str(downloads/'gscs-manifest.sig'), str(downloads/'gscs-manifest.json')], check=True)
manifest = json.loads((downloads/'gscs-manifest.json').read_text(encoding='utf-8'))
assert manifest['schemaVersion'] == 1 and 'v'+manifest['version'] == sys.argv[2]
for package in manifest['packages']:
    if package['rid'] not in ('linux-x64', 'linux-arm64'):
        continue
    assert package['role'] in ('master', 'node')
    name = package['file']
    assert pathlib.Path(name).name == name
    file = downloads/name
    assert file.stat().st_size == package['bytes']
    with file.open('rb') as stream:
        assert hashlib.file_digest(stream, 'sha256').hexdigest().lower() == package['sha256'].lower()
    arch = 'amd64' if package['rid'] == 'linux-x64' else 'arm64'
    target = root/'packages'/package['role']/('linux-'+arch)
    target.mkdir(parents=True, exist_ok=False)
    with zipfile.ZipFile(file) as archive:
        for entry in archive.infolist():
            assert (target/entry.filename).resolve().is_relative_to(target.resolve())
            assert ((entry.external_attr >> 16) & 0xf000) != 0xa000
        archive.extractall(target)
    assert (target/'gscs-role').read_text().strip() == package['role']
    (target/'GSCS').chmod(0o755)
print('All four signed Linux packages verified.')
