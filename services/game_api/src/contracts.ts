export const protocolVersion = 2;
export const roomLimit = 120;
export type Json = Record<string, any>;
export class ApiError extends Error {
  constructor(public status: number, public code: string) { super(code); }
}
export function requireValue(condition: unknown, status = 400, code = 'INVALID_REQUEST'): asserts condition {
  if (!condition) throw new ApiError(status, code);
}
export function safeId(value: unknown): asserts value is string {
  requireValue(typeof value === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(value));
}
export function validateAction(room: Json, seat: Json, secret: Json, body: Json, uid: string): void {
  requireValue(room.status === 'active' && room.actionsOpen === true, 409, 'WINDOW_CLOSED');
  requireValue(Number.isSafeInteger(body.expectedRevision) && body.expectedRevision === room.actionRevision && secret.promptRevision === room.actionRevision, 409, 'STALE_WINDOW');
  requireValue(seat.linkedUid === uid, 403, 'NOT_A_MEMBER');
  requireValue(typeof body.actionType === 'string' && typeof body.targetId === 'string');
  if (body.actionType === 'citizenSheikhReveal') {
    requireValue(seat.isAlive && !seat.isCitizenSheikhRevealed && secret.role === 'citizensSheikh' && secret.canReveal && body.targetId === seat.id && ['day','voting'].includes(room.phase), 403, 'INVALID_ACTION');
  } else {
    requireValue((seat.isAlive || body.actionType === 'retaliation') && room.actionsPhase === room.phase && room.actionsRound === room.round && secret.allowedTargetsByAction?.[body.actionType]?.includes(body.targetId), 403, 'INVALID_ACTION');
  }
}
export function transitionCommand(state: Json, desiredPhase: string, hasPrompts: boolean): string {
  const phase = state.phase;
  if (phase === 'roleReveal' && desiredPhase === 'night') return 'beginIntroductionNight';
  if ((phase === 'roleReveal' || (phase === 'night' && state.round === 1)) && desiredPhase === 'day') return 'skipIntroductionNight';
  if (phase === 'day' && desiredPhase === 'voting') return 'startVoting';
  if (phase === 'elimination' && desiredPhase === 'night') return 'openNightActions';
  if (phase === 'night' && desiredPhase === 'night' && hasPrompts) return 'openNightActions';
  if (phase === 'night' && ['day','triggeredAbility','winCheck'].includes(desiredPhase)) return 'closeNight';
  if (phase === 'voting' && desiredPhase === 'voting') return 'revote';
  if (phase === 'voting' && desiredPhase === 'night') return 'skipVote';
  if (phase === 'voting' && ['elimination','triggeredAbility','winCheck'].includes(desiredPhase)) return 'closeVote';
  if (phase === 'triggeredAbility') return 'retaliation';
  if (phase === desiredPhase) return 'project';
  throw new ApiError(409, 'INVALID_TRANSITION');
}
