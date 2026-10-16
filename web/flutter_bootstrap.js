{{flutter_js}}
{{flutter_build_config}}

function showLaunchError() {
  const message = document.getElementById('launch-message');
  if (message) message.textContent = 'تعذر تحميل اللعبة. تحقق من الاتصال ثم أعد المحاولة.';
  const retry = document.getElementById('retry');
  if (retry) retry.style.display = 'block';
}
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const runner = await engineInitializer.initializeEngine();
      await runner.runApp();
      document.getElementById('launch')?.remove();
    } catch (_) {
      showLaunchError();
    }
  }
}).catch(showLaunchError);
