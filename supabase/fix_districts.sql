-- Заполняем район для объектов, у которых он не был указан явно
-- (информация была зашита в текст адреса).
update public.zhk set district = 'Алмалинский' where id = 'c01';
update public.zhk set district = 'Наурызбайский' where id = 'c02';
update public.zhk set district = 'Наурызбайский' where id = 'c03';
update public.zhk set district = 'Алмалинский' where id = 'c04';
update public.zhk set district = 'Турксибский' where id = 'c05';
update public.zhk set district = 'Турксибский' where id = 'c06';
update public.zhk set district = 'Бостандыкский' where id = 'c07';
update public.zhk set district = 'Ауэзовский' where id = 'c08';
update public.zhk set district = 'Наурызбайский' where id = 'c09';

-- c10 физически находится в Талгарском районе Алматинской области,
-- не в черте города — не один из 8 районов Алматы.
update public.zhk set district = 'Талгарский р-н (обл.)' where id = 'c10';

-- p06: в исходном документе район не был указан однозначно
-- ("не указан явно (район ул. Ауэзова)") — оставляем пустым,
-- а не гадаем, чтобы не давать неверную информацию.
update public.zhk set district = null where id = 'p06';
