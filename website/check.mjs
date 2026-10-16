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
