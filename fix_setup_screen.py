import re

with open('lib/presentation/setup/setup_screen.dart', 'r') as f:
    content = f.read()

# Replace hardcoded colors
content = content.replace("backgroundColor: const Color(0xFF1A1A22)", "backgroundColor: AppTheme.surface")
content = content.replace("colors: [Color(0xFF261D15), Color(0xFF100C09), Color(0xFF07070B)]", "colors: [AppTheme.surfaceHigh, AppTheme.surface, AppTheme.background]")

# Replace the giant gradient logic with our new semantic colors
pattern_gradient = r'\? \(widget.isInteractive \? \[const Color\(0xFFFF512F\), const Color\(0xFFF09819\)\] : \[const Color\(0xFFDD2476\), const Color\(0xFF900C3F\)\]\)'
content = re.sub(pattern_gradient, r'? (widget.isInteractive ? [AppTheme.primaryCardStart, AppTheme.primaryCardEnd] : [AppTheme.secondaryCardStart, AppTheme.secondaryCardEnd])', content)

pattern_shadow = r'\? \[BoxShadow\(color: widget.isInteractive \? const Color\(0xFFFF512F\) : const Color\(0xFFDD2476\), blurRadius: 10, spreadRadius: 1\)\]'
content = re.sub(pattern_shadow, r'? [BoxShadow(color: widget.isInteractive ? AppTheme.glowColor : AppTheme.secondaryCardStart, blurRadius: 10, spreadRadius: 1)]', content)

with open('lib/presentation/setup/setup_screen.dart', 'w') as f:
    f.write(content)
