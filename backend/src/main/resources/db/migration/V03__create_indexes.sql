CREATE INDEX orders_id_products ON order_product
(
    order_id ASC NULLS LAST
);

CREATE INDEX product_id_products ON order_product
(
    product_id ASC NULLS LAST
);

CREATE INDEX orders_id ON orders
(
    id ASC NULLS LAST
);

CREATE INDEX product_id_product ON product
(
id ASC NULLS LAST
);
