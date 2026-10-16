import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';

/// Fixed, server-verified room styling. It never grants or saves guest access.
class RoomThemeScope extends ConsumerStatefulWidget {
  const RoomThemeScope({
    super.key,
    required this.sessionId,
    required this.child,
  });
  final String sessionId;
  final Widget child;
  @override
  ConsumerState<RoomThemeScope> createState() => _RoomThemeScopeState();
}

class _RoomThemeScopeState extends ConsumerState<RoomThemeScope> {
  late final Stream<InteractiveSession?> _room;
  @override
  void initState() {
    super.initState();
    _room = ref
        .read(interactiveServiceProvider)
        .streamSession(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<InteractiveSession?>(
    stream: _room,
    builder: (context, snapshot) {
      final room = snapshot.data;
      final id = room?.sharedThemeId;
      if (room?.status != SessionStatus.active ||
          id == null ||
          room?.themeVersion != ThemePalette.schemaVersion ||
          !ThemeCatalog.contains(id)) {
        return widget.child;
      }
      return Theme(
        data: AppTheme.getTheme(
          id,
          roleNames:
              Theme.of(context).extension<RoleLabels>()?.names ?? const {},
        ),
        child: widget.child,
      );
    },
  );
}
