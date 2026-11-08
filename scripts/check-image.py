"""Check a signed release image and its maintenance restart using disposable data."""
import argparse
import hashlib
import json
import subprocess
import time
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image')
parser.add_argument('version')
parser.add_argument('--socket', action='store_true')
args = parser.parse_args()
name = 'gscs-release-check-' + uuid.uuid4().hex[:12]
volume = name + '-data'

def run(*command, check=True):
    result = subprocess.run(['docker', *command], capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(' '.join(command[:2]) + ': ' + result.stderr[-3000:])
    return result.stdout.strip()

def wait_for(predicate, seconds=120):
    until = time.monotonic() + seconds
    while time.monotonic() < until:
        try:
            if predicate():
                return
        except (RuntimeError, ValueError, KeyError):
            pass
        time.sleep(1)
    raise TimeoutError('Release image did not become ready.')

def inspect():
    return json.loads(run('inspect', name))[0]

def boot():
    # Read only the boot marker from the supervisor environment, never its secrets.
    return run('exec', name, 'python3', '-c',
        "from pathlib import Path;pid=Path('/var/lib/gscs/run/supervisord.pid').read_text().strip();"
        "values=Path('/proc/'+pid+'/environ').read_bytes().split(b'\\0');"
        "print(next(v.split(b'=',1)[1].decode() for v in values if v.startswith(b'GSCS_CONTAINER_BOOT_ID=')))")

def health():
    state = json.loads(run('exec', name, 'curl', '--fail', '--silent', '--max-time', '3', 'http://127.0.0.1:5080/health'))
    return state['version'] == args.version and state['runtimeManifestSha256'] == manifest_hash

def sql(statement):
    return run('exec', name, 'bash', '-ec',
        'export PGPASSWORD=$(cat /var/lib/gscs/secrets/db_password); '
        'exec psql -h /var/lib/gscs/postgres-socket -U gscs -d gscs -v ON_ERROR_STOP=1 -tAc "$1"', '_', statement)

def request(marker):
    data = json.dumps({'bootId': marker, 'runId': name})
    run('exec', name, 'bash', '-ec',
        'printf scheduled-maintenance > /var/lib/gscs/maintenance.flag; '
        'printf "%s" "$1" > /var/lib/gscs/run/maintenance-restart.request; '
        'chown gscs:gscs /var/lib/gscs/maintenance.flag /var/lib/gscs/run/maintenance-restart.request', '_', data)

try:
    run('run', '--rm', '--network', 'none', '--entrypoint', '/opt/gscs/GSCS', args.image, '--verify-payload')
    manifest = subprocess.check_output(['docker', 'run', '--rm', '--network', 'none', '--entrypoint', 'cat', args.image, '/opt/gscs/gscs-runtime.json'])
    assert json.loads(manifest)['version'] == args.version
    manifest_hash = hashlib.sha256(manifest).hexdigest()
    run('volume', 'create', '--label', 'com.zumbyte.gscs.release-check=' + name, volume)
    extra = ['--mount', 'type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock'] if args.socket else []
    run('run', '--detach', '--name', name, '--network', 'none', '--memory', '4g', '--cpus', '2',
        '--restart', 'no' if args.socket else 'unless-stopped', '--label', 'com.zumbyte.gscs.release-check=' + name,
        '--mount', 'type=volume,src=' + volume + ',dst=/var/lib/gscs', *extra, args.image)
    wait_for(health)
    sql('CREATE TABLE release_maintenance_fixture(value integer); INSERT INTO release_maintenance_fixture VALUES(42);')
    old_boot = boot()
    before = inspect()['State']['StartedAt']
    time.sleep(11)
    request('foreign-boot-id')
    time.sleep(4)
    assert inspect()['State']['StartedAt'] == before, 'A foreign restart request was accepted'
    request(old_boot)
    wait_for(lambda: inspect()['State']['StartedAt'] != before and inspect()['State']['Running'])
    wait_for(health)
    assert boot() != old_boot, 'Only the panel process restarted'
    assert sql('SELECT value FROM release_maintenance_fixture') == '42'
    after = inspect()['State']['StartedAt']
    time.sleep(8)
    assert inspect()['State']['StartedAt'] == after, 'Maintenance caused a restart loop'
    print(json.dumps({'version': args.version, 'signedPayloadVerified': True, 'runtimeManifestSha256': manifest_hash,
        'fullContainerRestart': True, 'postgresDataPreserved': True, 'foreignBootIgnored': True,
        'noRestartLoop': True, 'dockerSocket': args.socket}))
except Exception:
    print(run('logs', '--tail', '50', name, check=False))
    raise
finally:
    run('rm', '--force', name, check=False)
    run('volume', 'rm', volume, check=False)
