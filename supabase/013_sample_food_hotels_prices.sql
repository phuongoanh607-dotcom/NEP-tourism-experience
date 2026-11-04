-- NÉP 013: add coherent sample restaurants, hotels, menus and package prices.
-- These are fictional planning examples for the student presentation, not supplier bookings.
with sample(title,restaurant,hotel,menu,price) as (values
('Cao Bằng – bản làng và thác nước','Nhà hàng Non Nước Cao Bằng','Khách sạn Mường Thanh Luxury Cao Bằng','Bữa sáng buffet; trưa lợn quay, rau rừng, canh; tối vịt quay 7 vị, xôi nếp',3290000),
('Ba Bể – nhịp sống bên hồ','Nhà hàng Bản Pác Ngòi','Ba Bể Green Homestay','Bữa sáng phở/bún; trưa cá hồ nướng, rau bò khai; tối gà đồi, xôi ngũ sắc',2190000),
('Mộc Châu – mùa xanh cao nguyên','Nhà hàng Đông Hải Mộc Châu','Mường Thanh Holiday Mộc Châu','Bữa sáng buffet; trưa bê chao, cá suối; tối lẩu cá hồi, rau cao nguyên',2490000),
('Điện Biên – ký ức và miền biên viễn','Nhà hàng Hương Sen Điện Biên','Mường Thanh Grand Điện Biên Phủ','Bữa sáng buffet; trưa pa pỉnh tộp, xôi nếp nương; tối gà nướng mắc khén',2590000),
('Hạ Long – di sản nhìn từ mặt nước','Nhà hàng Hồng Hạnh 3','The Light Hotel Hạ Long','Bữa sáng buffet; trưa hải sản theo set; tối chả mực, sá sùng, canh chua',2890000),
('Quảng Bình – dấu chân miền di sản','Nhà hàng nổi Bình Minh','Riverside Hotel Quảng Bình','Bữa sáng buffet; trưa cháo canh, gà đồi; tối cá kho, ram đẻn theo set',3690000),
('Đà Nẵng – thành phố bên sông và biển','Nhà hàng Madame Lân','Sanouva Danang Hotel','Bữa sáng buffet; trưa mì Quảng, bánh tráng cuốn; tối hải sản theo set',2790000),
('Quy Nhơn – miền biển hiền hòa','Nhà hàng Cơm Nhà 1989','Seagull Hotel Quy Nhon','Bữa sáng buffet; trưa bánh xèo tôm nhảy, cá hấp; tối hải sản theo set',2690000),
('Phú Yên – miền xanh xứ Nẫu','Nhà hàng Sala Tuy Hòa','Sala Grand Tuy Hoa Hotel','Bữa sáng buffet; trưa mắt cá ngừ đại dương, sò huyết; tối cơm niêu cá kho',2590000),
('Buôn Ma Thuột – chuyện kể đại ngàn','Nhà hàng Ako Dhong','Elephants Hotel Buôn Ma Thuột','Bữa sáng buffet; trưa gà nướng cơm lam; tối lẩu lá rừng, canh cà đắng',2490000),
('Tây Ninh – hành trình về miền nắng','Nhà hàng Hoàng Minh','Sunrise Hotel Tây Ninh','Bữa trưa bánh tráng phơi sương, bò tơ, canh chua; nước suối',890000),
('Bến Tre – theo dòng xứ dừa','Nhà hàng nổi Bến Tre','Không lưu trú – tour trong ngày','Bữa trưa cá tai tượng chiên xù, gỏi củ hủ dừa, tép rang nước cốt dừa',790000),
('An Giang – sắc màu miền biên giới','Nhà hàng Bảy Bồng 2','Victoria Núi Sam Lodge','Bữa sáng buffet; trưa bún cá Châu Đốc, gỏi sầu đâu; tối lẩu mắm',2390000),
('Cà Mau – chạm miền cực Nam','Nhà hàng Quạt Mo','Muong Thanh Luxury Ca Mau Hotel','Bữa sáng buffet; trưa cua Cà Mau theo mùa, ba khía; tối cá thòi lòi nướng',2490000)
)
update public.journeys j set
 price_from=s.price,
 itinerary=coalesce((select jsonb_agg(
   step || jsonb_build_object(
    'restaurant',s.restaurant,
    'menu',s.menu,
    'hotel',case when j.duration_days>1 then s.hotel else 'Không lưu trú – tour trong ngày' end,
    'stay',case when j.duration_days>1 then (j.duration_days-1)::text || ' đêm · nhận phòng 14:00, trả phòng 12:00' else 'Không áp dụng' end
   ) order by ord
 ) from jsonb_array_elements(coalesce(j.itinerary,'[]'::jsonb)) with ordinality as x(step,ord)), '[]'::jsonb)
from sample s where j.title=s.title;
