-- =========================================================
-- Campus Cafeteria – database schema (run once in Supabase SQL Editor)
-- =========================================================

-- 1. Tables ------------------------------------------------
create table public.cards (
  id       uuid primary key references auth.users (id) on delete cascade,
  card_no  text unique not null,
  name     text not null,
  balance  integer not null default 0 check (balance >= 0),
  role     text not null default 'student' check (role in ('student', 'admin'))
);

create table public.menu_items (
  id              serial primary key,
  name            text unique not null,
  price           integer not null check (price > 0),
  stock           integer not null check (stock >= 0),
  low_stock_limit integer not null default 5
);

create table public.offers (
  id     serial primary key,
  code   text unique not null,   -- which Strategy class to use in the app
  title  text not null,
  active boolean not null default true
);

create table public.orders (
  id         bigserial primary key,
  card_id    uuid not null references public.cards (id),
  subtotal   integer not null,
  discount   integer not null,
  total      integer not null,
  created_at timestamptz not null default now()
);

create table public.order_items (
  order_id   bigint  not null references public.orders (id) on delete cascade,
  item_id    integer not null references public.menu_items (id),
  qty        integer not null check (qty > 0),
  unit_price integer not null,
  primary key (order_id, item_id)
);

-- 2. Helper: is the logged-in user an admin? ---------------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from cards where id = auth.uid() and role = 'admin');
$$;

-- 3. Row Level Security -----------------------------------
alter table public.cards       enable row level security;
alter table public.menu_items  enable row level security;
alter table public.offers      enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- cards: a student sees only their own card; admin sees all.
-- Nobody can change a balance directly – only through the functions below.
create policy cards_select on public.cards
  for select to authenticated using (id = auth.uid() or public.is_admin());

-- menu and offers: everyone logged in can read; only admin can change.
create policy menu_select on public.menu_items
  for select to authenticated using (true);
create policy menu_admin_insert on public.menu_items
  for insert to authenticated with check (public.is_admin());
create policy menu_admin_update on public.menu_items
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy offers_select on public.offers
  for select to authenticated using (true);
create policy offers_admin_update on public.offers
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- orders: a student sees only their own orders; admin sees all.
-- No insert policy: orders are created only by place_order().
create policy orders_select on public.orders
  for select to authenticated using (card_id = auth.uid() or public.is_admin());
create policy order_items_select on public.order_items
  for select to authenticated using (
    exists (select 1 from public.orders o
            where o.id = order_id and (o.card_id = auth.uid() or public.is_admin())));

-- 4. Checkout: all-or-nothing --------------------------------
-- p_items example: [{"item_id": 1, "qty": 2}, {"item_id": 4, "qty": 1}]
-- If anything fails (out of stock, low balance) an exception is raised
-- and PostgreSQL rolls back EVERYTHING done inside this function.
create or replace function public.place_order(p_items jsonb, p_discount integer)
returns json
language plpgsql security definer set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_balance  integer;
  v_subtotal integer := 0;
  v_total    integer;
  v_order_id bigint;
  v_line     jsonb;
  v_price    integer;
  v_stock    integer;
  v_qty      integer;
begin
  if v_uid is null then
    raise exception 'NOT_LOGGED_IN';
  end if;

  -- lock the card row so two checkouts of the same card cannot overlap
  select balance into v_balance from cards where id = v_uid for update;
  if not found then
    raise exception 'CARD_NOT_FOUND';
  end if;

  -- check stock and compute subtotal from the REAL prices in the database
  for v_line in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_line ->> 'qty')::integer;
    if v_qty is null or v_qty <= 0 then
      raise exception 'BAD_QUANTITY';
    end if;
    select price, stock into v_price, v_stock
      from menu_items where id = (v_line ->> 'item_id')::integer
      for update;                       -- lock the item row
    if not found then
      raise exception 'ITEM_NOT_FOUND:%', v_line ->> 'item_id';
    end if;
    if v_stock < v_qty then
      raise exception 'OUT_OF_STOCK:%:%', v_line ->> 'item_id', v_stock;
    end if;
    v_subtotal := v_subtotal + v_price * v_qty;
  end loop;

  if v_subtotal = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if p_discount < 0 or p_discount > v_subtotal then
    raise exception 'BAD_DISCOUNT';
  end if;

  v_total := v_subtotal - p_discount;
  if v_balance < v_total then
    raise exception 'LOW_BALANCE:%:%', v_balance, v_total;
  end if;

  -- everything is fine: write the order, reduce stock and balance
  insert into orders (card_id, subtotal, discount, total)
    values (v_uid, v_subtotal, p_discount, v_total)
    returning id into v_order_id;

  for v_line in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_line ->> 'qty')::integer;
    update menu_items set stock = stock - v_qty
      where id = (v_line ->> 'item_id')::integer
      returning price into v_price;
    insert into order_items (order_id, item_id, qty, unit_price)
      values (v_order_id, (v_line ->> 'item_id')::integer, v_qty, v_price);
  end loop;

  update cards set balance = balance - v_total where id = v_uid
    returning balance into v_balance;

  return json_build_object('order_id', v_order_id, 'subtotal', v_subtotal,
                           'discount', p_discount, 'total', v_total,
                           'new_balance', v_balance);
end;
$$;

-- 5. Admin: top up a card -----------------------------------
create or replace function public.top_up(p_card_no text, p_amount integer)
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  v_balance integer;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;
  if p_amount <= 0 then
    raise exception 'BAD_AMOUNT';
  end if;
  update cards set balance = balance + p_amount where card_no = p_card_no
    returning balance into v_balance;
  if not found then
    raise exception 'CARD_NOT_FOUND';
  end if;
  return v_balance;
end;
$$;

-- only logged-in users may call the functions
revoke execute on function public.place_order(jsonb, integer) from public, anon;
revoke execute on function public.top_up(text, integer)       from public, anon;
grant  execute on function public.place_order(jsonb, integer) to authenticated;
grant  execute on function public.top_up(text, integer)       to authenticated;

-- 6. Sample data ------------------------------------------
insert into public.menu_items (name, price, stock) values
  ('Burger', 100, 50), ('Bread', 40, 70), ('Coffee', 50, 20), ('Tea', 30, 15);

insert into public.offers (code, title) values
  ('combo_pack',  'Combo pack: 1 Burger + 1 Coffee = 130 Tk'),
  ('free_tea',    '2 Burgers + 1 Tea: the Tea is free'),
  ('coffee_pair', '2 Coffees: 5 Tk off'),
  ('bill_flat',   'Bill 100 Tk or more: 15 Tk off'),
  ('bill_percent','Bill 500 Tk or more: 10% off');
