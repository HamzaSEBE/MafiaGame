'use strict';
const roles = [
  ['شيخ المافيا','فريق المافيا','الهدوء أحياناً أخطر اعتراف.','يقود المؤامرة مع فريق المافيا. يمكن تفعيل تمويه هويته أمام التحقيق من إعدادات القواعد.','mafia_sheikh.jpg'],
  ['بنت المافيا','فريق المافيا','كلمة واحدة منها… والمدينة تسكت.','تملك قدرة إسكات لاعب وفق حدود القواعد المختارة، وتشارك فريق المافيا في خطته.','mafia_girl.jpg'],
  ['مافيا','فريق المافيا','واحد من الشلة. لحد ما تغمضوا عيونكم.','يعمل مع فريق المافيا على اختيار ضحية الليل، ويحاول إخفاء هويته أثناء النقاش والتصويت.','normal_mafia.jpg'],
  ['شيخ المواطنين','فريق المواطنين','يسأل السؤال اللي الكل خايف يسأله.','يحقق في هوية لاعب ليلاً. يمكن تفعيل الكشف العلني لصفته مع زيادة وزن صوته حسب إعدادات القواعد.','citizens_sheikh.jpg'],
  ['بنت المواطنين','فريق المواطنين','لما المدينة تنام، هي بتحميها.','تحمي أحد اللاعبين أو نفسها ضمن حدود الحماية التي اختارها الحكم. قرارها قد يغيّر مصير الليلة.','citizens_girl.jpg'],
  ['المواطن الشجاع','فريق المواطنين','حتى رحيله إله كلمة أخيرة.','يملك قدرة الرد عند مقتله وفق قواعد المباراة. اختيار الهدف وتوقيت الرد تديرهما خطوات اللعبة.','citizens_boy.jpg'],
  ['مواطن صالح','فريق المواطنين','ما معه سلاح. معه عين ما بتنام.','يستخدم النقاش والملاحظة والتصويت لكشف المافيا. وقد يحصل أحد المواطنين عشوائياً على قدرة القناص: طلقة واحدة للمباراة، يمكن تأجيلها.','good_citizen.jpg'],
  ['الجوكر','مستقل','لما الكل يخسر أعصابه، هو بيكسب.','له هدف مستقل: إقناع المدينة بإعدامه نهاراً. فوزه لا يتبع فوز المافيا أو المواطنين.','joker.jpg']
];
const roleButtons = [...document.querySelectorAll('[data-role]')];
function selectRole(index) {
  const [name,team,quote,description,file] = roles[index];
  const image = document.querySelector('#role-image');
  image.src = `assets/${file}`; image.alt = `شخصية ${name}`;
  document.querySelector('#role-name').textContent = name;
  document.querySelector('#role-team').textContent = team;
  document.querySelector('#role-quote').textContent = quote;
  document.querySelector('#role-description').textContent = description;
  document.querySelector('#role-index').textContent = `${String(index+1).padStart(2,'0')} / 08`;
  roleButtons.forEach((button,i) => button.setAttribute('aria-pressed',String(i===index)));
}
roleButtons.forEach((button,index) => {
  button.addEventListener('click',() => selectRole(index));
  button.addEventListener('keydown',event => {
    if (!['ArrowRight','ArrowLeft','Home','End'].includes(event.key)) return;
    event.preventDefault();
    const next = event.key==='Home' ? 0 : event.key==='End' ? roles.length-1 : (index+(event.key==='ArrowLeft'?1:-1)+roles.length)%roles.length;
    roleButtons[next].focus(); selectRole(next);
  });
});
const themes = {blood:['الأحمر الدموي','الثيم الأصلي'],midnight:['منتصف الليل','Premium'],emerald:['النادي الزمردي','Premium'],royal:['الجناح الملكي','Premium']};
document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click',() => {
  const theme = button.dataset.theme;
  document.querySelector('#theme-preview').dataset.palette = theme;
  document.querySelector('#theme-name').textContent = themes[theme][0];
  document.querySelector('#theme-access').textContent = themes[theme][1];
  document.querySelectorAll('[data-theme]').forEach(item => item.setAttribute('aria-pressed',String(item===button)));
}));
const menu = document.querySelector('.menu-toggle');
const navigation = document.querySelector('#navigation');
function closeMenu(){menu.setAttribute('aria-expanded','false');navigation.dataset.open='false';}
menu.addEventListener('click',() => {
  const open = menu.getAttribute('aria-expanded')!=='true';
  menu.setAttribute('aria-expanded',String(open));navigation.dataset.open=String(open);
});
navigation.addEventListener('click',event => {if(event.target.closest('a'))closeMenu();});
document.addEventListener('keydown',event => {if(event.key==='Escape' && menu.getAttribute('aria-expanded')==='true'){closeMenu();menu.focus();}});
