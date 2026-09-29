import re

file_path = 'lib/presentation/night/night_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will just replace the exact garbled strings based on my knowledge of the previous output
replacements = {
    'O U,U,USU, 1 (OO1O OU?)': 'الليلة الأولى (التعارف)',
    'O"OU^O O1O U,US O OUUS:\\n\\nO U,UU, USOU.O  O1USU+USU\\nO U,U.O U?USO  OU?OO O1USU+USUO  \n(U,U,OO1O OU? U?U,O)\\nO U,U.O U?USO  OOU.O \\nO U,UU, USU?OO': 'الكل يغمض عينيه\nالمافيا يفتحون أعينهم\n(للتعارف فقط)\nالمافيا يغمضون\nالكل يفتح',
    'O OrOO O U,UO_U?:': 'اختر الهدف:',
    'OU,U,U% O-U.O USOc O3O O"U,Oc': 'محمي سابقاً',
    'OUSO U.OO O-': 'غير متاح',
    'OOUUSO_ O U,OOOO O': 'تأكيد الإجراء',
    'OU+UO O O U,U,O1O"OcOY': 'إنهاء اللعبة؟',
    'UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O"Oc U^O U,O1U^O_Oc \nU,U,U,O OU.Oc O U,OOUSO3USOcOY': 'هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟',
    'OU,OO O': 'إلغاء',
    'U+O1U.OO OU+UO O': 'تأكيد الإنهاء',
}

for k, v in replacements.items():
    content = content.replace(k, v)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)