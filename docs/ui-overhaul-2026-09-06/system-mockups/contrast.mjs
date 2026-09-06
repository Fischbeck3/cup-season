const hex=h=>{h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16)/255)};
const lin=c=>c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);
const L=h=>{const[r,g,b]=hex(h).map(lin);return 0.2126*r+0.7152*g+0.0722*b};
const cr=(a,b)=>{const l1=L(a),l2=L(b);return ((Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05))};
const f=n=>n.toFixed(2);
// sRGB -> Lab for deltaE
function lab(h){let[r,g,b]=hex(h).map(lin);let X=r*0.4124+g*0.3576+b*0.1805,Y=r*0.2126+g*0.7152+b*0.0722,Z=r*0.0193+g*0.1192+b*0.9505;
 const wx=0.95047,wy=1,wz=1.08883;const g2=t=>t>0.008856?Math.cbrt(t):(7.787*t+16/116);
 const fx=g2(X/wx),fy=g2(Y/wy),fz=g2(Z/wz);return [116*fy-16,500*(fx-fy),200*(fy-fz)];}
const dE=(a,b)=>{const A=lab(a),B=lab(b);return Math.hypot(A[0]-B[0],A[1]-B[1],A[2]-B[2]);};

const dark={bg0:'#0F1A15',bg1:'#1A2620',bg2:'#26352E',rule:'#4A6155',ink:'#F1F4EF',mut:'#9BA69D',dim:'#5E6A62',
 panel:'#E9ECE3',panelInk:'#0B120E',panelMut:'#4C574F',leaf:'#EFEADD',leafInk:'#1A1B14',leafMut:'#57605A',
 brand:'#E8622C',gold:'#D8B25A',pos:'#4EC584',neg:'#FF6A5E',cool:'#7F8C95',
 sq0:'#57A8FF',sq1:'#FB8B4B',sq2:'#A78BFA',sq3:'#2FD3BE',
 pig0:'#25352D',pig1:'#37302A',pig2:'#28313A',pig3:'#383524',pig4:'#322B39',pig5:'#363530',ceremony:'#0A0E0C'};
const light={bg0:'#F4F1E9',bg1:'#EAE6DB',bg2:'#DED8C8',rule:'#A9A08A',ink:'#151B17',mut:'#575F57',dim:'#8B9089',
 panel:'#141A16',panelInk:'#F4F1E9',panelMut:'#A6AEA5',leaf:'#FCFAF3',leafInk:'#1A1B14',leafMut:'#5A625A',
 brand:'#A8420F',gold:'#7A5A12',pos:'#0B7340',neg:'#B02A20',cool:'#5D6862',
 sq0:'#1B66B6',sq1:'#A64F10',sq2:'#6446CE',sq3:'#0A7266',
 pig0:'#E2E4D9',pig1:'#EBE0D4',pig2:'#DDE1E6',pig3:'#EDE6CE',pig4:'#E5DEE9',pig5:'#E9E6DE',ceremony:'#0A0E0C'};

for(const [nm,T] of [['DARK',dark],['LIGHT',light]]){
 console.log('\n=== '+nm+' ===  ground dE from #000 = '+dE(T.bg0,'#000000').toFixed(2)+'  dE(bg0,bg1)='+dE(T.bg0,T.bg1).toFixed(2));
 const grounds=['bg0','bg1','bg2'];
 console.log('token      '+grounds.map(g=>g.padStart(7)).join('')+'   role');
 for(const k of ['ink','mut','dim','rule','brand','gold','pos','neg','cool','sq0','sq1','sq2','sq3','panel','leaf'])
   console.log(k.padEnd(11)+grounds.map(g=>f(cr(T[k],T[g])).padStart(7)).join(''));
 console.log('on panel : panelInk '+f(cr(T.panelInk,T.panel))+'  panelMut '+f(cr(T.panelMut,T.panel))+'  gold '+f(cr(T.gold,T.panel))+'  brand '+f(cr(T.brand,T.panel)));
 console.log('on leaf  : leafInk '+f(cr(T.leafInk,T.leaf))+'  leafMut '+f(cr(T.leafMut,T.leaf))+'  gold '+f(cr(T.gold,T.leaf)));
 console.log('on metal : bg0-on-brand '+f(cr(T.bg0,T.brand))+'  bg0-on-gold '+f(cr(T.bg0,T.gold))+'  panelInk-on-gold '+f(cr(T.panelInk,T.gold)));
 console.log('ceremony : ink '+f(cr(T.ink,T.ceremony))+'  gold '+f(cr(T.gold,T.ceremony))+'  mut '+f(cr(T.mut,T.ceremony)));
 console.log('pigments (marker ink = mut / ink):');
 for(const p of ['pig0','pig1','pig2','pig3','pig4','pig5'])
   console.log('  '+p+' vs bg0 '+f(cr(T[p],T.bg0))+'  mut-on '+f(cr(T.mut,T[p]))+'  ink-on '+f(cr(T.ink,T[p])));
}
