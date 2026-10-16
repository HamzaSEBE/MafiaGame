#!/usr/bin/env python3
"""Runs the actual Dart engine, Firestore rules and Admin API integration tests.
Uses only dedicated loopback ports; terminates only processes it creates.
"""
import argparse
import os
from pathlib import Path
import signal
import socket
import subprocess
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--jar', default=os.environ.get('FIRESTORE_EMULATOR_JAR'))
parser.add_argument('--dart', default=str(ROOT / '.local_tools/flutter/bin/dart') if (ROOT / '.local_tools/flutter/bin/dart').exists() else 'dart')
args = parser.parse_args()
if not args.jar or not Path(args.jar).is_file():
    parser.error('Supply --jar or FIRESTORE_EMULATOR_JAR (Firestore emulator 1.22.0)')
for port in (8085, 8087):
    with socket.socket() as probe:
        probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            probe.bind(('127.0.0.1', port))
        except OSError:
            parser.error(f'Port {port} is busy; this script will not stop another process')
processes = []
environment = {**os.environ, 'FIRESTORE_EMULATOR_HOST': '127.0.0.1:8085', 'GAME_ENGINE_URL': 'http://127.0.0.1:8087'}
with tempfile.TemporaryDirectory(prefix='mafia-verify-') as directory:
    try:
        subprocess.run([args.dart, 'pub', 'get'], cwd=ROOT / 'services/game_engine', check=True)
        for name, command, cwd, extra in [
            ('firestore', ['java', '-Xmx384m', '-XX:MaxMetaspaceSize=192m', '-jar', str(Path(args.jar).resolve()), '--host', '127.0.0.1', '--port', '8085', '--project_id', 'demo-mafia-review', '--single_project_mode', 'true', '--rules', str(ROOT / 'firestore.rules')], ROOT, {}),
            ('engine', [args.dart, 'run', 'bin/server.dart'], ROOT / 'services/game_engine', {'PORT': '8087'}),
        ]:
            log = open(Path(directory) / f'{name}.log', 'w')
            process = subprocess.Popen(command, cwd=cwd, env={**environment, **extra}, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            processes.append((process, log, name))
        deadline = time.monotonic() + 30
        while True:
            if any(process.poll() is not None for process, _, _ in processes):
                raise RuntimeError('A service exited during startup')
            try:
                with socket.create_connection(('127.0.0.1', 8085), timeout=1):
                    pass
                with urllib.request.urlopen('http://127.0.0.1:8087/health', timeout=1) as response:
                    if response.status == 200:
                        break
            except OSError:
                pass
            if time.monotonic() > deadline:
                raise TimeoutError('Services did not become ready')
            time.sleep(.2)
        subprocess.run(['python3', '-m', 'unittest', 'discover', '-s', 'test/security', '-p', '*_test.py', '-v'], cwd=ROOT, env=environment, check=True)
        subprocess.run(['npm', 'test', '--prefix', 'services/game_api'], cwd=ROOT, env=environment, check=True)
        print('Backend verification passed against the actual Dart engine and Firestore emulator.')
    except Exception:
        for _, log, name in processes:
            log.flush()
            print(f'{name} diagnostics:')
            print((Path(directory) / f'{name}.log').read_text()[-4000:])
        raise
    finally:
        for process, log, _ in processes:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            log.close()
