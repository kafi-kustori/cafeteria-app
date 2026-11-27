-- Run AFTER creating the two users in Authentication -> Users
insert into public.cards (id, card_no, name, balance, role)
select id, '2203014', 'Kafi', 1000, 'student' from auth.users where email = '2203014@cafeteria.app';

insert into public.cards (id, card_no, name, balance, role)
select id, 'admin01', 'Cafeteria Admin', 0, 'admin' from auth.users where email = 'admin01@cafeteria.app';
