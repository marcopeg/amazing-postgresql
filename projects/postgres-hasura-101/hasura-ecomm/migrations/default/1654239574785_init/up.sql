SET check_function_bodies = false;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW."updated_at" = NOW();
  RETURN NEW;
END;
$$;
CREATE SEQUENCE public.movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
CREATE TABLE public.movements (
    id integer DEFAULT nextval('public.movements_id_seq'::regclass) NOT NULL,
    tenant_id text NOT NULL,
    product_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    amount integer NOT NULL,
    note text NOT NULL
);
CREATE TABLE public.products (
    id text NOT NULL,
    tenant_id text NOT NULL,
    is_visible boolean DEFAULT true NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    price integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT products_price_check CHECK ((price > 0))
);
CREATE MATERIALIZED VIEW public.products_availability_cached AS
 SELECT movements.product_id,
    sum(movements.amount) AS amount,
    now() AS updated_at
   FROM public.movements
  GROUP BY movements.product_id
  WITH NO DATA;
CREATE VIEW public.products_availability_live AS
 SELECT movements.product_id,
    sum(movements.amount) AS amount
   FROM public.movements
  GROUP BY movements.product_id;
CREATE VIEW public.products_display AS
 SELECT p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.price,
    a.amount,
    p.created_at,
    p.updated_at
   FROM (public.products_availability_live a
     LEFT JOIN public.products p ON ((p.id = a.product_id)))
  WHERE ((p.is_visible IS TRUE) AND (a.amount > 0));
CREATE TABLE public.tenants (
    id text NOT NULL,
    name text NOT NULL
);
ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);
CREATE INDEX movements_product_id_idx ON public.movements USING btree (product_id);
CREATE INDEX products_is_visible ON public.products USING btree (is_visible) WHERE (is_visible = true);
CREATE TRIGGER set_public_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
