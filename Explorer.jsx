import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, MapPin, Compass, CalendarDays, Wallet, Users, Sparkles, Map, Info } from 'lucide-react';
import { isConfigured, supabase } from './supabase';

const money=n=>new Intl.NumberFormat('vi-VN',{style:'currency',currency:'VND',maximumFractionDigits:0}).format(Number(n)||0);
const interests=['Thiên nhiên','Văn hóa bản địa','Làng nghề','Ẩm thực','Di sản','Nông nghiệp','Sông nước','Cộng đồng'];
const regions=['Toàn quốc','Miền Bắc','Miền Trung','Tây Nguyên','Miền Nam'];
const norm=s=>String(s||'').toLocaleLowerCase('vi-VN').normalize('NFD').replace(/[\u0300-\u036f]/g,'');
const durationRange={'2–3 giờ':[0,0.2],'Nửa ngày':[0.2,0.5],'1 ngày':[0.5,1],'2–3 ngày':[2,3],'Từ 4 ngày':[4,99]};
function match(x,a,type){
 const text=norm([x.name,x.title,x.category,x.tour_type,x.description,x.summary,x.region].join(' '));
 let points=0;const reasons=[];
 const regionMatch=a.region==='Toàn quốc'||norm(x.region)===norm(a.region);
 if(regionMatch&&a.region!=='Toàn quốc'){points+=5;reasons.push('đúng khu vực bạn chọn');}
 const matched=a.interests.filter(v=>text.includes(norm(v)));
 if(matched.length){points+=matched.length*3;reasons.push('khớp '+matched.slice(0,2).join(' và '));}
 if(a.mood==='Bình yên'&&/(thien nhien|song nuoc|vuon|cao nguyen|ho|rung|nong nghiep)/.test(text)){points+=2;reasons.push('phù hợp nhịp đi chậm');}
 if(a.mood==='Tìm hiểu văn hóa'&&/(van hoa|lang nghe|di san|cong dong|lich su|ban dia)/.test(text)){points+=2;reasons.push('có chiều sâu văn hóa');}
 if(a.mood==='Khám phá'&&/(kham pha|canh quan|thien nhien|di san|ban lang)/.test(text)){points+=2;reasons.push('có yếu tố khám phá');}
 if(type==='tour'){
  const days=Number(x.duration_days||1),range=durationRange[a.duration]||[0,99];
  const durationMatch=days>=range[0]&&days<=range[1];
  if(durationMatch){points+=3;reasons.push('đúng thời lượng mong muốn');}else points-=3;
  const guests= a.companions==='Đi một mình'?1:a.companions==='2 người'?2:a.companions==='3–5 người'?4:6;
  const min=Number(x.min_guests||1),max=x.max_guests==null?Infinity:Number(x.max_guests);
  if(guests>=min&&guests<=max){points+=1;reasons.push('phù hợp quy mô nhóm');}else points-=2;
 }
 const price=Number(x.price_from||0);
 if(a.budget>0&&price>0){if(price<=a.budget){points+=2;reasons.push('mức giá trong ngân sách tham khảo');}else points-=Math.min(5,Math.ceil((price-a.budget)/a.budget*2));}
 if(!reasons.length)reasons.push('lựa chọn để bạn tham khảo thêm');
 return {points,reasons};
}
function Card({item,type,rank,reason}){
 const tour=type==='tour',href=tour?'/tours/'+item.id:(item.slug?'/discover/'+item.slug:'/tours');
 const price=tour?((item.verified_at&&Number(item.price_from)>0)?'Từ '+money(item.price_from):'Cần xác nhận chi phí'):(Number(item.price_from)>0?'Từ '+money(item.price_from):'Miễn phí / cần xác nhận');
 return <article className="explorer-result"><div className="explorer-result-top"><span>{tour?'HÀNH TRÌNH':'ĐIỂM ĐẾN'} · GỢI Ý {rank}</span><span>{item.region||'Việt Nam'}</span></div><h3>{tour?item.title:item.name}</h3><p>{tour?item.summary:item.description}</p><div className="explorer-reason">{reason.join(' · ')}</div><div className="explorer-result-facts"><span><MapPin size={14}/>{item.region||'Việt Nam'}</span><span><Wallet size={14}/>{price}</span><span><CalendarDays size={14}/>{tour?(item.duration_label||((item.duration_days||1)+' ngày')):(item.duration||'Linh hoạt')}</span></div>{tour&&(!item.verified_at||!Number(item.price_from))&&<small className="explorer-note">Tour đang ở trạng thái tham khảo; lịch, giá và điều kiện vận hành cần được NÉP xác nhận trước khi đặt.</small>}<Link className="button small" to={href}>Xem chi tiết <ArrowRight size={15}/></Link></article>;
}
export default function Explorer({places=[]}){
 const [a,setA]=useState({mood:'Khám phá',interests:['Thiên nhiên','Văn hóa bản địa'],duration:'1 ngày',budget:1500000,companions:'2 người',region:'Toàn quốc'});
 const [done,setDone]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState(''),[tours,setTours]=useState([]),[departures,setDepartures]=useState([]);
 const upd=(k,v)=>setA(p=>({...p,[k]:v}));
 async function submit(e){
  e.preventDefault();setBusy(true);setDone(false);setError('');
  try{
   let rows=[];
   if(isConfigured){
    const r=await supabase.from('journeys').select('id,title,region,summary,tour_type,duration_days,duration_label,price_from,is_published,verified_at,min_guests,max_guests').eq('is_published',true);
    if(r.error)throw r.error;
    rows=r.data||[];
   }
   setTours(rows);
   if(rows.length){
    const d=await supabase.from('journey_departures').select('journey_id,departure_date,status').in('journey_id',rows.map(x=>x.id)).eq('status','scheduled').gte('departure_date',new Date().toISOString().slice(0,10));
    setDepartures(d.error?[]:d.data||[]);
   }else setDepartures([]);
   if(!isConfigured)setError('NÉP đang ở chế độ xem thử. Tour sẽ xuất hiện khi kết nối danh mục Supabase.');
  }catch(err){setTours([]);setDepartures([]);setError('Chưa tải được danh mục tour từ máy chủ. Bà vẫn có thể tham khảo các điểm đến hiện có.');}
  finally{setBusy(false);setDone(true);}
 }
 const rankedPlaces=useMemo(()=>places.map(item=>({...item,_match:match(item,a,'place')})).sort((x,y)=>y._match.points-x._match.points).slice(0,3),[places,a]);
 const rankedTours=useMemo(()=>tours.map(item=>({...item,_match:match(item,a,'tour')})).sort((x,y)=>y._match.points-x._match.points).slice(0,3),[tours,a]);
 const extra=useMemo(()=>places.filter(x=>x.id!==rankedPlaces[0]?.id&&(!rankedPlaces[0]?.region||norm(x.region)===norm(rankedPlaces[0].region))).slice(0,4),[places,rankedPlaces]);
 return <main className="explorer-page"><section className="explorer-hero"><div className="eyebrow">NÉP · HÀNH TRÌNH CỦA RIÊNG BẠN</div><h1>Tìm nơi chốn<br/><em>hợp với bạn.</em></h1><p>Chia sẻ sở thích và kế hoạch chuyến đi. NÉP đối chiếu với điểm đến và tour đã công bố để gợi ý lựa chọn phù hợp.</p><div className="explorer-promise"><span><Compass size={16}/> Gợi ý theo dữ liệu NÉP</span><span><Map size={16}/> Điểm đến trên khắp Việt Nam</span></div></section><section className="explorer-content"><form className="explorer-form" onSubmit={submit}><div className="explorer-form-heading"><div><span className="eyebrow">BƯỚC 01 · CHO NÉP BIẾT</span><h2>Bạn muốn chuyến đi như thế nào?</h2></div><Sparkles size={25}/></div><label className="explorer-label">Phong cách trải nghiệm</label><div className="explorer-choice-row">{['Bình yên','Khám phá','Tìm hiểu văn hóa'].map(v=><button type="button" key={v} className={a.mood===v?'explorer-choice active':'explorer-choice'} onClick={()=>upd('mood',v)}>{v}</button>)}</div><label className="explorer-label">Bạn quan tâm điều gì? <small>(có thể chọn nhiều)</small></label><div className="explorer-interest-grid">{interests.map(v=><label key={v} className={a.interests.includes(v)?'explorer-check active':'explorer-check'}><input type="checkbox" checked={a.interests.includes(v)} onChange={()=>upd('interests',a.interests.includes(v)?a.interests.filter(x=>x!==v):[...a.interests,v])}/>{v}</label>)}</div><div className="explorer-fields"><label><span><CalendarDays size={15}/> Thời gian</span><select value={a.duration} onChange={e=>upd('duration',e.target.value)}>{Object.keys(durationRange).map(v=><option key={v}>{v}</option>)}</select></label><label><span><Wallet size={15}/> Ngân sách dự kiến / người</span><select value={a.budget} onChange={e=>upd('budget',Number(e.target.value))}><option value="500000">Dưới 500.000đ</option><option value="1000000">500.000–1 triệu</option><option value="1500000">1–1,5 triệu</option><option value="3000000">1,5–3 triệu</option><option value="5000000">Trên 3 triệu</option><option value="0">Chưa xác định</option></select></label><label><span><Users size={15}/> Số người đi</span><select value={a.companions} onChange={e=>upd('companions',e.target.value)}>{['Đi một mình','2 người','3–5 người','Nhóm từ 6 người'].map(v=><option key={v}>{v}</option>)}</select></label><label><span><MapPin size={15}/> Khu vực mong muốn</span><select value={a.region} onChange={e=>upd('region',e.target.value)}>{regions.map(v=><option key={v}>{v}</option>)}</select></label></div><button className="button explorer-submit" disabled={busy}>{busy?'Đang tìm lựa chọn phù hợp…':'Xem gợi ý dành cho tôi'} <ArrowRight size={17}/></button><small className="explorer-disclaimer">Gợi ý được xếp hạng theo sở thích và dữ liệu đã công bố; không phải tư vấn AI hay xác nhận chỗ trống.</small></form>{done&&<section className="explorer-results" aria-live="polite"><div className="explorer-results-heading"><span className="eyebrow">BƯỚC 02 · KẾT QUẢ DÀNH CHO BẠN</span><h2>NÉP tìm thấy những lựa chọn này</h2><p>Thứ tự gợi ý dựa trên sở thích, thời lượng, ngân sách, quy mô nhóm và khu vực bạn chọn.</p></div>{error&&<p className="explorer-warning">{error}</p>}<div className="explorer-result-section"><h3><MapPin size={18}/> 3 điểm đến phù hợp</h3>{rankedPlaces.length?<div className="explorer-result-grid">{rankedPlaces.map((x,i)=><Card key={x.id} item={x} type="place" rank={i+1} reason={x._match.reasons}/>)}</div>:<p>Chưa có điểm đến được công bố phù hợp. Hãy xem <Link to="/tours">danh mục tour</Link>.</p>}</div><div className="explorer-result-section"><h3><Compass size={18}/> Tour phù hợp</h3>{rankedTours.length?<div className="explorer-result-grid">{rankedTours.map((x,i)=><Card key={x.id} item={x} type="tour" rank={i+1} reason={x._match.reasons}/>)}</div>:<p>Hiện chưa có tour được công bố trong danh mục. NÉP không tự tạo tour, giá hoặc lịch khởi hành chưa xác nhận.</p>}</div>{rankedPlaces.length>0&&extra.length>0&&<div className="explorer-result-section"><h3><Sparkles size={18}/> Khám phá thêm trong khu vực</h3><p>Một vài điểm đến khác cùng khu vực để bạn cân nhắc kết hợp vào hành trình.</p><div className="explorer-nearby-grid">{extra.map(x=><Link to={x.slug?'/discover/'+x.slug:'/tours'} key={x.id}><b>{x.name}</b><span>{x.category||'Điểm đến'} · {x.region}</span><ArrowRight size={15}/></Link>)}</div></div>}<div className="explorer-footnote"><Info size={16}/> {rankedTours.some(x=>departures.some(d=>d.journey_id===x.id))?'Có tour đã công bố lịch khởi hành; mở chi tiết để xem ngày và sức chứa.':'Lịch khởi hành và sức chứa chỉ hiển thị khi nhà tổ chức đã công bố.'}</div></section>}</section></main>;
}
