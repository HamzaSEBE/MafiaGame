'use strict';
const menu = document.querySelector('.studio-menu');
const navigation = document.querySelector('#studio-navigation');
function closeMenu() {
  menu.setAttribute('aria-expanded','false');
  navigation.dataset.open='false';
}
menu.addEventListener('click',() => {
  const open = menu.getAttribute('aria-expanded')!=='true';
  menu.setAttribute('aria-expanded',String(open));
  navigation.dataset.open=String(open);
});
navigation.addEventListener('click',event => {if(event.target.closest('a'))closeMenu();});
document.addEventListener('keydown',event => {
  if(event.key==='Escape' && menu.getAttribute('aria-expanded')==='true') {closeMenu();menu.focus();}
});
// Preserve the former game page's section links after it moved to mafia.html.
const oldGameSections = new Set(['experience','roles','themes','questions','download']);
if(oldGameSections.has(location.hash.slice(1))) location.replace(`mafia.html${location.hash}`);
