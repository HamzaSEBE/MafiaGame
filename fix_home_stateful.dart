import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  var content = file.readAsStringSync();
  
  if (content.contains('class HomeScreen extends ConsumerWidget')) {
    final oldClass = """
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
""";
    final newClass = """
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).startAmbience();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
""";
    
    content = content.replaceFirst(oldClass, newClass);
    file.writeAsStringSync(content);
    print('Made HomeScreen stateful and started ambience!');
  }
}