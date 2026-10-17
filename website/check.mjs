import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import test from 'node:test';
import assert from 'node:assert/strict';
const source = readFileSync(new URL('./studio.js',import.meta.url),'utf8');
function openPage(hash='') {
  const listeners = {}, menuEvents = {}, navEvents = {};
  const attributes = { 'aria-expanded':'false' };
  let focused=false;
  const menu={getAttribute:name=>attributes[name],setAttribute:(name,value)=>attributes[name]=value,addEventListener:(name,fn)=>menuEvents[name]=fn,focus:()=>focused=true};
  const navigation={dataset:{},addEventListener:(name,fn)=>navEvents[name]=fn};
  let redirect=null;
  const document={querySelector:selector=>selector==='.studio-menu'?menu:navigation,addEventListener:(name,fn)=>listeners[name]=fn};
  runInNewContext(source,{document,location:{hash,replace:url=>redirect=url}});
  return {menu,navigation,menuEvents,navEvents,listeners,redirect,get focused(){return focused;}};
}
test('studio menu opens, closes after selecting a link, and Escape returns keyboard focus',()=>{
  const page=openPage();
  page.menuEvents.click();
  assert.equal(page.menu.getAttribute('aria-expanded'),'true');
  assert.equal(page.navigation.dataset.open,'true');
  page.navEvents.click({target:{closest:()=>({})}});
  assert.equal(page.menu.getAttribute('aria-expanded'),'false');
  page.menuEvents.click();
  page.listeners.keydown({key:'Escape'});
  assert.equal(page.navigation.dataset.open,'false');
  assert.equal(page.focused,true);
});
for(const section of ['download','experience','roles','themes','questions']) {
  test(`former game bookmark #${section} keeps its destination`,()=>{
    assert.equal(openPage(`#${section}`).redirect,`mafia.html#${section}`);
  });
}
test('studio links and unknown fragments stay on the studio homepage',()=>{
  for(const hash of ['','#work','#about','#next','#https://example.com']) assert.equal(openPage(hash).redirect,null);
});

const gameSource = readFileSync(new URL('./app.js',import.meta.url),'utf8');
function openGamePage() {
  const makeElement=(dataset={})=>({dataset,attributes:{},events:{},textContent:'',focused:false,
    setAttribute(name,value){this.attributes[name]=value;},getAttribute(name){return this.attributes[name];},
    addEventListener(name,fn){this.events[name]=fn;},focus(){this.focused=true;}});
  const roles=Array.from({length:8},(_,index)=>makeElement({role:String(index)}));
  const themes=['blood','midnight','emerald','royal'].map(theme=>makeElement({theme}));
  const ids=Object.fromEntries(['role-image','role-name','role-team','role-description','theme-preview','theme-name','theme-access'].map(id=>[`#${id}`,makeElement()]));
  const menu=makeElement(),navigation=makeElement(),documentEvents={};
  menu.setAttribute('aria-expanded','false');
  const document={querySelector(selector){
    if(selector==='.menu-toggle')return menu;
    if(selector==='#navigation')return navigation;
    assert.ok(ids[selector],`Unexpected or removed DOM element ${selector}`);
    return ids[selector];
  },querySelectorAll(selector){return selector==='[data-role]'?roles:themes;},addEventListener(name,fn){documentEvents[name]=fn;}};
  runInNewContext(gameSource,{document});
  return {roles,themes,ids,menu,navigation,documentEvents};
}
test('all game roles remain selectable after removing decorative captions',()=>{
  const page=openGamePage();
  for(const role of page.roles){
    role.events.click();
    assert.ok(page.ids['#role-description'].textContent.length>20);
    assert.match(page.ids['#role-image'].src,/^assets\/[a-z_]+\.jpg$/);
    assert.equal(page.roles.filter(item=>item.attributes['aria-pressed']==='true').length,1);
  }
  assert.equal(page.ids['#role-name'].textContent,'الجوكر');
  page.roles[7].events.keydown({key:'Home',preventDefault(){}});
  assert.equal(page.roles[0].focused,true);
  assert.equal(page.ids['#role-name'].textContent,'شيخ المافيا');
});
test('theme preview still updates the redesigned game panel',()=>{
  const page=openGamePage();
  for(const theme of page.themes){
    theme.events.click();
    assert.equal(page.ids['#theme-preview'].dataset.palette,theme.dataset.theme);
    assert.ok(page.ids['#theme-name'].textContent);
    assert.equal(page.themes.filter(item=>item.attributes['aria-pressed']==='true').length,1);
  }
  assert.equal(page.ids['#theme-access'].textContent,'Premium');
});
test('game mobile menu closes with Escape and returns focus',()=>{
  const page=openGamePage();page.menu.events.click();
  assert.equal(page.navigation.dataset.open,'true');
  page.documentEvents.keydown({key:'Escape'});
  assert.equal(page.navigation.dataset.open,'false');
  assert.equal(page.menu.focused,true);
});
