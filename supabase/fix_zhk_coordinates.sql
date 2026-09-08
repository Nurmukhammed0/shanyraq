-- Исправление координат ЖК: старые значения были синтетическими
-- (расставлены по кругу вокруг центра района, а не геокодированы),
-- из-за чего маркеры на карте собирались кольцами в 2-3 точках.
-- Новые координаты получены геокодированием адресов через OpenStreetMap
-- Nominatim (2026-09-08). Выполнить в Supabase SQL Editor.

update public.zhk set lat = 43.2416514, lng = 76.9101708 where id = 'c01';
update public.zhk set lat = 43.2153051, lng = 76.7915968 where id = 'c02';
update public.zhk set lat = 43.215627, lng = 76.790154 where id = 'c03';
update public.zhk set lat = 43.2638694, lng = 76.9429466 where id = 'c04';
update public.zhk set lat = 43.315128, lng = 76.999831 where id = 'c05';
update public.zhk set lat = 43.323353, lng = 76.9476186 where id = 'c06';
update public.zhk set lat = 43.2401552, lng = 76.9150888 where id = 'c07';
update public.zhk set lat = 43.2461162, lng = 76.853085 where id = 'c08';
update public.zhk set lat = 43.2307752, lng = 76.8007799 where id = 'c09';
update public.zhk set lat = 43.2830772, lng = 77.0181499 where id = 'c10';
update public.zhk set lat = 43.3146426, lng = 76.8774804 where id = 'p01';
update public.zhk set lat = 43.341095, lng = 76.814125 where id = 'p02';
update public.zhk set lat = 43.2510565, lng = 76.9410984 where id = 'p03';
update public.zhk set lat = 43.2476174, lng = 76.8849497 where id = 'p04';
update public.zhk set lat = 43.2547586, lng = 76.9077435 where id = 'p05';
update public.zhk set lat = 43.2600107, lng = 76.9038454 where id = 'p06';
update public.zhk set lat = 43.158642, lng = 76.89946 where id = 'p07';
update public.zhk set lat = 43.1851146, lng = 76.8760053 where id = 'p08';
update public.zhk set lat = 43.2114682, lng = 76.9249656 where id = 'p09';
update public.zhk set lat = 43.185684, lng = 76.926392 where id = 'p10';
update public.zhk set lat = 43.1762341, lng = 76.8676493 where id = 'p11';
update public.zhk set lat = 43.1841322, lng = 76.9013204 where id = 'p12';
update public.zhk set lat = 43.185361, lng = 76.927545 where id = 'p13';
update public.zhk set lat = 43.2379268, lng = 76.9913122 where id = 'p14';
update public.zhk set lat = 43.1840778, lng = 76.9425507 where id = 'p15';
update public.zhk set lat = 43.184757, lng = 76.902209 where id = 'p16';
update public.zhk set lat = 43.1375789, lng = 76.9271235 where id = 'p17';
update public.zhk set lat = 43.2312049, lng = 76.9612974 where id = 'p18';
update public.zhk set lat = 43.2207093, lng = 76.9356661 where id = 'p19';
update public.zhk set lat = 43.2471195, lng = 76.9591203 where id = 'p20';
update public.zhk set lat = 43.2387919, lng = 76.9538181 where id = 'p21';
update public.zhk set lat = 43.2496497, lng = 76.9846764 where id = 'p22';
update public.zhk set lat = 43.2229794, lng = 76.9397427 where id = 'p23';
update public.zhk set lat = 43.175821, lng = 76.865671 where id = 'p24';
update public.zhk set lat = 43.1742607, lng = 76.8098007 where id = 'p25';
update public.zhk set lat = 43.1797468, lng = 76.8312927 where id = 'p26';
update public.zhk set lat = 43.1655386, lng = 76.8507745 where id = 'p27';
update public.zhk set lat = 43.1828203, lng = 76.8610146 where id = 'p28';
