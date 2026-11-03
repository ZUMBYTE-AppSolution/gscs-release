'use strict';
(()=>{
 const repository='ghcr.io/zumbyte-appsolution/gscs';
 const names={alpha:'Alpha',beta:'Beta',release:'Release'};
 const manifestUrl='https://raw.githubusercontent.com/ZUMBYTE-AppSolution/gscs-release/main/docker/unraid/channels.json';
 const start=()=>{
  const input=document.querySelector('input[name="contRepository"]');if(!input)return;
  const form=input.form;if(!form)return;
  let available={alpha:true,beta:false,release:false},box=null,select=null,generated=null,scheduled=false;
  const originalReadonly=new Map();
  function reference(){const value=input.value.trim();return value.startsWith(repository+':')&&/^[A-Za-z0-9_.-]+$/.test(value.slice(repository.length+1))?value:null;}
  function gameField(){
   const field=[...form.querySelectorAll('input[name="confTarget[]"]')].filter(e=>e.value==='GSCS_CONTAINER_IMAGE').map(e=>e.closest('[id^="ConfigNum"]')?.querySelector('[name="confValue[]"]')).find(Boolean);
   return field||generated?.querySelector('[name="confValue[]"]');
  }
  function addGameField(value){
   generated=document.createElement('div');generated.hidden=true;generated.dataset.gscsChannelField='true';
   const fields={Name:'Spielserver-Image',Target:'GSCS_CONTAINER_IMAGE',Default:value,Mode:'',Description:'Verwendet dasselbe Image wie GSCS.',Type:'Variable',Display:'advanced',Required:'true',Mask:'false',Value:value};
   for(const [name,text] of Object.entries(fields)){const field=document.createElement('input');field.type='hidden';field.name='conf'+name+'[]';field.value=text;generated.append(field);}
   form.append(generated);return generated.querySelector('[name="confValue[]"]');
  }
  function syncGame(value){
   const field=gameField()||addGameField(value);
   if(generated&&!generated.contains(field)){for(const item of originalReadonly.keys())if(generated.contains(item))originalReadonly.delete(item);generated.remove();generated=null;}
   if(!originalReadonly.has(field))originalReadonly.set(field,field.readOnly);
   field.value=value;if(field instanceof HTMLInputElement)field.readOnly=true;
  }
  function remove(){
   box?.remove();box=null;select=null;generated?.remove();generated=null;
   for(const [field,readonly] of originalReadonly)if(field.isConnected)field.readOnly=readonly;
   originalReadonly.clear();
  }
  function refresh(){
   const value=reference();if(!value){remove();return;}
   const tag=value.slice(repository.length+1);
   if(!box){
    box=document.createElement('div');box.id='gscs-channel-selector';box.style.cssText='margin:0 0 12px;display:flex;align-items:center;gap:10px;flex-wrap:wrap';
    const label=document.createElement('label');label.htmlFor='gscs-update-channel';label.textContent='Updatekanal';
    select=document.createElement('select');select.id='gscs-update-channel';select.setAttribute('aria-label','GSCS Updatekanal');select.style.minWidth='220px';
    for(const [key,name] of Object.entries(names)){const option=document.createElement('option');option.value=key;option.textContent=name;select.append(option);}
    box.append(label,select);input.before(box);
    select.addEventListener('change',()=>{
     if(!Object.hasOwn(names,select.value)||select.selectedOptions[0]?.disabled)return;
     input.value=repository+':'+select.value;syncGame(input.value);input.dispatchEvent(new Event('input',{bubbles:true}));input.dispatchEvent(new Event('change',{bubbles:true}));
     // Unraid uses the container-name change event to mark the template as edited.
     if(window.jQuery)window.jQuery('input[name="contName"]').trigger('change');
     refresh();
    });
   }
   let fixed=select.querySelector('[data-gscs-fixed]');
   if(!Object.hasOwn(names,tag)){
    if(!fixed){fixed=document.createElement('option');fixed.dataset.gscsFixed='true';select.append(fixed);}
    fixed.value=tag;const label='Version '+tag+' (fest)';if(fixed.textContent!==label)fixed.textContent=label;
   }else fixed?.remove();
   for(const [key,name] of Object.entries(names)){
    const option=[...select.options].find(o=>o.value===key);const enabled=available[key]||tag===key;option.disabled=!enabled;
    const label=enabled?name:name+' (noch nicht verfügbar)';if(option.textContent!==label)option.textContent=label;
   }
   select.value=tag;syncGame(value);
  }
  function schedule(){if(scheduled)return;scheduled=true;setTimeout(()=>{scheduled=false;refresh();},0);}
  input.addEventListener('input',schedule);input.addEventListener('change',schedule);
  new MutationObserver(schedule).observe(form,{childList:true,subtree:true});
  form.addEventListener('submit',()=>{const value=reference();if(value)syncGame(value);},true);
  refresh();schedule();
  // This public manifest contains availability only; registry credentials stay on Unraid.
  const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),5000);
  fetch(manifestUrl,{credentials:'omit',referrerPolicy:'no-referrer',cache:'no-cache',signal:controller.signal}).then(async response=>{
   if(!response.ok)return;const raw=await response.text();if(raw.length>16384)return;const data=JSON.parse(raw);
   if(data.schemaVersion!==1||data.repository!==repository)return;
   available=Object.fromEntries(Object.keys(names).map(key=>[key,data.channels?.[key]?.available===true]));refresh();
  }).catch(()=>{}).finally(()=>clearTimeout(timeout));
 };
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start,{once:true});else start();
})();
