"""Local Firestore emulator tests; refuses all non-loopback targets.

Start Firebase with firebase.emulator.json and project demo-mafia-review, then:
  python3 -m unittest discover -s test/security -p '*_test.py' -v
No production credentials or third-party Python packages are needed.
"""
import base64
import concurrent.futures
import json
import hashlib
import os
import time
import unittest
import urllib.error
import urllib.request
import uuid

HOST = os.environ.get('FIRESTORE_EMULATOR_HOST', '127.0.0.1:8085')
if HOST not in ('127.0.0.1:8085', 'localhost:8085'):
    raise RuntimeError('Tests only support the local emulator on port 8085')
PROJECT = 'demo-mafia-review'
ROOT = f'projects/{PROJECT}/databases/(default)/documents'
URL = f'http://{HOST}/v1/{ROOT}'


def token(uid):
    def encode(data):
        return base64.urlsafe_b64encode(json.dumps(data).encode()).decode().rstrip('=')
    now = int(time.time())
    return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
        'sub': uid, 'user_id': uid, 'aud': PROJECT,
        'iss': f'https://securetoken.google.com/{PROJECT}',
        'iat': now, 'exp': now + 3600,
        'firebase': {'sign_in_provider': 'anonymous'},
    }) + '.'


def request(method, suffix, data=None, uid='owner'):
    headers = {'Content-Type': 'application/json'}
    if uid:
        headers['Authorization'] = 'Bearer ' + ('owner' if uid == 'owner' else token(uid))
    payload = None if data is None else json.dumps(data).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(
            URL + suffix, data=payload, headers=headers, method=method), timeout=60) as response:
            body = response.read()
            return response.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        with error:
            return error.code, json.loads(error.read())


def value(data):
    if data is None: return {'nullValue': None}
    if isinstance(data, bool): return {'booleanValue': data}
    if isinstance(data, int): return {'integerValue': str(data)}
    if isinstance(data, str): return {'stringValue': data}
    if isinstance(data, list): return {'arrayValue': {'values': [value(v) for v in data]}}
    return {'mapValue': {'fields': fields(data)}}


def fields(data):
    return {k: value(v) for k, v in data.items()}


def write(path, data, *, timestamp=None, mask=None):
    result = {'update': {'name': f'{ROOT}/{path}', 'fields': fields(data)}}
    if timestamp:
        result['updateTransforms'] = [{'fieldPath': timestamp, 'setToServerValue': 'REQUEST_TIME'}]
    if mask is not None: result['updateMask'] = {'fieldPaths': mask}
    return result


def commit(uid, writes):
    return request('POST', ':commit', {'writes': writes}, uid)


class FirestoreRulesTest(unittest.TestCase):
    def setUp(self):
        self.room = 'room-' + uuid.uuid4().hex
        self.path = f'sessions/{self.room}'
        self.host = 'host-' + uuid.uuid4().hex
        self.player = 'player-' + uuid.uuid4().hex
        self.other = 'other-' + uuid.uuid4().hex
        self.session = {'id': self.room, 'hostUid': self.host, 'status': 'waiting',
                        'phase': 'setup', 'round': 1, 'actionRevision': 0,
                        'actionsPhase': None, 'actionsRound': None, 'winner': None}
        status, body = commit(self.host, [
            write(self.path, self.session, timestamp='createdAt'),
            write(self.path + '/seats/a', {'id': 'a', 'linkedUid': None,
                'status': 'unlinked', 'playerName': 'a', 'isAlive': True,
                'isCitizenSheikhRevealed': False}),
            write(self.path + '/seats/b', {'id': 'b', 'linkedUid': None,
                'status': 'unlinked', 'playerName': 'b', 'isAlive': True,
                'isCitizenSheikhRevealed': False}),
            write(self.path + '/secrets/a', {'id': 'a', 'role': 'citizensSheikh',
                'canReveal': True, 'allowedTargetsByAction': {'vote': ['b']}}),
        ])
        self.assertEqual(status, 200, body)

    def assertDenied(self, response):
        self.assertEqual(response[0], 403, response[1])

    def join(self, uid=None, seat='a'):
        uid = uid or self.player
        return commit(uid, [write(self.path + '/joinRequests/' + uid, {
            'uid': uid, 'seatId': seat, 'displayName': uid,
        }, timestamp='timestamp')])

    def approve(self, uid=None, seat='a'):
        uid = uid or self.player
        return commit(self.host, [
            write(self.path + '/seats/' + seat, {'linkedUid': uid, 'status': 'linked'},
                  mask=['linkedUid', 'status']),
            write(self.path + '/members/' + uid, {'uid': uid, 'seatId': seat}),
            {'delete': f'{ROOT}/{self.path}/joinRequests/{uid}'},
        ])

    def activate(self, action='vote', revision=1):
        self.assertEqual(commit(self.host, [
            write(self.path, {'status': 'active', 'phase': 'voting', 'round': 2,
                'actionRevision': revision, 'actionsPhase': 'voting', 'actionsRound': 2},
                mask=['status', 'phase', 'round', 'actionRevision', 'actionsPhase', 'actionsRound']),
            write(self.path + '/secrets/a', {'allowedTargetsByAction': {action: ['b']}},
                mask=['allowedTargetsByAction']),
        ])[0], 200)

    def action(self, action='vote', revision=1, target='b', uid=None, seat='a', extra=None):
        uid = uid or self.player
        action_id = uid + '_' + action
        data = {'id': action_id, 'uid': uid, 'seatId': seat, 'actionType': action,
                'targetId': target, 'revision': revision}
        data.update(extra or {})
        return commit(uid, [write(self.path + '/actionRequests/' + action_id, data, timestamp='timestamp')])

    def ready(self, action='vote'):
        self.assertEqual(self.join()[0], 200)
        self.assertEqual(self.approve()[0], 200)
        self.activate(action)

    def test_atomic_room_creation_and_host_identity(self):
        forged = dict(self.session, id='forged', hostUid=self.other)
        self.assertDenied(commit(self.host, [write('sessions/forged', forged, timestamp='createdAt')]))
        self.assertDenied(commit(self.host, [write(self.path, {'hostUid': self.other}, mask=['hostUid'])]))
        self.assertDenied(commit(self.other, [write(self.path, {'round': 4}, mask=['round'])]))

    def test_qr_lobby_atomic_creation_includes_checkpoint_and_resume_pointer(self):
        room = 'lobby-' + uuid.uuid4().hex
        path = 'sessions/' + room
        session = dict(self.session, id=room, stateVersion=0, actionsOpen=False)
        writes = [
            write(path, session, timestamp='createdAt'),
            write(path + '/hostState/current', {'schemaVersion': 1, 'state': {'id': room, 'phase': 'roleReveal'}}),
            write('users/' + self.host + '/settings/activeSession', {'sessionId': room}),
        ]
        for index in range(20):
            seat = str(index)
            writes.extend([
                write(path + '/seats/' + seat, {'id': seat, 'playerName': seat, 'linkedUid': None,
                    'status': 'unlinked', 'isAlive': True, 'isCitizenSheikhRevealed': False}),
                write(path + '/secrets/' + seat, {'id': seat}),
            ])
        status, body = commit(self.host, writes)
        self.assertEqual(status, 200, body)
        self.assertEqual(request('GET', '/' + path + '/hostState/current', uid=self.host)[0], 200)
        self.assertDenied(request('GET', '/' + path + '/hostState/current', uid=self.player))

    def test_manual_session_end_removes_continue_pointer_atomically(self):
        pointer = 'users/' + self.host + '/settings/activeSession'
        self.assertEqual(commit(self.host, [write(pointer, {'sessionId': self.room})])[0], 200)
        status, body = commit(self.host, [
            write(self.path, {'status': 'finished', 'actionsOpen': False}, mask=['status', 'actionsOpen']),
            {'delete': ROOT + '/' + pointer},
        ])
        self.assertEqual(status, 200, body)
        self.assertEqual(request('GET', '/' + pointer, uid=self.host)[0], 404)

    def test_public_get_does_not_allow_room_directory(self):
        self.assertEqual(request('GET', '/' + self.path, uid=None)[0], 200)
        self.assertDenied(request('GET', '/sessions', uid=None))
        self.assertDenied(request('GET', '/sessions', uid=self.player))

    def test_secret_is_readable_only_by_linked_player_and_host(self):
        self.assertDenied(request('GET', '/' + self.path + '/secrets/a', uid=self.player))
        self.ready()
        self.assertEqual(request('GET', '/' + self.path + '/secrets/a', uid=self.player)[0], 200)
        self.assertDenied(request('GET', '/' + self.path + '/secrets/a', uid=self.other))

    def test_join_request_cannot_impersonate_or_add_fields(self):
        self.assertDenied(commit(self.player, [write(self.path + '/joinRequests/' + self.other,
            {'uid': self.other, 'seatId': 'a', 'displayName': 'x'}, timestamp='timestamp')]))
        self.assertDenied(commit(self.player, [write(self.path + '/joinRequests/' + self.player,
            {'uid': self.player, 'seatId': 'a', 'displayName': 'x', 'isHost': True}, timestamp='timestamp')]))

    def test_seat_and_membership_are_atomic_and_immutable(self):
        self.assertEqual(self.join()[0], 200)
        self.assertDenied(commit(self.host, [write(self.path + '/seats/a',
            {'linkedUid': self.player, 'status': 'linked'}, mask=['linkedUid', 'status'])]))
        self.assertEqual(self.approve()[0], 200)
        self.assertDenied(self.approve(self.other))
        self.assertDenied(self.approve(self.player, 'b'))
        self.assertDenied(self.join(self.player, 'b'))

    def test_two_concurrent_seat_approvals_cannot_both_win(self):
        self.assertEqual(self.join()[0], 200)
        self.assertEqual(self.join(self.other)[0], 200)
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(self.approve, [self.player, self.other]))
        self.assertEqual(sorted(status for status, _ in results), [200, 403], results)

    def test_private_membership_signal_is_available_immediately_after_atomic_approval(self):
        member = '/' + self.path + '/members/' + self.player
        self.assertEqual(request('GET', member, uid=self.player)[0], 404)
        self.assertDenied(request('GET', member, uid=self.other))
        self.assertEqual(self.join()[0], 200)
        self.assertEqual(self.approve()[0], 200)
        status, data = request('GET', member, uid=self.player)
        self.assertEqual(status, 200, data)
        self.assertEqual(data['fields']['seatId']['stringValue'], 'a')
        self.assertDenied(request('GET', member, uid=self.other))
        self.assertEqual(request('GET', '/' + self.path + '/joinRequests/' + self.player, uid=self.player)[0], 404)

    def test_forged_stale_target_and_unknown_actions_are_denied(self):
        self.ready()
        self.assertDenied(self.action(uid=self.other))
        self.assertDenied(self.action(revision=0))
        self.assertDenied(self.action(target='a'))
        self.assertDenied(self.action(action='admin'))
        self.assertDenied(self.action(extra={'isHost': True}))
        self.assertEqual(self.action()[0], 200)

    def test_vote_retries_use_one_document(self):
        self.ready()
        for _ in range(30): self.assertEqual(self.action()[0], 200)
        status, result = request('GET', '/' + self.path + '/actionRequests', uid=self.host)
        self.assertEqual(status, 200, result)
        self.assertEqual(len(result.get('documents', [])), 1)

    def test_night_action_is_immutable_in_same_revision(self):
        self.ready('investigation')
        self.assertEqual(self.action('investigation')[0], 200)
        self.assertDenied(self.action('investigation'))
        self.activate('investigation', revision=2)
        self.assertEqual(self.action('investigation', revision=2)[0], 200)

    def test_reveal_preserves_vote_revision_and_prompts(self):
        self.ready()
        self.assertEqual(self.action()[0], 200)
        self.assertEqual(self.action('citizenSheikhReveal', target='a')[0], 200)
        self.assertEqual(commit(self.host, [
            write(self.path + '/seats/a', {'isCitizenSheikhRevealed': True}, mask=['isCitizenSheikhRevealed']),
            write(self.path, {'globalAnnouncement': 'revealed'}, mask=['globalAnnouncement']),
        ])[0], 200)
        self.assertEqual(self.action()[0], 200)
        self.assertDenied(self.action('citizenSheikhReveal', target='a'))

    def test_finished_room_denies_new_actions_and_reopening(self):
        self.ready()
        self.assertEqual(commit(self.host, [write(self.path, {'status': 'finished'}, mask=['status'])])[0], 200)
        self.assertDenied(self.action())
        self.assertDenied(commit(self.host, [write(self.path, {'status': 'active'}, mask=['status'])]))

    def test_premium_cannot_be_self_granted_or_removed(self):
        path = 'users/' + self.player
        self.assertDenied(commit(self.player, [write(path, {'isPremium': True})]))
        self.assertEqual(commit(self.player, [write(path, {'displayName': 'player'})])[0], 200)
        self.assertEqual(commit('owner', [write(path, {'isPremium': True}, mask=['isPremium'])])[0], 200)
        self.assertDenied(commit(self.player, [write(path, {'isPremium': False}, mask=['isPremium'])]))
        self.assertDenied(commit(self.player, [write(path, {'displayName': 'replacement'})]))
        self.assertEqual(commit(self.player, [write(path, {'displayName': 'renamed'}, mask=['displayName'])])[0], 200)
        self.assertDenied(request('DELETE', '/' + path, uid=self.player))
        self.assertDenied(commit(self.player, [write(path + '/entitlements/premium', {'active': True})]))

    def test_result_marker_retry_cannot_increment_stats_twice(self):
        user = 'users/' + self.player
        stat = write(user + '/stats/alice', {'name': 'alice'}, mask=['name'])
        stat['updateTransforms'] = [{'fieldPath': 'gamesPlayed', 'increment': {'integerValue': '1'}}]
        writes = [stat, write(user + '/games/game', {'id': 'game'}),
                  write(user + '/gameResults/game', {}, timestamp='recordedAt')]
        self.assertEqual(commit(self.player, writes)[0], 200)
        self.assertDenied(commit(self.player, writes))
        status, result = request('GET', '/' + user + '/stats/alice', uid=self.player)
        self.assertEqual(status, 200)
        self.assertEqual(result['fields']['gamesPlayed']['integerValue'], '1')

    def archive_delete(self, user, game_id):
        receipt = hashlib.sha256(f'{user}/{game_id}'.encode()).hexdigest()
        account = 'users/' + user
        return [write(account + '/resultReceipts/' + receipt, {'processed': True})] + [
            {'delete': f'{ROOT}/{account}/{collection}/{game_id}'}
            for collection in ['games', 'gameDetails', 'gameResults', 'gameResultsV2']]

    def test_archive_split_migration_and_owner_only_reads(self):
        account = 'users/' + self.player
        game = account + '/games/legacy'
        self.assertEqual(commit(self.player, [write(game, {'id': 'legacy', 'players': ['private']})])[0], 200)
        status, body = commit(self.player, [
            write(game, {'schemaVersion': 2, 'id': 'legacy', 'playerCount': 1}),
            write(account + '/gameDetails/legacy', {'players': ['private'], 'newspaperText': 'private'}),
        ])
        self.assertEqual(status, 200, body)
        self.assertEqual(request('GET', '/' + account + '/gameDetails/legacy', uid=self.player)[0], 200)
        self.assertDenied(request('GET', '/' + account + '/gameDetails/legacy', uid=self.other))
        self.assertDenied(commit(self.other, self.archive_delete(self.player, 'legacy')))
        self.assertDenied(commit(self.player, [write(account + '/gameDetails/orphan', {'players': ['x']})]))

    def test_permanent_delete_preserves_stats_and_blocks_old_client_recreation(self):
        account = 'users/' + self.player
        game_id = 'game'
        receipt = hashlib.sha256(f'{self.player}/{game_id}'.encode()).hexdigest()
        stat = write(account + '/stats/career', {'gamesPlayed': 7})
        status, body = commit(self.player, [stat,
            write(account + '/games/game', {'schemaVersion': 2, 'id': 'game', 'playerCount': 1}),
            write(account + '/gameDetails/game', {'players': ['alice'], 'newspaperText': 'report'}),
            write(account + '/resultReceipts/' + receipt, {'processed': True}),
        ])
        self.assertEqual(status, 200, body)
        # Seed historical markers as Admin; deletion must remove both old forms.
        self.assertEqual(commit('owner', [write(account + '/gameResults/game', {'recordedAt': 'old'}),
            write(account + '/gameResultsV2/game', {'recordedAt': 'old'})])[0], 200)
        self.assertDenied(request('DELETE', '/' + account + '/gameResults/game', uid=self.player))
        status, body = commit(self.player, self.archive_delete(self.player, game_id))
        self.assertEqual(status, 200, body)
        for collection in ['games', 'gameDetails', 'gameResults', 'gameResultsV2']:
            self.assertEqual(request('GET', '/' + account + '/' + collection + '/game', uid=self.player)[0], 404)
        saved = request('GET', '/' + account + '/stats/career', uid=self.player)[1]
        self.assertEqual(saved['fields']['gamesPlayed']['integerValue'], '7')
        receipt_data = request('GET', '/' + account + '/resultReceipts/' + receipt, uid=self.player)[1]
        self.assertEqual(receipt_data['fields'], {'processed': {'booleanValue': True}})
        self.assertDenied(commit(self.player, [write(account + '/games/game', {'id': 'game'}),
            write(account + '/gameResults/game', {}, timestamp='recordedAt')]))
        self.assertDenied(request('DELETE', '/' + account + '/resultReceipts/' + receipt, uid=self.player))
        self.assertDenied(commit(self.player, [write(account + '/resultReceipts/' + receipt, {'processed': False})]))
        # Repeated confirmed deletion is harmless, including receipt updates.
        self.assertEqual(commit(self.player, self.archive_delete(self.player, game_id))[0], 200)

    def test_three_archive_deletions_fit_atomic_rule_access_budget(self):
        account = 'users/' + self.player
        seed = []
        for game_id in ['one', 'two', 'three']:
            for collection in ['games', 'gameDetails', 'gameResults', 'gameResultsV2']:
                seed.append(write(f'{account}/{collection}/{game_id}', {'private': game_id}))
        self.assertEqual(commit('owner', seed)[0], 200)
        writes = sum((self.archive_delete(self.player, game_id) for game_id in ['one', 'two', 'three']), [])
        status, body = commit(self.player, writes)
        self.assertEqual(status, 200, body)
        for collection in ['games', 'gameDetails', 'gameResults', 'gameResultsV2']:
            status, body = request('GET', '/' + account + '/' + collection, uid=self.player)
            self.assertEqual(status, 200, body)
            self.assertEqual(body.get('documents', []), [])

    def test_finished_qr_room_children_delete_while_parent_authorizes_host(self):
        self.assertEqual(commit(self.host, [write(self.path, {'status': 'finished'}, mask=['status'])])[0], 200)
        self.assertEqual(commit('owner', [write(self.path + '/members/' + self.player, {'seatId': 'a'}),
            write(self.path + '/hostState/current', {'state': {'players': ['private']}})])[0], 200)
        for collection in ['hostState', 'actionRequests', 'joinRequests', 'secrets', 'seats', 'members']:
            status, body = request('GET', '/' + self.path + '/' + collection, uid=self.host)
            self.assertEqual(status, 200, body)
            documents = body.get('documents', [])
            if documents:
                writes = [{'delete': doc['name']} for doc in documents]
                self.assertDenied(commit(self.other, writes))
                self.assertEqual(commit(self.host, writes)[0], 200)
        self.assertEqual(request('DELETE', '/' + self.path, uid=self.host)[0], 200)
        self.assertEqual(request('GET', '/' + self.path, uid=self.host)[0], 404)

    def test_closed_gate_rejects_late_ballot_even_if_revision_matches(self):
        self.join(); self.approve(); self.activate()
        self.assertEqual(self.action()[0], 200)
        self.assertEqual(commit(self.host, [write(self.path, {'actionsOpen': False}, mask=['actionsOpen'])])[0], 200)
        self.assertDenied(self.action())

    def test_secret_prompt_revision_must_match_visible_window(self):
        self.join(); self.approve(); self.activate()
        self.assertEqual(commit(self.host, [write(self.path + '/secrets/a', {'promptRevision': 0}, mask=['promptRevision'])])[0], 200)
        self.assertDenied(self.action())

    def test_running_roster_is_not_readable_by_unrelated_account(self):
        self.join(); self.approve(); self.activate()
        self.assertDenied(request('GET', '/' + self.path + '/seats/a', uid=self.other))
        self.assertEqual(request('GET', '/' + self.path + '/seats/a', uid=self.player)[0], 200)

    def test_checkpoint_is_host_only(self):
        self.assertEqual(commit(self.host, [write(self.path + '/hostState/current', {'schemaVersion': 1, 'state': {'id': self.room}})])[0], 200)
        self.assertDenied(request('GET', '/' + self.path + '/hostState/current', uid=self.player))
        self.assertEqual(request('GET', '/' + self.path + '/hostState/current', uid=self.host)[0], 200)

    def test_profile_avatar_contract_and_entitlements_are_separate(self):
        path = 'users/' + self.player
        self.assertEqual(commit(self.player, [write(path, {'displayName': 'Player', 'photoPath': 'avatars/' + self.player + '/x.jpg', 'photoVersion': 'x'})])[0], 200)
        self.assertDenied(commit(self.player, [write(path, {'entitlements': {'schemaVersion': 1, 'status': 'active', 'features': ['themes']}}, mask=['entitlements'])]))

    def test_v2_clients_cannot_write_authoritative_state_or_read_other_secrets(self):
        path = 'sessionsV2/' + self.room
        self.assertEqual(commit('owner', [
            write(path, {'hostUid': self.host, 'status': 'active'}),
            write(path + '/members/' + self.player, {'seatId': 'a'}),
            write(path + '/secrets/a', {'role': 'mafiaSheikh'}),
            write(path + '/secrets/b', {'role': 'citizensGirl'}),
            write(path + '/roster/a', {'id': 'a', 'playerName': 'A'}),
        ])[0], 200)
        self.assertEqual(request('GET', '/' + path + '/secrets/a', uid=self.player)[0], 200)
        self.assertDenied(request('GET', '/' + path + '/secrets/b', uid=self.player))
        self.assertDenied(request('GET', '/' + path + '/roster/a', uid=self.other))
        self.assertDenied(commit(self.host, [write(path, {'status': 'finished'}, mask=['status'])]))
        self.assertDenied(commit(self.player, [write(path + '/actionRequests/fake', {'uid': self.player})]))


if __name__ == '__main__':
    unittest.main(verbosity=2)
